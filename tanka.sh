#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

usage() {
cat << EOF
This plugin provides integration with the Tanka project.

It provides Tanka integration with Helm, generating Helm
templates from jsonnet source.

Available Commands:
  show    Show the generated Kubernetes manifests.
  build   Build the jsonnet files into a Kubernetes manifests, but don't package it.
  package Generated a packaged Helm chart.

Typical usage:

   $ helm create mychart
   $ mkdir -p mychart/jsonnet
   $ cd mychart/jsonnet
   $ jb init
   $ edit main.jsonnet
   $ cd ../..
   $ helm tanka package mychart
   $ helm install ./mychart-0.1.0.tgz 

EOF
}

bundler() {
  cd $1/jsonnet
  jb install
  cd -
}

show() {
  bundler $1
  tk show --tla-code yaml="(importstr '$1/values.yaml')" $1/jsonnet
}

build() {
  bundler $1
  rm -rf $1/templates/*
  tk export --tla-code yaml="(importstr '$1/values.yaml')" $1/jsonnet $1/templates
}

package() {
  build $1
  helm package $1
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
  "help")
    usage
    ;;
  *)
    echo $1
    usage
    exit 1
    ;;
esac
