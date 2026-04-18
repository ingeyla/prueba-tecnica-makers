# Track Azure

## Stack

- Kubernetes: AKS.
- Datos: Azure Database for PostgreSQL Flexible Server.
- Artefactos: Azure Container Registry.
- Observabilidad: Azure Monitor + OpenTelemetry.
- CI/CD: Azure DevOps Pipelines / GitHub Actions.
- Automatización operativa: Bash + Python + Makefile.

## Subdirectorios

- `iac/`: Terraform (obligatorio) y Pulumi/CDK (opcional).
- `k8s/`: manifiestos de servicio.
- `observability/`: configuración de telemetría y alertas.
- `cicd/`: pipeline de referencia.
- `automation/`: tareas operativas automatizadas.
