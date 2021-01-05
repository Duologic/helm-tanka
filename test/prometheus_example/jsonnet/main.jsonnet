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
