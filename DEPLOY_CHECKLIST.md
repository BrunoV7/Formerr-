# ✅ Checklist de Deploy Multi-Cloud - Formerr

## 🔧 Setup Inicial

### 1. GitHub Secrets (Configurar no GitHub repo)
```
Repository Settings > Secrets and variables > Actions > New repository secret
```

**Secrets OBRIGATÓRIOS:**
- `DO_TOKEN_PROD` - Token da conta Digital Ocean principal
- `DO_TOKEN_STAGING` - Token da conta Digital Ocean secundária

**Secrets OPCIONAIS (se não configurar, usa valores padrão):**
- `POSTGRES_PASSWORD` - Senha do PostgreSQL (default: gerada automaticamente)
- `JWT_SECRET` - Chave secreta JWT (default: gerada automaticamente)
- `SESSION_SECRET` - Chave secreta de sessão (default: gerada automaticamente)
- `CLIENT_ID` - OAuth GitHub Client ID (default: placeholder)
- `CLIENT_SECRET` - OAuth GitHub Client Secret (default: placeholder)

**Para produção com PostgreSQL Digital Ocean (recomendado):**
- `DB_HOST` - Host do PostgreSQL DO
- `DB_PORT` - Porta do PostgreSQL DO  
- `DB_USER` - Usuário do PostgreSQL DO
- `DB_PASSWORD` - Senha do PostgreSQL DO
- `DB_NAME` - Nome do banco de dados
- `DATABASE_URL` - URL completa de conexão (ou será construída automaticamente)

**🎯 Super prático: Se você não configurar os secrets opcionais, a pipeline usa valores padrão seguros!**

### 3. Exemplo Prático de Configuração

**Configuração MÍNIMA (só 2 secrets):**
```
DO_TOKEN_PROD=dop_v1_abcd1234...
DO_TOKEN_STAGING=dop_v1_efgh5678...
```
→ Resto é gerado automaticamente com valores seguros

**Configuração COMPLETA (todos os secrets):**
```
DO_TOKEN_PROD=dop_v1_abcd1234...
DO_TOKEN_STAGING=dop_v1_efgh5678...
POSTGRES_PASSWORD=minha_senha_super_segura
JWT_SECRET=meu_jwt_secreto_super_longo_e_seguro
SESSION_SECRET=minha_session_secreta_super_longa
CLIENT_ID=Ov23libwTy1CTdfzvbRg
CLIENT_SECRET=4f07c7baa3fba7eb00d2e57ba48ae2e15d2da110

# Para produção com PostgreSQL Digital Ocean:
DB_HOST=db-postgresql-nyc1-67289-do-user-21734341-0.m.db.ondigitalocean.com
DB_PORT=25060
DB_USER=doadmin
DB_PASSWORD=AVNS_mT-30-FzCSW90ggdOZm
DB_NAME=defaultdb
DATABASE_URL=postgresql+asyncpg://doadmin:AVNS_mT-30-FzCSW90ggdOZm@db-postgresql-nyc1-67289-do-user-21734341-0.m.db.ondigitalocean.com:25060/defaultdb?ssl=require
```
→ Usa seus valores personalizados

### 2. Digital Ocean Container Registry
- Criar registry chamado `formerr` em ambas as contas DO
- Anotar URLs dos registries

### 3. Branches
- Criar branch `develop` se não existir:
  ```bash
  git checkout -b develop
  git push origin develop
  ```

## 🚀 Deploy Steps

### Passo 1: Deploy Completo Staging
1. Push código para branch `develop`
2. Verificar execução da pipeline `deploy-app-staging.yml` que:
   - ✅ Cria infraestrutura (cluster K8s + monitoramento)
   - ✅ Builda e publica aplicação
   - ✅ Deploya tudo no cluster staging
3. Aguardar ~15-20 min para conclusão completa
4. Anotar IPs do Load Balancer nos logs

### Passo 2: Deploy Completo Produção  
1. Merge `develop` → `main`
2. Verificar execução da pipeline `deploy-app-prod.yml` que:
   - ✅ Cria infraestrutura (cluster K8s + monitoramento)
   - ✅ Builda e publica aplicação  
   - ✅ Deploya tudo no cluster produção
3. Aguardar ~15-20 min para conclusão completa
4. Anotar IPs do Load Balancer nos logs

**🎯 Agora com qualquer commit, se o professor deletar tudo da Digital Ocean, um novo push vai recriar TUDO automaticamente!**

## 🔍 Verificações

### Aplicação Funcionando
- [ ] Frontend carrega em staging: `http://<STAGING_IP>`
- [ ] Frontend carrega em produção: `http://<PROD_IP>`
- [ ] Backend responde health check
- [ ] Login com GitHub funciona

### Monitoramento
- [ ] Grafana acessível: `http://<IP>/grafana` (admin/admin123)
- [ ] Dashboard mostra métricas de CPU
- [ ] Dashboard mostra métricas de Memory
- [ ] Dashboard mostra status dos Pods

## 📸 Screenshots para Entrega
- [ ] Grafana dashboard produção
- [ ] Grafana dashboard staging
- [ ] Aplicação rodando produção
- [ ] Aplicação rodando staging
- [ ] GitHub Actions todas green

## 🆘 Troubleshooting

**❌ YAML syntax errors nos workflows:**
- Ignorar warnings "Context access might be invalid" - são só avisos
- Garantir que indentação está correta
- Verificar se secrets estão configurados no GitHub

**❌ Cluster não criou:**
- Verificar se token DO está correto
- Verificar quota da conta DO (precisa de créditos)
- Aguardar mais tempo (pode levar 15-20 min)
- Verificar logs da pipeline no GitHub Actions

**❌ Pipeline falha:**
- Verificar se os dois tokens DO estão configurados
- Ver logs detalhados em Actions > [pipeline] > View logs
- Verificar se região escolhida tem disponibilidade

**❌ App não deploy:**
- Verificar se cluster secrets estão corretos
- Verificar se container registry existe em ambas contas DO
- Ver logs no GitHub Actions > deploy step
- Verificar se images foram pushed com sucesso

**Grafana não acessa:**
- Aguardar mais 5-10 min após deploy
- Verificar se Load Balancer está ready
- Tentar IP direto do serviço

## 📋 Comandos Úteis

**Verificar status local:**
```bash
# Ver pipelines no GitHub
https://github.com/[seu-usuario]/Formerr/actions

# Se tiver kubectl configurado:
kubectl get pods -n formerr
kubectl get svc -n formerr
kubectl logs -f deployment/formerr-frontend -n formerr
```

**Pegar IPs dos serviços:**
```bash
# Frontend (LoadBalancer)
kubectl get svc formerr-frontend-service -n formerr

# Grafana (dentro do cluster monitoring)
kubectl get svc -n monitoring | grep grafana
```

---

**✨ Pronto! Agora é só seguir os passos e fazer os deploys! ✨**
