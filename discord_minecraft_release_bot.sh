#!/bin/bash
# Script written by bugmancx

# Requirements:
## jq
## curl


#Default Configurable Variables
TMP=/tmp
MANIFEST_VERSION_URL='https://launchermeta.mojang.com/mc/game/version_manifest.json'


# Localised configuration
usage() {
echo "Usage: cmd [-c] <config file>"
}

while getopts "c:v" opt; do
  case ${opt} in
    c ) # Config file
        CONFIG_FILE=${OPTARG}
        #echo "Working with $CONFIG_FILE"
      if [ ! -f $CONFIG_FILE ] ; then
        echo "Configuration file $CONFIG_FILE not found!"
        exit
      else
        source $CONFIG_FILE
      fi
      ;;
    v ) # Verbose mode
      VERBOSE=1 # For future debug expansion
      ;;
    \? ) 
      usage
      ;;
  esac
done

if ((OPTIND == 1))
then
    echo "No options specified"
    usage
    exit
fi



validate_configuration() {
  # Check that variables are OK
  if [ -z ${ID+x} ]; then echo "ID is not set."; SYNTAX=1 ;
  else 
    SED_ID=$(echo $ID | sed 's/[^[:alnum:]]\+//g') # Ensure string is only letters and or numbers
    ID=$SED_ID
  fi

  if [ -z ${WEBHOOK_URL+x} ]; then
    echo "WEBHOOK_URL is not set."
    SYNTAX=1
  fi
  
  if [ -n $SYNTAX ] ; then
    SYNTAX=0 # No issues found
  fi

  if [ $SYNTAX -eq 1 ] ; then
    echo ; echo "Configuration file is not valid. Please check and run again."
    exit
  fi
}

## Start working
##################################################################

## CONSTRUCT VARIABLES
MANIFEST_CACHED_FILE="$TMP/$ID.cached_version_manifest.json"
MANIFEST_FILE="$TMP/$ID.version_manifest.json"
DIFF=0
FIRST_RUN=0
WEBHOOK_URL_POST=$WEBHOOK_URL # Set the webhook URL to post to - gets overridden later if others exist


## SET FUNCTIONS

function get_manifest() {
curl -s -o $MANIFEST_FILE $MANIFEST_VERSION_URL # Fetch latest manifest

if ! jq empty $MANIFEST_FILE; then
  echo "JSON is invalid"
  exit
fi



}

function update_cache() {
mv $MANIFEST_FILE $MANIFEST_CACHED_FILE
}


function retrieve_and_set_values() {
MANIFEST_VERSION_RELEASE=$(jq -r '.latest."release"' $MANIFEST_FILE)
MANIFEST_VERSION_SNAPSHOT=$(jq -r '.latest."snapshot"' $MANIFEST_FILE)

CACHED_VERSION_RELEASE=$(jq -r '.latest."release"' $MANIFEST_CACHED_FILE)
CACHED_VERSION_SNAPSHOT=$(jq -r '.latest."snapshot"' $MANIFEST_CACHED_FILE)

}


function manifest_compare() {
if [ ! "$CACHED_VERSION_SNAPSHOT" == "$MANIFEST_VERSION_SNAPSHOT" ] ; then
  echo "Differences were detected in SNAPSHOT"
  DIFF=1
  if [ ! -z ${SNAPSHOT_VERB+x} ] ; then # Check if a verb is defined
    VERB=$SNAPSHOT_VERB
  else
    VERB="**snapshot**"
  fi

  if [ ! -z ${SNAPSHOT_WEBHOOK_URL+x} ] ; then # Check if a snapshot webhook URL exists
    WEBHOOK_URL_POST=$SNAPSHOT_WEBHOOK_URL
  fi
fi

if [ ! "$CACHED_VERSION_RELEASE" == "$MANIFEST_VERSION_RELEASE" ] ; then
  echo "Differences were detected in RELEASE"
  DIFF=1
  if [ ! -z ${RELEASE_VERB+x} ] ; then
    VERB=$RELEASE_VERB
  else
    VERB="**release**"
  fi
  if [ ! -z ${RELEASE_WEBHOOK_URL+x} ] ; then # Check if a snapshot webhook URL exists
    WEBHOOK_URL_POST=$RELEASE_WEBHOOK_URL
  fi
fi

}

if [ -z ${DISCORD_USERNAME+x} ]; 
  then DISCORD_USERNAME="Minecraft" # Default
fi

function discord_post () {
curl -H "Content-Type: application/json" \
 -X POST \
 -d "{\"username\": \"$DISCORD_USERNAME\", \"content\": \"$MESSAGE_CONTENT\"}" {$WEBHOOK_URL_POST}
}

##############################################################################


## NOW GO, REALLY.

validate_configuration
get_manifest
retrieve_and_set_values

# Retrieve latest version from Mojang manifest
if [ ! -f $MANIFEST_CACHED_FILE ] ; then
  echo "WARNING: No cached manifest exists. This may be our first run."
  echo "No results will be posted until the next manifest update from Mojang."
  FIRST_RUN=1
  update_cache
  exit
fi

# Compare Release
VERB="version" # Default verb if for some reason type detection fails

manifest_compare


# If differences detected, do Discord
if [ $DIFF -gt 0 ] ; then
  if [ -z ${MESSAGE_CONTENT+x} ] ; then # If not already set in config file
    # Specify the default wording for the bot's custom message.
    MESSAGE_CONTENT="A new Minecraft $VERB is available! | Release: $MANIFEST_VERSION_RELEASE | Snapshot: $MANIFEST_VERSION_SNAPSHOT"
  else
    source $CONFIG_FILE # Freshen the MESSAGE_CONTENT now that other vars are populated
  fi

  if [ ! $FIRST_RUN -eq 1 ] ; then
    # Looks like this is our first run, so just exit here and don't post anything.
    # Post to Discord
    discord_post
  fi

# Make manifest new cached manifest.
update_cache

fi

if [ -f $MANIFEST_FILE ] ; then rm $MANIFEST_FILE ; fi
