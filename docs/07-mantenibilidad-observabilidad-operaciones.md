# Lineamientos de Mantenibilidad, Observabilidad y Operaciones

## Mantenibilidad

- Separar módulos IaC por dominio (network, compute, data, security).
- Definir convenciones de naming y tagging obligatorias.
- Reducir duplicación entre ambientes mediante variables y overlays.
- Documentar deuda técnica con backlog priorizado.

## Observabilidad

- Métricas: saturación, latencia, error rate, disponibilidad.
- Logs: estructurados y con correlación (`trace_id`, `request_id`).
- Trazas: instrumentación en servicios críticos y dependencias.
- Alertas: con umbrales útiles y runbook asociado.

## Operaciones avanzadas automatizadas

- Runbooks ejecutables en Bash/Python.
- Verificaciones de SLO en pipeline de release.
- Simulacros de incidente y rollback con evidencia.
- Validaciones preflight para evitar cambios no seguros.
