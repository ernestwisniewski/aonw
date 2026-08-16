# Multiplayer release smoke and failure drills

Use these checks for changes to multiplayer networking, persistence, lobby lifecycle, or command dispatch.

## Automated gate

```sh
tool/run_postgres_smoke.sh
```

The script creates an isolated PostgreSQL project, applies migrations, runs server integration tests, and executes the public HTTP/WebSocket journey from [critical-e2e.md](critical-e2e.md). It removes its containers and volume on exit.

## Manual lobby checks

Use at least two accounts.

Hosted lobby:

- start is available only when every human roster member is `connected`;
- disconnecting the last guest stream enters reconnecting state and blocks start;
- reconnect within the grace period keeps the same seat;
- guest expiry frees the seat;
- host expiry abandons the lobby, removes it from discovery, rejects joins, and returns guests to the previous screen;
- creating or joining without ever opening the stream reaches the same result after the initial-connect lease.

Quickplay:

- one connected player may wait indefinitely while heartbeats renew the lease;
- the countdown starts only when the complete human roster is connected;
- disconnect cancels the countdown;
- reconnect starts a fresh countdown;
- an expired member is removed and ownership is transferred safely;
- an empty queue becomes abandoned without requiring another matchmaking request.

## Restart drill

1. Keep one open lobby and one running match active.
2. Stop the active server process without graceful stream callbacks.
3. Confirm open-lobby clients reconnect and renew durable presence within the lease window.
4. Confirm running clients load the latest projected snapshot and converge on the same offset.
5. Confirm accepted commands are not duplicated and terminal lobby mutations occur once.

## Maintenance backlog drill

Create more expired leases than one maintenance page can hold, restart after a partial sweep, and verify that bounded follow-ups continue. A concurrent heartbeat must make a stale candidate a no-op after the generation/deadline recheck. One candidate failure must not stop the rest of the page.

## Alerts

Starter Prometheus rules live in `deploy/prometheus/aonw-alerts.yml` and cover API liveness and readiness probes.

The file is not a deployed monitoring system. Alerts are operational only after Prometheus, a blackbox probe, Alertmanager, and a tested notification route are configured. Record a successful synthetic alert before treating this as a production control.
