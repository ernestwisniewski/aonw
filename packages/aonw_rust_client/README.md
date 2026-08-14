# AoNW Rust client

This `package_ffi` package exposes the same current-only JSON client protocol
used by the Godot GDExtension. Native calls run on a dedicated helper isolate.

Normal Flutter builds compile a small unavailable stub and keep the Dart local
engine active. Set `AONW_ENABLE_RUST_FLUTTER=1` to build and bundle the host
Rust adapter for tests and development. Unsupported targets remain on the Dart
fallback until their Rust toolchain and packaging are qualified.

Run `make rust-flutter-test` from the repository root to verify both lanes. The
native session accepts only `aonw_contracts::client` JSON and does not expose
canonical state or raw Rust pointers to Flutter code.
