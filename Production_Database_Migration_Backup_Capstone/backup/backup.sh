#!/usr/bin/env bash
set -euo pipefail

# Required environment variables:
# DATABASE_URL
# BACKUP_DIR

: "${DATABASE_URL:?DATABASE_URL is required}"
: "${BACKUP_DIR:?BACKUP_DIR is required}"

mkdir -p "$BACKUP_DIR"

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
FILE="$BACKUP_DIR/postgres_${TIMESTAMP}.dump"

pg_dump "$DATABASE_URL" \
  --format=custom \
  --no-owner \
  --file="$FILE"

# Keep the newest 14 logical backups locally.
find "$BACKUP_DIR" -type f -name 'postgres_*.dump' \
  -printf '%T@ %p\n' |
  sort -nr |
  tail -n +15 |
  cut -d' ' -f2- |
  xargs -r rm -f

echo "Backup created: $FILE"
