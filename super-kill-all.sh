#!/bin/bash
set -e

echo "===================================="
echo "   SUPER RESET: Nuking K3s & Argo"
echo "===================================="

# --- Stop and disable services ---
echo "[*] Stopping and disabling k3s services..."
sudo systemctl stop k3s k3s-agent 2>/dev/null || true
sudo systemctl disable k3s k3s-agent 2>/dev/null || true
sudo systemctl mask k3s k3s-agent 2>/dev/null || true

# --- Kill any leftover processes ---
echo "[*] Killing stray k3s/containerd/argocd/dashboard processes..."
sudo pkill -9 k3s 2>/dev/null || true
sudo pkill -9 containerd 2>/dev/null || true
sudo pkill -9 containerd-shim-runc-v2 2>/dev/null || true
sudo pkill -9 argocd-server argocd-repo-server argocd-dex-server 2>/dev/null || true
sudo pkill -9 kubernetes-dashboard 2>/dev/null || true

# --- Run uninstall scripts if present ---
echo "[*] Running official uninstall scripts..."
[ -x /usr/local/bin/k3s-uninstall.sh ] && sudo /usr/local/bin/k3s-uninstall.sh || true
[ -x /usr/local/bin/k3s-agent-uninstall.sh ] && sudo /usr/local/bin/k3s-agent-uninstall.sh || true

echo "[*] Removing leftover k3s binaries..."
sudo rm -f /usr/local/bin/k3s \
           /usr/local/bin/k3s-agent \
           /usr/local/bin/kubectl \
           /usr/local/bin/ctr \
           /usr/local/bin/crictl

# --- Purge data directories ---
echo "[*] Removing leftover data directories..."
sudo rm -rf /etc/rancher /var/lib/rancher
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/containerd /run/containerd
sudo rm -rf /var/lib/cni /etc/cni /run/flannel
sudo rm -rf /var/log/pods /var/log/containers

# --- Delete ArgoCD and Dashboard namespaces + CRDs ---
echo "[*] Cleaning up ArgoCD and dashboard CRDs/namespaces (if API reachable)..."
kubectl delete namespace argocd --ignore-not-found=true 2>/dev/null || true
kubectl delete namespace kubernetes-dashboard --ignore-not-found=true 2>/dev/null || true
kubectl delete crd $(kubectl get crd -o name | grep argoproj.io) --ignore-not-found=true 2>/dev/null || true

# --- Final verification ---
echo "[*] Checking for leftover processes..."
ps aux | grep -E "k3s|argocd|dashboard|containerd" | grep -v grep || echo "✅ No processes found."

echo "[*] Checking critical directories..."
for d in /etc/rancher /var/lib/rancher /var/lib/kubelet /var/lib/containerd /var/lib/cni /etc/cni /run/flannel; do
  if [ -d "$d" ]; then
    echo "⚠️  Directory still exists: $d"
  else
    echo "✅ $d removed"
  fi
done

echo "===================================="
echo "  ✅ SUPER RESET COMPLETE"
echo "===================================="
