#!/usr/bin/env bash
set -euo pipefail

# Usage:
# DATABASE_URL='postgresql://...' ./restore.sh backup.dump

: "${DATABASE_URL:?DATABASE_URL is required}"

BACKUP_FILE="${1:?Pass a .dump backup file}"

pg_restore \
  --dbname="$DATABASE_URL" \
  --clean \
  --if-exists \
  --no-owner \
  "$BACKUP_FILE"

echo "Restore completed from: $BACKUP_FILE"
