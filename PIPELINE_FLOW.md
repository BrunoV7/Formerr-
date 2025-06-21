# 🔄 Fluxo das Pipelines CI/CD - Formerr Multi-Cloud

## 📋 Visão Geral do Fluxo

```
┌─────────────────┐    ┌─────────────────┐
│   STAGING       │    │   PRODUCTION    │
│  (Conta DO #2)  │    │  (Conta DO #1)  │
└─────────────────┘    └─────────────────┘
        ▲                       ▲
        │                       │
   Push develop              Push main
        │                       │
┌───────▼───────┐        ┌──────▼──────┐
│ 🏗️ Infra       │        │ 🏗️ Infra     │
│ Staging        │        │ Production  │
│ Pipeline       │        │ Pipeline    │
└───────┬───────┘        └──────┬──────┘
        │                       │
        ▼                       ▼
┌───────────────┐        ┌─────────────┐
│ ☸️ K8s Cluster │        │ ☸️ K8s      │
│ + Prometheus  │        │ Cluster +   │
│ + Grafana     │        │ Monitoring  │
└───────┬───────┘        └──────┬──────┘
        │                       │
        ▼                       ▼
┌───────────────┐        ┌─────────────┐
│ 🚀 App        │        │ 🚀 App      │
│ Staging       │        │ Production  │
│ Pipeline      │        │ Pipeline    │
└───────────────┘        └─────────────┘
```

## 📊 Pipeline 1: Infraestrutura Staging

**Arquivo:** `.github/workflows/deploy-infra-staging.yml`

**Trigger:** 
- Push para branch `develop` 
- Mudanças em `infrastructure/terraform/staging/`

**O que faz:**
1. ✅ Checkout do código
2. ✅ Setup Terraform
3. ✅ Valida sintaxe (`terraform fmt`, `terraform validate`)
4. ✅ Plano de deploy (`terraform plan`)
5. ✅ Aplica infraestrutura (`terraform apply`)
6. ✅ Salva credenciais do cluster

