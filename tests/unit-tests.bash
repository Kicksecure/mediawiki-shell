#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Offline unit tests for mediawiki-shell: pure functions and helpers that
## need no live wiki -- the filename<->title codec (mw-urlencode), the import
## XML builder (mw-build-import-xml), and the security/iteration helpers in
## usr/share/mediawiki-shell/common (path-traversal guard, continue-from
## logic, backup-item encode/decode round-trip).
##
## Run on CI (no wiki required). For live-wiki coverage see integration-tests.bash.

set -o nounset
set -o pipefail

if [ "${CI:-}" != "true" ]; then
  printf '%s\n' "$0: These tests are only supposed to run on CI (set CI=true)." >&2
  exit 1
fi

PASS=0
FAIL=0
ERRORS=""

pass() { printf '%s\n' "PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { printf '%s\n' "FAIL: $1" >&2; FAIL=$(( FAIL + 1 )); ERRORS="${ERRORS}  FAIL: $1"$'\n'; }

assert_eq() {
  ## assert_eq DESC EXPECTED ACTUAL
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$2', got '$3')"; fi
}

assert_rc() {
  ## assert_rc DESC EXPECTED_RC ACTUAL_RC
  if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected rc '$2', got '$3')"; fi
}

mw_urlencode="$(command -v mw-urlencode)"
import_xml_builder="/usr/libexec/mediawiki-shell/mw-build-import-xml"

## ===========================================================================
printf '%s\n' "=== mw-urlencode: filename <-> title round-trip ==="
## ===========================================================================
## set_backup_page_item / decode_backup_page_item are built on these two.
## Round-trip is EXACT for canonical (underscore-form) titles. Spaces are
## intentionally normalized to underscores (MediaWiki treats space and
## underscore as equivalent in titles; git-mediawiki filename convention), so
## display-form titles with spaces are tested as a normalization below, not
## here. These cover the characters that MUST percent-encode to be
## filesystem-safe and decode back unchanged.
roundtrip_titles=(
  "Documentation"
  "Dev/mediawiki"
  "Template:Header"
  "Widget:CodeSelect"
  "A_page_with_underscores"
  "Foo&Bar"
  "100%Done"
  "C++Programming"
  "Question?Mark"
  "Hash#Fragment"
  "Category:Tor"
)
for title in "${roundtrip_titles[@]}"; do
  enc="$("${mw_urlencode}" --encode-page-to-filename "${title}")" || { fail "encode '${title}' errored"; continue; }
  ## Encoded form must be a single line and contain no '/' (subpage separator
  ## must be percent-encoded so it cannot create directories) and no spaces.
  if printf '%s' "${enc}" | grep -q '/'; then fail "encoded '${title}' still contains '/': '${enc}'"; continue; fi
  if printf '%s' "${enc}" | grep -q ' '; then fail "encoded '${title}' still contains a space: '${enc}'"; continue; fi
  dec="$("${mw_urlencode}" --decode-filename-to-page "${enc}")" || { fail "decode '${enc}' errored"; continue; }
  assert_eq "round-trip '${title}' (enc='${enc}')" "${title}" "${dec}"
done

## Spaces specifically must become underscores (git-mediawiki convention).
enc_space="$("${mw_urlencode}" --encode-page-to-filename "A page with spaces")"
assert_eq "space -> underscore" "A_page_with_spaces" "${enc_space}"

## Decoding the underscore form yields the underscore (canonical) title, NOT a
## space. MediaWiki treats space and underscore as equivalent in titles, so
## this is lossless at the wiki level; assert it as intended behavior.
dec_us="$("${mw_urlencode}" --decode-filename-to-page "A_page_with_spaces")"
assert_eq "decode keeps underscore canonical form (space==underscore)" "A_page_with_spaces" "${dec_us}"

## '/' must become %2F (preserve subpage, no directory traversal).
enc_slash="$("${mw_urlencode}" --encode-page-to-filename "Dev/mediawiki")"
assert_eq "slash -> %2F" "Dev%2Fmediawiki" "${enc_slash}"

## ===========================================================================
printf '%s\n' "=== mw-build-import-xml: XML construction + unsafe-title skip ==="
## ===========================================================================
fixture_dir="$(mktemp -d)"
xml_out="$(mktemp)"
cleanup_fixtures() { rm -rf -- "${fixture_dir}" "${xml_out}"; }
trap cleanup_fixtures EXIT

## Three legitimate pages across namespaces, with content needing XML escaping.
printf '%s\n' "Hello <world> & friends" > "${fixture_dir}/Documentation.mw"
printf '%s\n' "subpage body"            > "${fixture_dir}/Dev%2Fmediawiki.mw"
printf '%s\n' "{{#widget:CodeSelect}}"  > "${fixture_dir}/Widget:CodeSelect.mw"
## A non-.mw file must be ignored.
printf '%s\n' "ignore me"               > "${fixture_dir}/README.txt"

count="$("${import_xml_builder}" "${fixture_dir}" "${xml_out}")"
assert_eq "import-xml page count (3 .mw files, 1 non-.mw ignored)" "3" "${count}"

