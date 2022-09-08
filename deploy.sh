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

echo "REVISION: ${REVISION}"
echo "REVISION_MSG: ${REVISION_MSG}"
echo "REV_PULL: ${REV_PULL}"
echo "REV_EXISTS: ${REV_EXISTS}"

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

# echo pwd
# find .
cp ./optional_extensions/ruby.config ./dist/.ebextensions/ruby.config

if [ "${ENTRYPOINT}" == "" ]; then
  export ENTRYPOINT="web"
  jq --arg image $CONTAINER_IMAGE:$REVISION --arg entry "$ENTRYPOINT" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292" | del(.Entrypoint)' Dockerrun.template > dist/Dockerrun.aws.json
else
  jq --arg image $CONTAINER_IMAGE:$REVISION --arg entry "$ENTRYPOINT" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292" | .Entrypoint=$entry' Dockerrun.template > dist/Dockerrun.aws.json
fi

cat dist/Dockerrun.aws.json

sed -i'' "s/<APP_NAME>/${EB_APP}/" ./dist/.elasticbeanstalk/config.yml
sed -i'' "s/<GITHUB_TOKEN>/$GITHUB_TOKEN/" ./dist/.ebextensions/github.config
sed -i'' "s/<GITHUB_USER>/$GITHUB_USER/" ./dist/.ebextensions/github.config
sed -i'' "s/<RAILS_MASTER_KEY>/$RAILS_MASTER_KEY/" ./dist/.ebextensions/ruby.config
sed -i'' "s/REPLACED_ENV_TYPE/${RAILS_ENV}/" ./dist/.ebextensions/00env.config
sed -i'' "s/REPLACED_VERSION_NAME/$REVISION/" ./dist/.ebextensions/00env.config
sed -i'' "s/REPLACED_APP_NAME/${EB_APP}/" ./dist/.ebextensions/00env.config

cd dist && eb deploy -r $EB_REGION $EB_ENV --label $REVISION-${ENTRYPOINT} --message "$REVISION_MSG"
end=$(date +%s)
duration=$end-$START
echo "Deploy took: $((duration / 60)) min and $((duration % 60)) sec"