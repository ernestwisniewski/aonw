# Data Retention

This document records the automatic retention behavior currently implemented
by Age of New Worlds. It is an operational inventory, not a privacy policy or
a promise that every copy of data is deleted on the schedules below. Database
backups are separate copies and require their own storage and lifecycle policy.

## Current Automatic Retention

| Data | Current rule | Notes |
| --- | --- | --- |
| Serverpod session logs | 90 days or 100,000 records, whichever limit is reached first | Database-backed development, test, staging, and production modes use the same limits. |
| JWT refresh tokens | Configured refresh-token lifetime plus a 7-day grace period | The lifetime comes from the active JWT configuration. Rotation updates the token record used to calculate eligibility. |
| Steam authentication requests | 7 days after `expiresAt` | Expired request rows become eligible for maintenance after the grace period. |
| Authentication rate-limit attempts | 7 days after `attemptedAt` | Maintenance applies to the Age of New Worlds authentication rate-limit domain. |

Authentication maintenance is scheduled every 6 hours. Work is bounded to 500
rows per batch and 10 batches per target in one invocation. If a target still
has a backlog after reaching that budget, the scheduler requests a follow-up
after 1 minute instead of allowing one maintenance run to monopolize a server
process.

The implementation sources of truth are:

- `server/config/*.yaml` for Serverpod session-log limits;
- `server/lib/src/auth/auth_maintenance_service.dart` for authentication
  retention cutoffs and batch bounds;
- `server/lib/src/auth/auth_maintenance_future_call.dart` for scheduling and
  backlog follow-ups.

## Data Without Automatic Retention

The following persisted data currently has no automatic age-based or
count-based deletion policy:

- authentication accounts and account profiles;
- multiplayer matches and their player records;
- multiplayer snapshots;
- multiplayer event history.

Finishing, abandoning, resigning from, or leaving a multiplayer match does not
by itself establish a database retention deadline. Pagination and bounded
queries limit how much data one request processes; they do not delete the
underlying records.

There is currently no user-facing account-deletion flow in this repository.
Signing out revokes a session and clears local credentials; it must not be
described as deleting an account or profile.

Introducing destructive retention for accounts, profiles, matches, snapshots,
or events requires an explicit product and privacy decision. That decision
must define at least the intended retention period, treatment of active and
finished matches, recovery and support requirements, related-record cleanup,
backup handling, and any player-facing controls or notices. Do not infer these
rules from the operational cleanup policies above.

## PostgreSQL Backups

`deploy/postgres/backup.sh` keeps local backup files for 14 days by default.
`AONW_BACKUP_RETENTION_DAYS` can override that value. The script only creates
and prunes dumps and checksum files in its configured backup directory; it does
not create a durable or offsite copy.

Production and staging backups must be stored on durable storage or copied to
an offsite or object-storage destination. The only backup copy must not live on
the same ephemeral host or disk as PostgreSQL. See
[PostgreSQL Backup And Restore](postgres-backup.md) for the backup and restore
procedure.

Any future destructive data policy must address backup copies separately,
including how long they remain recoverable and how deletion obligations are
handled after a restore.

## Keeping This Document Current

Update this document in the same change whenever a retention cutoff, batch
budget, maintenance cadence, backup default, or covered data category changes.
Operational configuration and automated checks remain authoritative when they
disagree with prose; treat any disagreement as documentation drift that must
be corrected before release.
