#!/usr/bin/env bash
CURRENT_DIR=`dirname "$0"`

. $CURRENT_DIR/docker_build.sh
cd $CURRENT_DIR/..

docker image tag launcher kitware/trame:launcher
docker image push kitware/trame:launcher