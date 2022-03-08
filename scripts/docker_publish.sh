#!/usr/bin/env bash
CURRENT_DIR=`dirname "$0"`

. $CURRENT_DIR/docker_build.sh
cd $CURRENT_DIR/..

docker image tag launcher jourdain/trame-apps:launcher
docker image push jourdain/trame-apps:launcher