#!/bin/bash

APPNAME=<%= appName %>
DBNAME=<%= dbName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list
PORT=<%= port %>
USE_LOCAL_MONGO=<%= useLocalMongo? "1" : "0" %>

# Remove previous version of the app, if exists
docker rm -f $APPNAME

# Remove frontend container if exists
docker rm -f $APPNAME-frontend

# We don't need to fail the deployment because of a docker hub downtime
set +e
docker pull nelioteam/meteord:base
set -e

if [ "$USE_LOCAL_MONGO" == "1" ]; then
  docker run \
    -d \
    --restart=always \
    --publish=$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --env-file=$ENV_FILE \
    --hostname="$HOSTNAME-$APPNAME" \
    --network=nelio_database \
    --env=MONGO_URL=mongodb://mongo:27017/$DBNAME \
    --name=$APPNAME \
    nelioteam/meteord:base
else
  docker run \
    -d \
    --restart=always \
    --network=nelio_database \
    --publish=127.0.0.1:$PORT:80 \
    --volume=$BUNDLE_PATH:/bundle \
    --hostname="$HOSTNAME-$APPNAME" \
    --env-file=$ENV_FILE \
    --env=MONGO_URL=mongodb://mongo:27017/$DBNAME \
    --name=$APPNAME \
    nelioteam/meteord:base
fi

<% if(typeof sslConfig === "object")  { %>
  # We don't need to fail the deployment because of a docker hub downtime
  set +e
  docker pull meteorhacks/mup-frontend-server:latest
  set -e
  docker run \
    -d \
    --restart=always \
    --volume=/opt/$APPNAME/config/bundle.crt:/bundle.crt \
    --volume=/opt/$APPNAME/config/private.key:/private.key \
    --link=$APPNAME:backend \
    --publish=<%= sslConfig.port %>:443 \
    --name=$APPNAME-frontend \
    meteorhacks/mup-frontend-server /start.sh
<% } %>
