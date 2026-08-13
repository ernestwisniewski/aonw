//! Godot-only adapter around validated content and the deterministic engine.

mod bridge;
mod local_session;
mod wire;

use godot::prelude::*;

struct AonwGodotExtension;

#[gdextension]
unsafe impl ExtensionLibrary for AonwGodotExtension {}
