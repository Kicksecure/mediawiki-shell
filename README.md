## Bash shell scripts for usage of MediaWiki API

Download, upload changes to, and manage pages from MediaWiki wikis from the
command line.

This tool may work on other wiki sites, but is primarily intended for
management of the Kicksecure and Whonix wikis.

## Setup

Create a credentials file in `/usr/share/mediawiki-shell/credentials` or
`~/.mediawikishell_credentials`. Credentials are stored in associative
arrays keyed by wiki alias, so a single file can hold auth for multiple
wikis:

```sh
## Optional: default wiki used when no WIKI is given on the command line
## and the WIKI_URL environment variable is not set. May be an alias or a
## full URL.
DEFAULT_WIKI_URL='kicksecure'

## Per-wiki credentials, keyed by alias (or full URL).
WIKI_USER_NAMES[kicksecure]='username1'
WIKI_USER_PASSES[kicksecure]='password1'

WIKI_USER_NAMES[whonix]='username2'
WIKI_USER_PASSES[whonix]='password2'

## Optional: define additional aliases (or override the built-in
## 'kicksecure' / 'whonix' aliases).
#WIKI_URLS[my-wiki]='https://example.org/w'
#WIKI_USER_NAMES[my-wiki]='username3'
#WIKI_USER_PASSES[my-wiki]='password3'
```

With `DEFAULT_WIKI_URL` set, commands whose only argument is the wiki
(`mw-login`, `mw-logout`, `mw-login-test`) can be invoked with no
arguments. Commands that take additional positional arguments (e.g.
`mw-edit`) still require WIKI as the first positional.

Resolution order for the active wiki: positional argument > `WIKI_URL`
environment variable > `DEFAULT_WIKI_URL` from the credentials file.

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
