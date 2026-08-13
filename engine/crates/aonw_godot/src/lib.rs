//! Godot-only adapter around validated content and the deterministic engine.

mod bridge;
mod local_session;
mod wire;

mod extension_entrypoint {
    #![allow(unsafe_code)]

    use godot::prelude::*;

    struct AonwGodotExtension;

    // SAFETY: Godot requires this marker implementation to register the extension entrypoint.
    #[gdextension]
    unsafe impl ExtensionLibrary for AonwGodotExtension {}
}
