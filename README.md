# bash shell scripts for usage of MediaWiki API #

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

## How to install `mediawiki-shell` using apt-get ##

1\. Download the APT Signing Key.

```
wget https://www.kicksecure.com/keys/derivative.asc
```

Users can [check the Signing Key](https://www.kicksecure.com/wiki/Signing_Key) for better security.

2\. Add the APT Signing Key.

```
sudo cp ~/derivative.asc /usr/share/keyrings/derivative.asc
```

3\. Add the derivative repository.

```
echo "deb [signed-by=/usr/share/keyrings/derivative.asc] https://deb.kicksecure.com bookworm main contrib non-free" | sudo tee /etc/apt/sources.list.d/derivative.list
```

4\. Update your package lists.

```
sudo apt-get update
```

5\. Install `mediawiki-shell`.

```
sudo apt-get install mediawiki-shell
```

## How to Build deb Package from Source Code ##

Can be build using standard Debian package build tools such as:

```
dpkg-buildpackage -b
```

See instructions.

NOTE: Replace `generic-package` with the actual name of this package `mediawiki-shell`.

* **A)** [easy](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package/easy), _OR_
* **B)** [including verifying software signatures](https://www.kicksecure.com/wiki/Dev/Build_Documentation/generic-package)

## Contact ##

* [Free Forum Support](https://forums.kicksecure.com)
* [Premium Support](https://www.kicksecure.com/wiki/Premium_Support)

## Donate ##

`mediawiki-shell` requires [donations](https://www.kicksecure.com/wiki/Donate) to stay alive!
