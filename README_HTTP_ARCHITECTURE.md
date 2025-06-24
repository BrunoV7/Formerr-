# 🚀 Formerr - Arquitetura HTTP Simplificada

## 📋 **Visão Geral**

O projeto Formerr foi migrado para uma **arquitetura HTTP simplificada**, removendo toda a complexidade de SSL/HTTPS para garantir deploys mais rápidos e confiáveis.

## 🏗️ **Arquitetura Atual**

```
Internet (HTTP) → LoadBalancer → Frontend (Público)
                                    ↓
                               Backend (Interno)
                                    ↓
                            Monitoring (Port-forward)
```

### **Componentes:**
- ✅ **Frontend**: Acesso direto via LoadBalancer (HTTP)
- ✅ **Backend**: Acesso interno via ClusterIP (HTTP)
- ✅ **Monitoring**: Prometheus + Grafana (port-forward)
- ❌ **SSL/HTTPS**: Removido (simplificação)
- ❌ **cert-manager**: Não instalado
- ❌ **Traefik**: Substituído por LoadBalancer direto

## 🚀 **Deploy Rápido**

### **1. Deploy Completo (Recomendado)**
```bash
# Deploy completo da aplicação (HTTP apenas)
./scripts/deploy-http-only.sh
```

### **2. Deploy por Etapas**
```bash
# 1. Instalar infraestrutura
./scripts/install-simple-infrastructure-http-only.sh

# 2. Deploy da aplicação
kubectl apply -f k8s/production/

# 3. Testar arquitetura
./scripts/test-http-only-architecture.sh
```

### **3. Deploy Ultra Simples**
```bash
# Infraestrutura mínima + deploy
./scripts/install-ultra-simple-infrastructure.sh
kubectl apply -f k8s/production/
```

## 🧹 **Limpeza (Se Necessário)**

Se você tinha cert-manager instalado anteriormente:

```bash
# Remove cert-manager completamente
./scripts/remove-cert-manager.sh
```

## 🌐 **Acesso aos Serviços**

### **Frontend (Público)**
```bash
# Obter IP do LoadBalancer
kubectl get svc formerr-frontend-service -n formerr

# Acessar aplicação
curl http://<LOADBALANCER-IP>
```

### **Backend (Interno)**
```bash
# Teste interno (de dentro do cluster)
kubectl run test --rm -i --tty --image=curlimages/curl -- \
  curl http://formerr-backend-service.formerr.svc.cluster.local:8000/health
```

### **Monitoring**
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# Acesse: http://localhost:9090

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# Acesse: http://localhost:3000 (admin/admin)
```

## 📊 **Comandos Úteis**

### **Status da Aplicação**
```bash
# Status geral
kubectl get all -n formerr

# Logs em tempo real
kubectl logs -f deployment/formerr-frontend -n formerr
kubectl logs -f deployment/formerr-backend -n formerr

# Escalabilidade
kubectl scale deployment formerr-frontend --replicas=3 -n formerr
kubectl scale deployment formerr-backend --replicas=2 -n formerr
```

### **Troubleshooting**
```bash
# Teste completo da arquitetura
./scripts/test-http-only-architecture.sh

# Debug de conectividade
kubectl run debug --rm -i --tty --image=nicolaka/netshoot
```

## 🔧 **Configuração de DNS**

Após obter o IP do LoadBalancer:

```bash
# Obter IP
FRONTEND_IP=$(kubectl get svc formerr-frontend-service -n formerr -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo "Frontend IP: $FRONTEND_IP"

# Configurar DNS (exemplo)
# formerr.com A $FRONTEND_IP
# www.formerr.com CNAME formerr.com
```

## 🎯 **Ambientes**

### **Staging (GCP)**
- **Cluster**: GKE no Google Cloud Platform
- **Pipeline**: `.github/workflows/stage-deploy.yml`
- **Terraform**: `infrastructure/gcp-staging/`

### **Production (DigitalOcean)**
- **Cluster**: DOKS no DigitalOcean
- **Pipeline**: `.github/workflows/prod-deploy-production.yml`
- **Terraform**: `infrastructure/digitalocean-production/`

## 📝 **Estrutura de Arquivos**

```
Formerr-/
├── scripts/
│   ├── deploy-http-only.sh                    # Deploy completo HTTP
│   ├── install-simple-infrastructure-http-only.sh  # Infra HTTP
│   ├── install-ultra-simple-infrastructure.sh     # Infra mínima
│   ├── remove-cert-manager.sh                      # Remove SSL
│   └── test-http-only-architecture.sh              # Teste arquitetura
├── k8s/
│   └── production/
│       ├── frontend-deployment.yaml          # Frontend (LoadBalancer)
│       ├── backend-deployment.yaml           # Backend (ClusterIP)
│       └── ingress-simple.yaml              # Ingress HTTP apenas
├── infrastructure/
│   ├── gcp-staging/                          # Terraform GCP
│   └── digitalocean-production/              # Terraform DO
└── .github/workflows/                        # Pipelines CI/CD
```

## 🏆 **Benefícios da Arquitetura HTTP**

- ✅ **Simplicidade**: Sem complexidade de certificados
- ✅ **Confiabilidade**: Menos pontos de falha
- ✅ **Performance**: Acesso direto via LoadBalancer
- ✅ **Debugging**: Mais fácil troubleshooting
- ✅ **Deploy**: Mais rápido e confiável
- ✅ **Custo**: Menor overhead de infraestrutura

## ⚠️ **Considerações de Segurança**

Esta arquitetura HTTP é **ideal para**:
- 🧪 **Desenvolvimento e testes**
- 🔧 **Prototipagem rápida**
- 🏗️ **Validação de conceitos**
- 📊 **Ambientes internos**

Para **produção com dados sensíveis**, considere:
- 🔒 Adicionar SSL/HTTPS posteriormente
- 🛡️ Configurar WAF (Web Application Firewall)
- 🔐 Implementar autenticação robusta
- 📋 Compliance com regulamentações

## 🆘 **Suporte**

### **Documentação Adicional**
- 📖 `HTTP_ONLY_MIGRATION_COMPLETE.md` - Guia completo de migração
- 🧪 `scripts/test-http-only-architecture.sh` - Teste de validação
- 🔧 `REQUIREMENTS_CHECKLIST.md` - Checklist de requisitos

### **Troubleshooting Comum**
1. **LoadBalancer IP não aparece**: Aguarde 2-5 minutos
2. **Pods não iniciam**: Verifique `kubectl describe pod`
3. **Conectividade falha**: Use script de teste
4. **Monitoring não acessa**: Verifique port-forward

---

**Status**: ✅ **ARQUITETURA HTTP IMPLEMENTADA** - Pronto para uso!
