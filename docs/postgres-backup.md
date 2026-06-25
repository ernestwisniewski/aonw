# PostgreSQL Backup And Restore

Production and TestFlight staging data must be recoverable without relying on
the Docker volume alone. Use custom-format `pg_dump` backups plus a periodic
restore test.

## Backup

Run the backup from a host that has network access to PostgreSQL and PostgreSQL
client tools installed:

```sh
DATABASE_URL="$AONW_PRODUCTION_DATABASE_URL" \
AONW_BACKUP_DIR=/var/backups/aonw/postgres \
AONW_BACKUP_RETENTION_DAYS=14 \
deploy/postgres/backup.sh
```

The script writes `aonw-<utc timestamp>.dump` and a matching `.sha256` file. It
deletes backups older than `AONW_BACKUP_RETENTION_DAYS`.

Suggested cron:

```cron
17 3 * * * cd /srv/aonw && DATABASE_URL="$AONW_PRODUCTION_DATABASE_URL" AONW_BACKUP_DIR=/var/backups/aonw/postgres deploy/postgres/backup.sh
```

Store the backup directory on durable storage or sync it to object storage. Do
not keep the only copy on the same ephemeral disk as the database.

## Restore Test

At least once per release, restore the newest dump into an empty throwaway
database:

```sh
latest="$(ls -1t /var/backups/aonw/postgres/aonw-*.dump | head -1)"
AONW_RESTORE_DATABASE_URL="$AONW_EMPTY_RESTORE_DATABASE_URL" \
deploy/postgres/restore.sh "$latest"
```

The restore script refuses to write to `DATABASE_URL` unless
`AONW_RESTORE_ALLOW_PROD=true` is set, then runs `pg_restore` and verifies that
`serverpod_migrations` is readable.

## Emergency Restore

1. Stop the Serverpod server or block writes at the load balancer.
2. Create or choose the target database.
3. Run `deploy/postgres/restore.sh <backup.dump>` with
   `AONW_RESTORE_DATABASE_URL` pointing at the target.
4. Start the server and check `/livez`, `/readyz`, `/startupz`, Insights, and
   a known match load.
5. Keep the backup file and restore logs until the incident is closed.
