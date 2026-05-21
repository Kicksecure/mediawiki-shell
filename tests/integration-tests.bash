#!/bin/bash

## Copyright (C) 2026 - 2026 ENCRYPTED SUPPORT LLC <adrelanos@whonix.org>
## See the file COPYING for copying conditions.

## AI-Assisted

## Live-wiki integration tests for mediawiki-shell. Exercises the read-only
## query path and the (read-only) backup path against a running MediaWiki:
##   mw-all-pages, mw-fetch, mw-page-pending-check, mw-wiki-fetch-backup,
##   mw-process-all-pages.
##
## These need a live wiki. Point WIKI_URL at it (".../w", no trailing slash).
## Locally that is the reproduced wiki from dist-encrypted; in CI it is the
## wiki stood up by the reproduction job (see the suggested workflow).
##
## Mutating scripts (mw-edit/mw-delete/mw-protect/mw-file-upload/
## mw-flagged-revisions-*/mw-copy-*/mw-multi-wiki) are NOT exercised here: they
## require a logged-in bot account (WIKI_API_USER_NAME/PASS), the
## 'mediawiki-shell' change tag registered on the wiki, and review rights.
## They belong in a separate, credential-gated suite run against a throwaway
## wiki.
##
## Env:
##   WIKI_URL            default http://127.0.0.1:9090/w
##   SOURCE_BACKUP_DIR   default /home/user/kicksecure-wiki-backup
##                       (when present, fetched pages are byte-compared to it)
##   SANITY_TITLE        default Documentation   (a ns0 page expected to exist)
##   SANITY_WIDGET       default Widget:CodeSelect (ns274, backup sanity anchor)

set -o nounset
set -o pipefail

if [ "${CI:-}" != "true" ]; then
  printf '%s\n' "$0: These tests are only supposed to run on CI (set CI=true)." >&2
  exit 1
fi

WIKI_URL="${WIKI_URL:-http://127.0.0.1:9090/w}"
SOURCE_BACKUP_DIR="${SOURCE_BACKUP_DIR:-/home/user/kicksecure-wiki-backup}"
SANITY_TITLE="${SANITY_TITLE:-Documentation}"
SANITY_WIDGET="${SANITY_WIDGET:-Widget:CodeSelect}"

PASS=0
FAIL=0
ERRORS=""
pass() { printf '%s\n' "PASS: $1"; PASS=$(( PASS + 1 )); }
fail() { printf '%s\n' "FAIL: $1" >&2; FAIL=$(( FAIL + 1 )); ERRORS="${ERRORS}  FAIL: $1"$'\n'; }

work="$(mktemp -d)"
export TMPFOLDER="${work}/mws-temp"
mkdir -p "${TMPFOLDER}"
cleanup() { rm -rf -- "${work}"; }
trap cleanup EXIT

printf '%s\n' "WIKI_URL=${WIKI_URL}  SOURCE_BACKUP_DIR=${SOURCE_BACKUP_DIR}"

## ===========================================================================
printf '%s\n' "=== mw-all-pages: enumerate (read-only) ==="
## ===========================================================================
allpages="${work}/allpages.txt"
rc=0
mw-all-pages --namespace-extra-list="274 500" --article-sanity-test="${SANITY_WIDGET}" \
  "${WIKI_URL}" allpages "${allpages}" >/dev/null 2>&1 || rc=$?
if [ "${rc}" = "0" ] && [ -s "${allpages}" ]; then
  n="$(wc -l < "${allpages}")"
  pass "mw-all-pages enumerated ${n} page(s)"
  if grep -qx "${SANITY_TITLE}" "${allpages}"; then pass "mw-all-pages list contains '${SANITY_TITLE}'"; else fail "mw-all-pages list missing '${SANITY_TITLE}'"; fi
  if grep -qi "${SANITY_WIDGET}" "${allpages}"; then pass "mw-all-pages list contains sanity widget '${SANITY_WIDGET}'"; else fail "mw-all-pages list missing '${SANITY_WIDGET}'"; fi
else
  fail "mw-all-pages failed (rc=${rc})"
fi

