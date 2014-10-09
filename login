#!/bin/bash

# API documentation: http://www.mediawiki.org/wiki/API:Main_page

stty -echo
read -p "Password: " USERPASS
stty echo
echo

if [ -z "$USERPASS" ]; then
  echo "Password not supplied"
  exit 1
fi

. wiki-config
 
echo "Logging into $WIKIAPI as $USERNAME..."

CR=$(curl -s -S \
	--location \
	--retry 2 \
	--retry-delay 5\
	--cookie $cookie_jar \
	--cookie-jar $cookie_jar \
	--keepalive-time 60 \
	--header "Accept-Language: en-GB" \
	--header "Connection: keep-alive" \
	--compressed \
	--data-urlencode "lgname=${USERNAME}" \
	--data-urlencode "lgpassword=${USERPASS}" \
	--data-urlencode "lgdomain=${USERDOMAIN}" \
	--request "POST" "${WIKIAPI}?action=login&format=txt")


TOKEN=$(echo "$CR" | awk '/\[token\] =>/ {print $3}')
RESULT=$(echo "$CR" | awk '/\[result\] =>/ {print $3}')

if [ "$RESULT" = "NeedToken" ]; then
  CR=$(curl -s -S \
	--location \
	--cookie $cookie_jar \
	--cookie-jar $cookie_jar \
	--keepalive-time 60 \
	--header "Accept-Language: en-GB" \
	--header "Connection: keep-alive" \
	--compressed \
	--data-urlencode "lgname=${USERNAME}" \
	--data-urlencode "lgpassword=${USERPASS}" \
	--data-urlencode "lgdomain=${USERDOMAIN}" \
	--data-urlencode "lgtoken=${TOKEN}" \
	--request "POST" "${WIKIAPI}?action=login&format=txt")

  RESULT=$(echo "$CR" | awk '/\[result\] =>/ {print $3}')
fi

if [ "$RESULT" = "Success" ]; then
  echo "Successfully logged in as $USERNAME."
else
  echo "Login failed:"
  echo "$CR"
  exit 1
fi

