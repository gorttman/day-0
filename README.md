# Pi-Lab Day-0 Bootstrap

This repo bootstraps the Pi-Lab cluster.

## Flow
1. Ansible installs:
   - Required system packages (curl, git, nfs-utils)
   - k3s via curl
   - Minimal ArgoCD manifests

2. Ansible creates ArgoCD repo secret for `pi-lab-foundation`

3. Ansible applies `apps/bootstrap.yaml`

4. ArgoCD takes over and deploys the **foundation-layer** (Ingress, NFS, Sealed Secrets, Argo self-manage, Cert-Manager).

## Usage
```bash
ansible-galaxy install -r requirements.yml
ansible-playbook playbooks/day0-bootstrap.yml --tags install_day0
```
