# Escenarios Técnicos

## Cloud / Kubernetes

1. Tu API en Kubernetes pasa readiness pero falla liveness esporádicamente solo bajo picos. ¿Cómo investigas y qué cambiarías primero?
2. Un HPA escala pods, pero latencia sigue alta y CPU está baja. ¿Cuáles son tres hipótesis técnicas?
3. Si debes cumplir RPO=5 min y RTO=30 min para la base de datos principal, ¿qué arquitectura mínima propones?
4. ¿Cuál es el riesgo real de usar imágenes `latest` en despliegues de producción?

## CI/CD

5. El pipeline tarda 25 minutos y el equipo hace bypass de tests. ¿Cómo rediseñas flujo y guardrails?
6. ¿Qué diferencia operativa hay entre `blue/green` y `canary` para una API de pagos?
7. ¿Cómo evitar que secretos queden expuestos en logs de pipeline?

## Sistemas Operativos y Contenedores

8. Un contenedor tiene OOMKilled cada 2 horas, pero el nodo muestra memoria libre. ¿Cómo lo explicas?
9. Diferencia práctica entre `ulimit`, `cgroups` y `requests/limits` en Kubernetes.
10. ¿Qué síntomas esperas al agotar file descriptors y cómo lo mitigas?

## Observabilidad

11. ¿Qué métrica y alerta usarías para detectar degradación silenciosa de un worker de colas?
12. ¿Cómo correlacionas un incidente entre logs, trazas y métricas sin depender de una sola herramienta?
