#!/bin/bash
echo "Configuring Docker"
echo $(/opt/elasticbeanstalk/bin/get-config environment -k GITHUB_TOKEN) | docker login ghcr.io -u $(/opt/elasticbeanstalk/bin/get-config environment -k GITHUB_USER) --password-stdin