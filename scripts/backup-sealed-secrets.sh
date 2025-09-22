#!/bin/bash
# Backup the Sealed Secrets controller private key
# Initially runs every 5 min (via cron). Once a key is found and backed up,
# reconfigure cron to run weekly instead.

set -euo pipefail

BACKUP_DIR="$(dirname "$0")/../credentials"
mkdir -p "$BACKUP_DIR"

TIMESTAMP=$(date +%F-%H%M%S)
OUTPUT_FILE="$BACKUP_DIR/sealed-secrets-key-$TIMESTAMP.yaml"

# Check if the key exists in the cluster
if ! kubectl get secret sealed-secrets-key -n kube-system >/dev/null 2>&1; then
  echo "[*] sealed-secrets-key not found yet, will check again later."
  exit 0
fi

# Export the key
kubectl get secret sealed-secrets-key -n kube-system -o yaml > "$OUTPUT_FILE"
echo "[*] Backed up Sealed Secrets key to $OUTPUT_FILE"

# Update cronjob to weekly
CRON_JOB="0 3 * * 0 /usr/local/bin/backup-sealed-secrets.sh"
CRONTAB_TMP=$(mktemp)

# Remove any existing entries for this script
crontab -l 2>/dev/null | grep -v "backup-sealed-secrets.sh" > "$CRONTAB_TMP" || true

# Add the weekly schedule
echo "$CRON_JOB" >> "$CRONTAB_TMP"

# Install new crontab
crontab "$CRONTAB_TMP"
rm -f "$CRONTAB_TMP"

echo "[*] Cron updated: now runs weekly at 03:00 on Sundays."
