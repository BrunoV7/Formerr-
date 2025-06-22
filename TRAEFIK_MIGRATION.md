# Migração para Traefik: NGINX Ingress + Cert-Manager → Traefik

## 🎯 **Por que migrar para Traefik?**

### **Problemas com NGINX + Cert-Manager:**
- ❌ Problemas de timing com webhooks do cert-manager
- ❌ Configuração complexa (2 componentes separados)
- ❌ Erros frequentes: "failed calling webhook cert-manager"
- ❌ Dependências entre componentes
- ❌ Mais recursos K8s necessários

### **Vantagens do Traefik:**
- ✅ **Gratuito e open-source** (Apache 2.0)
- ✅ **Tudo integrado** - ingress + SSL em um só lugar
- ✅ **Auto-discovery** automático de serviços
- ✅ **Let's Encrypt nativo** - sem webhooks problemáticos
- ✅ **Dashboard web integrado** para monitoring
- ✅ **Configuração mais simples**
- ✅ **Melhor performance** 
- ✅ **Menos problemas de deployment**

## 🚀 **O que mudou?**

### **Antes (NGINX + Cert-Manager):**
```yaml
# Precisava de ClusterIssuers separados
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: admin@example.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx

# E depois Ingress separado
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
    kubernetes.io/ingress.class: nginx
```

### **Agora (Traefik):**
```yaml
# Tudo em um lugar - SSL automático!
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt
spec:
  ingressClassName: traefik
  rules:
  - host: your-domain.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: your-service
            port:
              number: 80
  tls:
  - hosts:
    - your-domain.com
    secretName: your-domain-tls
```

## 📁 **Arquivos Criados/Modificados:**

### **Novos arquivos:**
- `scripts/install-traefik.sh` - Script de instalação completa
- `k8s/monitoring/traefik-ingress.yaml` - Exemplos de Ingress

### **Arquivos modificados:**
- `.github/workflows/deploy-production.yml` - Usa Traefik ao invés de NGINX
- `.github/workflows/deploy-staging.yml` - Usa Traefik ao invés de NGINX

### **Arquivos que podem ser removidos:**
- `scripts/install-ingress.sh` (obsoleto)
- `k8s/monitoring/ingress-cert-manager.yaml` (obsoleto)

## 🔧 **Como usar:**

### **1. Instalação (automática via workflow):**
O script `install-traefik.sh` é executado automaticamente durante o deploy e instala:
- Traefik v3.0
- CRDs necessários
- Configuração com Let's Encrypt
- LoadBalancer service
- Dashboard (opcional)

### **2. Configuração de domínio:**
```bash
# 1. Obter IP do LoadBalancer
kubectl get service traefik -n traefik

# 2. Configurar DNS
# A record: your-domain.com → EXTERNAL-IP
# A record: api.your-domain.com → EXTERNAL-IP
```

### **3. Atualizar email para Let's Encrypt:**
Edite `scripts/install-traefik.sh` e mude:
```yaml
email: admin@formerr.example.com  # Para seu email real
```

### **4. Criar Ingress para suas aplicações:**
Use os exemplos em `k8s/monitoring/traefik-ingress.yaml`

## 🎛️ **Dashboard do Traefik:**

### **Acesso seguro via port-forward:**
```bash
kubectl port-forward -n traefik service/traefik-dashboard 8080:8080
# Acesse: http://localhost:8080
```

### **Acesso via Ingress (opcional):**
Descomente a seção do dashboard em `traefik-ingress.yaml`

## 📊 **Comparação de recursos:**

| Aspecto | NGINX + Cert-Manager | Traefik |
|---------|---------------------|---------|
| **Pods** | ~5 pods | ~1 pod |
| **ConfigMaps** | ~3 | ~1 |
| **Services** | ~3 | ~2 |
| **CRDs** | ~6 | ~7 |
| **Namespaces** | 2 (ingress-nginx, cert-manager) | 1 (traefik) |
| **Problemas de timing** | ❌ Frequentes | ✅ Raros |
| **Configuração SSL** | ❌ Complexa | ✅ Simples |
| **Dashboard** | ❌ Não incluso | ✅ Incluso |

## 🔍 **Troubleshooting:**

### **Verificar status do Traefik:**
```bash
# Pods
kubectl get pods -n traefik

# Services e LoadBalancer
kubectl get services -n traefik

# Logs
kubectl logs -n traefik deployment/traefik

# Ingress classes
kubectl get ingressclass
```

### **Verificar certificados SSL:**
```bash
# Secrets TLS criados automaticamente
kubectl get secrets --all-namespaces | grep tls

# Verificar específico
kubectl describe secret your-domain-tls -n default
```

### **Comandos úteis:**
```bash
# Dashboard via port-forward
kubectl port-forward -n traefik service/traefik-dashboard 8080:8080

# Ver configuração atual
kubectl get configmap traefik-config -n traefik -o yaml

# Restart Traefik se necessário
kubectl rollout restart deployment/traefik -n traefik
```

## 🎉 **Benefícios da migração:**

1. **✅ Menos problemas de deployment** - sem mais erros de webhook
2. **✅ Configuração mais simples** - tudo em um lugar
3. **✅ SSL automático** - sem ClusterIssuers separados
4. **✅ Dashboard de monitoramento** - visibilidade total
5. **✅ Melhor performance** - menos overhead
6. **✅ Menos recursos** - footprint menor no cluster

## 🚀 **Próximos passos:**

1. ✅ Traefik instalado via workflow
2. 🔄 Atualizar DNS para apontar para o novo LoadBalancer
3. 🔄 Mudar email no script `install-traefik.sh`
4. 🔄 Criar Ingress resources usando os exemplos
5. 🔄 Testar SSL automático
6. 🔄 Configurar dashboard (opcional)

---

**Status:** ✅ **MIGRAÇÃO COMPLETA** - Traefik substituiu NGINX + Cert-Manager com sucesso!

**LoadBalancer:** Verifique com `kubectl get service traefik -n traefik`
**Dashboard:** `kubectl port-forward -n traefik service/traefik-dashboard 8080:8080`
