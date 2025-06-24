# 🔐 GUIA COMPLETO - PERMISSÕES GCP SERVICE ACCOUNT

## 🎯 **PERMISSÕES OBRIGATÓRIAS (MÍNIMAS)**

### **Para funcionar 100% com sua infraestrutura, a Service Account precisa destas roles:**

```bash
# 1. Kubernetes Engine Admin (Gerenciar GKE)
roles/container.admin

# 2. Compute Admin (Gerenciar VMs, redes, discos)
roles/compute.admin

# 3. Storage Admin (Gerenciar Container Registry)
roles/storage.admin

# 4. Service Account User (Para usar outras SAs)
roles/iam.serviceAccountUser

# 5. Security Admin (Para firewalls e políticas)
roles/compute.securityAdmin
```

---

## 📋 **PASSO A PASSO - CRIAR SERVICE ACCOUNT**

### **Opção 1: Via Console GCP (Recomendado)**

1. **Acessar IAM & Admin**
   ```
   console.cloud.google.com → IAM & Admin → Service Accounts
   ```

2. **Criar Service Account**
   ```
   • Clique em "CREATE SERVICE ACCOUNT"
   • Nome: formerr-ci-cd
   • ID: formerr-ci-cd
   • Descrição: Service Account para CI/CD do Formerr
   ```

3. **Adicionar Roles (TODAS ESSAS)**
   ```
   ✅ Kubernetes Engine Admin
   ✅ Compute Admin  
   ✅ Storage Admin
   ✅ Service Account User
   ✅ Security Admin
   ```

4. **Gerar Chave JSON**
   ```
   • Na lista de SAs, clique nos 3 pontos → "Manage keys"
   • "ADD KEY" → "Create new key" → JSON
   • Baixar o arquivo JSON
   ```

### **Opção 2: Via gcloud CLI**

```bash
# 1. Definir variáveis
export PROJECT_ID="seu-projeto-gcp"
export SA_NAME="formerr-ci-cd"
export SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# 2. Criar Service Account
gcloud iam service-accounts create ${SA_NAME} \
    --display-name="Formerr CI/CD Service Account" \
    --description="Service Account para deploy automatizado do Formerr"

# 3. Adicionar roles obrigatórias
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/container.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/compute.securityAdmin"

# 4. Gerar chave JSON
gcloud iam service-accounts keys create formerr-sa-key.json \
    --iam-account=${SA_EMAIL}
```

---

## 🔍 **DETALHES DAS PERMISSÕES**

### **1. Kubernetes Engine Admin (`roles/container.admin`)**
**O que faz:**
- Criar, modificar e deletar clusters GKE
- Gerenciar node pools
- Configurar networking do cluster
- Instalar add-ons (Helm charts)

**Por que precisa:**
- Seu Terraform cria cluster GKE
- Pipeline instala Prometheus/Grafana via Helm
- Gerencia scaling e updates

### **2. Compute Admin (`roles/compute.admin`)**
**O que faz:**
- Criar VPCs, subnets, firewalls
- Gerenciar load balancers
- Criar e gerenciar discos
- Configurar IPs externos

**Por que precisa:**
- Terraform cria VPC e subnets
- Load balancers para Grafana/Prometheus
- Discos persistentes para dados

### **3. Storage Admin (`roles/storage.admin`)**
**O que faz:**
- Gerenciar Google Container Registry (GCR)
- Upload/download de imagens Docker
- Configurar políticas de acesso

**Por que precisa:**
- Pipeline faz push das imagens Docker
- GKE puxa imagens do GCR

### **4. Service Account User (`roles/iam.serviceAccountUser`)**
**O que faz:**
- Usar outras service accounts
- Impersonar SAs para operações

**Por que precisa:**
- GKE nodes usam SAs próprias
- Terraform precisa criar SAs para recursos

### **5. Security Admin (`roles/compute.securityAdmin`)**
**O que faz:**
- Gerenciar regras de firewall
- Configurar políticas de segurança
- Gerenciar SSL certificates

**Por que precisa:**
- Terraform cria regras de firewall
- Load balancers precisam de configurações SSL

---

## ⚠️ **PERMISSÕES EXTRAS (OPCIONAIS PARA MELHORIAS)**

