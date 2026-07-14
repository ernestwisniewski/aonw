# Critical End-to-End Journeys

The critical E2E gate protects the two stateful journeys whose boundaries are
not fully represented by unit tests: saving a local game across a fresh
runtime, and completing a multiplayer turn through the public Serverpod API.
Both journeys use deterministic commands and assert durable state rather than
widget internals, implementation-specific JSON, or fixed delays.

## Protected Journeys

| Journey | Real boundaries | Contract proved |
| --- | --- | --- |
| Local persistence | application use cases, local command transport, JSON game repository, event log, and snapshot store | a created game accepts a command and reloads with the same state and event offset after every runtime object is replaced |
| Public multiplayer | HTTP authentication, JWT refresh, PostgreSQL, generated client, WebSocket stream, command endpoint, and reconnect | two real accounts can start a match, submit an idempotent command, reconnect with a fresh authenticated client, and converge on persisted offsets |

The local journey lives in
`test/game/local_game_persistence_flow_test.dart`. It creates a game in a
temporary directory, bootstraps it, dispatches a deterministic fortify
command, discards the runtime, and rebuilds every persistence adapter before
loading the game again. The final assertions cover the save listing, event
history, event offset, and fortified unit state.

The multiplayer journey lives in `tool/serverpod_critical_e2e.dart`. The shell
harness starts `server/test/support/critical_e2e_server.dart` in Serverpod test
mode on an isolated port and drives the public HTTP and WebSocket surfaces. It
creates then signs in two accounts, starts a match, retries one command with
the same client message id, verifies a single persisted event, refreshes authentication,
and reconnects through a newly constructed client. Assertions wait for
positive protocol messages and exact history; elapsed time is never used as
proof that an event did not occur.

## Canonical Commands

Run the filesystem-backed journey while developing local game persistence:

```sh
make local-game-e2e-test
```

Run the complete hermetic PostgreSQL gate, including the public Serverpod
journey, against a fresh isolated database:

```sh
tool/run_postgres_smoke.sh
```

When `aonw_test` is already provisioned locally or by CI, run only the public
Serverpod journey, or both critical journeys, with:

```sh
make serverpod-critical-e2e-test
make critical-e2e-test
```

The focused live harness uses `aonw_test` on local PostgreSQL and automatically
selects a free contiguous IPv4-loopback port triplet immediately before it
starts the server. API, Insights, and web use the base, base + 1, and base + 2.
An explicit base-port override is available when a caller already owns a safe
triplet. The database port defaults to `5432`, but is explicit so the release
smoke can use an ephemeral Compose port:

```sh
AONW_SERVERPOD_CRITICAL_E2E_PORT=19080 \
AONW_TEST_DATABASE_PORT=5432 \
SERVERPOD_TEST_DATABASE_PASSWORD=aonw_dev \
make serverpod-critical-e2e-test
```

When no API-port override is supplied,
`tool/run_serverpod_critical_e2e.sh` uses
`tool/allocate_loopback_port_triplet.dart` to select three available ports and
atomically locks all three port numbers before releasing the probe sockets.
The lock set remains owned until the exact server child terminates, so concurrent
harness runs cannot select the same triplet during the socket handoff. The
server is launched immediately after allocation. An explicit override is
validated and passed through the wrapper's sanitized nested Make environment;
the caller is then responsible for reserving that triplet.

The API, Insights, and web listeners occupy the selected port and the next two
ports. A dedicated `IOOverrides` adapter validates Serverpod's expected socket
calls and maps all three wildcard binds to IPv4 loopback. The live scenario
then probes every non-loopback IPv4 interface and fails if any listener is
reachable through it. On a host without such an interface the runtime probe is
reported as skipped; the adapter contract remains covered by focused tests.

The harness fails if the child server exits or does not become live, prints its
captured log on failure, and always terminates the exact child process. A
cryptographic per-run nonce is written to that process's private log only after
the ordinary Serverpod bootstrap has started. Readiness requires both that
owned marker and a bounded, proxy-free `/livez` response, so a stale or foreign
listener cannot satisfy the probe. The harness creates fresh per-run secrets
for the service, email hash, JWT signing, and refresh-token hash boundaries, so
focused executions neither share authentication material nor a persistent
rate-limit bucket. Generic inherited Serverpod service and authentication
secrets are deliberately ignored. The only accepted credential input is the
dedicated local test database password (`AONW_TEST_DATABASE_PASSWORD`, then
`SERVERPOD_TEST_DATABASE_PASSWORD`), with a local-development fallback.

The dedicated server entry point loads the final environment-derived
`ServerpodConfig` and fails closed before binding a listener. It accepts no
configuration arguments and requires test mode, a monolith role, migrations
enabled, repair migrations and future calls disabled, Redis disabled, all
three public/listen addresses on IPv4 loopback, and the exact local PostgreSQL
target
`aonw@localhost:$AONW_TEST_DATABASE_PORT/aonw_test` without SSL or a Unix
socket. Configuration drift toward another database, host, role, or run mode
aborts the journey instead of risking an external environment. The harness
does not read `.env` or contact a deployed service. These invariants live in
`server/test/support/critical_e2e_server_config.dart` and are covered by
`server/test/critical_e2e_server_config_test.dart`. The bind adapter lives in
`server/test/support/critical_e2e_loopback_io_overrides.dart` and is covered by
`server/test/critical_e2e_loopback_io_overrides_test.dart`.

For the complete PostgreSQL release gate, use:

```sh
tool/run_postgres_smoke.sh
```

That script creates a uniquely named Compose project with a fresh volume,
random PostgreSQL password and random database host port. Its delegated live
harness independently allocates and locks an API/Insights/web triplet bound
only to `127.0.0.1` immediately before starting Serverpod.
It waits for a successful authenticated PostgreSQL query over TCP, rather than
mistaking the temporary Unix-socket server used by `initdb` for readiness. It
then creates `aonw_test`, runs every Serverpod integration smoke, and delegates
to `make serverpod-critical-e2e-test` with the isolated credential. On
failure it prints the isolated service state and bounded PostgreSQL logs before
its exit trap removes the containers and volume. It does not reuse the normal
`aonw` Compose project or its database volume.
`make release-check` invokes the same script after the repository-wide quality
and configuration gates.

## CI Ownership

The local persistence test is a normal Flutter test and therefore runs in the
root coverage job as well as through its focused Make target. The
`server-integration` CI job owns the live journey because it provides the
ephemeral PostgreSQL service. Keep the workflow delegated to the Make target
so local, CI, and release executions use the same server harness and secrets.

When either journey fails, preserve the first failing boundary in the report:

- a local failure before runtime replacement points to creation, command
  dispatch, or persistence;
- a local failure after replacement points to replay or bootstrap;
- an HTTP/auth failure precedes multiplayer state creation;
- an ACK or exact-history failure points to command idempotency or storage;
- a reconnect snapshot mismatch points to stream catch-up or token rotation.

Do not weaken these journeys with injected authentication, fake repositories,
reused reconnect clients, arbitrary sleeps, or broad retry loops. Add focused
tests for narrower behavior, but keep this gate at the real process and
persistence boundaries.
