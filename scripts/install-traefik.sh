#!/bin/bash

# Install Traefik Ingress Controller with Let's Encrypt
# This replaces NGINX Ingress + Cert-Manager with a simpler, more integrated solution

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Installing Traefik Ingress Controller${NC}"
echo "=========================================="

# Get script directory for relative paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed or not in PATH${NC}"
    exit 1
fi

# Check if we can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo -e "${RED}❌ Cannot connect to Kubernetes cluster${NC}"
    echo "   Make sure you're connected to the cluster with:"
    echo "   doctl kubernetes cluster kubeconfig save <cluster-name>"
    exit 1
fi

echo -e "${GREEN}✅ Connected to Kubernetes cluster${NC}"
CLUSTER_INFO=$(kubectl cluster-info | head -1)
echo "   $CLUSTER_INFO"

# Check if Traefik is already installed and working
echo ""
echo "🔍 Checking if Traefik is already installed..."

TRAEFIK_DEPLOYMENT=$(kubectl get deployment traefik -n traefik 2>/dev/null || echo "")
TRAEFIK_SERVICE=$(kubectl get service traefik -n traefik 2>/dev/null || echo "")

if [[ -n "$TRAEFIK_DEPLOYMENT" && -n "$TRAEFIK_SERVICE" ]]; then
    # Check if Traefik pods are running
    TRAEFIK_READY=$(kubectl get pods -n traefik -l app.kubernetes.io/name=traefik --field-selector=status.phase=Running 2>/dev/null | grep -c "Running" || echo "0")
    
    if [[ "$TRAEFIK_READY" -gt 0 ]]; then
        # Check if LoadBalancer has external IP
        EXTERNAL_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "")
        
        if [[ -n "$EXTERNAL_IP" && "$EXTERNAL_IP" != "<pending>" ]]; then
            echo -e "${GREEN}✅ Traefik is already installed and running${NC}"
            echo "   External IP: $EXTERNAL_IP"
            echo "   Pods running: $TRAEFIK_READY"
            echo "   Dashboard: http://$EXTERNAL_IP:8080 (if enabled)"
            echo ""
            echo "🚀 Skipping installation, Traefik is already operational!"
            
            # Still check and apply ClusterIssuers if they don't exist
            echo ""
            echo "🔍 Checking Let's Encrypt ClusterIssuers..."
            ISSUERS_COUNT=$(kubectl get clusterissuers 2>/dev/null | grep -c "letsencrypt" || echo "0")
            
            if [[ "$ISSUERS_COUNT" -lt 2 ]]; then
                echo "📜 Applying Let's Encrypt ClusterIssuers..."
                kubectl apply -f "$SCRIPT_DIR/../k8s/monitoring/traefik-clusterissuers.yaml" || echo "Warning: Failed to apply ClusterIssuers"
            else
                echo -e "${GREEN}✅ ClusterIssuers already configured${NC}"
            fi
            
            exit 0
        fi
    fi
fi

echo -e "${YELLOW}⚠️  Traefik not found or not fully operational, proceeding with installation...${NC}"

# Install Traefik using Helm (if available) or manifests
echo ""
echo "🌐 Installing Traefik Ingress Controller..."

# Create Traefik namespace
kubectl create namespace traefik --dry-run=client -o yaml | kubectl apply -f -

# Apply Traefik CRDs first
echo "📋 Installing Traefik CRDs..."
if kubectl apply -f https://raw.githubusercontent.com/traefik/traefik/v3.0/docs/content/reference/dynamic-configuration/kubernetes-crd-definition-v1.yml; then
    echo -e "${GREEN}✅ Traefik CRDs installed${NC}"
else
    echo -e "${RED}❌ Failed to install Traefik CRDs${NC}"
    exit 1
fi

# Create Traefik configuration
echo ""
echo "⚙️ Creating Traefik configuration..."

# Create Traefik ConfigMap
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ConfigMap
metadata:
  name: traefik-config
  namespace: traefik
data:
  traefik.yml: |
    global:
      checkNewVersion: false
      sendAnonymousUsage: false
    
    serversTransport:
      insecureSkipVerify: true
    
    entryPoints:
      web:
        address: ":80"
        http:
          redirections:
            entrypoint:
              to: websecure
              scheme: https
              permanent: true
      websecure:
        address: ":443"
    
    certificatesResolvers:
      letsencrypt:
        acme:
          email: admin@formerr.example.com  # Change this to your email
          storage: /data/acme.json
          httpChallenge:
            entryPoint: web
      letsencrypt-staging:
        acme:
          email: admin@formerr.example.com  # Change this to your email
          storage: /data/acme-staging.json
          caServer: https://acme-staging-v02.api.letsencrypt.org/directory
          httpChallenge:
            entryPoint: web
    
    providers:
      kubernetesIngress: {}
      kubernetesCRD: {}
    
    api:
      dashboard: true
      insecure: false
    
    log:
      level: INFO
    
    accessLog: {}
EOF

# Create RBAC for Traefik
echo "🔐 Creating Traefik RBAC..."
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: traefik
  namespace: traefik
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: traefik
rules:
  - apiGroups:
      - ""
    resources:
      - services
      - endpoints
      - secrets
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses
      - ingressclasses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - extensions
      - networking.k8s.io
    resources:
      - ingresses/status
    verbs:
      - update
  - apiGroups:
      - traefik.containo.us
      - traefik.io
    resources:
      - middlewares
      - middlewaretcps
      - ingressroutes
      - traefikservices
      - ingressroutetcps
      - ingressrouteudps
      - tlsoptions
      - tlsstores
      - serverstransports
    verbs:
      - get
      - list
      - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: traefik
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: traefik
subjects:
  - kind: ServiceAccount
    name: traefik
    namespace: traefik
