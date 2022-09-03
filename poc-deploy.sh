#!/bin/bash
rm -rf ./dist
mkdir -p ./dist
cp -rf ./base_eb_ignore ./dist/.ebignore
cp -rf ./base_elasticbeanstalk ./dist/.elasticbeanstalk
cp -rf ./base_platform ./dist/.platform
cp -rf ./base_extensions ./dist/.ebextensions
cp ./optional_extensions/ruby.config ./dist/.ebextensions/ruby.config
jq --arg image "ghcr.io/iugu-private/rails7-buildpack:0.0.1" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292"' Dockerrun.template > dist/Dockerrun.aws.json
sed -i '' "s/<GITHUB_TOKEN>/$GITHUB_TOKEN/" ./dist/.ebextensions/github.config
sed -i '' "s/<GITHUB_USER>/$GITHUB_USER/" ./dist/.ebextensions/github.config
sed -i '' "s/<RAILS_MASTER_KEY>/$(cat ../rails7-buildpack/config/master.key)/" ./dist/.ebextensions/ruby.config
cd dist && eb deploy $1