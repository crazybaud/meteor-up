#!/bin/bash

APPNAME=<%= appName %>
MONGO_URL=<%= mongoUrl %>
APP_PATH=/opt/$APPNAME
BUNDLE_PATH=$APP_PATH/current
ENV_FILE=$APP_PATH/config/env.list


insertMeteor() {
  ssh -p 42 nelio@$1 /bin/bash << EOF
  sudo mkdir -p $BUNDLE_PATH
  sudo chown nelio -R /opt/
EOF
  scp -P 42 -r $BUNDLE_PATH/bundle.tar.gz nelio@$1:$BUNDLE_PATH
  ssh -p 42 nelio@$1 /bin/bash << EOF
  cd /opt/nelio_app_meteor/current/
  tar -xvf bundle.tar.gz
EOF
}

# bad method to check if it's dev or prod
if [[ $MONGO_URL == *"nelio-dev"* ]]; then
  insertMeteor 145.239.13.202
  insertMeteor 145.239.158.86
else
  insertMeteor 145.239.158.81
  insertMeteor 145.239.158.80
fi

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
  --replicas 1 \
  --constraint 'node.role == manager' \
  --name $APPNAME \
  --update-delay 10s \
  --hostname "$HOSTNAME-$APPNAME" \
  --env-file=$ENV_FILE \
  --network=nelio_app \
  --network=meteor_nelio_app \
  --detach=false \
  --log-opt max-size=50m \
  --mount type=bind,source=$BUNDLE_PATH,destination=/bundle \
  nelioteam/meteord:base-update

dockerSecret=$(docker secret ls -f name="mongo_url" --format "{{.Name}}")
if [ ${#dockerSecret} -ge 2 ]; then
  docker service update --secret-add  src="$dockerSecret",target="mongo_url" $APPNAME
else
  echo "" | docker secret create mongo_url_temporary -
  docker service update --secret-add  src="mongo_url_temporary",target="mongo_url" $APPNAME
  /home/nelio/nelio_fresh_admin/devops/docker/updateSecret.sh mongo_url $MONGO_URL
fi
