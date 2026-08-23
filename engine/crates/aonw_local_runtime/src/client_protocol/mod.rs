mod decode;
mod encode;

use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCodecError, ClientErrorDto, ClientOutcomeDto, ClientRequestBodyDto,
    ClientRequestDto, ClientResponseBodyDto, ClientResponseDto,
};

use crate::{LocalRuntime, RuntimeError};

use decode::DecodedCommand;

/// Framework-neutral dispatcher for the shared Godot and Flutter client protocol.
pub struct ClientProtocol;

impl ClientProtocol {
    /// Decodes, dispatches, and encodes one strict client JSON document.
    #[must_use]
    pub fn dispatch_json(runtime: &mut LocalRuntime, input: &str) -> String {
        let response = match ClientRequestDto::from_json(input) {
            Ok(request) => Self::dispatch(runtime, request),
            Err(error @ ClientCodecError::UnsupportedVersion { .. }) => {
                failure("unsupported_client_api_version", error)
            }
            Err(error) => failure("invalid_client_request", error),
        };
        response
            .to_json()
            .unwrap_or_else(|_| serialization_failure())
    }

    /// Executes one validated current client request against a local runtime.
    #[must_use]
    pub fn dispatch(runtime: &mut LocalRuntime, request: ClientRequestDto) -> ClientResponseDto {
        if request.api_version != CLIENT_API_VERSION {
            return failure(
                "unsupported_client_api_version",
                format!(
                    "unsupported client API version {}; expected {CLIENT_API_VERSION}",
                    request.api_version
                ),
            );
        }

        match request.request {
            ClientRequestBodyDto::Capabilities => success(encode::capabilities()),
            ClientRequestBodyDto::InspectMap { map_document } => {
                match decode::map_document(&map_document) {
                    Ok(document) => match encode::map(&document) {
                        Ok(map) => success(ClientResponseBodyDto::MapInspected { map }),
                        Err(error) => failure("map_hash_failed", error),
                    },
                    Err(error) => error.into_response(),
                }
            }
            ClientRequestBodyDto::OpenSession {
                map_document,
                scenario_document,
                actor_player_id,
            } => match decode::open_session(&map_document, &scenario_document, &actor_player_id) {
                Ok(request) => match runtime.open(request) {
                    Ok(stamp) => success(ClientResponseBodyDto::SessionOpened {
                        stamp: encode::stamp(stamp),
                    }),
                    Err(error) => failure("session_open_failed", error),
                },
                Err(error) => error.into_response(),
            },
            ClientRequestBodyDto::CloseSession => {
                runtime.close();
                success(ClientResponseBodyDto::SessionClosed)
            }
            ClientRequestBodyDto::Snapshot => match runtime.snapshot() {
                Ok(snapshot) => success(ClientResponseBodyDto::Snapshot {
                    snapshot: encode::snapshot(&snapshot),
                }),
                Err(error) => runtime_failure(error),
            },
            ClientRequestBodyDto::Query { query } => match decode::query(query) {
                Ok(query) => match runtime.query(&query) {
                    Ok(result) => success(ClientResponseBodyDto::Query {
                        result: encode::query_result(&result),
                    }),
                    Err(error) => runtime_failure(error),
                },
                Err(error) => error.into_response(),
            },
            ClientRequestBodyDto::Dispatch { command } => match decode::command(command) {
                Ok(command) => dispatch_command(runtime, command),
                Err(error) => error.into_response(),
            },
            ClientRequestBodyDto::ExportSave => match runtime.export_save_json() {
                Ok(document) => success(ClientResponseBodyDto::SaveExported { document }),
                Err(error) => failure("save_export_failed", error),
            },
            ClientRequestBodyDto::OpenSave {
                map_document,
                save_document,
            } => match decode::map(&map_document) {
                Ok(map) => match runtime.open_save_json(
                    map,
                    aonw_content::RulesetDefinition::standard().clone(),
                    &save_document,
                ) {
                    Ok(stamp) => success(ClientResponseBodyDto::SaveOpened {
                        stamp: encode::stamp(stamp),
                    }),
                    Err(error) => failure("save_open_failed", error),
                },
                Err(error) => error.into_response(),
            },
            ClientRequestBodyDto::ExportReplay => match runtime.export_replay_json() {
                Ok(document) => success(ClientResponseBodyDto::ReplayExported { document }),
                Err(error) => failure("replay_export_failed", error),
            },
            ClientRequestBodyDto::VerifyReplay {
                map_document,
                replay_document,
            } => match decode::map(&map_document) {
                Ok(map) => match LocalRuntime::verify_replay_json(
                    map,
                    aonw_content::RulesetDefinition::standard().clone(),
                    &replay_document,
                ) {
                    Ok(verification) => success(ClientResponseBodyDto::ReplayVerified {
                        verification: encode::replay_verification(verification),
                    }),
                    Err(error) => failure("replay_verification_failed", error),
                },
                Err(error) => error.into_response(),
            },
        }
    }
}

fn serialization_failure() -> String {
    format!(
        r#"{{"apiVersion":{CLIENT_API_VERSION},"outcome":{{"status":"failure","error":{{"code":"adapter_serialization_failed","message":"adapter serialization failed"}}}}}}"#
    )
}

fn dispatch_command(runtime: &mut LocalRuntime, command: DecodedCommand) -> ClientResponseDto {
    let result = match command {
        DecodedCommand::Move(command) => runtime.dispatch(&command),
        DecodedCommand::Cancel(command) => runtime.cancel_unit_action(&command),
        DecodedCommand::Skip(command) => runtime.skip_unit_turn(&command),
        DecodedCommand::Fortify(command) => runtime.fortify_unit(&command),
    };
    match result {
        Ok(result) => success(ClientResponseBodyDto::Command {
            result: encode::command_result(&result),
        }),
        Err(error) => runtime_failure(error),
    }
}

fn runtime_failure(error: RuntimeError) -> ClientResponseDto {
    failure(error.code(), error)
}

fn success(response: ClientResponseBodyDto) -> ClientResponseDto {
    ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Success {
            response: Box::new(response),
        },
    }
}

fn failure(code: &str, error: impl core::fmt::Display) -> ClientResponseDto {
    ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Failure {
            error: ClientErrorDto {
                code: code.to_owned(),
                message: error.to_string(),
            },
        },
    }
}

pub(super) struct ClientDecodeError {
    code: &'static str,
    message: String,
}

impl ClientDecodeError {
    pub(super) fn new(code: &'static str, error: impl core::fmt::Display) -> Self {
        Self {
            code,
            message: error.to_string(),
        }
    }

    fn into_response(self) -> ClientResponseDto {
        failure(self.code, self.message)
    }
}
