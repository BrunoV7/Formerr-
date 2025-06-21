#!/bin/bash

echo "🔧 Script para importar cluster existente no Terraform"
echo ""

# Verificar se o DO_TOKEN_PROD está definido
if [ -z "$DO_TOKEN_PROD" ]; then
  echo "❌ Erro: Defina a variável DO_TOKEN_PROD"
  echo "Exemplo: export DO_TOKEN_PROD=dop_v1_your_token_here"
  exit 1
fi

echo "📋 Buscando cluster 'formerr-production'..."

# Buscar ID do cluster
CLUSTER_ID=$(curl -s -X GET \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $DO_TOKEN_PROD" \
  "https://api.digitalocean.com/v2/kubernetes/clusters" | \
  jq -r '.kubernetes_clusters[]? | select(.name=="formerr-production") | .id')

if [ -z "$CLUSTER_ID" ] || [ "$CLUSTER_ID" = "null" ]; then
  echo "❌ Cluster 'formerr-production' não encontrado"
  echo "Talvez já foi deletado ou tem outro nome?"
  exit 1
fi

echo "✅ Cluster encontrado: $CLUSTER_ID"
echo ""

echo "📁 Navegando para pasta de produção..."
cd infrastructure/terraform/production

echo "🔧 Inicializando Terraform..."
terraform init

echo "📥 Importando cluster existente..."
terraform import -var="do_token=$DO_TOKEN_PROD" digitalocean_kubernetes_cluster.formerr_prod $CLUSTER_ID

if [ $? -eq 0 ]; then
  echo ""
  echo "✅ Import realizado com sucesso!"
  echo "🚀 Agora você pode fazer 'git push origin main' sem problemas"
  echo ""
  echo "📋 Próximos passos:"
  echo "1. git push origin main"
  echo "2. O pipeline vai usar o cluster existente"
  echo "3. Não vai mais tentar criar um novo cluster"
else
  echo ""
  echo "❌ Erro no import. Pode ser que já esteja importado."
  echo "Execute 'terraform plan' para verificar o estado"
fi
