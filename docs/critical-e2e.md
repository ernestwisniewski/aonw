# Critical end-to-end journeys

Two stateful journeys protect boundaries that unit tests do not cover completely.

Canonical entry points:

- `test/game/local_game_persistence_flow_test.dart`
- `tool/run_serverpod_critical_e2e.sh`
- `tool/run_postgres_smoke.sh`
- `tool/allocate_loopback_port_triplet.dart`
- `test/tool/allocate_loopback_port_triplet_test.dart`
- `tool/serverpod_critical_e2e.dart`
- `server/test/support/critical_e2e_server.dart`
- `server/test/support/critical_e2e_server_config.dart`
- `server/test/support/critical_e2e_loopback_io_overrides.dart`
- `server/test/critical_e2e_server_config_test.dart`
- `server/test/critical_e2e_loopback_io_overrides_test.dart`

| Journey | Real boundary | Test |
| --- | --- | --- |
| Local save and reload | use cases, command transport, event log, snapshot store, fresh runtime | `test/game/local_game_persistence_flow_test.dart` |
| Public multiplayer | auth, JWT refresh, PostgreSQL, generated client, two accounts, idempotent Rust command, restart and private resync | `tool/serverpod_critical_e2e.dart` |

```mermaid
flowchart LR
  subgraph Local["Local save and reload"]
    L1["Create runtime"] --> L2["Dispatch deterministic commands"] --> L3["Persist event log + snapshot"] --> L4["Replace runtime"] --> L5["Bootstrap / replay"] --> L6["Assert durable state"]
  end

  subgraph Online["Public multiplayer"]
    O1["Authenticate two accounts"] --> O2["Create and join match"] --> O3["Submit idempotent Rust command"] --> O4["Persist in PostgreSQL"] --> O5["Restart server + resync"] --> O6["Assert private snapshots and offsets"]
  end
```

Both journeys use deterministic commands and assert durable state. They do not treat widget internals, fixed delays, or injected authentication as evidence.

## Commands

```sh
make local-game-e2e-test
make serverpod-critical-e2e-test
make critical-e2e-test
```

This is the default sequence for critical journeys:

- The public HTTP Serverpod surface is covered by `tool/run_serverpod_critical_e2e.sh` and verified by `serverpod-critical-e2e-test`.
- The harness uses fresh per-run secrets and a cryptographic per-run nonce during database and token initialization.
- The run is bounded, proxy-free, and fails closed when one of the required listeners or processes cannot be launched.
- The database URL must stay local and isolated: `aonw@localhost:$AONW_TEST_DATABASE_PORT/aonw_test`.
- The run maps all three wildcard binds to IPv4 loopback, and each process has a uniquely named Compose project for isolated teardown.

The Serverpod journey needs a provisioned `aonw_test` database. The release-safe wrapper creates an isolated PostgreSQL project and runs the complete server smoke:

```sh
tool/run_postgres_smoke.sh
```

The harness binds all test listeners to IPv4 loopback, creates fresh auth secrets, selects isolated ports, and tears down the exact child process on failure.

Operationally this includes:

- `test/game/local_game_persistence_flow_test.dart`
- `tool/allocate_loopback_port_triplet.dart`
- `test/tool/allocate_loopback_port_triplet_test.dart`
- `server/test/support/critical_e2e_server_config.dart`
- `server/test/support/critical_e2e_loopback_io_overrides.dart`
- `server/test/critical_e2e_server_config_test.dart`
- `server/test/critical_e2e_loopback_io_overrides_test.dart`

## Failure ownership

- failure before local runtime replacement: creation, dispatch, or persistence;
- failure after replacement: bootstrap or replay;
- auth/HTTP failure: session boundary;
- command-outcome/history mismatch: idempotency or storage;
- restart/resync mismatch: recipient projection, catch-up, or token rotation.

Add focused tests for narrower behavior, but keep these journeys at the real persistence and transport boundaries.
