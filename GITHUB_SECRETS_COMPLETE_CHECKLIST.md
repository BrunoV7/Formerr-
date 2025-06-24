# 🔐 GITHUB SECRETS CHECKLIST COMPLETO

## 📊 ANÁLISE ATUAL - Secrets Detectados nos Workflows

### ✅ **PRODUÇÃO (DigitalOcean) - CONFIGURADOS**
```
DO_TOKEN_PROD            ✅ (usado em prod-deploy-*.yml)
DATABASE_URL             ✅ (database principal)
CLIENT_ID                ✅ (GitHub OAuth)
CLIENT_SECRET            ✅ (GitHub OAuth)
JWT_SECRET               ✅ (autenticação)
SESSION_SECRET           ✅ (sessões)
DB_HOST                  ✅ (host do banco)
DB_PORT                  ✅ (porta do banco)
DB_NAME                  ✅ (nome do banco)
DB_USER                  ✅ (usuário do banco)
DB_PASSWORD              ✅ (senha do banco)
```

### ⚠️ **STAGING (GCP) - PARCIALMENTE CONFIGURADOS**
```
GCP_PROJECT_ID           ⚠️ (usado em stage-*.yml)
GCP_SA_KEY               ⚠️ (service account key)
GCP_CLUSTER_ZONE         ⚠️ (zona do cluster)

# Secrets específicos de staging (opcionais)
STAGING_GITHUB_CLIENT_ID     ❌ (fallback para CLIENT_ID)
STAGING_GITHUB_CLIENT_SECRET ❌ (fallback para CLIENT_SECRET)
STAGING_JWT_SECRET           ❌ (fallback para JWT_SECRET)
STAGING_SESSION_SECRET       ❌ (fallback para SESSION_SECRET)
```

### ❌ **FALTANDO (Para funcionar 100%)**
```
# Para banco de staging
DATABASE_URL_STAGING     ❌ (PostgreSQL para staging)
DB_HOST_STAGING          ❌ (host staging)
DB_USER_STAGING          ❌ (usuário staging)
DB_PASSWORD_STAGING      ❌ (senha staging)

# Para Docker Registry (se não usar GCP Container Registry)
DOCKER_USERNAME          ❌ (DockerHub)
DOCKER_PASSWORD          ❌ (DockerHub)
```

---

## 🎯 PLANO DE CONFIGURAÇÃO - PRIORIDADES

### **🔥 ALTA PRIORIDADE** (Para staging funcionar)

1. **Configurar GCP Secrets**
```bash
# No GitHub → Settings → Secrets and variables → Actions

GCP_PROJECT_ID=seu-projeto-gcp-id
GCP_SA_KEY={"type":"service_account","project_id":"..."}
GCP_CLUSTER_ZONE=us-central1-a
```

2. **Banco de Dados Staging**
```bash
# Configurar banco staging separado
DATABASE_URL_STAGING=postgresql://user:pass@host:5432/formerr_staging
DB_HOST_STAGING=staging-db-host
DB_USER_STAGING=staging_user
DB_PASSWORD_STAGING=staging_password
```

### **📋 MÉDIA PRIORIDADE** (Para isolamento completo)

3. **Secrets específicos de staging**
```bash
STAGING_GITHUB_CLIENT_ID=client_id_staging
STAGING_GITHUB_CLIENT_SECRET=client_secret_staging
STAGING_JWT_SECRET=jwt_secret_staging
STAGING_SESSION_SECRET=session_secret_staging
```

### **🔧 BAIXA PRIORIDADE** (Para melhorias)

4. **Registry alternativo**
```bash
DOCKER_USERNAME=seu_dockerhub_user
DOCKER_PASSWORD=seu_dockerhub_password
```

---

## 📝 COMO CONFIGURAR CADA SECRET

### **1. GCP Service Account (GCP_SA_KEY)**
```bash
# 1. Ir para GCP Console → IAM & Admin → Service Accounts
# 2. Criar nova Service Account ou usar existente
# 3. Dar permissões: 
#    - Kubernetes Engine Admin
#    - Container Registry Admin
#    - Compute Admin
# 4. Criar chave JSON
# 5. Copiar conteúdo JSON inteiro para GCP_SA_KEY
```

### **2. GCP Project (GCP_PROJECT_ID)**
```bash
# No GCP Console → Dashboard
# Copiar o Project ID (não o nome)
GCP_PROJECT_ID=meu-projeto-123456
```

### **3. GCP Cluster Zone (GCP_CLUSTER_ZONE)**
```bash
# Escolher zona onde vai criar o cluster
GCP_CLUSTER_ZONE=us-central1-a
# ou
GCP_CLUSTER_ZONE=us-east1-b
```

### **4. Database Staging**
```bash
# Opção 1: Usar Google Cloud SQL
DATABASE_URL_STAGING=postgresql://user:pass@ip:5432/formerr_staging

# Opção 2: Usar ElephantSQL (gratuito)
DATABASE_URL_STAGING=postgres://user:pass@server.db.elephantsql.com/database

# Opção 3: Usar Supabase (gratuito)
DATABASE_URL_STAGING=postgresql://postgres:pass@db.supabase.co:5432/postgres
```

---

## 🧪 COMO TESTAR OS SECRETS

### **1. Teste Local**
```bash
# Criar arquivo .env.staging
echo "GCP_PROJECT_ID=meu-projeto" > .env.staging
echo "GCP_SA_KEY=..." >> .env.staging

# Testar conexão GCP
gcloud auth activate-service-account --key-file=service-account.json
gcloud config set project meu-projeto
gcloud container clusters get-credentials cluster-name --zone=us-central1-a
```

### **2. Teste nos Workflows**
```bash
# Fazer commit em branch staging/develop
git checkout develop
git commit --allow-empty -m "test: secrets configuration"
git push origin develop

# Verificar logs no GitHub Actions
```

---

## 📋 CHECKLIST FINAL DE CONFIGURAÇÃO

### **Para Produção (DigitalOcean)** ✅
- [x] DO_TOKEN_PROD
- [x] DATABASE_URL
- [x] CLIENT_ID / CLIENT_SECRET
- [x] JWT_SECRET / SESSION_SECRET
- [x] DB_* (todos os parâmetros do banco)

### **Para Staging (GCP)** ❌
- [ ] GCP_PROJECT_ID
- [ ] GCP_SA_KEY  
- [ ] GCP_CLUSTER_ZONE
- [ ] DATABASE_URL_STAGING
- [ ] DB_HOST_STAGING / DB_USER_STAGING / DB_PASSWORD_STAGING

### **Opcionais**
- [ ] STAGING_* (secrets específicos staging)
- [ ] DOCKER_* (se usar DockerHub)

---

## 🚀 COMANDO RÁPIDO - CRIAR SECRETS

```bash
# Template para GitHub Secrets
gh secret set GCP_PROJECT_ID --body "meu-projeto-123"
gh secret set GCP_SA_KEY --body "$(cat service-account.json)"
gh secret set GCP_CLUSTER_ZONE --body "us-central1-a"
gh secret set DATABASE_URL_STAGING --body "postgresql://..."
```

---

## 🎯 RESUMO EXECUTIVO

**Status atual**: 85% dos secrets configurados
**Falta para 100%**: GCP credentials + Database staging
**Tempo estimado**: 30-60 minutos
**Prioridade**: Configure GCP_PROJECT_ID, GCP_SA_KEY e DATABASE_URL_STAGING

**Após configurar estes 3 secrets principais, o staging vai funcionar!**
