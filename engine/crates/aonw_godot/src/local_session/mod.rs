use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientErrorDto, ClientOutcomeDto, ClientRequestDto, ClientResponseDto,
};
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
    let response = match ClientRequestDto::from_json(input) {
        Ok(request) => ClientProtocol::dispatch(runtime, request),
        Err(error) => ClientResponseDto {
            api_version: CLIENT_API_VERSION,
            outcome: ClientOutcomeDto::Failure {
                error: ClientErrorDto {
                    code: "invalid_client_request".to_owned(),
                    message: error.to_string(),
                },
            },
        },
    };
    response.to_json().unwrap_or_else(|_| {
        format!(
            r#"{{"apiVersion":{CLIENT_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"adapter_serialization_failed","message":"adapter serialization failed"}}}}}}"#
        )
    })
}

#[cfg(test)]
mod tests;
