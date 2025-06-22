# 🏗️ Formerr - Arquitetura Multinuvem Digital Ocean

## ✅ O que foi Criado

### 1. Infraestrutura como Código (Terraform)
- **📁 `infrastructure/digitalocean-production/`**
  - Cluster Kubernetes (3 nós s-2vcpu-4gb)
  - PostgreSQL 15 gerenciado
  - Container Registry
  - Load Balancer
  - VPC dedicada (10.0.0.0/16)
  - Prometheus + Grafana via Helm

- **📁 `infrastructure/digitalocean-staging/`**
  - Cluster Kubernetes (2 nós s-2vcpu-2gb)
  - PostgreSQL 15 gerenciado
  - Container Registry
  - Load Balancer
  - VPC dedicada (10.1.0.0/16)
  - Prometheus + Grafana via Helm

### 2. Manifests Kubernetes
- **📁 `k8s/production/`**
  - Backend deployment (3 réplicas)
  - Frontend deployment (3 réplicas)
  - Services ClusterIP
  - Ingress com SSL automático
  - Secrets para aplicação

- **📁 `k8s/staging/`**
  - Backend deployment (2 réplicas)
  - Frontend deployment (2 réplicas)
  - Services ClusterIP
  - Ingress com SSL automático
  - Secrets para aplicação

- **📁 `k8s/monitoring/`**
  - NGINX Ingress Controller
  - Cert-Manager
  - Let's Encrypt ClusterIssuers

### 3. Pipelines CI/CD (GitHub Actions)
- **🚀 `deploy-production.yml`**
  - Trigger: Push para `main`
  - Deploy completo da infraestrutura
  - Build e push das imagens
  - Deploy no Kubernetes
  - Validação de saúde

- **🧪 `deploy-staging.yml`**
  - Trigger: Push para `develop/staging` ou PR para `main`
  - Deploy completo da infraestrutura
  - Build e push das imagens
  - Deploy no Kubernetes
  - Testes de integração

- **🗑️ `destroy-infrastructure.yml`**
  - Trigger: Manual com confirmação
  - Destruição segura da infraestrutura

- **📊 `health-monitoring.yml`**
  - Trigger: A cada 15 minutos
  - Verificação de saúde dos clusters
  - Monitoramento de recursos
  - Alertas em caso de falha

### 4. Helm Charts
- **📦 `charts/formerr/`**
  - Chart principal da aplicação
  - Values para produção e staging
  - Configuração de autoscaling
  - Pod disruption budgets

### 5. Scripts de Desenvolvimento
- **🛠️ `scripts/dev-setup.sh`**
  - Verificação de dependências
  - Setup do ambiente local
  - Conexão com clusters remotos
  - Deploy da infraestrutura

## 🔧 Configuração Necessária

### Secrets do GitHub (Repository Settings > Secrets)
```
DO_PROD_TOKEN=dop_v1_xxxxxxxxxxxxxxxx
DO_STAGING_TOKEN=dop_v1_yyyyyyyyyyyy
GITHUB_CLIENT_ID=your_github_app_id
GITHUB_CLIENT_SECRET=your_github_app_secret
JWT_SECRET=your_jwt_secret_32_chars_min
SESSION_SECRET=your_session_secret_32_chars_min
```

### Tokens Digital Ocean
1. **Conta 1 (Produção)**: Gere token em cloud.digitalocean.com/account/api/tokens
2. **Conta 2 (Staging)**: Gere token em cloud.digitalocean.com/account/api/tokens

### GitHub OAuth App
1. Acesse github.com/settings/developers
2. Crie OAuth App com callbacks:
   - Produção: `https://api.formerr.example.com/auth/github/callback`
   - Staging: `https://api-staging.formerr.example.com/auth/github/callback`

## 🚀 Como Usar

### Deploy Automático
1. **Staging**: Push para `develop` ou `staging`
2. **Produção**: Push para `main`

### Deploy Manual
1. Acesse Actions no GitHub
2. Selecione workflow desejado
3. Click "Run workflow"

### Ambiente Local
```bash
# Setup inicial
./scripts/dev-setup.sh setup

# Iniciar ambiente local
./scripts/dev-setup.sh start

# Conectar ao cluster
./scripts/dev-setup.sh connect staging
./scripts/dev-setup.sh connect production
```

## 📊 Monitoramento

### Dashboards Grafana
- **CPU e Memória do cluster**
- **Status dos Pods**
- **Network I/O**
- **Métricas customizadas da aplicação**

### Endpoints
- **Produção**:
  - App: `https://formerr.example.com`
  - API: `https://api.formerr.example.com`
  - Grafana: `https://<grafana-lb-ip>`
  - Prometheus: `https://<prometheus-lb-ip>:9090`

- **Staging**:
  - App: `https://staging.formerr.example.com`
  - API: `https://api-staging.formerr.example.com`
  - Grafana: `https://<staging-grafana-lb-ip>`
  - Prometheus: `https://<staging-prometheus-lb-ip>:9090`

## ⚡ Funcionalidades Implementadas

### ✅ Infraestrutura
- [x] Clusters Kubernetes em regiões diferentes
- [x] Banco de dados PostgreSQL gerenciado
- [x] Container Registry
- [x] Load Balancers
- [x] VPCs isoladas
- [x] SSL automático com Let's Encrypt

### ✅ CI/CD
- [x] Build automático das imagens
- [x] Push para registries
- [x] Deploy automático no Kubernetes
- [x] Validação de deploy
- [x] Rollback automático em caso de falha

### ✅ Monitoramento
- [x] Prometheus para métricas
- [x] Grafana com dashboards
- [x] Alertas de saúde da aplicação
- [x] Monitoramento de recursos
- [x] Health checks automáticos

### ✅ Segurança
- [x] Secrets gerenciados
- [x] SSL/TLS automático
- [x] Network policies
- [x] Pod security contexts
- [x] Image pull secrets

## 🔄 Fluxo de Deploy

```
1. Desenvolvedor faz push para branch
2. GitHub Actions detecta mudança
3. Terraform provisiona/atualiza infraestrutura
4. Build das imagens Docker
5. Push para Container Registry
6. Deploy no Kubernetes
7. Validação de saúde
8. Notificação de sucesso/falha
```

## 📈 Próximos Passos Sugeridos

1. **DNS**: Configurar registros A para os domínios
2. **Alertas**: Integrar com Slack/PagerDuty
3. **Backup**: Configurar backup automático do DB
4. **Security**: Implementar network policies
5. **Costs**: Implementar monitoramento de custos
6. **Scaling**: Configurar HPA baseado em métricas customizadas

## 🆘 Troubleshooting

### Verificar status dos clusters
```bash
kubectl get nodes
kubectl get pods -n formerr
kubectl get pods -n monitoring
```

### Ver logs
```bash
kubectl logs -f deployment/formerr-backend -n formerr
kubectl logs -f deployment/formerr-frontend -n formerr
```

### Obter IPs dos Load Balancers
```bash
kubectl get services -n ingress-nginx
kubectl get services -n monitoring
```

---

**🎉 Arquitetura multinuvem implementada com sucesso!**

Você agora tem:
- ✅ 2 ambientes completamente isolados
- ✅ 4 pipelines distintas (staging frontend/backend + production frontend/backend)
- ✅ Monitoramento completo com Prometheus + Grafana
- ✅ Deploy automático via CI/CD
- ✅ SSL automático e load balancing
- ✅ Infraestrutura como código
