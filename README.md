## Bash shell scripts for usage of MediaWiki API

Download, upload changes to, and manage pages from MediaWiki wikis from the
command line.

This tool may work on other wiki sites, but is primarily intended for
management of the Kicksecure and Whonix wikis.

## Setup

Create a credentials file in `/usr/share/mediawiki-shell/credentials` or
`~/.mediawikishell_credentials` with the following contents:

```sh
case "${WIKI_URL-}" in
  *".whonix."*)
    WIKI_API_USER_NAME='username'
    WIKI_API_USER_PASS='password'
    ;;
  *".kicksecure."*)
    WIKI_API_USER_NAME='username'
    WIKI_API_USER_PASS='password'
    ;;
esac
WIKI_API="$WIKI_URL/api.php"
WIKI_INDEX="$WIKI_URL/index.php"
```

If using a different wiki, add an entry to the `case` block.

Alternatively, credentials for multiple wikis may be defined in
associative arrays keyed by full WIKI URL:

```sh
WIKI_USER_NAMES['https://www.whonix.org/w']='username1'
WIKI_USER_PASSES['https://www.whonix.org/w']='password1'

WIKI_USER_NAMES['https://www.kicksecure.com/w']='username2'
WIKI_USER_PASSES['https://www.kicksecure.com/w']='password2'
```

## How to Build deb Package from Source Code

Can be built using standard Debian package build tools such as:

```
dpkg-buildpackage -b
```

See instructions. (Replace `generic-package` with the actual name of this package: `mediawiki-shell`.)

* **A)** [easy](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package/easy), _OR_
* **B)** [including verifying software signatures](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package)

## Contact

* [Free Forum Support](https://forums.kicksecure.com)
* [Professional Support](https://www.kicksecure.com/wiki/Professional_Support)

## Donate

`mediawiki-shell` requires [donations](https://www.kicksecure.com/wiki/Donate) to stay alive!
