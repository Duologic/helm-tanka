.PHONY: test
test:
	@rm -rf prometheus_example && \
	../tanka.sh create prometheus_example && \
	../tanka.sh fetch prometheus_example github.com/grafana/jsonnet-libs/prometheus@ca37710 prometheus.libsonnet && \
	../tanka.sh test prometheus_example "$$(cat ./expected)"
