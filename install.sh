#!/bin/bash
set -e

# keep track of the last executed command
trap 'last_command=$current_command; current_command=$BASH_COMMAND' DEBUG
# echo an error message before exiting
# trap 'echo "\"${last_command}\" command filed with exit code $?."' EXIT

# DEPLOYERDIR=~/dev/paketo-iugu-deploy

export START=$(date +%s)
export TARGETAPPDIR=$(pwd)
cd /tmp
rm -rf paketo_deployer
mkdir -p paketo_deployer
cd paketo_deployer
export DEPLOYDIR=$(pwd)
if [[ -z $DEPLOYERDIR ]]; then
  echo "Using remote deployer"
  curl -L0 https://github.com/iugu/eb_buildpack_deploy/archive/refs/heads/main.zip -o main.zip && unzip ./main.zip -d archive && mv ./archive/*/* .
else
  echo "Using local deployer"
  cp -rf $DEPLOYERDIR/* .
fi

./deploy.sh