EOF

# Deploy Traefik
echo "🚀 Deploying Traefik..."
cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: traefik
  namespace: traefik
  labels:
    app: traefik
spec:
  replicas: 1
  selector:
    matchLabels:
      app: traefik
  template:
    metadata:
      labels:
        app: traefik
    spec:
      serviceAccountName: traefik
      containers:
        - name: traefik
          image: traefik:v3.0
          args:
            - --configfile=/config/traefik.yml
          ports:
            - name: web
              containerPort: 80
            - name: websecure
              containerPort: 443
            - name: admin
              containerPort: 8080
          volumeMounts:
            - name: config
              mountPath: /config
            - name: data
              mountPath: /data
          livenessProbe:
            httpGet:
              path: /ping
              port: 8080
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /ping
              port: 8080
            initialDelaySeconds: 5
            periodSeconds: 5
      volumes:
        - name: config
          configMap:
            name: traefik-config
        - name: data
          emptyDir: {}
---
apiVersion: v1
kind: Service
metadata:
  name: traefik
  namespace: traefik
  labels:
    app: traefik
spec:
  type: LoadBalancer
  selector:
    app: traefik
  ports:
    - name: web
      port: 80
      targetPort: 80
    - name: websecure
      port: 443
      targetPort: 443
---
apiVersion: v1
kind: Service
metadata:
  name: traefik-dashboard
  namespace: traefik
  labels:
    app: traefik
spec:
  selector:
    app: traefik
  ports:
    - name: admin
      port: 8080
      targetPort: 8080
EOF

# Wait for Traefik to be ready
echo ""
echo "⏳ Waiting for Traefik to be ready..."
if kubectl wait --namespace traefik \
  --for=condition=ready pod \
  --selector=app=traefik \
  --timeout=300s; then
    echo -e "${GREEN}✅ Traefik is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Timeout waiting for Traefik, but continuing...${NC}"
fi

# Create IngressClass
echo ""
echo "📋 Creating Traefik IngressClass..."
cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: traefik
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"
spec:
  controller: traefik.io/ingress-controller
EOF

# Show installation status
echo ""
echo "📊 Installation Status:"
echo "======================"

echo ""
echo "📋 Traefik Pods:"
kubectl get pods -n traefik

echo ""
echo "📋 Traefik Services:"
kubectl get services -n traefik

echo ""
echo "📋 IngressClass:"
kubectl get ingressclass

# Get LoadBalancer IP
echo ""
echo "🌐 LoadBalancer Information:"
LB_IP=$(kubectl get service traefik -n traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || echo "Pending...")
echo "   External IP: $LB_IP"

if [[ "$LB_IP" != "Pending..." && -n "$LB_IP" ]]; then
    echo ""
    echo -e "${GREEN}✅ Traefik installation completed successfully!${NC}"
    echo ""
    echo "🔗 Access points:"
    echo "   Main LoadBalancer: http://$LB_IP"
    echo "   Dashboard: http://$LB_IP:8080 (access via port-forward for security)"
    echo ""
    echo "🔧 To access the dashboard securely:"
    echo "   kubectl port-forward -n traefik service/traefik-dashboard 8080:8080"
    echo "   Then visit: http://localhost:8080"
else
    echo ""
    echo -e "${YELLOW}⚠️  LoadBalancer IP is still pending${NC}"
    echo "   Check again in a few minutes with:"
    echo "   kubectl get service traefik -n traefik"
fi

echo ""
echo "📝 Next steps:"
echo "1. Update your DNS to point to: $LB_IP"
echo "2. Change the email in Traefik config for Let's Encrypt"
echo "3. Create Ingress resources with automatic HTTPS:"
echo ""
echo "Example Ingress with automatic HTTPS:"
echo "---"
echo "apiVersion: networking.k8s.io/v1"
echo "kind: Ingress"
echo "metadata:"
echo "  name: example-ingress"
echo "  annotations:"
echo "    traefik.ingress.kubernetes.io/router.tls.certresolver: letsencrypt"
echo "    traefik.ingress.kubernetes.io/router.middlewares: default-redirect-https@kubernetescrd"
echo "spec:"
echo "  ingressClassName: traefik"
echo "  rules:"
echo "  - host: your-domain.com"
echo "    http:"
echo "      paths:"
echo "      - path: /"
echo "        pathType: Prefix"
echo "        backend:"
echo "          service:"
echo "            name: your-service"
echo "            port:"
echo "              number: 80"
echo "  tls:"
echo "  - hosts:"
echo "    - your-domain.com"
echo "    secretName: your-domain-tls"

echo ""
echo "📚 Useful commands:"
echo "   # Check Traefik status"
echo "   kubectl get pods -n traefik"
echo "   kubectl logs -n traefik deployment/traefik"
echo ""
echo "   # Access dashboard"
echo "   kubectl port-forward -n traefik service/traefik-dashboard 8080:8080"
echo ""
echo "   # Check certificates"
echo "   kubectl get secrets --all-namespaces | grep tls"
echo ""
echo -e "${GREEN}🎉 Traefik installation completed!${NC}"