### **Para recursos avançados:**
```bash
# DNS Admin (se usar Cloud DNS)
roles/dns.admin

# Logging Admin (para logs centralizados)
roles/logging.admin

# Monitoring Admin (para alertas avançados)
roles/monitoring.admin

# Cloud SQL Admin (se usar Cloud SQL)
roles/cloudsql.admin
```

---

## 🧪 **COMO TESTAR AS PERMISSÕES**

### **1. Teste via gcloud (local)**
```bash
# 1. Ativar service account
gcloud auth activate-service-account --key-file=formerr-sa-key.json

# 2. Definir projeto
gcloud config set project SEU_PROJECT_ID

# 3. Testar permissões
gcloud container clusters list  # Deve funcionar
gcloud compute networks list    # Deve funcionar
gcloud auth list               # Verificar conta ativa
```

### **2. Teste via GitHub Actions**
```bash
# Fazer commit em branch develop para testar
git checkout develop
git commit --allow-empty -m "test: gcp permissions"
git push origin develop

# Acompanhar logs em GitHub Actions
```

---

## 🔒 **CONFIGURAÇÃO NO GITHUB**

### **1. Preparar o JSON**
```bash
# O arquivo JSON baixado deve ter essa estrutura:
{
  "type": "service_account",
  "project_id": "seu-projeto",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "formerr-ci-cd@projeto.iam.gserviceaccount.com",
  "client_id": "...",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  ...
}
```

### **2. Adicionar aos GitHub Secrets**
```bash
# No GitHub → Settings → Secrets and variables → Actions

# Secret 1: GCP_PROJECT_ID
GCP_PROJECT_ID = seu-projeto-id

# Secret 2: GCP_SA_KEY (CONTEÚDO COMPLETO DO JSON)
GCP_SA_KEY = {"type":"service_account","project_id":"..."}

# Secret 3: GCP_CLUSTER_ZONE  
GCP_CLUSTER_ZONE = us-central1-a
```

---

## ⚡ **COMANDOS RÁPIDOS**

### **Setup completo em 5 comandos:**
```bash
# 1. Criar SA
gcloud iam service-accounts create formerr-ci-cd

# 2. Adicionar todas as roles
for role in roles/container.admin roles/compute.admin roles/storage.admin roles/iam.serviceAccountUser roles/compute.securityAdmin; do
  gcloud projects add-iam-policy-binding SEU_PROJECT_ID \
    --member="serviceAccount:formerr-ci-cd@SEU_PROJECT_ID.iam.gserviceaccount.com" \
    --role="$role"
done

# 3. Gerar chave
gcloud iam service-accounts keys create sa-key.json \
  --iam-account=formerr-ci-cd@SEU_PROJECT_ID.iam.gserviceaccount.com

# 4. Ver conteúdo da chave
cat sa-key.json

# 5. Copiar JSON para GitHub Secrets
```

---

## 🚨 **TROUBLESHOOTING**

### **Erro: "Permission denied"**
```bash
# Verificar se SA tem todas as roles:
gcloud projects get-iam-policy SEU_PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:formerr-ci-cd@SEU_PROJECT_ID.iam.gserviceaccount.com"
```

### **Erro: "Cluster not found"**
```bash
# Verificar se APIs estão habilitadas:
gcloud services enable container.googleapis.com
gcloud services enable compute.googleapis.com
gcloud services enable storage.googleapis.com
```

### **Erro: "Quota exceeded"**
```bash
# Verificar quotas disponíveis:
gcloud compute project-info describe --project=SEU_PROJECT_ID
```

---

## ✅ **CHECKLIST FINAL**

```bash
□ Service Account criada
□ 5 roles obrigatórias adicionadas:
  □ roles/container.admin
  □ roles/compute.admin  
  □ roles/storage.admin
  □ roles/iam.serviceAccountUser
  □ roles/compute.securityAdmin
□ Chave JSON gerada
□ APIs habilitadas (container, compute, storage)
□ GitHub Secrets configurados:
  □ GCP_PROJECT_ID
  □ GCP_SA_KEY  
  □ GCP_CLUSTER_ZONE
□ Teste via pipeline realizado
```

**Com essas permissões, sua pipeline de staging funcionará perfeitamente!** 🚀
