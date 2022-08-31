#!/usr/bin/env bash

# LOAD ENVIRONMENT
source .env

function create() {
  # CREATE DOCKER REGISTRY
  echo -e " \033[32m»\033[0m creating registry container unless it already exists"

  if [ "$(docker inspect -f '{{.State.Running}}' "${REGISTRY_NAME}" 2>/dev/null || true)" == 'true' ]; then
    echo -e " \033[32m✓\033[0m registry is running"
  else
    echo -e " \033[31m✗\033[0m no registry running, start"

    docker run \
      -d --restart always -p "127.0.0.1:${REGISTRY_PORT}:5000" --name "${REGISTRY_NAME}" --volume "${REGISTRY_STORAGE_PATH}:/var/lib/registry" --env REGISTRY_STORAGE_DELETE_ENABLED=true \
      registry:2

    echo -e " \033[32m✓\033[0m registry started"
  fi

  # CREATE KIND CLUSTER
  echo -e " \033[32m»\033[0m creating a cluster with the local registry enabled in containerd"

  cat <<EOF | kind create cluster --config=-
  kind: Cluster
  apiVersion: kind.x-k8s.io/v1alpha4
  name: ${CLUSTER_NAME}
  containerdConfigPatches:
    - |-
      [plugins."io.containerd.grpc.v1.cri".registry.mirrors."localhost:${REGISTRY_PORT}"]
        endpoint = ["http://${REGISTRY_NAME}:5000"]
  nodes:
  - role: control-plane
    kubeadmConfigPatches:
    - |
      kind: InitConfiguration
      nodeRegistration:
        kubeletExtraArgs:
          node-labels: "ingress-ready=true"
    extraPortMappings:
    - containerPort: 80
      hostPort: 80
      protocol: TCP
    - containerPort: 443
      hostPort: 443
      protocol: TCP
  - role: worker
EOF

  echo -e " \033[32m✓\033[0m cluster created successfully"

  # CONNECT THE REGISTRY TO THE CLUSTER NETWORK
  echo -e " \033[32m»\033[0m connecting the registry to the cluster network if not already connected"

  if [ "$(docker inspect -f='{{json .NetworkSettings.Networks.kind}}' "${REGISTRY_NAME}")" = 'null' ]; then
    docker network connect "kind" "${REGISTRY_NAME}"
  fi

  echo -e " \033[32m✓\033[0m cluster connected successfully"

  # DOCUMENT LOCAL REGISTRY
  echo -e " \033[32m»\033[0m document the local registry"

  cat <<EOF | kubectl apply -f -
  apiVersion: v1
  kind: ConfigMap
  metadata:
    name: local-registry-hosting
    namespace: kube-public
  data:
    localRegistryHosting.v1: |
      host: "localhost:${REGISTRY_PORT}"
      help: "https://kind.sigs.k8s.io/docs/user/local-registry/"
EOF

  echo -e " \033[32m✓\033[0m cluster documented successfully"

  # INSTALL AND CONFIGURE KONG INGRESS CONTROLLER
  echo -e " \033[32m»\033[0m installing kong ingress controller"
  kubectl apply -f https://raw.githubusercontent.com/Kong/kubernetes-ingress-controller/master/deploy/single/all-in-one-dbless.yaml

  echo -e " \033[32m✓\033[0m kong installed successfully"

  echo -e " \033[32m»\033[0m setting up kong ingress controller"

  kubectl patch deployment -n kong ingress-kong -p '{"spec":{"template":{"spec":{"containers":[{"name":"proxy","ports":[{"containerPort":8000,"hostPort":80,"name":"proxy","protocol":"TCP"},{"containerPort":8443,"hostPort":443,"name":"proxy-ssl","protocol":"TCP"}]}],"nodeSelector":{"ingress-ready":"true"},"tolerations":[{"key":"node-role.kubernetes.io/control-plane","operator":"Equal","effect":"NoSchedule"},{"key":"node-role.kubernetes.io/master","operator":"Equal","effect":"NoSchedule"}]}}}}'
  kubectl patch service -n kong kong-proxy -p '{"spec":{"type":"NodePort"}}'

  echo -e " \033[32m✓\033[0m kong configured successfully"
}

function delete() {
  echo -e " \033[32m»\033[0m will delete these containers:"

  docker ps --filter 'label=io.x-k8s.kind.cluster='"$CLUSTER_NAME"

  kind delete cluster --name "$CLUSTER_NAME"

  echo -e " \033[32m✓\033[0m containers deleted successfully"
}

function status() {
  docker ps --filter 'label=io.x-k8s.kind.cluster='"$CLUSTER_NAME"

  kubectl cluster-info --context=kind-"$CLUSTER_NAME"
}

function main() {
  echo "$1"

  for cmd in create delete status ; do
    if [ "$1" == "$cmd" ]; then
      $cmd
      return $?
    fi
  done

  cat <<EOF
Usage:
  $0 create|delete|status
EOF
  return 1
}

main "$@"
