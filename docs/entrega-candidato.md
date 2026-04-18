# Entrega

## 1. Modalidad y alcance

- **Track(s) trabajados:** AWS 
- **Supuestos:**
  - Equipo DevOps de 1-2 personas, presupuesto seed acotado.
  - Se priorizan correcciones de seguridad y operabilidad sobre perfección.
  - Se asume que los servicios ya están containerizados y listos para despliegue en K8s.
  - Se favorecen herramientas open-source y servicios nativos de AWS para reducir costos.

## 2. Estrategia de arquitectura

### Arquitectura propuesta en Kubernetes (EKS)

La red se armaría desplegando VPC con sus subnets públicas/privadas típicas, dejando los nodos de K8s y el RDS completamente ocultos en la privada y saliendo vía un NAT Gateway para actualizaciones (esto nos asegura no recibir peticiones de internet directo por error). Adentro, corremos dos deployments (`payments-api` y `risk-worker`) y la DB de postgresql abajo.

**¿Por qué armé la arquitectura así?:**
- Dejé los nodos de EKS en subnets privadas y usé un NAT Gateway. Sacar la API a internet directamente es mala idea, así que el acceso quedó privado.
- Puse Multi-AZ en RDS y EKS. Si se cae una zona, el estado (base de datos) no se pierde.
- Configuré `payments-api` con un HorizontalPodAutoscaler (HPA) pidiendo un mínimo de 2 réplicas desde el inicio.
- Para los secretos, preferí usar Kubernetes Secrets pasados como variables en el deployment (externalizando AWS Secrets Manager si armáramos algo a futuro).
- Dejé a `risk-worker` simplemente escuchando la cola, con sus recursos fijos (limits/requests).

**Trade-offs:**
- NAT Gateway tiene costo fijo, para presupuesto seed es aceptable vs. exponer nodos a internet.
- Single NAT Gateway (no HA) como optimización de costos para dev/staging.

## 3. Estrategia CI/CD

### Flujo: commit → despliegue seguro

El pipeline sigue una secuencia recta y lógica:
- Cuando abren un PR, corre el Lint y se genera el plan de Terraform para validar qué va a cambiar.
- Cuando se hace merge a main, construímos la imagen de Docker, la etiquetamos con el ID del código (el SHA) y se publica en GHCR. Tras eso aplicamos Terraform.
- Paso final: Desplegamos en Kubernetes y la capa final arranca a validar que los SLO de salud sigan vivos. Si estallan los errores o latencia, hace el rollback automático anulando el deploy.

**Para armar este pipeline apliqué un par de reglas sencillas:**
Lo limpié de los clásicos errores, le quité el famoso permiso de `write-all` que daba admin access al pipeline (quedó en `contents: read`), lo más importante es que quité el `-auto-approve` de Terraform y ahora lo forcé a hacer un `terraform plan` de por medio, ademas, me aseguré de que todos los despliegues de imagen salgan etiquetados con el SHA del commit en lugar de sobreescribir un tag `latest` peligroso, y agregué las validaciones del script de SLO post-deploy. Las ramas están protegidas para requerir pull requests.

**Riesgos residuales:**
- No se implementó merge queue (requiere GitHub Team plan).
- Tests de integración no están en el pipeline (requiere ambiente ephemeral).

## 4. Observabilidad

### Stack: Prometheus + OpenTelemetry + Grafana + Loki + Tempo

- **Métricas:** Usaremos Prometheus (con scrape de 15s) para atrapar el Error rate, la latencia, saturación y llenado de las colas.
- **Logs:** Loki (vía OTel Collector) para traer logs estructurados metiéndole el `trace_id` automáticamente.
- **Trazas:** Tempo manejando el tracing distribuido desde la API hacia los workers y la base.
- **Alertas:** Alertmanager chillando si superamos 1% de errores, métricas caídas, u OOM kills.
- **Grafana:** Como el tablero para juntarlo absolutamente todo de un solo vistazo.

