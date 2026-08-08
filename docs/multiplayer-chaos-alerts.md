# Multiplayer Serverpod Smoke And Alerts

Use this as the release gate for multiplayer changes that touch networking,
persistence, or command dispatch.

## Real PostgreSQL And Stream Smoke

Run the local Serverpod integration smoke:

```sh
tool/run_postgres_smoke.sh
```

The script starts PostgreSQL in a uniquely named Compose project with a fresh
volume, random password, and random loopback-only host port. It creates
`aonw_test`, runs every `make server-integration-test` smoke, and then delegates
to `make serverpod-critical-e2e-test`. Its exit trap removes the isolated
containers and volume. The integration layer applies Serverpod migrations in
test mode and verifies endpoint dispatch and persistence inside the test
harness.

The critical E2E layer starts a separate test-mode server and uses only its
public HTTP and WebSocket surfaces. It signs in real accounts, creates and
starts a persisted match, retries the same `clientMessageId` without creating a
second event, rotates authentication, and catches up from an old event offset
with a fresh client. All three test-server listeners are forced onto IPv4
loopback and probed from non-loopback interfaces. See
[Critical End-to-End Journeys](critical-e2e.md) for the complete contract and
focused commands.

## Quickplay Lobby Smoke

Before release, verify the Serverpod quickplay lobby contract:

1. Create or reuse two signed-in accounts with different selected countries.
2. Join quickplay with the first account and confirm it changes from
   `connecting` to `connected`; keep it waiting for longer than one minute and
   verify heartbeat renewal prevents age-only abandonment.
3. Join quickplay with the second account and confirm a 30-second countdown
   starts only after both players are connected.
4. Re-enter quickplay from the same account after changing country and confirm
   the existing player tile updates to the new country instead of staying on an
   old default.
5. Join two more accounts and confirm the fourth human starts the match
   immediately only when the complete human roster is connected.
6. Close one of two streams owned by the same account and confirm presence does
   not change. Close its last stream and confirm the member becomes
   `reconnecting` and the countdown is cancelled.
7. Reconnect within the 10-second grace and confirm the same seat is restored
   and a new countdown begins. Repeat without reconnecting and confirm the
   expired member is removed and technical ownership is transferred safely.
8. Stop every client in a quickplay queue. Durable maintenance must abandon the
   empty queue without another matchmaking request; a later join must create or
   select a healthy queue without a stale country or seat.

## Open-Lobby Presence And Expiry Drill

Use two accounts and run the hosted cases for both public and private lobbies:

1. Create the lobby, join as a guest, and verify start is available only while
   every human roster member is `connected`.
2. Stop the guest's last stream. Verify `reconnecting` is broadcast and start is
   blocked. Restore the stream within 10 seconds and confirm the seat survives.
3. Stop it again and let grace expire. The guest must be removed from the roster
   and its country/seat must be reusable without a new discovery request.
4. Stop the host's last stream and restore it within grace. The room remains
   open. Repeat without reconnecting: the room becomes `abandoned`, disappears
   from discovery, rejects joins, and returns the guest to the previous screen.
5. Prevent a newly created or joined client from opening its stream. Confirm the
   20-second initial-connect lease expires with the same guest/host outcomes.
6. While a reconnect and expiry are racing, restore the connection. A delayed
   callback from the old stream must not replace the new 30-second lease or evict
   the member.

Abandonment is a soft delete. Inspect PostgreSQL after the drill: the terminal
match remains available for audit/recovery policy, while public discovery and
matchmaking no longer return it.

## Manual Reconnect Drill

1. Start the staging stack.
2. Open two clients in an open lobby, wait for at least one heartbeat, and then
   start a second pair in a running match and submit a command.
3. Send `SIGTERM` to the active server container so the process-local subscriber
   and stream-count registries disappear without graceful disconnect callbacks.
4. Verify `/readyz` stops receiving new traffic while `/livez` remains healthy.
5. Verify the open-lobby clients reconnect within the durable lease window and
   renew presence instead of losing their seats or abandoning the room.
6. Verify running-match clients converge to the latest snapshot and event offset
   after resuming from background or a hidden browser tab; running membership is
   retained even if its presence later becomes `offline`.
7. Inspect the server logs for expected auth sessions, presence renewals, stream
   reconnects, and no repeated command rejects or duplicate terminal mutations.

## Maintenance Recovery And Backlog Drill

1. Create more expired initial/reconnect leases than fit in one configured
   maintenance page, mixing hosted guests, hosted owners, and quickplay members.
2. Stop the server after one bounded page commits, then restart it.
3. Confirm the reconciled maintenance FutureCall is restored without duplicate
   schedules and drains the remaining pages through bounded follow-ups.
4. Renew one candidate concurrently with a sweep and verify the locked deadline
   and generation recheck turns that stale candidate into a no-op.
5. Force one candidate transaction to fail. Other candidates must continue, no
   state may be broadcast before commit, and the failed candidate must remain
   eligible for a later sweep.
6. Confirm expired hosted rooms and empty quickplay queues are absent from
   discovery throughout recovery, while terminal rows remain physically stored
   under the documented retention policy.

## Alert Rules

Prometheus starter rules live in
`deploy/prometheus/aonw-alerts.yml`. They cover:

- API liveness probe failure;
- API readiness probe failure.

The rule file is configuration, not a running monitoring stack. It only becomes
effective after an operator deploys Prometheus, configures blackbox probe jobs
with the expected `job` labels, loads the rule file, and connects Alertmanager
to a tested notification route. Until those pieces exist, `/livez` and
`/readyz` remain release checks but no automated alert is delivered.

Tune thresholds after the first TestFlight sessions produce baseline traffic,
and record a successful synthetic alert before treating monitoring as a
production control.
