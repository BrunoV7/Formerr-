# 🚀 Migração para Arquitetura HTTP Apenas (Sem SSL/HTTPS)

## ✅ **Status da Migração**

A infraestrutura foi **completamente simplificada** para usar apenas HTTP, removendo toda a complexidade de SSL/HTTPS.

## 🎯 **Arquitetura Final - HTTP Apenas**

```
┌─────────────────────────────────────────────────────────────┐
│                        INTERNET                            │
└─────────────────────────────────────────────────────────────┘
                               │ HTTP (Port 80)
                               │
┌─────────────────────────────────────────────────────────────┐
│                     LoadBalancer                           │
│                 (Frontend - Público)                       │
└─────────────────────────────────────────────────────────────┘
                               │
┌─────────────────────────────────────────────────────────────┐
│                  Kubernetes Cluster                        │
│                                                             │
│  ┌──────────────────┐    ┌────────────────────────────────┐ │
│  │     Frontend     │    │           Backend              │ │
│  │   LoadBalancer   │    │         ClusterIP              │ │
│  │   (Público)      │    │        (Interno)               │ │
│  │                  │────│                                │ │
│  │  formerr-frontend│    │     formerr-backend            │ │
│  │      :3000       │    │         :8000                  │ │
│  └──────────────────┘    └────────────────────────────────┘ │
│                                                             │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │              Monitoring                                 │ │
│  │  Prometheus (9090) + Grafana (3000)                    │ │
│  │             (Port-forward apenas)                      │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## 🛠️ **Componentes Removidos**

- ❌ **cert-manager**: Completamente removido
- ❌ **SSL/TLS certificates**: Não instalados
- ❌ **HTTPS listeners**: Removidos
- ❌ **Traefik**: Substituído por LoadBalancer direto
- ❌ **ClusterIssuers**: Não necessários

## 🎯 **Componentes Mantidos**

- ✅ **Frontend**: LoadBalancer direto (HTTP apenas)
- ✅ **Backend**: ClusterIP interno (HTTP apenas)
- ✅ **Monitoring**: Prometheus + Grafana (port-forward)
- ✅ **NGINX Ingress**: Apenas para acesso interno ao backend

## 🚀 **Scripts de Deploy Atualizados**

### **1. Deploy Completo (HTTP Apenas)**
```bash
# Deploy completo da aplicação (HTTP apenas)
./scripts/deploy-http-only.sh
```

### **2. Instalar Infraestrutura Básica**
```bash
# Infraestrutura mínima (Prometheus + NGINX)
./scripts/install-simple-infrastructure-http-only.sh
```

### **3. Instalar Infraestrutura Ultra Simples**
```bash
# Infraestrutura ultra simples (Prometheus básico)
./scripts/install-ultra-simple-infrastructure.sh
```

### **4. Remover cert-manager (Se Instalado)**
```bash
# Remove cert-manager completamente
./scripts/remove-cert-manager.sh
```

## 📝 **Configurações Atualizadas**

### **Frontend Service (LoadBalancer)**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: formerr-frontend-service
  namespace: formerr
spec:
  type: LoadBalancer  # ← Acesso direto via IP público
  ports:
  - port: 80
    targetPort: 3000
    protocol: TCP
  selector:
    app: formerr-frontend
```

### **Backend Ingress (HTTP Apenas)**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: formerr-backend-ingress
  namespace: formerr
  annotations:
    kubernetes.io/ingress.class: "nginx"
    # Sem anotações de SSL
spec:
  # SEM seção tls
  rules:
  - host: api-internal.formerr.tech
    http:
      paths:
      - path: /(.*)
        pathType: Prefix
        backend:
          service:
            name: formerr-backend-service
            port:
              number: 8000
```

## 🌐 **Acesso aos Serviços**

### **1. Frontend (Público)**
```bash
# Obter IP do LoadBalancer
kubectl get svc formerr-frontend-service -n formerr

# Acesso direto
curl http://<LOADBALANCER-IP>
```

### **2. Backend (Interno)**
```bash
# Apenas acesso interno via DNS do cluster
curl http://formerr-backend-service.formerr.svc.cluster.local:8000/health
```

### **3. Monitoring**
```bash
# Prometheus
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090

# Grafana
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
```

## 🔧 **Comandos de Verificação**

### **Status dos Serviços**
```bash
# Status geral
kubectl get all -n formerr

# IP do LoadBalancer
kubectl get svc formerr-frontend-service -n formerr -o wide

# Logs do frontend
kubectl logs -f deployment/formerr-frontend -n formerr

# Logs do backend
kubectl logs -f deployment/formerr-backend -n formerr
```

### **Teste de Conectividade**
```bash
# Teste do frontend (substituir IP)
curl -v http://<FRONTEND-IP>

# Teste do backend (de dentro do cluster)
kubectl run test-pod --rm -i --tty --image=curlimages/curl -- sh
# Dentro do pod:
curl http://formerr-backend-service.formerr.svc.cluster.local:8000/health
```

## 📋 **Checklist de Migração**

- [x] **cert-manager removido** da infraestrutura GCP
- [x] **SSL annotations removidas** dos ingresses
- [x] **Frontend configurado** para LoadBalancer direto
- [x] **Backend configurado** para ClusterIP interno
- [x] **Scripts atualizados** para HTTP apenas
- [x] **Ingress atualizado** para HTTP apenas
- [x] **Documentação criada** para nova arquitetura

## 🎯 **Próximos Passos**

1. **Teste a pipeline de staging** no GCP:
   ```bash
   git push origin staging
   ```

2. **Verifique o IP do LoadBalancer**:
   ```bash
   kubectl get svc formerr-frontend-service -n formerr
   ```

3. **Atualize seu DNS** para apontar para o novo IP

4. **Teste a aplicação**:
   ```bash
   # Substitua pelo IP real do LoadBalancer
   curl http://<FRONTEND-IP>
   ```

5. **Configure monitoramento**:
   ```bash
   kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
   # Acesse http://localhost:3000 (admin/admin)
   ```

## ⚠️ **Observações Importantes**

- **HTTP apenas**: Sem HTTPS/SSL por simplicidade
- **Produção**: Para produção real, considere adicionar SSL posteriormente
- **DNS**: Atualize seus registros DNS para o novo IP do LoadBalancer
- **Firewall**: Certifique-se de que a porta 80 está aberta
- **Monitoramento**: Acesso apenas via port-forward (segurança)

## 🎉 **Benefícios da Nova Arquitetura**

- ✅ **Simplicidade**: Sem complexidade de SSL
- ✅ **Confiabilidade**: Menos pontos de falha
- ✅ **Performance**: Acesso direto via LoadBalancer
- ✅ **Debugging**: Mais fácil de debugar problemas
- ✅ **Deploy**: Deploy mais rápido e simples

---

**Status**: ✅ **MIGRAÇÃO COMPLETA** - Arquitetura HTTP simplificada implementada com sucesso!
