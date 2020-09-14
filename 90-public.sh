#!/bin/bash
# Configure web public user if enabled
# Waits for OMERO to start before creating necessary accounts so there is a very
# brief window on first startup when OMERO.server and OMERO.web may be available
# but the public user is not yet created

set -eu

omero=/opt/omero/server/OMERO.server/bin/omero
CONFIG_omero_web_public_enabled=${CONFIG_omero_web_public_enabled:-false}

function createPublicUser {
  PUBLIC_GROUP=${PUBLIC_GROUP:-public-group}
  CONFIG_omero_web_public_user=${CONFIG_omero_web_public_user:-public-user}
  CONFIG_omero_web_public_password=${CONFIG_omero_web_public_password:-omero}

  $omero -s localhost -p 4064 -u root -w $ROOTPASS group info $PUBLIC_GROUP \
    && echo "Skipping existing public group ($PUBLIC_GROUP) creation" \
    || $omero -s localhost -p 4064 -u root -w $ROOTPASS group add --type read-only $PUBLIC_GROUP
  $omero -s localhost -p 4064 -u root -w $ROOTPASS user info $CONFIG_omero_web_public_user \
    && echo "Skipping existing public user ($CONFIG_omero_web_public_user) creation" \
    || $omero -s localhost -p 4064 -u root -w $ROOTPASS user add --group-name $PUBLIC_GROUP -P $CONFIG_omero_web_public_password $CONFIG_omero_web_public_user Public User
}

# Never time out as there could be steps of unknown duration between this and
# OMERO server successfully starting.
function waitForOmero {
  while ! $omero -s localhost -p 4064 -u root -w $ROOTPASS login >/dev/null 2>&1; do
    echo "$(date) - waiting for OMERO server..."
    sleep 5
  done
  echo "OMERO server connection established"
  createPublicUser
}

if [ "$CONFIG_omero_web_public_enabled" = true ]; then
  waitForOmero &
fi
