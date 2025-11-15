#!/usr/bin/env bash
set -euo pipefail

###############################################
# Usage:
#   ./destroy.sh <namespace>
#
# Example:
#   ./destroy.sh wordpress
#
# Default:
#   namespace = wordpress
###############################################

NAMESPACE=${1:-wordpress}

echo "============================================"
echo " Destroying WordPress Stack"
echo " Namespace: $NAMESPACE"
echo "============================================"
echo

# Ensure namespace exists
if ! kubectl get ns "$NAMESPACE" >/dev/null 2>&1; then
  echo "Namespace '$NAMESPACE' does not exist. Nothing to delete."
  exit 0
fi

# Delete Helm releases (ignore failures)
echo "[1/5] Deleting Helm releases..."
helm uninstall nginx -n "$NAMESPACE" 2>/dev/null || true
helm uninstall wordpress -n "$NAMESPACE" 2>/dev/null || true
helm uninstall mysql -n "$NAMESPACE" 2>/dev/null || true
helm uninstall prometheus -n "$NAMESPACE" 2>/dev/null || true
echo "✓ Helm releases removed"
echo

# Delete PVCs
echo "[2/5] Deleting PersistentVolumeClaims..."
kubectl delete pvc --all -n "$NAMESPACE" 2>/dev/null || true
echo "✓ PVCs deleted"
echo

# Delete PVs that belong to this namespace (hostPath / NFS type)
echo "[3/5] Deleting PersistentVolumes..."
for pv in $(kubectl get pv --no-headers | awk '{print $1}'); do
  claim_ns=$(kubectl get pv "$pv" -o jsonpath='{.spec.claimRef.namespace}' 2>/dev/null || echo "")
  if [[ "$claim_ns" == "$NAMESPACE" ]]; then
    kubectl delete pv "$pv" 2>/dev/null || true
  fi
done
echo "✓ PVs deleted"
echo

# Delete monitoring CRDs / objects if exist
echo "[4/5] Cleaning up monitoring resources..."
kubectl delete -f k8s/monitoring/ -n "$NAMESPACE" 2>/dev/null || true
echo "✓ Monitoring resources removed"
echo

# Delete namespace last
echo "[5/5] Deleting namespace..."
kubectl delete ns "$NAMESPACE" 2>/dev/null || true
echo "✓ Namespace deletion triggered"
echo

echo "============================================"
echo " Cleanup Complete!"
echo "============================================"
echo
echo "You can verify cleanup with:"
echo "  kubectl get all -n $NAMESPACE"
echo "  kubectl get pv,pvc"
echo
