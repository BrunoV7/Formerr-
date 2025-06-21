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
│ 🎯 Orquestradora │        │ 🎯 Orquestradora │
│ Pipeline       │        │ Pipeline    │
└───────┬───────┘        └──────┬──────┘
        │                       │
        ▼                       ▼
┌───────────────┐        ┌─────────────┐
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
└───────┬───────┘        └──────┬──────┘
        │                       │
        ▼                       ▼
┌───────────────┐        ┌─────────────┐
│ 🔍 Validação  │        │ 🔍 Validação │
│ Observabilidade│        │ Observabilidade│
│ Pipeline      │        │ Pipeline    │
└───────────────┘        └─────────────┘
```

## 🎯 Pipeline 1: Orquestradora

**Arquivo:** `.github/workflows/orchestrator.yml`

**Trigger:** 
- Push para branch `main` ou `develop`
- Workflow dispatch manual

**O que faz:**
1. ✅ Detecta contexto do commit (infra vs app)
2. ✅ Verifica se infraestrutura existe via API DO
3. ✅ Decide quais pipelines executar
4. ✅ Chama pipelines específicas via `workflow_call`
5. ✅ Gera relatório final consolidado

**Lógica de Decisão:**
- **Se mudanças em infra:** Deploy infraestrutura
- **Se mudanças em app:** Deploy aplicação
- **Se infra não existe:** Deploy infra + app
- **Se apenas app mudou:** Apenas deploy app

**Resultado:**
- Execução inteligente das pipelines
- Idempotência e eficiência
- Relatórios consolidados

## 🏗️ Pipeline 2: Infraestrutura - Produção

**Arquivo:** `.github/workflows/infrastructure-production.yml`

**Trigger:**
- Chamada pela orquestradora
- Push para `main` com mudanças em `infrastructure/terraform/production/`
- Workflow dispatch manual

**O que faz:**
1. ✅ Validação e lint Terraform
2. ✅ Escaneamento de segurança (TFsec)
3. ✅ Cache inteligente
4. ✅ Deploy cluster Kubernetes
5. ✅ Instalação Prometheus + Grafana
6. ✅ Escaneamento vulnerabilidades (Trivy)
7. ✅ Relatórios detalhados

**Resultado:**
- Cluster K8s em New York (conta DO #1)
- Prometheus + Grafana instalados
- Monitoramento completo configurado
- Credenciais salvas como artifacts

**Secrets Necessários:**
- `DO_TOKEN_PROD`

## 🚀 Pipeline 3: Deploy - Produção

**Arquivo:** `.github/workflows/deploy-production.yml`

**Trigger:**
- Chamada pela orquestradora
- Push para `main` com mudanças em código da aplicação
- Workflow dispatch manual

**O que faz:**
1. ✅ Build otimizado com Docker Buildx
2. ✅ Cache de layers Docker
3. ✅ Push para DO Container Registry
4. ✅ Escaneamento vulnerabilidades nas imagens
5. ✅ Deploy no Kubernetes
6. ✅ Validação pós-deploy
7. ✅ Testes de performance

**Resultado:**
- Imagens Docker buildadas e pushadas
- Aplicação deployada no cluster
- Validação completa executada
- URLs de acesso disponíveis

**Secrets Necessários:**
- `DO_TOKEN_PROD`
- `DB_PASSWORD`
- `JWT_SECRET`
- `SESSION_SECRET`
- `CLIENT_ID`
- `CLIENT_SECRET`

## 🏗️ Pipeline 4: Infraestrutura - Staging

**Arquivo:** `.github/workflows/infrastructure-staging.yml`

**Trigger:**
- Chamada pela orquestradora
- Push para `develop` com mudanças em `infrastructure/terraform/staging/`
- Workflow dispatch manual

**O que faz:**
1. ✅ Mesmas funcionalidades da produção
2. ✅ Configurações específicas para staging
3. ✅ Banco de dados isolado
4. ✅ Monitoramento com retenção reduzida

**Resultado:**
- Cluster K8s em Frankfurt (conta DO #2)
- Prometheus + Grafana instalados
- Configurações otimizadas para testes
- Credenciais salvas como artifacts

**Secrets Necessários:**
- `DO_TOKEN_STAGING`

## 🚀 Pipeline 5: Deploy - Staging

**Arquivo:** `.github/workflows/deploy-staging.yml`

**Trigger:**
- Chamada pela orquestradora
- Push para `develop` com mudanças em código da aplicação
- Workflow dispatch manual

**O que faz:**
1. ✅ Build isolado com tags específicas
2. ✅ Cache otimizado para staging
3. ✅ Push para DO Container Registry
4. ✅ Deploy no Kubernetes
5. ✅ Testes básicos de API
6. ✅ Validação específica para staging

**Resultado:**
- Imagens Docker buildadas com tags staging
- Aplicação deployada no cluster staging
- Testes básicos executados
- URLs de acesso disponíveis

**Secrets Necessários:**
- `DO_TOKEN_STAGING`
- Secrets específicos para staging (opcional)

## 🔍 Pipeline 6: Validação e Observabilidade

**Arquivo:** `.github/workflows/validation-observability.yml`

**Trigger:**
- Chamada pela orquestradora após deploy
- Workflow dispatch manual
- Workflow run (após deploy)

**O que faz:**
1. ✅ Health checks de endpoints
2. ✅ Validação de métricas Prometheus
3. ✅ Verificação de dashboards Grafana
4. ✅ Testes de performance
5. ✅ Relatórios consolidados

**Resultado:**
- Validação completa da aplicação
- Verificação do monitoramento
- Relatórios de observabilidade
- Alertas em caso de falha

## ⚡ Fluxo de Trabalho Típico

### 🔄 Desenvolvimento → Staging:
```bash
# 1. Trabalhar na branch develop
git checkout develop
git add .
git commit -m "feat: nova funcionalidade"
git push origin develop