**Correcciones aplicadas:**
- `scrape_interval` de 1s a 15s (el original generaba carga excesiva en Prometheus).
- `retention` de 2d a 15d (2 días es insuficiente para post-mortems y análisis de tendencias).
- OTel Collector: agregados pipelines de métricas y logs (solo tenía traces).
- Agregadas alerting rules (HighErrorRate, HighLatencyP95, PodCrashLooping, WorkerQueueBacklog).
- Filtrado de atributos sensibles (db.statement, http.request.body) para PCI-DSS.

**Correlación de incidentes:**
- OpenTelemetry inyecta `trace_id` en logs, traces y métricas.
- Grafana permite saltar entre pilares via exemplars y links.
- Flujo: Alerta (Prometheus) → Trace (Tempo) → Logs (Loki) → Root cause.

## 5. Mantenibilidad

### Modularidad IaC
- **Módulos separados por dominio:** `network`, `compute`, `data` (ya existente, mejorado).
- **Environments via composition:** `environments/dev/main.tf` compone módulos con variables por ambiente.
- **Convenciones de naming:** `{project}-{environment}-{resource}` (ej: `novaledger-dev-postgres`).
- **Tagging obligatorio:** `Project`, `Environment`, `ManagedBy`, `Compliance` en todos los recursos.

### Reducción de duplicación
- **Kustomize overlays** para K8s: `base/` con configuración común, `overlays/staging/` y `overlays/prod/` solo con diferencias.
- **Variables de Terraform** con defaults sensatos pero override por ambiente.
- **Backend remoto** (S3 + DynamoDB) para state compartido y locking.

### Deuda técnica identificada
1. **Migrar secretos a External Secrets Operator:** (Prioridad Alta) se puede realizar en unos 2-3 días.
2. **Implementar remote state con S3 backend:** (Prioridad Media)  1 día de esfuerzo.
3. **Agregar environments staging y prod en Terraform:** (Prioridad Media) Unos 2 días.
4. **Service mesh (Istio) para canary deployments:** (Prioridad Baja) Es más pesado, requerirá casi una semana.
5. **mTLS entre servicios via OTel:** (Prioridad Baja) Solo si sobra tiempo, toma un par de días.

## 6. Operaciones automatizadas

### Runbooks implementados
1. **`preflight.sh`** — Verifica herramientas, AWS credentials, cluster, namespace, secrets y Terraform state antes de desplegar.
2. **`slo_check.py`** — Consulta Prometheus para validar SLOs (error rate ≤1%, p95 ≤300ms, disponibilidad ≥99.9%). Se ejecuta post-deploy y bloquea/revierte si falla.

### Verificaciones de SLO en pipeline
- SLO check integrado en el pipeline CI/CD como step post-deploy.
- Si falla, trigger automático de rollback.

### Makefile como punto de entrada
```bash
make preflight    # Verificaciones previas
make slo-check    # Validación de SLOs
make deploy       # Despliegue completo (preflight + terraform + k8s + slo-check)
```

## 7. Rollback y respuesta a incidentes

### Estrategia de rollback
1. **Despliegues K8s:** `kubectl rollout undo` con historial de revisiones. RollingUpdate con `maxUnavailable: 0` garantiza zero-downtime.
2. **Terraform:** State en S3 permite `terraform plan` para review antes de cualquier cambio, en emergencia: revertir commit y re-aplicar.
3. **Base de datos:** RDS Multi-AZ con failover automático (<2 min). PITR disponible con granularidad de 5 minutos.

### Proceso de respuesta a incidentes
1. **Detección (MTTD):** Alertas de Prometheus (error rate, latencia, crash loops) → Alertmanager → notificación.
2. **Triaje:** Grafana dashboards → identificar servicio afectado → correlacionar con traces y logs.
3. **Mitigación:** Rollback automático disparado por el pipeline.
4. **Resolución:** Fix → PR → pipeline completo con validación.
5. **Post-mortem:** Con datos de métricas (15 días de retention).

