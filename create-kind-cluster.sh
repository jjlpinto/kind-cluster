#!/bin/sh
set -o errexit


while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$package - deploy kind cluster"
      echo " "
      echo "$package [options]"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-r, --repository          deploy local repository to port 5000"
      exit 0
      ;;
    -r)
      shift
      REPOSITORY=true
      ;;
    --repository)
      REPOSITORY=true
      shift
      ;;
    *)
      break
      ;;
  esac
done

# create kind cluster
echo "Deploying kind-cluster using kind-config.yaml"
kind create cluster --config kind-config.yaml --name cluster

if [[ $REPOSITORY ]]; then
  echo "Deploying local docker repository on port 5000"
  # create registry container
  reg_name='kind-registry'
  reg_port='5000'
  running="$(docker inspect -f '{{.State.Running}}' "${reg_name}" 2>/dev/null || true)"
  if [ "${running}" != 'true' ]; then
    docker run \
      -d --restart=always -p "${reg_port}:5000" --name "${reg_name}" \
      registry:2
  fi

  # connect kind network to local registry
  docker network connect "kind" "${reg_name}"

else
  echo "Deploying cluster without local repository"
fi

# deploy nginx ingress
echo "Deploying nginx based ingress controller"
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/master/deploy/static/provider/kind/deploy.yaml
echo "Waiting for ingress controller to start..."
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=90s
