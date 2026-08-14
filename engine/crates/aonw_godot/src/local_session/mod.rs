use aonw_local_runtime::{ClientProtocol, LocalRuntime};
use godot::classes::{IRefCounted, RefCounted};
use godot::prelude::*;

#[derive(GodotClass)]
#[class(base=RefCounted)]
struct AonwLocalSession {
    runtime: LocalRuntime,
    base: Base<RefCounted>,
}

#[godot_api]
impl IRefCounted for AonwLocalSession {
    fn init(base: Base<RefCounted>) -> Self {
        Self {
            runtime: LocalRuntime::default(),
            base,
        }
    }
}

#[godot_api]
#[allow(clippy::needless_pass_by_value)]
impl AonwLocalSession {
    #[func]
    fn request_json(&mut self, request_json: GString) -> GString {
        let response = dispatch_json(&mut self.runtime, &request_json.to_string());
        GString::from(response.as_str())
    }
}

fn dispatch_json(runtime: &mut LocalRuntime, input: &str) -> String {
    ClientProtocol::dispatch_json(runtime, input)
}

#[cfg(test)]
mod tests;
