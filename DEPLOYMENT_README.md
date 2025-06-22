# Formerr - Multi-Cloud Deployment Guide

Este projeto implementa uma arquitetura multinuvem para a aplicação Formerr, utilizando **Digital Ocean** para ambos os ambientes (Produção e Staging) em regiões diferentes.

## 🏗️ Arquitetura

### Ambiente de Produção (Digital Ocean - NYC1)
- **Cluster Kubernetes**: 3 nós (s-2vcpu-4gb)
- **Banco de dados**: PostgreSQL 15 (db-s-1vcpu-1gb)
- **Container Registry**: formerr-production
- **Monitoramento**: Prometheus + Grafana

### Ambiente de Staging (Digital Ocean - AMS3)
- **Cluster Kubernetes**: 2 nós (s-2vcpu-2gb)
- **Banco de dados**: PostgreSQL 15 (db-s-1vcpu-1gb)
- **Container Registry**: formerr-staging
- **Monitoramento**: Prometheus + Grafana

## 🚀 Configuração Inicial

### 1. Configurar Secrets no GitHub

Acesse o repositório no GitHub e vá em **Settings > Secrets and variables > Actions** e adicione os seguintes secrets:

#### Tokens de Acesso Digital Ocean
```
DO_TOKEN_PROD=dop_v1_xxxxxxxxxxxxxxxxxxxx
DO_STAGING_TOKEN=dop_v1_yyyyyyyyyyyyyyyyyyyy
```

#### Configurações OAuth GitHub
```
GITHUB_CLIENT_ID=your_GITHUB_CLIENT_ID
GITHUB_CLIENT_SECRET=your_github_client_secret
```

#### Secrets de Segurança
```
JWT_SECRET=your_super_secret_jwt_key_here_min_32_chars
SESSION_SECRET=your_super_secret_session_key_here_min_32_chars
```

### 2. Obter Tokens da Digital Ocean

