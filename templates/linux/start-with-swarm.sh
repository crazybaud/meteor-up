#!/bin/bash

APPNAME=<%= appName %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list

set +e
docker pull nelioteam/meteord:base-update
isServiceExist=$(echo $(docker service ls -f name="$APPNAME") | grep -c "$APPNAME")
set -e

if  [ "$isServiceExist" == "1" ]; then
    echo "Update service $APPNAME"
    docker service rm $APPNAME
fi
echo "Create service $APPNAME"
docker service create \
  --replicas 3 \
  --constraint 'node.role == manager' \
  --name $APPNAME \
  --update-delay 10s \
  --hostname "$HOSTNAME-$APPNAME" \
  --env-file=$ENV_FILE \
  --network=nelio_app \
  --network=meteor_nelio_app \
  --detach=false \
  --mount type=bind,source=$BUNDLE_PATH,destination=/bundle \
  nelioteam/meteord:base-update
