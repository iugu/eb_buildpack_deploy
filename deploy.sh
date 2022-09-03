#!/bin/bash
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
# trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

start=$(date +%s)
PWD=$(pwd)
EB_APP=$1
EB_ENV=$2
DEPLOYERDIR=~/dev/paketo-iugu-deploy
APPNAME=$4
TARGETAPPDIR=$3
rm -rf tmp
mkdir -p tmp
cd tmp
DEPLOYDIR=$(pwd)
if [[ -z $DEPLOYERDIR ]]; then
  echo "Using remote"
else
  echo "Using local deployer"
  cp -rf $DEPLOYERDIR/* .
fi

export REVISION=`git -C $TARGETAPPDIR rev-parse HEAD`
export REVISION_MSG=`git -C $TARGETAPPDIR log --format="%s" -n 1 $REVISION`
export REV_EXISTS=`docker inspect ghcr.io/$GITHUB_ORG/$APPNAME:$REVISION 2> /dev/null`
if [ "${REV_EXISTS}" == "[]" ]; then
  echo "BUILDING NEW REVISION!"
  pack build $APPNAME \
  --builder paketobuildpacks/builder:full \
  --path $TARGETAPPDIR
  echo $GITHUB_TOKEN | docker login ghcr.io -u $GITHUB_USER --password-stdin
  docker tag "$APPNAME":latest ghcr.io/$GITHUB_ORG/$APPNAME:$REVISION
  docker push ghcr.io/$GITHUB_ORG/$APPNAME:$REVISION
else
  echo "DEPLOYING EXISTING REVISION!"
fi

rm -rf ./dist
mkdir -p ./dist
cp -rf ./base_eb_ignore ./dist/.ebignore
cp -rf ./base_elasticbeanstalk ./dist/.elasticbeanstalk
cp -rf ./base_platform ./dist/.platform
cp -rf ./base_extensions ./dist/.ebextensions
cp ./optional_extensions/ruby.config ./dist/.ebextensions/ruby.config
jq --arg image "ghcr.io/${GITHUB_ORG}/${APPNAME}:${REVISION}" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292"' Dockerrun.template > dist/Dockerrun.aws.json
sed -i '' "s/<APP_NAME>/${EB_APP}/" ./dist/.elasticbeanstalk/config.yml
sed -i '' "s/<GITHUB_TOKEN>/$GITHUB_TOKEN/" ./dist/.ebextensions/github.config
sed -i '' "s/<GITHUB_USER>/$GITHUB_USER/" ./dist/.ebextensions/github.config
sed -i '' "s/<RAILS_MASTER_KEY>/$(cat ${TARGETAPPDIR}/config/master.key)/" ./dist/.ebextensions/ruby.config
# cd dist && eb deploy $1

# jq --arg image "432388178442.dkr.ecr.sa-east-1.amazonaws.com/$APP_NAME:$REVISION" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292"' Dockerrun.template > Dockerrun.aws.json
# eb deploy $APP_ENV --label $REVISION --message "$REVISION_MSG"
cd dist && eb deploy $EB_ENV --label $REVISION --message "$REVISION_MSG"
end=$(date +%s)
duration=$end-$start
echo "Deploy took: $((duration / 60)) min and $((duration % 60)) sec"