## 8. Riesgos detectados y priorización

- **Baches Críticos (Ya todo lo arreglé):**
  - Existía un password hardcoded directamente quemado en Terraform.
  - La base de datos postgres estaba marcada deliberadamente para ser accesible a todo en internet público.
  - El Security group tenía abierto su red `0.0.0.0/0`.
  - Secretos tirados en plaintext en el deploy YAML de la API.
  - El Pipeline venía con permisos destructivos `write-all`.
  - Hacían despliegue "suicida" de Terraform (`apply -auto-approve` directamente a ciegas).

- **Otras fallas altas (Ya listas en PR):**
  - Faltaba el disco encriptado (rompía directo las normas de PCI-DSS).
  - La base no tenía la propiedad de backups habilitada, le puse 7 días.
  - Uso peligroso de docker `latest` e inexistencia de control de limits.
  - La subnet privada en Terraform estaba puesta para mapear IPs públicas, la arreglé.
  - Prometheus estaba reventándose haciéndose ping de "1s", se pasó a unos amables 15s.

**Criterio de priorización:** Seguridad de datos financieros > Disponibilidad > Operabilidad > Mantenibilidad.

## 9. Riesgos residuales

A pesar de lo solucionado, dejo anotado esto para atacar después:
- El State remoto de Terraform en S3 está comentado, se necesitaría activar el backend con DynamoDB.
- Los Secretos en K8s no se están rotando solos, se necesitaría conectarlos definitivamente con Secrets Manager más adelante.
- Hay un solo NAT Gateway para achicar la factura inicial, estaría bueno en producción pagar dos, uno por Availability Zone si se quiere estar 100% blindados de red.
- A futuro se podría proteger la llamada frontend al Ingress tirándole un AWS WAF enfrente del ALB.

## 10. Plan 30/60/90 días

### Días 1-30: Foundations
- Se corregirían  las vulnerabilidades críticas de seguridad (passwords, los grupos de seguridad, y obligar la encriptación de discos).
- Se dejaría ya implementado el pipeline CI/CD con todas sus revisiones de seguridad limpias.
- Se configurarían las alarmas básicas para agarrar al vuelo el error rate, la latencia y los crashes mortales.
- Se activaría oficialmente el remote state con S3 + DynamoDB.
- Se dejaría creado el ambiente de "staging" replicando todo con un Kustomize overlay.
- Se sacarían los secretos de los archivos para meterlos con External Secrets Operator.
- Por último empezaría a documentar los "runbooks" en la wiki para que todos sepan qué hacer si se rompe algo.

### Días 31-60: Hardening
- Nos meteríamos con la red pesada: agregar un WAF en el ALB para estar protegidos de inyecciones y bots.
- Levantaríamos el despliegue Canary con Flagger o Argo Rollouts para no volver a arriesgar a los usuarios.
- Agregaríamos un NAT Gateway adicional (uno por AZ) para alta disponibilidad.
- Incluiríamos una buena suite de tests de integración en el pipeline usando un ambiente efímero por cada pull request.
- Tocaría hacer un simulacro tipo "Disaster recovery": matar manualmente el RDS principal y ver qué tan rápido reacciona la réplica.
- Unificar la lectura de logs mandando todo concentrado con Loki en el clúster.

### Días 61-90: Excellence
- Analizar si vale la pena montar Istio (service mesh) para asegurar el tráfico interno de los microservicios con encriptado mutuo.
- Hacer la migración pura a GitOps controlando todo el cluster desde ArgoCD.
- Meter un poco de Chaos Engineering matando pods al azar en la semana a ver si algo tiembla.
- Terminar de automatizar la contraseña maestra de PostgreSQL para que rote solita cada X días.
- Ponerle ojo a los costos reales y comprar Reserved Instances e ir por Savings Plans.
- Tirar formalmente la auditoría PCI-DSS con todas las palomitas en verde.
- Habilitar por fin las métricas DORA para ver si estamos desplegando más rápido a producción sin romper las cosas.
