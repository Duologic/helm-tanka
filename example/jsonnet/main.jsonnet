{
  local values = std.native('parseYaml')(std.extVar('yaml'))[0],
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
