#!/bin/bash
# Script written by bugmancx

#User Configurable Variables
TMP=/tmp
MANIFEST_VERSION_URL='https://launchermeta.mojang.com/mc/game/version_manifest.json'
DISCORD_USERNAME="Minecraft"
#DISCORD_WEBHOOK_URL='https://discordapp.com/api/webhooks/example/webhook'
## Note - Discord Webhook URL must be contained within single quotes within the variable in order to work with curl.
DISCORD_WEBHOOK_URL=''

#Setup Variables
CACHED_FILE="$TMP/cached_version_manifest.json"
MANIFEST_FILE="$TMP/version_manifest.json"
DIFF=0

# Retrieve current release values from cached copy on filesystem
if [ -f $CACHED_FILE ] ; then
  CACHED_VERSION_RELEASE=$(jq -r '.latest."release"' $CACHED_FILE)
  CACHED_VERSION_SNAPSHOT=$(jq -r '.latest."snapshot"' $CACHED_FILE)
else
  CACHED_VERSION_RELEASE="unknown"
  CACHED_VERSION_SNAPSHOT="unknown"
fi

# Retrieve latest version from Mojang manifest
curl -s -o $MANIFEST_FILE $MANIFEST_VERSION_URL
## Write this to disk; we'll use it twice and want to reduce calls against the Mojang API.

MANIFEST_VERSION_RELEASE=$(jq -r '.latest."release"' $MANIFEST_FILE)
MANIFEST_VERSION_SNAPSHOT=$(jq -r '.latest."snapshot"' $MANIFEST_FILE)


# Compare Release

if [ ! "$CACHED_VERSION_RELEASE" == "$MANIFEST_VERSION_RELEASE" ] ; then
  # Differences detected in RELEASE
  DIFF=1
fi

if [ ! "$CACHED_VERSION_SNAPSHOT" == "$MANIFEST_VERSION_SNAPSHOT" ] ; then
  # Differences detected in SNAPSHOT
  DIFF=1
fi

# If differences detected, do Discord
if [ $DIFF -gt 0 ] ; then

  # Specify the wording for the bot's custom message.
  MESSAGE_CONTENT="Release: $MANIFEST_VERSION_RELEASE | Snapshot: $MANIFEST_VERSION_SNAPSHOT"

  # Post to Discord
  curl -H "Content-Type: application/json" \
  -X POST \
  -d "{\"username\": \"$DISCORD_USERNAME\", \"content\": \"$MESSAGE_CONTENT\"}" $DISCORD_WEBHOOK_URL

  # Make manifest new cached manifest.
  mv $MANIFEST_FILE $CACHED_FILE

fi

