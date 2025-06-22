# 🗄️ Configuração de Banco de Dados

## 📊 Visão Geral

A arquitetura utiliza estratégias diferentes para cada ambiente:

- **🏭 Produção**: Banco PostgreSQL gerenciado da Digital Ocean (externo)
- **🧪 Staging**: PostgreSQL dentro do cluster Kubernetes (interno)

## 🏭 Ambiente de Produção

### Configuração Atual
Você já possui um banco PostgreSQL gerenciado na Digital Ocean com os seguintes secrets configurados no GitHub:

```
DATABASE_URL    # URL completa de conexão
DB_HOST        # Host do banco
DB_NAME        # Nome do banco
DB_PASSWORD    # Senha do usuário
DB_PORT        # Porta (5432)
DB_USER        # Usuário do banco
```

### Como funciona
1. O Terraform **NÃO** cria novos recursos de banco
2. As variáveis do banco são passadas via secrets do GitHub
3. O secret `formerr-db-secret` é criado no Kubernetes com os valores dos secrets
4. A aplicação consome esses secrets via variáveis de ambiente

### 🌐 Acesso de Rede
O banco gerenciado precisa permitir conexões do cluster Kubernetes. Isso é configurado automaticamente durante o deployment:

1. O pipeline obtém o VPC ID do cluster via Terraform output
2. Adiciona o VPC às regras de firewall do banco (`db-postgresql-nyc1-67289`)
3. Verifica se a regra já existe para evitar duplicação

**Configuração manual** (se necessário):
```bash
# Obter VPC ID do cluster
cd infrastructure/digitalocean-production
CLUSTER_VPC_ID=$(terraform output -raw vpc_id)

# Adicionar VPC ao firewall do banco
doctl databases firewalls append db-postgresql-nyc1-67289 \
  --rule type:trusted_source,value:$CLUSTER_VPC_ID \
  --wait
```

### Exemplo de conexão
```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: formerr-db-secret
      key: DATABASE_URL
```

## 🧪 Ambiente de Staging

### Configuração
PostgreSQL executando dentro do cluster Kubernetes:

- **Image**: `postgres:15-alpine`
- **Storage**: 20Gi com `do-block-storage`
- **Resources**: 256Mi RAM, 250m CPU (request)
- **Database**: `formerr_db`
- **User**: `formerr_user`
- **Senhas**: Geradas automaticamente pelo CI/CD

### Como funciona
1. O pipeline gera senhas aleatórias para PostgreSQL
2. Cria o secret `postgres-secret` com as senhas
3. Aplica os manifests do PostgreSQL
4. Script de inicialização cria o usuário `formerr_user`
5. Cria o secret `formerr-db-secret` para a aplicação

### Estrutura dos Secrets

#### postgres-secret (interno)
```yaml
data:
  POSTGRES_PASSWORD: <senha_do_postgres>
  FORMERR_USER_PASSWORD: <senha_do_formerr_user>
```

#### formerr-db-secret (aplicação)
```yaml
data:
  DATABASE_URL: postgresql://formerr_user:password@postgresql.formerr.svc.cluster.local:5432/formerr_db
  DB_HOST: postgresql.formerr.svc.cluster.local
  DB_PORT: "5432"
  DB_NAME: formerr_db
  DB_USER: formerr_user
  DB_PASSWORD: <senha_gerada>
```

## 🔧 Comandos Úteis

### Produção (Digital Ocean Gerenciado)
```bash
# Verificar secret do banco
kubectl get secret formerr-db-secret -n formerr -o yaml

# Testar conexão (de dentro de um pod)
kubectl exec -it deployment/formerr-backend -n formerr -- psql $DATABASE_URL -c "SELECT version();"
```

