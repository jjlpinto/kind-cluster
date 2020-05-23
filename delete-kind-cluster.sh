#!/bin/sh -x

kind delete cluster --name cluster

if [ "$(docker ps -q -f name=kind-registry)" ]; then
  docker stop kind-registry
  docker rm kind-registry
fi

docker network rm kind
