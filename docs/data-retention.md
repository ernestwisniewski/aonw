# Data retention

This page records automatic deletion currently implemented by the repository. It is an operational inventory, not a privacy policy. Backups are separate copies with their own lifecycle.

## Automatic retention

| Data | Rule |
| --- | --- |
| Serverpod session logs | 90 days or 100,000 rows, whichever limit is reached first. |
| JWT refresh tokens | Configured token lifetime plus 7 days. |
| Steam authentication requests | 7 days after `expiresAt`. |
| Authentication rate-limit attempts | 7 days after `attemptedAt`. |

Authentication maintenance runs every six hours in bounded batches. Backlogs schedule a short follow-up rather than allowing one job to monopolize the server.

## Lifecycle cleanup is not retention

Lobby presence maintenance may remove an expired guest, abandon a hosted lobby whose owner expired, or mark a running participant offline. These changes remove stale rooms and seats from active product surfaces, but they do not physically delete match history.

A running match is marked `abandoned/all_players_inactive` after 12 hours without human activity. Its match row, snapshot, players, and event history remain stored.

## Data without automatic age-based deletion

The repository currently has no automatic physical retention deadline for:

- accounts and profiles;
- multiplayer matches and player rows;
- snapshots;
- event history.

There is also no user-facing account-deletion flow. Signing out revokes the session and clears local credentials; it does not delete the account.

A destructive retention policy for these records requires a product and privacy decision, transactional cleanup rules, recovery/support requirements, and an explicit backup policy.

## Backups

`deploy/postgres/backup.sh` keeps local dump files for 14 days by default. `AONW_BACKUP_RETENTION_DAYS` overrides the value. The script does not create an offsite copy.

Production and staging backups must be stored on durable storage or copied elsewhere. See [PostgreSQL backup and restore](postgres-backup.md).

## Sources

- `server/config/*.yaml`
- `server/lib/src/auth/auth_maintenance_service.dart`
- `server/lib/src/auth/auth_maintenance_future_call.dart`
- `server/lib/src/multiplayer/match_lifecycle_service_presence.dart`
- `server/lib/src/multiplayer/multiplayer_turn_timeout_future_call.dart`
- `deploy/postgres/backup.sh`

Update this document whenever a cutoff, maintenance cadence, batch limit, or covered data category changes.
