#!/bin/bash
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
# trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

export REVISION=`git -C $TARGETAPPDIR rev-parse HEAD`
export REVISION_MSG=`git -C $TARGETAPPDIR log --format="%s" -n 1 $REVISION`
export REV_PULL=`docker pull $CONTAINER_IMAGE:$REVISION 2> /dev/null`
export REV_EXISTS=`docker inspect $CONTAINER_IMAGE:$REVISION 2> /dev/null`

# Configure GITHUB USER
# Configure MASTER KEY
# $(cat ${TARGETAPPDIR}/config/master.key)

rm -rf ./dist
mkdir -p ./dist
cp -rf ./base_eb_ignore ./dist/.ebignore
cp -rf ./base_elasticbeanstalk ./dist/.elasticbeanstalk
cp -rf ./base_platform ./dist/.platform
cp -rf ./base_extensions ./dist/.ebextensions

# Create Detections here
# Detect DataDog
# Detect Ruby ...

echo pwd
find .
cp ./optional_extensions/ruby.config ./dist/.ebextensions/ruby.config
jq --arg image $CONTAINER_IMAGE:$REVISION --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292"' Dockerrun.template > dist/Dockerrun.aws.json
sed -i'' "s/<APP_NAME>/${EB_APP}/" ./dist/.elasticbeanstalk/config.yml
sed -i'' "s/<GITHUB_TOKEN>/$GITHUB_TOKEN/" ./dist/.ebextensions/github.config
sed -i'' "s/<GITHUB_USER>/$GITHUB_USER/" ./dist/.ebextensions/github.config
sed -i'' "s/<RAILS_MASTER_KEY>/$RAILS_MASTER_KEY/" ./dist/.ebextensions/ruby.config

cd dist && eb deploy -r $EB_REGION $EB_ENV --label $REVISION --message "$REVISION_MSG"
end=$(date +%s)
duration=$end-$START
echo "Deploy took: $((duration / 60)) min and $((duration % 60)) sec"