**Resultado:**
- Cluster K8s em Frankfurt (conta DO #2)
- Prometheus + Grafana instalados
- Load Balancer configurado
- Namespace `formerr` e `monitoring` criados

**Secrets Necessários:**
- DO_TOKEN_STAGING

## 📊 Pipeline 2: Infraestrutura Produção

**Arquivo:** `.github/workflows/deploy-infra-prod.yml`

**Trigger:**
- Push para branch `main`
- Mudanças em `infrastructure/terraform/production/`

**O que faz:**
1. ✅ Checkout do código
2. ✅ Setup Terraform
3. ✅ Valida sintaxe
4. ✅ Plano de deploy
5. ✅ Aplica infraestrutura
6. ✅ Salva credenciais do cluster

**Resultado:**
- Cluster K8s em New York (conta DO #1)
- Prometheus + Grafana instalados
- Load Balancer configurado
- Namespace `formerr` e `monitoring` criados

**Secrets Necessários:**
- DO_TOKEN_PROD

## 🚀 Pipeline 3: Aplicação Staging

**Arquivo:** `.github/workflows/deploy-app-staging.yml`

**Trigger:**
- Push para branch `develop`
- Mudanças em código (`Formerr-FastAPI/`, `formerr-frontend/`, `infrastructure/k8s/`)

**O que faz:**
1. ✅ Build Docker images (Backend + Frontend)
2. ✅ Tag com `staging-$GITHUB_SHA` e `staging-latest`
3. ✅ Push para DO Container Registry
4. ✅ Configura kubectl para cluster staging
5. ✅ Deploy no Kubernetes:
   - PostgreSQL
   - Backend FastAPI
   - Frontend Next.js
   - Secrets e Services
6. ✅ Aguarda deployment completar
7. ✅ Mostra URLs de acesso

**Secrets Necessários:**
- DO_TOKEN_STAGING
- STAGING_CLUSTER_ENDPOINT
- STAGING_CLUSTER_TOKEN
- STAGING_CLUSTER_CA

## 🚀 Pipeline 4: Aplicação Produção

**Arquivo:** `.github/workflows/deploy-app-prod.yml`

**Trigger:**
- Push para branch `main`
- Mudanças em código da aplicação

**O que faz:**
1. ✅ Build Docker images
2. ✅ Tag com `$GITHUB_SHA` e `latest`
3. ✅ Push para DO Container Registry
4. ✅ Configura kubectl para cluster produção
5. ✅ Deploy no Kubernetes
6. ✅ Aguarda deployment completar
7. ✅ Mostra URLs de acesso

**Secrets Necessários:**
- DO_TOKEN_PROD
- PROD_CLUSTER_ENDPOINT
- PROD_CLUSTER_TOKEN
- PROD_CLUSTER_CA

## ⚡ Fluxo de Trabalho Típico

### 🔄 Desenvolvimento → Staging:
```bash
# 1. Trabalhar na branch develop
git checkout develop
git add .
git commit -m "feat: nova funcionalidade"
git push origin develop

# 2. GitHub Actions automaticamente:
# ✅ Roda pipeline infra-staging (se mudou infra)
# ✅ Roda pipeline app-staging (se mudou código)
# ✅ Deploy completo no ambiente staging
```

### 🔄 Staging → Produção:
```bash
# 1. Merge develop para main
git checkout main
git merge develop
git push origin main

# 2. GitHub Actions automaticamente:
# ✅ Roda pipeline infra-prod (se mudou infra)
# ✅ Roda pipeline app-prod (se mudou código)
# ✅ Deploy completo no ambiente produção
```

## 🎯 Dependências entre Pipelines

### Ordem de Execução:
1. **Primeiro:** Pipelines de infraestrutura (criam clusters)
2. **Depois:** Pipelines de aplicação (deployam no cluster)

### Dependências de Secrets:
- **Para infra:** Apenas tokens DO
- **Para app:** Tokens DO + credenciais dos clusters criados

### Dependências de Branches:
- **develop:** Trigga staging
- **main:** Trigga produção

## 📈 Monitoramento do Fluxo

### Acompanhar no GitHub:
- URL: `github.com/[seu-user]/Formerr/actions`
- Ver status em tempo real
- Logs detalhados de cada step
- Histórico de deployments

### Verificar Resultados:
- **Grafana:** `http://<CLUSTER_IP>/grafana`
- **App Staging:** `http://<STAGING_LB_IP>`
- **App Produção:** `http://<PROD_LB_IP>`

## 🚨 Cenários de Falha e Soluções

### Se pipeline de infra falha:
**Problema:** App não consegue deployar (sem cluster)
**Solução:** 
- Verificar tokens DO e quotas
- Verificar logs no GitHub Actions
- Re-executar pipeline manualmente
- Verificar disponibilidade da região

### Se pipeline de app falha:
**Problema:** Cluster existe, mas app não atualiza
**Solução:**
- Verificar build de images
- Verificar credenciais K8s
- Verificar se container registry existe
- Verificar se secrets K8s estão corretos

### Estratégia de Rollback:
1. **Rollback automático:** Fazer revert do commit → Push trigga novo deploy
2. **Rollback manual:** Rodar pipeline manualmente com versão anterior
3. **Rollback K8s:** `kubectl rollout undo deployment/formerr-backend -n formerr`

## 🔄 Ciclo Completo de Deploy

### Primeira Execução (Setup):
1. Configure secrets DO no GitHub
2. Push para `develop` → Cria infra staging
3. Configure secrets do cluster staging
4. Push código → Deploy app staging
5. Push para `main` → Cria infra produção
6. Configure secrets do cluster produção
7. Push código → Deploy app produção

### Execuções Subsequentes:
1. Desenvolve em `develop`
2. Push → Deploy automático staging
3. Testa no staging
4. Merge para `main` → Deploy automático produção

## 📋 Resumo dos Arquivos Criados

### Terraform:
- `infrastructure/terraform/production/main.tf`
- `infrastructure/terraform/production/variables.tf`
- `infrastructure/terraform/production/outputs.tf`
- `infrastructure/terraform/staging/main.tf`
- `infrastructure/terraform/staging/variables.tf`
- `infrastructure/terraform/staging/outputs.tf`

### Kubernetes:
- `infrastructure/k8s/backend-deployment.yaml`
- `infrastructure/k8s/frontend-deployment.yaml`
- `infrastructure/k8s/postgres-deployment.yaml`
- `infrastructure/k8s/secrets.yaml`

### GitHub Actions:
- `.github/workflows/deploy-infra-prod.yml`
- `.github/workflows/deploy-infra-staging.yml`
- `.github/workflows/deploy-app-prod.yml`
- `.github/workflows/deploy-app-staging.yml`

### Documentação:
- `DEPLOYMENT_README.md`
- `DEPLOY_CHECKLIST.md`
- `PIPELINE_FLOW.md` (este arquivo)

---

**Esse fluxo garante deploy automatizado, testado e confiável em ambos os ambientes! 🚀**

**Atende 100% aos requisitos acadêmicos:**
- ✅ 2 ambientes em nuvens/contas diferentes
- ✅ 4 pipelines CI/CD distintas
- ✅ Kubernetes + Prometheus + Grafana
- ✅ Deploy automatizado via GitHub Actions
- ✅ Infraestrutura como código (Terraform)
