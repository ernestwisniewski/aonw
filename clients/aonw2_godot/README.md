# AoNW2 Godot Client

This directory reserves the Godot 3D AoNW2 presentation client. A Godot project
and native extension are deliberately not scaffolded in the initial pure-Rust
foundation change.

The client will own:

- Godot scenes, GDScript presentation, input mapping, camera, rendering, UI,
  animation, audio, shaders, localization, and client assets;
- a thin `aonw_godot` GDExtension adapter for local sessions;
- a recipient-scoped remote replica for Serverpod multiplayer.

It must not implement or approximate authoritative game rules in scenes,
GDScript, shaders, or network reconciliation. Local play will call the shared
Rust runtime; remote play will consume recipient-safe state and evidence only.

The future structure is documented in the
[Rust migration plan](../../docs/rust-engine-migration.md). Add `project.godot`,
`scenes/`, `scripts/`, `addons/aonw_native/`, `shaders/`, `assets/`, and `tests/`
only with their first executable vertical slice.
