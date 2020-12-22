function(yaml) {
  local values = std.native('parseYaml')(yaml)[0],
  values: values,
  apiVersion: 'tanka.dev/v1alpha1',
  kind: 'Environment',
  metadata: {
    name: 'helm-privatebin-libsonnet',
  },
  spec: {
    namespace: values.namespace,
  },
  data: (import 'privatebin-libsonnet/privatebin.libsonnet'),
}
