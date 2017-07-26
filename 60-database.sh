#!/bin/bash
# 50-config.py or equivalent must be run first to set all omero.db.*
# omero.db.host may require special handling since the default is
# to use `--link postgres:db`

set -eu

omero=/opt/omero/server/OMERO.server/bin/omero
omego=/opt/omero/omego/bin/omego
cd /opt/omero/server

CONFIG_omero_db_host=${CONFIG_omero_db_host:-}
if [ -n "$CONFIG_omero_db_host" ]; then
    DBHOST="$CONFIG_omero_db_host"
else
    DBHOST=db
    $omero config set omero.db.host "$DBHOST"
fi
DBUSER="${CONFIG_omero_db_user:-omero}"
DBNAME="${CONFIG_omero_db_name:-omero}"
DBPASS="${CONFIG_omero_db_pass:-omero}"
ROOTPASS="${ROOTPASS:-omero}"

export PGPASSWORD="$DBPASS"

i=0
while ! psql -h "$DBHOST" -U "$DBUSER" "$DBNAME" >/dev/null 2>&1 < /dev/null; do
    i=$(($i+1))
    if [ $i -ge 50 ]; then
        echo "$(date) - postgres:5432 still not reachable, giving up"
        exit 1
    fi
    echo "$(date) - waiting for postgres:5432..."
    sleep 1
done
echo "postgres connection established"

psql -w -h "$DBHOST" -U "$DBUSER" "$DBNAME" -c \
    "select * from dbpatch" 2> /dev/null && {
    echo "Upgrading database"
    $omego db upgrade --serverdir=OMERO.server
    } || {
        if [ -f "/opt/omero/sql/db.sql" ]; then
            echo "Restoring database"
            $omego db init --omerosql "/opt/omero/sql/db.sql" --serverdir=OMERO.server
        else
            echo "Initialising database"
            $omego db init --rootpass "$ROOTPASS" --serverdir=OMERO.server
        fi
    }