# 2. GitHub Actions automaticamente:
# ✅ Orquestradora detecta mudanças
# ✅ Deploy infraestrutura (se necessário)
# ✅ Build e push das imagens
# ✅ Deploy no Kubernetes
# ✅ Validação e observabilidade
```

### 🔄 Staging → Produção:
```bash
# 1. Merge develop para main
git checkout main
git merge develop
git push origin main

# 2. GitHub Actions automaticamente:
# ✅ Orquestradora detecta mudanças
# ✅ Deploy infraestrutura (se necessário)
# ✅ Build e push das imagens
# ✅ Deploy no Kubernetes
# ✅ Validação e observabilidade
```

## 🎯 Dependências entre Pipelines

### Ordem de Execução:
1. **Orquestradora:** Detecta contexto e decide
2. **Infraestrutura:** Cria/atualiza clusters
3. **Aplicação:** Deploy da aplicação
4. **Validação:** Verifica funcionamento

### Dependências de Secrets:
- **Para infra:** Apenas tokens DO
- **Para app:** Tokens DO + credenciais dos clusters
- **Para validação:** Credenciais dos clusters

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

### Se orquestradora falha:
**Problema:** Nenhuma pipeline executa
**Solução:** 
- Verificar logs da orquestradora
- Verificar configuração de secrets
- Executar pipeline manualmente

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

### Se validação falha:
**Problema:** App deployada mas não funcionando
**Solução:**
- Verificar health checks
- Verificar configuração de serviços
- Verificar logs dos pods
- Verificar conectividade de rede

### Estratégia de Rollback:
1. **Rollback automático:** Fazer revert do commit → Push trigga novo deploy
2. **Rollback manual:** Rodar pipeline manualmente com versão anterior
3. **Rollback K8s:** `kubectl rollout undo deployment/formerr-backend -n formerr`

## 🔄 Ciclo Completo de Deploy

### Primeira Execução (Setup):
1. Configure secrets DO no GitHub
2. Push para `develop` → Orquestradora detecta necessidade de infra
3. Pipeline de infra staging cria cluster
4. Pipeline de app staging faz deploy
5. Pipeline de validação verifica funcionamento
6. Push para `main` → Orquestradora detecta necessidade de infra
7. Pipeline de infra produção cria cluster
8. Pipeline de app produção faz deploy
9. Pipeline de validação verifica funcionamento

### Execuções Subsequentes:
1. Desenvolve em `develop`
2. Push → Orquestradora detecta mudanças de app
3. Pipeline de app staging faz deploy
4. Pipeline de validação verifica funcionamento
5. Merge para `main` → Orquestradora detecta mudanças de app
6. Pipeline de app produção faz deploy
7. Pipeline de validação verifica funcionamento

## 📋 Resumo dos Arquivos Criados

### GitHub Actions:
- `.github/workflows/orchestrator.yml`
- `.github/workflows/infrastructure-production.yml`
- `.github/workflows/deploy-production.yml`
- `.github/workflows/infrastructure-staging.yml`
- `.github/workflows/deploy-staging.yml`
- `.github/workflows/validation-observability.yml`

### Documentação:
- `CI_CD_ARCHITECTURE.md`
- `GITHUB_SECRETS_TEMPLATE.md`

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
- `infrastructure/k8s/secrets-template.yaml`

## 🎉 Benefícios da Nova Arquitetura

### Para Desenvolvedores:
- ✅ Deploy automático e seguro
- ✅ Feedback rápido e detalhado
- ✅ Ambiente de teste isolado
- ✅ Rollback fácil e automático

### Para Operações:
- ✅ Infraestrutura como código
- ✅ Monitoramento completo
- ✅ Alertas automáticos
- ✅ Escalabilidade garantida

### Para Negócio:
- ✅ Entrega contínua
- ✅ Qualidade garantida
- ✅ Rastreabilidade completa
- ✅ Redução de downtime

## 🔐 Segurança Implementada

- ✅ Credenciais em GitHub Secrets
- ✅ Escaneamento de vulnerabilidades
- ✅ Validação de segurança Terraform
- ✅ Imagens Docker escaneadas
- ✅ Secrets Kubernetes gerenciados
- ✅ Tokens separados por ambiente

## 📊 Observabilidade

- ✅ Prometheus para métricas
- ✅ Grafana para dashboards
- ✅ Health checks automáticos
- ✅ Testes de performance
- ✅ Relatórios consolidados
- ✅ Alertas configuráveis

---

**🎯 Resultado:** Sistema de CI/CD completo, seguro e automatizado que garante robustez, previsibilidade e rastreabilidade em todas as etapas, alinhado com as melhores práticas modernas de DevOps e GitOps.
