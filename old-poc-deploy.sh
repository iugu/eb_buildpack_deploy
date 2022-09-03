#!/bin/bash
export APP_NAME=my-app
export APP_DIR=../sample-r6-app-nodb/ 
export REVISION=`git -C $APP_DIR rev-parse HEAD`
export REVISION_MSG=`git -C $APP_DIR log --format="%s" -n 1 $REVISION`
export APP_ENV='poc6-default-web12-ecs-fargate'
start=$(date +%s)
pack build $APP_NAME \
  --builder paketobuildpacks/builder:base \
  --path $APP_DIR
env AWS_PROFILE=iugu-vault-services-/AdministratorAccessRole aws ecr get-login-password --region sa-east-1 | docker login --username AWS --password-stdin 432388178442.dkr.ecr.sa-east-1.amazonaws.com
docker tag "$APP_NAME":latest 432388178442.dkr.ecr.sa-east-1.amazonaws.com/"$APP_NAME":$REVISION
docker push 432388178442.dkr.ecr.sa-east-1.amazonaws.com/$APP_NAME:$REVISION
jq --arg image "432388178442.dkr.ecr.sa-east-1.amazonaws.com/$APP_NAME:$REVISION" --arg port "Port" '.Image.Name=$image | .Ports[].ContainerPort="9292"' Dockerrun.template > Dockerrun.aws.json
eb deploy $APP_ENV --label $REVISION --message "$REVISION_MSG"
end=$(date +%s)
duration=$end-$start
echo "Deploy took: $((duration / 60)) min and $((duration % 60)) sec"