### Staging (In-Cluster)
```bash
# Verificar status do PostgreSQL
kubectl get pods -n formerr -l app=postgresql

# Ver logs do PostgreSQL
kubectl logs -f deployment/postgresql -n formerr

# Conectar diretamente ao PostgreSQL
kubectl exec -it deployment/postgresql -n formerr -- psql -U postgres -d formerr_db

# Verificar usuário da aplicação
kubectl exec -it deployment/postgresql -n formerr -- psql -U postgres -d formerr_db -c "\du"

# Testar conexão da aplicação
kubectl exec -it deployment/formerr-backend -n formerr -- psql $DATABASE_URL -c "SELECT current_user;"
```

### Backup e Restore (Staging)
```bash
# Backup
kubectl exec deployment/postgresql -n formerr -- pg_dump -U postgres formerr_db > backup.sql

# Restore
kubectl exec -i deployment/postgresql -n formerr -- psql -U postgres formerr_db < backup.sql
```

## 🔐 Segurança

### Produção
- ✅ SSL/TLS obrigatório (`sslmode=require`)
- ✅ Banco isolado na rede privada da Digital Ocean
- ✅ Backups automáticos gerenciados
- ✅ Firewall rules aplicadas

### Staging
- ✅ Senhas geradas automaticamente (32 caracteres)
- ✅ Secrets do Kubernetes
- ✅ Network policies (se habilitadas)
- ✅ Storage persistente criptografado

## 🚀 Migrations e Inicialização

### Produção
Como você já tem o banco configurado, as migrations podem ser executadas:

```bash
# Via kubectl (dentro do pod do backend)
kubectl exec -it deployment/formerr-backend -n formerr -- python manage.py migrate

# Ou via pipeline (adicionar step)
```

### Staging
O banco é limpo a cada deploy. Para persistir dados:

1. **Migrations automáticas**: Adicionar step no pipeline
2. **Dados de teste**: Script de seed
3. **Backup/Restore**: Entre deploys se necessário

## 🔄 Pipeline Integration

### Produção
```yaml
- name: Terraform Apply
  run: |
    terraform apply -auto-approve \
      -var="database_url=${{ secrets.DATABASE_URL }}" \
      -var="db_host=${{ secrets.DB_HOST }}" \
      # ... outros secrets
```

### Staging
```yaml
- name: Deploy PostgreSQL
  run: |
    # Gera senhas aleatórias
    POSTGRES_PASSWORD=$(openssl rand -base64 32)
    FORMERR_USER_PASSWORD=$(openssl rand -base64 32)
    
    # Cria secrets e aplica manifests
    kubectl apply -f k8s/staging/postgresql.yaml
```

## 📈 Monitoramento

### Métricas Disponíveis
- **Connection count**
- **Query performance**
- **Storage usage**
- **Backup status** (produção)

### Logs
```bash
# Produção: Via Digital Ocean Dashboard
# Staging: Via kubectl
kubectl logs -f deployment/postgresql -n formerr
```

## 🔧 Troubleshooting

### Problemas Comuns

#### Produção
1. **Connection timeout**: Verificar firewall/VPC rules
2. **SSL errors**: Verificar certificados
3. **Permission denied**: Verificar secrets no GitHub

#### Staging
1. **Pod não inicia**: Verificar storage class
2. **Connection refused**: Aguardar pod estar Ready
3. **User não existe**: Verificar logs de inicialização

### Logs de Debug
```bash
# Verificar se secrets existem
kubectl get secrets -n formerr

# Verificar valores dos secrets (cuidado em produção!)
kubectl get secret formerr-db-secret -n formerr -o jsonpath='{.data}' | base64 -d

# Testar conectividade
kubectl exec -it deployment/formerr-backend -n formerr -- nc -zv postgresql.formerr.svc.cluster.local 5432
```

---

Esta configuração garante que:
- ✅ **Produção** usa seu banco Digital Ocean existente
- ✅ **Staging** tem banco isolado e descartável
- ✅ **Secrets** são gerenciados de forma segura
- ✅ **Pipeline** automatiza toda a configuração
