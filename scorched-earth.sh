#!/bin/bash
set -euo pipefail

echo "===================================="
echo "   SCORCHED EARTH: Nuking K3s & Argo"
echo "===================================="

# --- Stop and disable services ---
echo "[*] Stopping and disabling k3s + containerd..."
sudo systemctl stop k3s k3s-agent containerd 2>/dev/null || true
sudo systemctl disable k3s k3s-agent containerd 2>/dev/null || true
sudo systemctl mask k3s k3s-agent containerd 2>/dev/null || true

# --- Kill any leftover processes ---
echo "[*] Killing stray processes..."
sudo pkill -9 k3s k3s-agent containerd containerd-shim-runc-v2 \
  argocd-server argocd-repo-server argocd-dex-server kubernetes-dashboard \
  || true

# --- Run uninstall scripts if present ---
echo "[*] Running uninstall scripts..."
[ -x /usr/local/bin/k3s-uninstall.sh ] && sudo /usr/local/bin/k3s-uninstall.sh || true
[ -x /usr/local/bin/k3s-agent-uninstall.sh ] && sudo /usr/local/bin/k3s-agent-uninstall.sh || true

# --- Remove binaries ---
echo "[*] Removing leftover binaries..."
sudo rm -f /usr/local/bin/{k3s,k3s-agent,kubectl,ctr,crictl,containerd*}

# --- Purge data directories ---
echo "[*] Removing data directories..."
sudo rm -rf /etc/rancher /var/lib/rancher
sudo rm -rf /var/lib/kubelet
sudo rm -rf /var/lib/containerd /run/containerd
sudo rm -rf /var/lib/cni /etc/cni /run/flannel
sudo rm -rf /var/log/pods /var/log/containers

# --- Delete ArgoCD + dashboard CRDs/namespaces ---
echo "[*] Cleaning ArgoCD + dashboard CRDs/namespaces..."
kubectl delete namespace argocd --ignore-not-found=true || true
kubectl delete namespace kubernetes-dashboard --ignore-not-found=true || true
kubectl delete crd $(kubectl get crd -o name | grep argoproj.io || true) --ignore-not-found=true || true

# --- Check for leftovers ---
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

# --- Optional reboot with countdown ---
echo
echo "===================================="
echo "  ⚠️  REBOOT RECOMMENDED"
echo "===================================="
for i in {10..1}; do
  echo -ne "Rebooting in $i seconds... (Ctrl+C to cancel)\r"
  sleep 1
done

sudo reboot