## XML well-formedness + content escaping + subpage title decode.
if command -v xmllint >/dev/null 2>&1; then
  if xmllint --noout "${xml_out}" 2>/dev/null; then pass "import XML is well-formed"; else fail "import XML is not well-formed"; fi
fi
if grep -q '<title>Dev/mediawiki</title>' "${xml_out}"; then pass "subpage filename %2F decoded back to '/' in title"; else fail "subpage title not decoded"; fi
if grep -q 'Hello &lt;world&gt; &amp; friends' "${xml_out}"; then pass "page text XML-escaped"; else fail "page text not XML-escaped"; fi

## Unsafe titles must be skipped, not written (path traversal / absolute / control).
unsafe_dir="$(mktemp -d)"
printf '%s\n' "evil" > "${unsafe_dir}/%2E%2E%2Fescape.mw"   # decodes to "../escape"
printf '%s\n' "ok"   > "${unsafe_dir}/Safe.mw"
unsafe_count="$("${import_xml_builder}" "${unsafe_dir}" "$(mktemp)" 2>/dev/null)"
assert_eq "import-xml skips traversal title (only 'Safe' kept)" "1" "${unsafe_count}"
rm -rf -- "${unsafe_dir}"

## ===========================================================================
printf '%s\n' "=== common: assert_path_within_dir (traversal guard) ==="
## ===========================================================================
## Run each in a subshell so common's 'set -o errexit'/traps don't abort the
## harness; capture the exit code (die -> non-zero).
run_in_common() { ( source /usr/share/mediawiki-shell/common >/dev/null 2>&1; "$@" ) >/dev/null 2>&1; }

base_dir="$(mktemp -d)"
rc=0; run_in_common assert_path_within_dir "${base_dir}" "${base_dir}/sub/file.mw" || rc=$?
assert_rc "assert_path_within_dir allows path inside base" "0" "${rc}"

rc=0; run_in_common assert_path_within_dir "${base_dir}" "${base_dir}/../escape" || rc=$?
if [ "${rc}" != "0" ]; then pass "assert_path_within_dir blocks '..' traversal"; else fail "assert_path_within_dir allowed traversal"; fi

rc=0; run_in_common assert_path_within_dir "${base_dir}" "/etc/passwd" || rc=$?
if [ "${rc}" != "0" ]; then pass "assert_path_within_dir blocks absolute outside path"; else fail "assert_path_within_dir allowed outside path"; fi
rmdir "${base_dir}" 2>/dev/null || true

## ===========================================================================
printf '%s\n' "=== common: should_start_processing (--continue-from) ==="
## ===========================================================================
## Empty continue-from -> always process. Integer -> from that 1-based index.
## String -> from the matching title (case-insensitive).
ssp() {
  ## ssp INDEX TITLE CONTINUE_FROM INITIAL_STATE -> prints "process" or "skip"
  ( source /usr/share/mediawiki-shell/common >/dev/null 2>&1
    # shellcheck disable=SC2034  # consumed by should_start_processing via nameref ($4)
    state="$4"
    if should_start_processing "$1" "$2" "$3" state; then printf 'process'; else printf 'skip'; fi )
}
assert_eq "continue-from empty -> process"            "process" "$(ssp 1 Alpha '' no)"
assert_eq "continue-from int 3, index 2 -> skip"      "skip"    "$(ssp 2 Beta 3 no)"
assert_eq "continue-from int 3, index 3 -> process"   "process" "$(ssp 3 Gamma 3 no)"
assert_eq "continue-from int 3, index 4 -> process"   "process" "$(ssp 4 Delta 3 no)"
assert_eq "continue-from already-yes -> process"      "process" "$(ssp 1 Alpha SomeTitle yes)"
assert_eq "continue-from title match (case-insens)"   "process" "$(ssp 5 documentation Documentation no)"
assert_eq "continue-from title no-match -> skip"      "skip"    "$(ssp 5 Other Documentation no)"

## ===========================================================================
printf '%s\n' "=== common: set_backup_page_item/decode round-trip ==="
## ===========================================================================
## The encode/decode pair used by the backup/restore filename mapping.
bp_roundtrip() {
  ( source /usr/share/mediawiki-shell/common >/dev/null 2>&1
    enc="$(set_backup_page_item "$1")"
    decode_backup_page_item "${enc}" )
}
for t in "Documentation" "Dev/mediawiki" "Template:Header" "Foo&Bar"; do
  assert_eq "set/decode_backup_page_item round-trip '${t}'" "${t}" "$(bp_roundtrip "${t}")"
done

## ===========================================================================
printf '%s\n' "=== SUMMARY ==="
## ===========================================================================
printf '%s\n' "PASS=${PASS} FAIL=${FAIL}"
if [ "${FAIL}" -ne 0 ]; then
  printf '%s\n' "FAILURES:" >&2
  printf '%s' "${ERRORS}" >&2
  exit 1
fi
printf '%s\n' "$0: all unit tests passed."
