# Instrucciones

## Modalidad

Su evaluador le indicará el track asignado: `aws`, `gcp` o `azure`.

Trabaje solo sobre el track indicado.

## Parte A - Estrategia escrita

En `docs/entrega-candidato.md` describa:

1. Arquitectura propuesta de servicios en Kubernetes.
2. Flujo CI/CD desde commit a despliegue seguro.
3. Estrategia de observabilidad (métricas, logs, trazas, alertas).
4. Estrategia de mantenibilidad (modularidad IaC, convenciones, deuda técnica).
5. Operaciones avanzadas automatizadas (runbooks ejecutables, checks de SLO, resiliencia).
6. Estrategia de rollback y respuesta a incidentes.

## Parte B - Infraestructura como código

En el track asignado:

- Terraform obligatorio.
- Pulumi y/o CDK opcional (bonus).

Debe:

1. Detectar errores de diseño, seguridad y operación.
2. Corregir los que considere críticos.
3. Explicar la priorización y riesgos residuales.

## Parte C - Operabilidad y observabilidad

Ajuste los artefactos de:

- `k8s/`
- `observability/`
- `automation/`
- `cicd/`

Con foco en:

- MTTD/MTTR.
- Evidencia de salud operacional.
- Evitar configuraciones no mantenibles.

## Parte D - Escenarios técnicos

Responda en `scenarios/respuestas-candidato.md`:

- `scenarios/escenarios-tecnicos.md`

## Entregables

1. Pull request con cambios.
2. Documento técnico con decisiones y trade-offs.
3. Lista de riesgos residuales no resueltos.
4. Plan incremental de 30/60/90 días para evolución operacional.
