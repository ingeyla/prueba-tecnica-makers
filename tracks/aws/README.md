# Track AWS

## Stack

- Kubernetes: EKS.
- Datos: RDS PostgreSQL.
- Artefactos: ECR/GHCR.
- Observabilidad: Prometheus + OTEL Collector + Grafana.
- CI/CD: GitHub Actions.
- Automatización operativa: Bash + Python + Makefile.

## Subdirectorios

- `iac/`: Terraform (obligatorio) y Pulumi/CDK (opcional).
- `k8s/`: manifiestos de servicio.
- `observability/`: configuración de telemetría y alertas.
- `cicd/`: pipeline de referencia.
- `automation/`: tareas operativas automatizadas.
