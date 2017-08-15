#!/bin/bash

APPNAME=<%= appName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list

set +e
docker pull nelioteam/meteord:base
isServiceExist=$(echo $(docker service ls -f name="$APPNAME") | grep -c "$APPNAME")
set -e

if  [ "$isServiceExist" == "1" ]; then
    echo "Update service $APPNAME"
    docker service update $APPNAME --force --detach=false
else
    echo "Create service $APPNAME"
    docker service create \
      --replicas 3 \
      --constraint 'node.role == manager' \
      --name $APPNAME \
      --update-delay 10s \
      --hostname "$HOSTNAME-$APPNAME" \
      --env-file=$ENV_FILE \
      --network=nelio_database \
      --detach=false \
      --mount type=bind,source=$BUNDLE_PATH,destination=/bundle \
      nelioteam/meteord:base
fi