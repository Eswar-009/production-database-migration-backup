# Production Database Migration & Backup Strategy Capstone

A production-oriented PostgreSQL database repository demonstrating version-controlled schema migrations, database views, stored procedures, audit triggers, materialized views, and disaster-recovery backup practices.

## Architecture

```text
database/
├── migrations/
│   ├── V001__create_core_schema.sql
│   ├── V001__create_core_schema_down.sql
│   ├── V002__create_audit_log.sql
│   ├── V002__create_audit_log_down.sql
│   ├── V003__create_reporting_view.sql
│   ├── V003__create_reporting_view_down.sql
│   ├── V004__create_materialized_view.sql
│   └── V004__create_materialized_view_down.sql
├── views/
│   └── customer_order_summary.sql
├── procedures/
│   └── place_order.sql
├── triggers/
│   └── audit_order_changes.sql
├── backup/
│   ├── backup.sh
│   └── restore.sh
└── README.md
```

## Database choice

PostgreSQL 14+ is used because it supports transactional DDL, materialized views, functions/procedures, row-level triggers, and robust backup/restore tooling.

## Migration strategy

Every migration has a matching `down` script.

- `V001` creates the core schema.
- `V002` creates the audit table and trigger function.
- `V003` creates a reporting view.
- `V004` creates a materialized reporting view.

Run migrations in ascending version order. Store migration files in Git and never edit an already-applied production migration. Create a new migration for subsequent changes.

Example:

```bash
psql "$DATABASE_URL" -f migrations/V001__create_core_schema.sql
psql "$DATABASE_URL" -f migrations/V002__create_audit_log.sql
psql "$DATABASE_URL" -f migrations/V003__create_reporting_view.sql
psql "$DATABASE_URL" -f migrations/V004__create_materialized_view.sql
```

## Stored procedure

`place_order()` performs a transactional order creation and inventory decrement.

The procedure:

1. Locks the inventory row with `FOR UPDATE`.
2. Checks available stock.
3. Creates the order.
4. Creates the order item.
5. Decrements inventory.
6. Raises an exception when stock is insufficient.

An exception aborts the current transaction, preventing partial order creation.

## Audit logging

The order audit trigger records:

- INSERT
- UPDATE
- DELETE
- operation timestamp
- database user
- old row JSON
- new row JSON

JSONB snapshots make the audit log flexible while preserving the original row state.

## Views

`customer_order_summary` provides frequently used customer-level order metrics without repeating joins and aggregation logic.

## Materialized view

`mv_daily_sales` stores daily sales aggregation for high-frequency analytics.

Refresh:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_daily_sales;
```

A unique index is created so concurrent refresh can be used.

For very large datasets, refresh the materialized view through a scheduled job during an appropriate reporting window.

## Backup strategy

### Logical backup

Use `pg_dump` for database-level logical backups:

```bash
pg_dump "$DATABASE_URL" \
  --format=custom \
  --file="backup_$(date +%Y%m%d_%H%M%S).dump"
```

### Full cluster / physical recovery

For production PostgreSQL installations, combine regular base backups with WAL archiving when point-in-time recovery (PITR) is required.

Recommended policy:

- Daily automated logical backup.
- Regular physical/base backups for production recovery.
- Continuous WAL archiving for PITR where business requirements justify it.
- Keep multiple backup generations.
- Store at least one backup copy outside the primary database host.
- Encrypt backup storage and restrict access.
- Test restoration regularly.

## Disaster recovery runbook

1. Identify the incident and stop unsafe application writes.
2. Preserve logs and determine the recovery point.
3. Provision a clean PostgreSQL environment.
4. Restore the latest valid base/logical backup.
5. Replay WAL when PITR is configured and required.
6. Verify schema, row counts, constraints, indexes, and application connectivity.
7. Run smoke tests.
8. Redirect application traffic.
9. Monitor errors and replication/recovery status.
10. Document the incident and update the recovery procedure.

## Backup validation

A backup is not considered reliable until restoration has been tested.

Example:

```bash
createdb recovery_test
pg_restore \
  --dbname=recovery_test \
  --clean \
  --if-exists \
  latest.dump
```

Then verify:

```sql
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM orders;
SELECT COUNT(*) FROM order_items;
SELECT COUNT(*) FROM inventory;
```

Also verify:

```sql
SELECT * FROM customer_order_summary LIMIT 10;
SELECT * FROM mv_daily_sales LIMIT 10;
```

## Security recommendations

- Do not commit passwords, connection strings, or `.env` files.
- Use environment variables or a secrets manager.
- Give the application database user only the privileges it requires.
- Restrict backup access to trusted operators.
- Encrypt backups at rest and in transit.
- Rotate backup credentials.
- Audit restore operations.

## Production checklist

- [x] Version-controlled up/down migrations
- [x] Core relational schema
- [x] Stored procedure for order placement
- [x] Inventory row locking
- [x] Audit trigger and audit table
- [x] Reporting view
- [x] Materialized analytical view
- [x] Backup script
- [x] Restore script
- [x] Disaster recovery guide
- [x] Backup validation procedure
- [x] Security guidance

> This repository is a capstone/reference architecture. Before production deployment, adapt retention, RPO/RTO, access control, monitoring, encryption, and operational procedures to the organization's requirements.
