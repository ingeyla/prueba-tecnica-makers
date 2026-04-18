# Contexto del Problema

Una startup financiera llamada `NovaLedger` ofrece:

- API de pagos.
- Motor de riesgo transaccional.
- Servicio de conciliación nocturna.
- Portal interno para operaciones.

## Situación actual

- Time-to-market lento por despliegues manuales.
- Ambientes inconsistentes (dev/staging/prod).
- Incidentes sin trazabilidad completa.
- Hallazgos de seguridad por mala gestión de secretos.

## Restricciones

- Presupuesto limitado (etapa seed).
- Equipo técnico pequeño (6 personas).
- Necesidad de disponibilidad de API >= 99.9%.
- Cumplimiento básico de controles tipo PCI-DSS (nivel inicial).

## Lo que se espera

1. Estrategia escrita de arquitectura objetivo.
2. Propuesta de pipeline CI/CD con controles mínimos.
3. Estrategia de observabilidad y respuesta a incidentes.
4. Ajustes sobre los artefactos IaC/K8s para reducir riesgo operativo.
