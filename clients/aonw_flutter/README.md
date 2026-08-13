# AoNW Flutter Client

This directory reserves the final location of the Flutter/Flame AoNW1
presentation client.

The active, buildable, and releasable Flutter application remains at the
repository root throughout the Rust migration. Do not move or duplicate its
`lib/`, platform directories, assets, tests, or release tooling here until the
Dart engine retirement gates pass. Keeping this placeholder must not alter any
current Flutter build.

In the target architecture this client owns:

- Flutter and Flame presentation;
- input, camera, selection, interaction state, animation, and accessibility;
- application orchestration and native/remote adapters;
- platform packaging and client-specific assets.

It does not own movement, combat, economy, fog-of-war, turn, AI, save, or replay
rules. Local rules will be consumed from `engine/` through a coarse native or
WASM adapter; multiplayer remains a recipient-scoped Serverpod client.

See the [Rust migration plan](../../docs/rust-engine-migration.md) before adding
files below this directory.