1. Acesse o [Digital Ocean Control Panel](https://cloud.digitalocean.com/)
2. Vá em **API > Tokens/Keys**
3. Gere um novo **Personal Access Token** para cada conta
4. Copie os tokens e adicione como secrets no GitHub

### 3. Configurar GitHub OAuth App

1. Acesse [GitHub Developer Settings](https://github.com/settings/developers)
2. Crie uma nova **OAuth App**
3. Configure as URLs:
   - **Authorization callback URL (Produção)**: `https://api.formerr.example.com/auth/github/callback`
   - **Authorization callback URL (Staging)**: `https://api-staging.formerr.example.com/auth/github/callback`

## 🔧 Deploy

### Deploy Automático

#### Staging
- **Push para branch `develop` ou `staging`**: Deploy automático para staging
- **Pull Request para `main`**: Deploy de teste no staging

#### Produção
- **Push para branch `main`**: Deploy automático para produção

### Deploy Manual

Você também pode executar os deploys manualmente:

1. Vá para **Actions** no GitHub
2. Selecione o workflow desejado:
   - `Deploy to Staging (DigitalOcean)`
   - `Deploy to Production (DigitalOcean)`
3. Clique em **Run workflow**

## 📊 Monitoramento

### Grafana Dashboards

Após o deploy, você terá acesso aos dashboards do Grafana:

- **Produção**: `https://<grafana-lb-ip>`
- **Staging**: `https://<staging-grafana-lb-ip>`

**Credenciais padrão:**
- Username: `admin`
- Password: `admin`

### Dashboards Incluídos

1. **Kubernetes Cluster Monitoring** (Grafana ID: 7249)
   - CPU e Memória do cluster
   - Status dos nós
   - Network I/O

2. **Kubernetes Pod Monitoring** (Grafana ID: 6417)
   - Status dos pods
   - Resource usage por pod
   - Restart count

3. **Node Exporter** (Grafana ID: 1860)
   - Métricas detalhadas dos nós
   - Disk I/O
   - Network metrics

### Prometheus Metrics

- **Produção**: `https://<prometheus-lb-ip>:9090`
- **Staging**: `https://<staging-prometheus-lb-ip>:9090`

## 🌐 Endpoints da Aplicação

### Produção
- **Frontend**: `https://formerr.example.com`
- **Backend API**: `https://api.formerr.example.com`

### Staging
- **Frontend**: `https://staging.formerr.example.com`
- **Backend API**: `https://api-staging.formerr.example.com`

> **Nota**: Substitua `formerr.example.com` pelo seu domínio real e configure os DNS A records para apontar para os IPs dos Load Balancers.

## 🗄️ Estrutura do Projeto

```
├── .github/workflows/          # GitHub Actions CI/CD
│   ├── deploy-production.yml   # Pipeline de produção
│   ├── deploy-staging.yml      # Pipeline de staging
│   └── destroy-infrastructure.yml # Pipeline de destruição
├── infrastructure/             # Terraform Infrastructure as Code
│   ├── digitalocean-production/
│   └── digitalocean-staging/
├── k8s/                       # Kubernetes manifests
│   ├── production/            # Manifests de produção
│   ├── staging/               # Manifests de staging
│   └── monitoring/            # Ingress e Cert-Manager
├── Formerr-FastAPI/          # Backend application
└── formerr-frontend/         # Frontend application
```

## 🔍 Comandos Úteis

### Conectar ao Cluster Kubernetes

```bash
# Produção
doctl kubernetes cluster kubeconfig save formerr-production-cluster

# Staging
doctl kubernetes cluster kubeconfig save formerr-staging-cluster
```

### Verificar Status dos Pods

```bash
kubectl get pods -n formerr
kubectl get pods -n monitoring
```

### Ver Logs dos Pods

```bash
# Backend
kubectl logs -f deployment/formerr-backend -n formerr

# Frontend
kubectl logs -f deployment/formerr-frontend -n formerr
```

### Obter IPs dos Load Balancers

```bash
# Ingress Controller
kubectl get service ingress-nginx-controller -n ingress-nginx

# Grafana
kubectl get service prometheus-grafana -n monitoring

# Prometheus
kubectl get service prometheus-kube-prometheus-prometheus -n monitoring
```

## 🚨 Troubleshooting

### Pipeline Failing

1. **Verifique os secrets**: Certifique-se de que todos os secrets estão configurados corretamente
2. **Tokens expirados**: Verifique se os tokens da Digital Ocean ainda são válidos
3. **Quotas**: Verifique se você tem quota suficiente na Digital Ocean

### Aplicação não Acessível

1. **DNS**: Verifique se os DNS estão apontando para os IPs corretos
2. **Certificados SSL**: Aguarde alguns minutos para o Let's Encrypt gerar os certificados
3. **Ingress**: Verifique se o Ingress Controller está funcionando

### Pods não Startando

1. **Secrets**: Verifique se os secrets da aplicação estão criados
2. **Images**: Certifique-se de que as imagens foram enviadas para o registry
3. **Resources**: Verifique se há recursos suficientes no cluster

## 🗑️ Destruição da Infraestrutura

Para destruir a infraestrutura de um ambiente:

1. Vá para **Actions** no GitHub
2. Selecione **Destroy Infrastructure**
3. Choose the environment (staging/production)
4. Type "DESTROY" to confirm
5. Run workflow

> ⚠️ **ATENÇÃO**: Esta ação é irreversível e irá destruir todos os recursos do ambiente selecionado.

## 📝 Próximos Passos

1. **Configure DNS**: Aponte seus domínios para os IPs dos Load Balancers
2. **Customize Dashboards**: Adicione métricas específicas da sua aplicação
3. **Alertas**: Configure alertas no Prometheus/Grafana
4. **Backup**: Configure backup automático do banco de dados
5. **Security**: Configure network policies e pod security standards

## 🤝 Contribuindo

1. Faça alterações em uma branch separada
2. Teste no ambiente de staging
3. Crie um Pull Request para main
4. Após aprovação, o deploy para produção será automático

---

## 📧 Suporte

Para dúvidas ou problemas, abra uma issue no repositório ou entre em contato com a equipe de DevOps.