## ===========================================================================
printf '%s\n' "=== mw-fetch: fetch page wikitext (read-only) ==="
## ===========================================================================
fetched="${work}/fetched.mw"
rc=0
mw-fetch "${WIKI_URL}" "${SANITY_TITLE}" "${fetched}" >/dev/null 2>&1 || rc=$?
if [ "${rc}" = "0" ] && [ -s "${fetched}" ]; then
  pass "mw-fetch '${SANITY_TITLE}' returned $(wc -c < "${fetched}") bytes"
else
  fail "mw-fetch '${SANITY_TITLE}' failed (rc=${rc})"
fi

## ===========================================================================
printf '%s\n' "=== mw-page-pending-check: not-pending page (read-only) ==="
## ===========================================================================
## In the reproduced wiki (FlaggedRevs with default empty namespaces), imported
## pages are not pending -> exit 0.
rc=0
mw-page-pending-check "${WIKI_URL}" "${SANITY_TITLE}" >/dev/null 2>&1 || rc=$?
if [ "${rc}" = "0" ]; then pass "mw-page-pending-check '${SANITY_TITLE}' -> not pending (exit 0)"; else fail "mw-page-pending-check '${SANITY_TITLE}' unexpected rc=${rc}"; fi

## ===========================================================================
printf '%s\n' "=== mw-wiki-fetch-backup: single page -> .mw + fidelity ==="
## ===========================================================================
out_one="${work}/one.mw"
rc=0
mw-wiki-fetch-backup "${WIKI_URL}" "${SANITY_TITLE}" "${out_one}" >/dev/null 2>&1 || rc=$?
if [ "${rc}" = "0" ] && [ -s "${out_one}" ]; then
  pass "mw-wiki-fetch-backup wrote '${SANITY_TITLE}'"
  src="${SOURCE_BACKUP_DIR}/$(mw-urlencode --encode-page-to-filename "${SANITY_TITLE}").mw"
  if [ -f "${src}" ]; then
    if cmp -s "${out_one}" "${src}"; then pass "fetched '${SANITY_TITLE}' byte-identical to source backup"; else fail "fetched '${SANITY_TITLE}' differs from source backup"; fi
  fi
else
  fail "mw-wiki-fetch-backup '${SANITY_TITLE}' failed (rc=${rc})"
fi

## ===========================================================================
printf '%s\n' "=== mw-process-all-pages: backup one namespace + fidelity ==="
## ===========================================================================
## Limit to the MediaWiki: namespace (ns8) only to keep this fast while still
## exercising the full enumerate->fetch->write orchestration end to end.
ns_dir="${work}/ns8-backup"
mkdir -p "${ns_dir}"
rc=0
mw-process-all-pages --namespace-default-list="8" \
  "${WIKI_URL}" mw-wiki-fetch-backup "${ns_dir}" >/dev/null 2>&1 || rc=$?
produced="$(find "${ns_dir}" -maxdepth 1 -name '*.mw' | wc -l)"
if [ "${rc}" = "0" ] && [ "${produced}" -gt 0 ]; then
  pass "mw-process-all-pages backed up ${produced} MediaWiki:-namespace page(s)"
  if [ -d "${SOURCE_BACKUP_DIR}" ]; then
    mism=0
    while IFS= read -r f; do
      s="${SOURCE_BACKUP_DIR}/$(basename "$f")"
      [ -f "$s" ] || { mism=$((mism+1)); continue; }
      cmp -s "$f" "$s" || mism=$((mism+1))
    done < <(find "${ns_dir}" -maxdepth 1 -name '*.mw')
    if [ "${mism}" -eq 0 ]; then pass "all ${produced} ns8 backups byte-identical to source"; else fail "${mism}/${produced} ns8 backups differ from source"; fi
  fi
else
  fail "mw-process-all-pages (ns8) failed (rc=${rc}, produced=${produced})"
fi

## ===========================================================================
printf '%s\n' "=== SUMMARY ==="
## ===========================================================================
printf '%s\n' "PASS=${PASS} FAIL=${FAIL}"
if [ "${FAIL}" -ne 0 ]; then printf '%s' "${ERRORS}" >&2; exit 1; fi
printf '%s\n' "$0: all integration tests passed."
