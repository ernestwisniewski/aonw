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

## Multiplayer Presence Cleanup Is Not Retention

Multiplayer maintenance also reconciles expired lobby-presence leases in
bounded pages. That work keeps the active roster and discovery projection true;
it does not physically delete match history:

- an expired guest is removed from an open hosted roster;
- expiry of an open hosted owner changes the match to `abandoned`;
- expired quickplay members are removed, and an empty queue becomes
  `abandoned`;
- an expired running-match member becomes `offline` without losing membership.

An abandoned lobby is a soft delete from the active product surface. It is
immediately excluded from discovery and matchmaking, rejects joins, and sends a
terminal update to subscribed clients. Its match row, terminal snapshot, and
event history remain persisted. Player rows removed as part of an authoritative
roster mutation are a lifecycle state change, not an age-based retention purge.
The durable, recurring maintenance schedule and its bounded paginated sweeps
are lifecycle correctness mechanisms, not a retention deadline.

Presence-lease rows are server-only operational records. They are removed when
the corresponding lobby membership ends and cascade with the match; they are
not retained as gameplay or audit history.

Running-match inactivity is a lifecycle deadline, not physical retention. A
match is changed to `abandoned/all_players_inactive` after 12 hours without
human activity. The terminal row, snapshot, and event history remain stored.
Automated turn processing and AI work do not extend this deadline.

The implementation sources of truth are:

- `server/config/*.yaml` for Serverpod session-log limits;
- `server/lib/src/auth/auth_maintenance_service.dart` for authentication
  retention cutoffs and batch bounds;
- `server/lib/src/auth/auth_maintenance_future_call.dart` for scheduling and
  backlog follow-ups;
- `server/lib/src/multiplayer/models/game_match_presence_lease.spy.yaml` for the
  server-only durable lobby-presence record;
- `server/lib/src/multiplayer/multiplayer_match_store_presence.dart` for bounded
  expiry pages and generation-checked targeted lease writes.
- `server/lib/src/multiplayer/match_lifecycle_service_presence.dart` for the
  lifecycle-specific expiry decisions and post-commit notifications;
- `server/lib/src/multiplayer/multiplayer_turn_timeout_future_call.dart` for
  the reconciled ten-second multiplayer maintenance schedule shared by turn
  timeout and presence sweeps.

## Data Without Automatic Retention

The following persisted data currently has no automatic physical age-based or
count-based deletion policy:

- authentication accounts and account profiles;
- multiplayer matches and their player records;
- multiplayer snapshots;
- multiplayer event history.

Finishing, abandoning, resigning from, leaving, or expiring presence from a
multiplayer match does not by itself establish a database retention deadline.
Removing an expired open-lobby member changes the active roster, and abandoning
a room removes it from active discovery, but neither operation physically
deletes the match aggregate. Pagination and bounded queries limit how much data
one maintenance invocation processes; they do not delete terminal records.

There is currently no user-facing account-deletion flow in this repository.
Signing out revokes a session and clears local credentials; it must not be
described as deleting an account or profile.

Introducing destructive retention for accounts, profiles, matches, snapshots,
or events requires an explicit product and privacy decision. That decision
must define at least the intended retention period, treatment of active and
finished or abandoned matches, recovery and support requirements,
related-record cleanup, backup handling, and any player-facing controls or
notices. A future terminal-match purge must preserve enough time for
disconnected lobby clients to observe the authoritative terminal result and
must delete related snapshots, events, and player rows transactionally. Do not
infer such a period from presence-lease or maintenance timing.

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
