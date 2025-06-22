# Documentação Final do Projeto: Arquitetura Multinuvem com CI/CD

## Visão Geral

Este projeto entrega uma arquitetura multinuvem simulada, composta por dois ambientes totalmente independentes:

- **Ambiente de Produção:** Provisionado em uma conta de nuvem (ex: DigitalOcean, AWS, GCP ou Azure).
- **Ambiente de Homologação (Stage):** Provisionado em uma segunda conta de nuvem distinta (ex: DigitalOcean, AWS, GCP ou Azure).

Cada ambiente possui sua própria infraestrutura, monitoramento e pipelines de CI/CD, garantindo isolamento, rastreabilidade e automação de ponta a ponta.

---

## Objetivo da Entrega

- **Provisionar dois ambientes completos (Produção e Stage) em nuvens distintas.**
- **Automatizar o deploy da infraestrutura e da aplicação em ambos os ambientes via CI/CD (GitHub Actions).**
- **Manter o deploy das duas aplicações desenvolvidas no Mensal 3, totalizando 4 pipelines distintas.**

---

## Infraestrutura Provisionada

### 1. Cluster Kubernetes (K8s) para cada ambiente

- **Produção:** Cluster K8s dedicado, provisionado via Terraform.
- **Stage:** Cluster K8s dedicado, provisionado via Terraform.

### 2. Monitoramento com Prometheus + Grafana

- **Prometheus:** Coleta métricas básicas do cluster (CPU, memória, status dos pods).
- **Grafana:** Dashboard customizado para cada ambiente, exibindo:
  - Uso de CPU
  - Uso de Memória
  - Status dos Pods

---

## Arquitetura de CI/CD

A automação é realizada via **GitHub Actions**, com pipelines separadas para cada ambiente e para cada aplicação:

### Pipelines

1. **Infraestrutura Produção:**  
   - Provisiona o cluster K8s e instala Prometheus + Grafana na nuvem de produção.
2. **Infraestrutura Stage:**  
   - Provisiona o cluster K8s e instala Prometheus + Grafana na nuvem de homologação.
3. **Deploy Aplicação Produção:**  
   - Builda, empacota e faz deploy da aplicação de produção no cluster K8s de produção.
4. **Deploy Aplicação Stage:**  
   - Builda, empacota e faz deploy da aplicação de homologação no cluster K8s de stage.

---

## Fluxo das Pipelines

### 1. Provisionamento da Infraestrutura (via Terraform)
- Executado automaticamente ao detectar mudanças em arquivos de infraestrutura.
- Cria recursos como cluster K8s, VPC, storage, etc.

### 2. Configuração do Cluster e Instalação de Monitoramento
- Instala Prometheus e Grafana via Helm Charts.
- Garante que as métricas do cluster estejam expostas.

### 3. Build da Aplicação
- Builda a imagem Docker do backend e frontend.

### 4. Push da Imagem para Repositório
- Envia as imagens para um repositório de container (ECR, GCR, DockerHub, DigitalOcean Container Registry, etc).

### 5. Deploy Automatizado no Cluster Kubernetes
- Aplica os manifests do Kubernetes (ou Helm Charts) para backend e frontend.

### 6. Aplicação de Manifests e Helm Charts
- Aplica arquivos YAML ou Helm Charts para criar/atualizar deployments, services, ingress, secrets, etc.

### 7. Validação de Sucesso no Deploy
- Realiza health checks automáticos nos endpoints.
- Valida a coleta de métricas no Prometheus.
- Valida a visualização dos dashboards no Grafana.

---

## Exemplo de Estrutura de Pastas

```text
Formerr/
├── Formerr-FastAPI/         # Backend FastAPI
├── formerr-frontend/        # Frontend Next.js
├── infrastructure/          # (opcional) IaC com Terraform
│   ├── production/
│   └── staging/
└── .github/
    └── workflows/
        ├── infra-prod.yml
        ├── infra-stage.yml
        ├── deploy-prod.yml
        └── deploy-stage.yml
```

---

## Exemplo de Pipeline (GitHub Actions)

```yaml
# .github/workflows/infra-prod.yml
name: Infraestrutura Produção

on:
  push:
    paths:
      - 'infrastructure/production/**'
  workflow_dispatch:

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: 1.6.0
      - run: terraform init
        working-directory: infrastructure/production
      - run: terraform apply -auto-approve
        working-directory: infrastructure/production
      # Instalação do Prometheus e Grafana via Helm pode ser feita aqui
```

---

## Exemplo de Dashboard Grafana

- **CPU:** `sum(rate(container_cpu_usage_seconds_total[5m])) by (pod)`
- **Memória:** `sum(container_memory_usage_bytes) by (pod)`
- **Status dos Pods:** `kube_pod_status_phase`

---

## Validação e Observabilidade

- **Endpoints de health check expostos e validados via pipeline.**
- **Prometheus acessível e coletando métricas.**
- **Grafana acessível com dashboards configurados.**
- **Relatórios automáticos de sucesso/falha do deploy.**

---

## Considerações Finais

- **Isolamento total entre ambientes:** Cada ambiente em uma conta de nuvem distinta.
- **Automação completa:** Do provisionamento ao deploy e validação.
- **Observabilidade:** Monitoramento robusto com Prometheus e Grafana.
- **Rastreabilidade:** Pipelines versionadas e auditáveis via GitHub Actions.

---

Se desejar exemplos de comandos Terraform, manifests Kubernetes, exemplos de dashboards Grafana, ou detalhamento extra, consulte os diretórios específicos ou solicite ao time DevOps. 