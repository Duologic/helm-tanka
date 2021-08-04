#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
cat << EOF
This plugin provides integration with the Tanka project.

It provides Tanka integration with Helm, generating Helm
templates from jsonnet source.

Available Commands:
  create    Create initial setup
  fetch   Fetch a Jsonnet library (on first setup)
  show    Show the generated Kubernetes manifests.
  build   Build the jsonnet files into a Kubernetes manifests, but don't package it.
  package Generated a packaged Helm chart.

Fetch usage:

   $ helm tanka fetch <url> <entrypoint>

Typical usage:

   $ helm tanka create prometheus
   $ helm tanka fetch prometheus github.com/grafana/jsonnet-libs/prometheus prometheus.libsonnet
   $ helm tanka package prometheus
   $ helm install ./prometheus-0.1.0.tgz 

EOF
}

create() {
  ## create basic helm chart
  helm create $1
  rm -rf $1/templates $1/charts

  ## initialize tanka setup
  mkdir -p $1/jsonnet
  cd $1/jsonnet
  jb init
  tk env add -i .

  ## install kubernetes libraries
  jb install github.com/jsonnet-libs/k8s-libsonnet/1.18@main
  cat <<EOF > k.libsonnet
(import 'github.com/jsonnet-libs/k8s-libsonnet/1.18/main.libsonnet')
EOF

  ## ensure namespace is set
  cd -
  echo "namespace: 'mynamespace'" > $1/values.yaml
  sed -i "1i local yaml = std.native('parseYaml')(std.extVar('yaml'))[0];" $1/jsonnet/main.jsonnet
  sed -i "s/ namespace: .*/namespace: yaml.namespace,/" $1/jsonnet/main.jsonnet
}

fetch(){
  cd $1/jsonnet
  jb install $2
  import=$(basename $2 | sed 's/@.*$//')/${3}
  sed -i "s/ data: .*/data: \n(import '${import//\//\\/}')\n+{ _config+: yaml }/" main.jsonnet
  tk fmt main.jsonnet
  cd -
}

bundler() {
  cd $1/jsonnet
  jb install
  cd -
}

show() {
  bundler $1
  tk show --ext-code yaml="(importstr '$1/values.yaml')" $1/jsonnet
}

## for testing purposes
compare() {
  bundler $1
  OUT=$(tk show --dangerous-allow-redirect --ext-code yaml="(importstr '$1/values.yaml')" $1/jsonnet)
  test "${OUT}" = "${2}"
}

build() {
  bundler $1
  rm -rf $1/templates/*
  cd $1/jsonnet
  tk export --ext-code yaml="(importstr '../values.yaml')" ../templates ./main.jsonnet
  cd -
  for f in $(find $1/templates/*.yaml); do
      sed -i 's/\({{\|}}\)/{{ "$1" }}/g' $f
  done
}

package() {
  build $1
  helm package $1
}

args() {
  if [ $1 -lt $2 ]; then
    echo "===> ERROR: Missing required arguments. Try 'helm tanka help'"
    exit 1
  fi
}

if [[ $# < 1 ]]; then
  echo "===> ERROR: Subcommand required. Try 'helm tanka help'"
  exit 1
elif [[ $# < 2 && $1 != "help" ]]; then
  echo "===> ERROR: Missing chart path. Use '.' for the present directory."
  exit 1
fi

JB=$(which jb)
if [[ "" == $JB ]]; then 
  echo "===> ERROR: 'jb' not found on PATH. Install 'tk'."
  exit 1
fi

TANKA=$(which tk)
if [[ "" == $TANKA ]]; then 
  echo "===> ERROR: 'tk' not found on PATH. Install 'tk'."
  exit 1
fi

case "${1:-"help"}" in
  "package")
    package $2
    ;;
  "show")
    show $2
    ;;
  "build")
    build $2
    ;;
  "fetch")
    args $# 4
    fetch $2 $3 $4
    ;;
  "create")
    create $2
    ;;
  "test")
    args $# 3
    compare $2 "$3"
    ;;
  "help")
    usage
    ;;
  *)
    echo $1
    usage
    exit 1
    ;;
esac
