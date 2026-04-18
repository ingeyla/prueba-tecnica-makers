# Track GCP

## Stack

- Kubernetes: GKE.
- Datos: Cloud SQL PostgreSQL.
- Artefactos: Artifact Registry.
- Observabilidad: Managed Prometheus + OpenTelemetry.
- CI/CD: Cloud Build / GitHub Actions.
- Automatización operativa: Bash + Python + Makefile.

## Subdirectorios

- `iac/`: Terraform (obligatorio) y Pulumi/CDK (opcional).
- `k8s/`: manifiestos de servicio.
- `observability/`: configuración de telemetría y alertas.
- `cicd/`: pipeline de referencia.
- `automation/`: tareas operativas automatizadas.
