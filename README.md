# Helm Tanka plugin

A Helm plugin for rendering Jsonnet into Helm charts with Tanka.

Heavily inspired by https://github.com/technosophos/helm-ksonnet.

## Installation

Prerequisites:

* [jsonnet-bundler](https://github.com/jsonnet-bundler/jsonnet-bundler/)>=0.4.0
* [tanka](https://tanka.dev/)>=0.17.1
* [helm](https://helm.sh/)>=3.4 (tested with version 3.6.2)

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
  create    Create initial setup
  fetch   Fetch a Jsonnet library (on first setup)
  show    Show the generated Kubernetes manifests.
  build   Build the jsonnet files into a Kubernetes manifests, but don't package it.
  package Generated a packaged Helm chart.

Fetch usage:

   $ helm tanka fetch <url> <entrypoint>

Typical usage:

   $ helm tanka create prometheus
   $ helm tanka fetch prometheus github.com/grafana/jsonnet-libs/prometheus prometheus/prometheus.libsonnet
   $ helm tanka package prometheus
   $ helm install ./prometheus-0.1.0.tgz 

```

### Writing Tanka Charts

Also see included example.

Get started by creating a standard chart:

```console
$ helm tanka create prometheus
```

You can populate your `values.yaml` with the required data:

```console
$ cat prometheus/values.yaml

namespace: 'mynamespace'
```

Then fetch the library you want to use in this Helm chart:

```console
$ helm tanka fetch prometheus github.com/grafana/jsonnet-libs/prometheus prometheus/prometheus.libsonnet
```

After this you can edit the `prometheus/jsonnet/main.jsonnet` in case you crave more advanced use cases:

```jsonnet
local yaml = std.native('parseYaml')(std.extVar('yaml'))[0];
{
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: '.',
  },
  spec: {
    apiServer: '',
    namespace: yaml.namespace,
    resourceDefaults: {},
    expectVersions: {},
  },
  data:
    (import 'prometheus/prometheus.libsonnet')
    + { _config+: yaml },
}
```


### Testing Your Chart

To test that your chart is working correctly, use the `helm tanka show` command:

```console
$ helm tanka show ./prometheus/

apiVersion: v1
kind: ServiceAccount
metadata:
  name: prometheus
  namespace: mynamespace
---
apiVersion: v1
data:
  alerts.rules: |
    groups:

# ...
```

### Packaging and Installing Your Chart

The first step is to create a chart package, and then install it:

```console
$ helm tanka package ./prometheus
Successfully packaged chart and saved it to: ./prometheus-0.1.0.tgz
```


At this point, you can now easily install this package using the regular Helm commands:

```console
$ helm install ./prometheus-0.1.0.tgz
```

> TIP: You can also use `helm install --dry-run --debug ./prometheus-0.1.0.tgz` to run a test install.

### Installing without Packaging

It is possible to install a chart without first packaging it. In this method, we build the Kubernetes manifests but do not package the chart:

```console
$ helm tanka build ./prometheus
./prometheus/templates/apps-v1.StatefulSet-prometheus.yaml
./prometheus/templates/rbac.authorization.k8s.io-v1beta1.ClusterRoleBinding-prometheus.yaml
./prometheus/templates/rbac.authorization.k8s.io-v1beta1.ClusterRole-prometheus.yaml
./prometheus/templates/v1.ConfigMap-prometheus-alerts.yaml
./prometheus/templates/v1.ConfigMap-prometheus-config.yaml
./prometheus/templates/v1.ConfigMap-prometheus-recording.yaml
./prometheus/templates/v1.ServiceAccount-prometheus.yaml
./prometheus/templates/v1.Service-prometheus.yaml
```

This tells us that it has built the manifest, but has not packaged it. We can still use Helm to install it, though:

```console
$ helm install ./prometheus
```
