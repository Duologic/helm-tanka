.PHONY: test
test:
	@rm -rf prometheus_example && \
	../tanka.sh create prometheus_example && \
	../tanka.sh fetch prometheus_example github.com/grafana/jsonnet-libs/prometheus@00795013f5975f518a0a3de99253f9d5590271c8 prometheus.libsonnet && \
	../tanka.sh test prometheus_example "$$(cat ./expected)"
