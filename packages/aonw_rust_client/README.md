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

Consumers omit the hook setting to compile a small unavailable stub. A native
consumer that requires Rust declares the cache-aware setting below in its
`pubspec.yaml`:

    hooks:
      user_defines:
        aonw_rust_client:
          rust_backend: true

The successor client sets this unconditionally, so it has no Dart engine or
per-request fallback. Unsupported targets report the typed adapter-unavailable
state until their Rust toolchain and packaging are qualified.

The package does not yet implement the app's authoritative `LocalEnginePort`.
The current recipient patch intentionally cannot reconstruct every field of the
full Dart `DomainState`; treating it as a handled transport result would lose
canonical state. The native package remains opt-in until the complete-state
cutover mapper and persistence parity gate are implemented.

Run `make rust-flutter-test` from the repository root to verify both lanes. The
native session accepts only `aonw_contracts::client` JSON and does not expose
canonical state or raw Rust pointers to Flutter code.
