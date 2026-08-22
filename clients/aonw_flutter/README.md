# AoNW Flutter Client

This directory is the final location of the successor Flutter presentation
client. M1.2 introduces only its framework-free `oddQFlatTop` geometry so both
clients can execute the same neutral vectors. M1.3 creates the standalone app,
package manifest, and platform shell around it.

The active, buildable, and releasable Flutter application remains at the
repository root throughout the migration. Do not move or duplicate its `lib/`,
platform directories, assets, tests, or release tooling here. Successor code is
implemented vertically and must not alter the current Flutter build.

In the target architecture this client owns:

- Flutter presentation;
- input, camera, selection, interaction state, animation, and accessibility;
- application orchestration and native/remote adapters;
- platform packaging and client-specific assets.

It does not own movement, combat, economy, fog-of-war, turn, AI, save, or replay
rules. Local rules will be consumed from `engine/` through a coarse native or
WASM adapter; multiplayer remains a recipient-scoped Serverpod client.

Cross-client geometry evidence lives in
`aonw_tests/fixtures/geometry/odd_q_flat_top.v1.json`.
