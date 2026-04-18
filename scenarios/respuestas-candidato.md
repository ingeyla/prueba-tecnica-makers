# Respuestas del Candidato

> Complete este archivo con respuestas breves y justificadas.


## Cloud / Kubernetes

### 1. Tu API en Kubernetes pasa readiness pero falla liveness esporádicamente solo bajo picos. ¿Cómo investigas y qué cambiarías primero?

Para investigar, lo primero que miraría son las métricas de CPU y memoria del pod (usando kubectl top o Prometheus) durante los picos de tráfico para ver si hay algún tipo de saturación que tranque a la aplicación. También verificaría los logs buscando deadlocks o pausas súper largas del Garbage Collector, y me aseguraría de que el propio endpoint de liveness no esté haciendo consultas pesadas a la base de datos de manera innecesaria.

Por otra parte, lo primero que cambiaría sería separar los endpoints, el liveness debería ser algo muy rápido y tonto (tipo `return 200`) que solo valide que el contenedor no está bloqueado por completo. Al readiness sí le metería validación profunda. También, le subiría un poco el `timeoutSeconds` para que aguante los picos sin que Kubernetes asuma que está muerto y empeore todo reiniciándolo.


### 2. Un HPA escala pods, pero latencia sigue alta y CPU está baja. ¿Cuáles son tres hipótesis técnicas?

1. **Cuellos de botella externos:** El HPA escala pods, pero si todos esos pods compiten en la base de datos limitando un connection pool, escalar empeora las cosas. La solución de esto la darían las métricas de latencia de backend o DB.
2. **Contención de I/O:** Estás escalando por CPU, pero los procesos se están quedando dormidos esperando disco, red o un DNS muy lento. La CPU sale baja porque nadie la usa mientras esperan bloqueados.
3. **Throttling "Oculto" (CFS):** Si el CPU tiene limits, el kernel puede "ahorcar" y pausar el contenedor microscópicamente cuando se pasa de la fracción permitida, todo se alenta sin notar que la métrica agregada está alta. Esto lo confirmaríamos con la métrica `container_cpu_cfs_throttled_seconds_total`.


### 3. Si debes cumplir RPO=5 min y RTO=30 min para la base de datos principal, ¿qué arquitectura mínima propones?

Sin irnos por arquitecturas súper costosas, lo cumpliría sencillo así:
- Usando RDS en PostgreSQL con Multi-AZ. Al ser de copiado síncrono, si se revienta una falla zonal nos regala un RPO casi de cero y hace failover (RTO) automático en 2 minutos aproximadamente.
- Configurando los backups nativos con una retención de 7 días prendiendo Point-In-Time-Recovery (que permite volver a cualquier minuto exacto, dejándome bien parado con el objetivo RPO=5min).
- Cuidando poner el periodo de mantenimiento e instantáneas de madrugada, no le veo necesidad inmediata de levantar réplicas cruzadas de región hasta que crezca mucho el presupuesto de la empresa.



### 4. ¿Cuál es el riesgo real de usar imágenes `latest` en despliegues de producción?

Usar `latest` es de las peores deudas técnicas operativas, principalmente porque no sabes qué está corriendo de verdad, cuando debugeas el `kubectl describe`, solo te dice que es 'latest', peor aún para operaciones, si el equipo me pide hacer un rollback, al intentar el `rollout undo`, el deployment trata de bajar la de nuevo la supuesta versión base que igual sigue siendo apuntada a la misma etiqueta 'latest', causando un confusión con el cache y con pods que acaban difiriendo de versión sin enterarse, lo ideal (y lo más seguro) es usar sha256 fijos, o el Tag con el SHA del commit del pipeline.


## CI/CD

### 5. El pipeline tarda 25 minutos y el equipo hace bypass de tests. ¿Cómo rediseñas flujo y guardrails?

Un pipeline de 25 minutos alienta el despliegue al punto de causar fricción. Para optimizar eso:
- Paralelizaríamos el QA (arrancando linting, análisis unitario y scans todo al mismo tiempo en runners separados).
- Usar cachés fuertes para que no esté descargando el módulo de python y las capas grandes de docker todos los días. 
- Dejaría los End to End, que son los que más tardan, para ejecuciones "nightly" (o al mergear a Dev), y limitaría las pull requests solo a checks unitarios que respondan en < 5 minutos.

Luego, pondría guardrails configurando un Branch Protection en GitHub, pidiendo obligatoriamente los status check en verde impidiendo a los devs usar puros "force push".


### 6. ¿Qué diferencia operativa hay entre `blue/green` y `canary` para una API de pagos?

El Blue/Green cambia bruscamente el 100% del tráfico a los nuevos pods en un instante, requiere duplicar infraestructura, si la nueva versión de la API de pagos tiene un error en lógica que los tests no vieron, el 100% de los usuarios tendrán transacciones caídas.
En cambio, el **Canary** desvía inicialmente un porcentaje bajo (ej. 5%) para validar comportamiento con solicitudes reales y luego incrementarlo, especialmente en pagos, Canary reduce drásticamente el área de daño de un defecto financiero.

