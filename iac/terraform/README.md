# Terraform - Base de Infraestructura

Este directorio contiene una base minima para la prueba.

## Alcance

- Red (VPC + subnets).
- Compute (EKS).
- Datos (RDS PostgreSQL).

## Uso rapido

```bash
cd iac/terraform/environments/dev
terraform init
terraform plan -var-file=terraform.tfvars
```

## Nota

La configuracion contiene decisiones discutibles y riesgos tecnicos intencionales para la prueba.
El candidato debe identificar, priorizar y justificar remediaciones.
