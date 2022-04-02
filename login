#!/bin/bash

set -e
source common

if [ -z "$USERPASS" ]; then
   echo "$0: ERROR: Password not supplied!"
   exit 1
fi

echo "$0: INFO: Logging into '$WIKI_API' as '$USERNAME'..."

curl \
   --fail \
   --silent \
   --show-error \
   --location \
   --retry 2 \
   --retry-delay 5\
   --cookie "$cookie_jar" \
   --cookie-jar "$cookie_jar" \
   --keepalive-time 60 \
   --header "Accept-Language: en-GB" \
   --header "Connection: keep-alive" \
   --compressed \
   --data-urlencode "lgname=${USERNAME}" \
   --data-urlencode "lgpassword=${USERPASS}" \
   --data-urlencode "lgdomain=${USERDOMAIN}" \
   --output "${TMPFOLDER}/login.json" \
   --request "POST" \
   "${WIKI_API}?action=login&format=json"

RESULT=$(cat "${TMPFOLDER}/login.json" | jq --raw-output '.login.result')
TOKEN=$(cat "${TMPFOLDER}/login.json" | jq --raw-output '.login.token')

if [ "$RESULT" = "NeedToken" ]; then
   curl \
   --fail \
   --silent \
   --show-error \
   --location \
   --cookie "$cookie_jar" \
   --cookie-jar "$cookie_jar" \
   --keepalive-time 60 \
   --header "Accept-Language: en-GB" \
   --header "Connection: keep-alive" \
   --compressed \
   --data-urlencode "lgname=${USERNAME}" \
   --data-urlencode "lgpassword=${USERPASS}" \
   --data-urlencode "lgdomain=${USERDOMAIN}" \
   --data-urlencode "lgtoken=${TOKEN}" \
   --output "${TMPFOLDER}/login.json2" \
   --request "POST" \
   "${WIKI_API}?action=login&format=json"

   RESULT=$(cat "${TMPFOLDER}/login.json2" | jq -r '.login.result')
fi

if [ "$RESULT" = "Success" ]; then
   echo "$0: INFO: Successfully logged in as '$USERNAME'."
else
   echo "$0: ERROR: Login failed"
   exit 1
fi
