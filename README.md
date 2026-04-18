# Prueba Técnica DevOps - NovaLedger

## Contexto

NovaLedger es una startup fintech que ofrece una API de pagos, motor de riesgo transaccional, servicio de conciliación nocturna y portal interno de operaciones. Necesita evolucionar su plataforma hacia una arquitectura distribuida, segura y observable sobre Kubernetes.

Revise `docs/01-contexto-problema.md` para el contexto completo.

## Qué se espera de usted

1. **Estrategia escrita** en `docs/entrega-candidato.md`.
2. **Ajustes sobre artefactos IaC/K8s/CI-CD/Observabilidad** en el track asignado.
3. **Respuestas a escenarios** en `scenarios/respuestas-candidato.md`.

Revise `docs/02-instrucciones-candidato.md` para las instrucciones detalladas.

## Estructura del repositorio

- `docs/` - contexto, instrucciones y reglas.
- `tracks/` - artefactos técnicos por proveedor cloud (AWS, GCP, Azure).
- `iac/` - infraestructura como código base (Terraform, CDK, Pulumi).
- `k8s/` - manifiestos Kubernetes base con Kustomize.
- `scenarios/` - escenarios técnicos.

Cada track en `tracks/` incluye:

- `iac/` - Terraform (obligatorio), CDK y Pulumi (opcional/bonus).
- `k8s/` - manifiestos de despliegue.
- `cicd/` - pipeline de referencia.
- `observability/` - configuración de telemetría y alertas.
- `automation/` - tareas operativas (Makefile, scripts).

## Tiempo

Dispone de un máximo de **4 horas**.

## Entregables

1. Pull request con sus cambios.
2. Documento técnico en `docs/entrega-candidato.md`.
3. Respuestas en `scenarios/respuestas-candidato.md`.

## Importante

No se espera corregir todo. Se valora la detección de problemas, su priorización por impacto, y un plan de remediación claro con trade-offs explicados.
