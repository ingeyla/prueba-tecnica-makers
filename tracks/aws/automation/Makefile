SHELL := /bin/bash

.PHONY: preflight slo-check rollback help

help: ## Mostrar ayuda
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

preflight: ## Verificaciones previas al despliegue
	bash scripts/preflight.sh

slo-check: ## Validación de SLOs contra Prometheus
	python3 scripts/slo_check.py

rollback: ## Rollback de deployment (uso: make rollback DEPLOY=payments-api)
	bash scripts/rollback.sh $(DEPLOY) $(REVISION)

deploy: preflight ## Despliegue completo (preflight + terraform + k8s)
	@echo "▸ Terraform apply..."
	cd ../../iac/terraform && terraform init && terraform plan -out=tfplan && terraform apply tfplan
	@echo "▸ Kubernetes apply..."
	kubectl apply -k ../../../k8s/base/
	@echo "▸ Post-deploy SLO check..."
	$(MAKE) slo-check
