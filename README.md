# Helm Tanka plugin

A Helm plugin for rendering Tanka/Jsonnet inside Helm charts.

Heavily inspired by https://github.com/technosophos/helm-ksonnet.

## Installation

Prerequisites:

* [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler/)>=0.4.0
* [tanka](https://tanka.dev/)>=0.13.0
* [helm](https://helm.sh/)>=3.4 (tested with version 3.4.1)

Install the Helm plugin:

```console
$ helm plugin install https://github.com/Duologic/helm-tanka.git
```

## Usage

After installation, the plugin is available at `helm tanka`.

```console
$ helm tanka help

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
   $ helm package mychart
   $ helm install ./mychart-0.1.0.tgz 

```

### Writing Tanka Charts

Also see included example.

Get started by creating a standard chart:

```console
$ helm create mychart
```

Inside of your chart, you will need to create a `jsonnet/` directory, which will be the home for your jsonnet files.

```console
$ mkdir -p mychart/jsonnet
```

Then initialize the jsonnet directory with `jb` and create a `main.jsonnet` file. Tanka treats `main.jsonnet` as the
entry point and uses the `jsonnetfile.json` as the relative entrypoint for finding libraries.

```console
$ cd mychart/jsonnet
$ jb init
$ touch main.jsonnet
```

Now edit the `main.jsonnet`, Tanka expects an [inline `tanka.dev/Environment`](https://tanka.dev/inline-environments#inline-environments) 
object and this plugin provides the `values.yaml` through a top-level function:

```jsonnet
function(yaml) { // top-level function
  local values = std.native('parseYaml')(yaml)[0],
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: 'mychart',
  },
  spec: {
    namespace: values.namespace,
  },
  data: {
    /* your kubernetes objects go here */
  }
}
```

You can now populate your `values.yaml` with the required data:

```console
$ cat mychart/values.yaml

---
namespace: 'default'
```

### Testing Your Chart

To test that your chart is working correctly, use the `helm tanka show` command:

```console
$ helm tanka show ./mychart/
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: default
spec:

# ...
```

### Packaging and Installing Your Chart

The first step is to create a chart package, and then install it:

```console
$ helm tanka package ./mychart
Successfully packaged chart and saved it to: ./mychart-0.1.0.tgz
```


At this point, you can now easily install this package using the regular Helm commands:

```console
$ helm install ./mychart-0.1.0.tgz
```

> TIP: You can also use `helm install --dry-run --debug ./mychart-0.1.0.tgz` to run a test install.

### Installing without Packaging

It is possible to install a chart without first packaging it. In this method, we build the Kubernetes manifests but do not package the chart:

```console
$ helm ksonnet build ./mychart
./mychart/templates/deployment.yaml
```

This tells us that it has built the manifest, but has not packaged it. We can still use Helm to install it, though:

```console
$ helm install ./mychart
```
