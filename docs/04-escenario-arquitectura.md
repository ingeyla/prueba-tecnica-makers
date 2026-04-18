# Escenario de Arquitectura

## Contexto de negocio

`NovaLedger` procesa pagos de comercios en LATAM.

- 4 millones de transacciones por día.
- Picos de 250 TPS en horario laboral.
- Integración con bancos externos y antifraude.

## Servicios principales

1. `payments-api`
   - Exposición pública para autorización y captura.
2. `risk-worker`
   - Consumo asíncrono para scoring y reglas de fraude.
3. `reconciliation-job`
   - Conciliación batch nocturna.
4. `ops-portal`
   - Consola interna para operaciones.

## Requisitos no funcionales

- Disponibilidad objetivo API: 99.9% mensual.
- p95 de autorización: < 300 ms.
- RPO datos financieros: 5 min.
- RTO plataforma crítica: 30 min.
- Auditoría de cambios en infraestructura y despliegues.

## Restricciones técnicas

- Equipo DevOps pequeño (1-2 personas).
- Presupuesto mensual acotado.
- Ambientes: `dev`, `staging`, `prod`.
- IaC requerido para recursos persistentes.

## Lo que debe resolver la propuesta

1. Estrategia de aislamiento entre servicios.
2. Patrón de despliegue seguro para cambios frecuentes.
3. Observabilidad para detectar degradación temprana.
4. Endurecimiento de seguridad sin frenar velocidad de entrega.
