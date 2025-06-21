# Formerr - Multi-Cloud Infrastructure Deployment

## 🎯 Objetivo

Este projeto implementa uma arquitetura multinuvem para o **Formerr** (construtor de formulários dinâmicos) com:
- **Ambiente de Produção** na Digital Ocean (conta principal)
- **Ambiente de Staging** na Digital Ocean (conta secundária)
- **4 pipelines CI/CD** distintas via GitHub Actions
- **Clusters Kubernetes** com monitoramento Prometheus + Grafana

## 🏗️ Arquitetura

### Ambientes
- **Produção**: Digital Ocean (NYC1) - 2 nodes s-2vcpu-2gb
- **Staging**: Digital Ocean (FRA1) - 1 node s-1vcpu-2gb

### Aplicação
- **Backend**: FastAPI com PostgreSQL
- **Frontend**: Next.js
- **Monitoramento**: Prometheus + Grafana
- **Container Registry**: Digital Ocean Container Registry

## 🚀 Deploy

### Pré-requisitos

1. **GitHub Secrets** necessários:
   ```
   DO_TOKEN_PROD         # Token da conta DO produção
   DO_TOKEN_STAGING      # Token da conta DO staging
   PROD_CLUSTER_ENDPOINT # Endpoint do cluster prod
   PROD_CLUSTER_TOKEN    # Token do cluster prod
   PROD_CLUSTER_CA       # CA certificate do cluster prod
   STAGING_CLUSTER_ENDPOINT
   STAGING_CLUSTER_TOKEN
   STAGING_CLUSTER_CA
   ```

2. **Container Registry** criado na Digital Ocean com nome `formerr`

### Pipelines

#### 1. Infraestrutura - Produção
- **Trigger**: Push para `main` com mudanças em `infrastructure/terraform/production/`
- **Ação**: Provisiona cluster K8s + Prometheus/Grafana na conta principal DO

#### 2. Infraestrutura - Staging  
- **Trigger**: Push para `develop` com mudanças em `infrastructure/terraform/staging/`
- **Ação**: Provisiona cluster K8s + Prometheus/Grafana na conta secundária DO

#### 3. Aplicação - Produção
- **Trigger**: Push para `main` com mudanças em código da aplicação
- **Ação**: Build → Push para registry → Deploy no cluster de produção

#### 4. Aplicação - Staging
- **Trigger**: Push para `develop` com mudanças em código da aplicação  
- **Ação**: Build → Push para registry → Deploy no cluster de staging

## 🔧 Setup Local

### 1. Clonar e configurar
```bash
git clone <repo-url>
cd Formerr
cp .env.example .env
# Editar .env com suas configurações
```

### 2. Development (Docker)
```bash
# Desenvolvimento com hot reload
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up --build

# Produção local
docker-compose up --build
```

### 3. Terraform Local (opcional)
```bash
cd infrastructure/terraform/production
terraform init
terraform plan -var="do_token=YOUR_TOKEN"
terraform apply -var="do_token=YOUR_TOKEN"
```

## 📊 Monitoramento

### Grafana Access
- **Produção**: `http://<PROD_LB_IP>/grafana`
- **Staging**: `http://<STAGING_LB_IP>/grafana`
- **Usuário**: `admin`
- **Senha**: `admin123`

### Dashboards Inclusos
- CPU Usage por node/pod
- Memory Usage por node/pod  
- Pod Status e Health Checks
- Cluster Overview

## 🌐 URLs da Aplicação

Após o deploy, as aplicações estarão disponíveis em:
- **Produção**: `http://<PROD_FRONTEND_LB_IP>`
- **Staging**: `http://<STAGING_FRONTEND_LB_IP>`

## 📁 Estrutura do Projeto

```
Formerr/
├── .github/workflows/          # GitHub Actions pipelines
│   ├── deploy-infra-prod.yml   # Deploy infra produção
│   ├── deploy-infra-staging.yml# Deploy infra staging
│   ├── deploy-app-prod.yml     # Deploy app produção
│   └── deploy-app-staging.yml  # Deploy app staging
├── infrastructure/
│   ├── terraform/
│   │   ├── production/         # Terraform para produção
│   │   └── staging/           # Terraform para staging
│   └── k8s/                   # Manifests Kubernetes
├── Formerr-FastAPI/           # Backend FastAPI
├── formerr-frontend/          # Frontend Next.js
└── docker-compose*.yml       # Docker local
```

## 🔐 Secrets Management

Os secrets são gerenciados via:
1. **GitHub Secrets** para tokens de acesso
2. **Kubernetes Secrets** para dados da aplicação
3. **Base64 encoding** para valores sensíveis

⚠️ **IMPORTANTE**: Atualize os valores em `infrastructure/k8s/secrets.yaml` com seus dados reais antes do deploy.

## 🚀 Workflow de Deploy

1. **Desenvolvimento**: 
   - Trabalhe na branch `develop`
   - Push trigga deploy no ambiente de staging

2. **Produção**:
   - Merge `develop` → `main` 
   - Push trigga deploy no ambiente de produção

3. **Monitoramento**:
   - Acesse Grafana para verificar métricas
   - Monitore logs via `kubectl logs`

## 📝 Troubleshooting

### Problemas Comuns

1. **Cluster not ready**: Aguarde 5-10 min após criação do cluster
2. **Images not found**: Verifique se o container registry foi criado
3. **Secrets not found**: Certifique-se que todos os GitHub Secrets estão configurados
4. **LoadBalancer pending**: Digital Ocean pode levar alguns minutos para provisionar

### Comandos Úteis

```bash
# Verificar status dos pods
kubectl get pods -n formerr

# Ver logs da aplicação
kubectl logs -f deployment/formerr-backend -n formerr

# Acessar Grafana
kubectl port-forward svc/prometheus-grafana 3000:80 -n monitoring
```

## 🎯 Entrega

### Screenshots Necessários
- [ ] Grafana dashboard produção
- [ ] Grafana dashboard staging  
- [ ] Aplicação rodando em produção
- [ ] Aplicação rodando em staging
- [ ] GitHub Actions executando com sucesso

### Links de Entrega
- **Repositório**: `<seu-github-repo>`
- **Produção**: `http://<PROD_IP>`
- **Staging**: `http://<STAGING_IP>`
- **Grafana Prod**: `http://<PROD_IP>/grafana`
- **Grafana Staging**: `http://<STAGING_IP>/grafana`

---

**Desenvolvido por**: [Seu Nome]  
**Data**: Dezembro 2024  
**Disciplina**: Arquitetura Multi-Cloud