Es decir, si subo un error en pagos, con canary arruino unas cuantas transacciones por minuto antes de alertar mi monitorieo, mientras que con blue/green bloqueo al total de los clientes por unos dos minutos con costo altísimo reputacional.


### 7. ¿Cómo evitar que secretos queden expuestos en logs de pipeline?

Lo primordial: Ocultarlos bien de cara del logueo nativo, usando los 'secrets' de Github que tapan contraseñas con asteriscos `***`
Pero hay un par de cosas más astutas a nivel CI/CD:
- Evitar pasar cosas como strings de bash (en vez de `docker login -u user -p $SECRETO` usar --password-stdin). Y tener apagados modos de depuración extremos (`set -x`)
- Correr utilidades como Gitleaks en un step o en un gancho de Pre-Commit para atrapar llaves de AWS antes de que lleguen siquiera al remoto.


## Sistemas Operativos y Contenedores

### 8. Un contenedor tiene OOMKilled cada 2 horas, pero el nodo muestra memoria libre. ¿Cómo lo explicas?

El OOM killer que Kubernetes aplica acá es en base a los controles "cgroups", por sobrepasarse del límite de memoria establecido en su definition YAML (`resources.limits`), así que matarlo es intencional por más que al nodo aún le sobraran gigas limpias de memoria por compartir.
Si ocurre cada 2 horas puede ser un leak de memoria (memory leak) de la app misma, lo diagnosticaría metiéndome a sacar un volcado perfilado justo antes de que lo maten, y si resulta no ser un leak sino la constante natural que ocupa la herramienta, iría y le subiría de forma ajustada el umbral al limit en Kubernetes.


### 9. Diferencia práctica entre `ulimit`, `cgroups` y `requests/limits` en Kubernetes.

- **ulimit:** Operacional a nivel proceso. Es como un permiso que le ajustas a tu máquina/contenedor (común `ulimit -n`) para cosas de bajo nivel del sistema (ejemplo, ¿cuántas tuberías/sockets le dejas mantener abiertas a ese servicio de red?).
- **cgroups:** Aislamiento del Kernel Linux mismo. Las jaulas de las cuales Docker y pods sacan los recursos físicos apartando partes de memoria, ancho de hardware.
- **requests/limits (K8s):** Esto ya son abstracciones superiores del orquestador. Kubernetes usa los **requests** básicamente solo para organizarse y preguntar: "¿En qué nodo tengo espacio para agendarte?", y usa los **limits** pasándole esa info al cgroup de abajo garantizando la decapitación del pod (OOM / throttle) si se pasa.


### 10. ¿Qué síntomas esperas al agotar file descriptors y cómo lo mitigas?

Si la app agota todos los "descriptors", generalmente verás fallando logs con errores como `Too many open files`,  va rechazar solicitudes, mostrará 502/504 en la API y hasta botarte del Ingress porque como Linux cuenta conexiones a red como archivos, no puede agarrar el "handle" temporal para recibir tráfico.

Para mitigar la falla a corto plazo y estabilizar el servicio, subiría temporalmente el ulimit (o ajusto fs.file-max vía sysctl) para darle oxígeno a la aplicación, sin embargo, una vez contenida la emergencia, toca sentarse con el equipo de desarrollo, puesto que la causa raíz de este fallo casi siempre es código que abre una conexión (REST o a la base de datos) y olvida cerrarla correctamente en un bloque finally, dejando sockets colgados hasta que el sistema agota sus descriptores

## Observabilidad

### 11. ¿Qué métrica y alerta usarías para detectar degradación silenciosa de un worker de colas?

      - Métrica: Utilizaría "Age of Oldest Message" (Tiempo del mensaje más antiguo sin procesar) y "Queue Depth" (Cantidad de items pendientes acumulados).
      - Alerta: Configurar un Threshold en donde si el tiempo del mensaje más antiguo tiene más de X minutos sin ser sacado de la cola, dispararía la alerta severa. No usaría uso de CPU del worker, ya que en un error donde el worker hace un "deadlock", la CPU se iría a ~0 pero dejaría procesar.


### 12. ¿Cómo correlacionas un incidente entre logs, trazas y métricas sin depender de una sola herramienta?

La clave con stacks de open-source es "Estampar" (Correlación cruzada) todos los flujos, el id de traza, el `trace_id` es el ancla principal. En NovaLedger armaría:
- Poner la auto-instrumentación de OpenTelemetry (OTel SDK). OTel se encarga de inyectar por defecto el mismo W3C Trace Id en todos las llamadas y eventos entre los nodos de red de AWS y mis dos apps.  
- En el logueo de las aplicaciones le agrego un log que diga `{'Mensaje': 'error db', 'traceId':'1x1x' }`.
- Con Grafana pegaría las tres:
  - Miro la alarma disparada en Prometheus por la saturación o error, en ese mismo dashboard (exemplar) doy click, y navego mágicamente a las gráficas en cascadas directas a un nodo en Tempo a ver en qué milisegundo ocurrió la falla, luego de ahí recojo el ID y con Loki recupero de toda la terminal en los clusters a ver el texto y la traza del error Java/Node del fallo sin salirme a usar licencias enormes y caras.
