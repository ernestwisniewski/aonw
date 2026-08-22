# AoNW Rust client

This `package_ffi` package exposes the same current-only JSON client protocol
used by the Godot GDExtension. Native calls run on a dedicated helper isolate.
`AonwClientRequest`, `AonwClientResponse`, and the `AonwRustSession.send`
extension provide the typed Dart boundary. Snapshots, queries, command results,
map views, events, evidence, patches, stamps, and persistence responses are
parsed into strict read models; command acceptance is a tagged
accepted/rejected outcome. `inspectMap` exposes the same validated map identity
and presentation semantics as the Godot client.
Raw JSON remains confined to the transport. Rust, Dart, and
Godot consume the same committed protocol goldens.

Normal Flutter builds compile a small unavailable stub and keep the Dart local
engine active. Set `AONW_ENABLE_RUST_FLUTTER=1` to build and bundle the host
Rust adapter for tests and development. Unsupported targets remain on the Dart
fallback until their Rust toolchain and packaging are qualified.

The package does not yet implement the app's authoritative `LocalEnginePort`.
The current recipient patch intentionally cannot reconstruct every field of the
full Dart `DomainState`; treating it as a handled transport result would lose
canonical state. The native package remains opt-in until the complete-state
cutover mapper and persistence parity gate are implemented.

Run `make rust-flutter-test` from the repository root to verify both lanes. The
native session accepts only `aonw_contracts::client` JSON and does not expose
canonical state or raw Rust pointers to Flutter code.
