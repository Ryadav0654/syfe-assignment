# #!/usr/bin/env bash
# set -euo pipefail

# ###############################################
# # Usage:
# #   ./deploy.sh <registry> <tag> <namespace>
# #
# # Example:
# #   ./deploy.sh mydockerhub v1 prod
# #
# # If you omit args, defaults are used:
# #   registry="yourdockerhub"
# #   tag="latest"
# #   namespace="wordpress"
# ###############################################

# # REGISTRY=${1:-yourdockerhub}
# TAG=${2:-latest}
# NAMESPACE=${3:-wordpress}

# echo "============================================"
# echo " Deploying WordPress Stack on Kubernetes"
# # echo " Registry: $REGISTRY"
# echo " Tag:      $TAG"
# echo " Namespace: $NAMESPACE"
# echo "============================================"
# echo

# # Create namespace
# echo "[1/6] Creating namespace..."
# kubectl create ns $NAMESPACE 2>/dev/null || true
# echo "✓ Namespace ready"
# echo

# # Build images
# echo "[2/6] Building Docker images..."
# docker build -t nginx-openresty:${TAG} -f docker/nginx/Dockerfile docker/nginx
# docker build -t wordpress:${TAG} -f docker/wordpress/Dockerfile docker/wordpress
# docker build -t mysql:${TAG} -f docker/mysql/Dockerfile docker/mysql
# echo "✓ Images built"
# echo

# # # Push images
# # echo "[3/6] Pushing images to registry..."
# # docker push ${REGISTRY}/nginx-openresty:${TAG}
# # docker push ${REGISTRY}/wordpress:${TAG}
# # docker push ${REGISTRY}/mysql:${TAG}
# # echo "✓ Images pushed"
# # echo

# # Apply storage manifests
# echo "[4/6] Applying storage (PV/PVC)..."
# kubectl apply -f k8s/storage/ -n $NAMESPACE
# kubectl get pvc -n $NAMESPACE
# echo "✓ Storage applied"
# echo

# # Deploy monitoring stack
# echo "[5/6] Deploying Prometheus + Grafana (kube-prometheus-stack)..."
# helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
# helm repo update
# helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n $NAMESPACE
# echo "✓ Monitoring stack deployed"
# echo

# # Deploy application charts
# echo "[6/6] Deploying MySQL..."
# helm upgrade --install mysql charts/mysql -n $NAMESPACE

# echo "Deploying WordPress..."
# helm upgrade --install wordpress charts/wordpress -n $NAMESPACE

# echo "Deploying Nginx OpenResty..."
# helm upgrade --install nginx charts/nginx -n $NAMESPACE

# echo "Applying monitoring resources..."
# kubectl apply -f k8s/monitoring/servicemonitor-nginx.yaml -n $NAMESPACE 2>/dev/null || true
# kubectl apply -f k8s/monitoring/prometheusrule-wordpress.yaml -n $NAMESPACE 2>/dev/null || true

# echo
# echo "============================================"
# echo " Deployment Complete!"
# echo "============================================"
# echo
# echo "Grafana Access:"
# echo "  kubectl port-forward svc/prometheus-grafana 3000:80 -n $NAMESPACE"
# echo "  → http://localhost:3000"
# echo "  Default creds: admin / prom-operator"
# echo
# echo "Nginx Access:"
# echo "  kubectl get svc nginx -n $NAMESPACE"
# echo
# echo "Logs:"
# echo "  kubectl logs deployment/nginx -n $NAMESPACE"
# echo "  kubectl logs deployment/wordpress -n $NAMESPACE"
# echo "  kubectl logs deployment/mysql -n $NAMESPACE"
# echo
# echo "Done!"



#!/usr/bin/env bash
set -euo pipefail

###############################################
# Usage:
#   ./deploy.sh <tag> <namespace>
#
# Example:
#   ./deploy.sh v1 wordpress
#
# Defaults:
#   tag="latest"
#   namespace="wordpress"
###############################################

TAG=${1:-latest}
NAMESPACE=${2:-wordpress}

echo "============================================"
echo " Deploying WordPress Stack on Kubernetes"
echo " Tag:      $TAG"
echo " Namespace: $NAMESPACE"
echo "============================================"
echo

# Create namespace
echo "[1/7] Creating namespace..."
kubectl create ns "$NAMESPACE" 2>/dev/null || true
echo "✓ Namespace ready"
echo

# Build images (use folder context so COPY works)
echo "[2/7] Building Docker images..."
docker build -t nginx-openresty:"${TAG}" -f docker/nginx/Dockerfile docker/nginx
docker build -t wordpress:"${TAG}" -f docker/wordpress/Dockerfile docker/wordpress
docker build -t mysql:"${TAG}" -f docker/mysql/Dockerfile docker/mysql
echo "✓ Images built"
echo

# Apply storage manifests
echo "[3/7] Applying storage (PV/PVC)..."
kubectl apply -f k8s/storage/ -n "$NAMESPACE"
kubectl get pvc -n "$NAMESPACE" || true
echo "✓ Storage applied"
echo

# Ensure Helm is installed (install automatically if missing)
if ! command -v helm >/dev/null 2>&1; then
  echo "[4/7] Helm not found — installing Helm 3..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
  else
    echo "curl is not installed; please install curl or helm manually and re-run the script."
    exit 1
  fi
else
  echo "[4/7] Helm found: $(helm version --short)"
fi
echo "✓ Helm ready"
echo

# Deploy monitoring stack
echo "[5/7] Deploying Prometheus + Grafana (kube-prometheus-stack)..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 2>/dev/null || true
helm repo update
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack -n "$NAMESPACE"
echo "✓ Monitoring stack deployed"
echo

# Deploy application charts
echo "[6/7] Deploying MySQL..."
helm upgrade --install mysql charts/mysql -n "$NAMESPACE"

echo "Deploying WordPress..."
helm upgrade --install wordpress charts/wordpress -n "$NAMESPACE"

echo "Deploying Nginx OpenResty..."
helm upgrade --install nginx charts/nginx -n "$NAMESPACE"

# Apply any monitoring resources (ServiceMonitor / PrometheusRule)
echo "[7/7] Applying monitoring resources..."
kubectl apply -f k8s/monitoring/servicemonitor-nginx.yaml -n "$NAMESPACE" 2>/dev/null || true
kubectl apply -f k8s/monitoring/prometheusrule-wordpress.yaml -n "$NAMESPACE" 2>/dev/null || true

echo
echo "============================================"
echo " Deployment Complete!"
echo "============================================"
echo
echo "Grafana Access:"
echo "  kubectl port-forward svc/prometheus-grafana 3000:80 -n $NAMESPACE"
echo "  → http://localhost:3000"
echo "  Default creds: admin / prom-operator"
echo
echo "Nginx Access:"
echo "  kubectl get svc nginx -n $NAMESPACE"
echo
echo "Logs:"
echo "  kubectl logs deployment/nginx -n $NAMESPACE"
echo "  kubectl logs deployment/wordpress -n $NAMESPACE"
echo "  kubectl logs deployment/mysql -n $NAMESPACE"
echo
echo "Done!"
