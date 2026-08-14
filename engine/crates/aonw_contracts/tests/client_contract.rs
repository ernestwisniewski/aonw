//! Golden and strict-boundary tests for the shared current client protocol.

use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientCommandResultDto, ClientErrorDto, ClientEventDto,
    ClientEvidenceDto, ClientFeatureDto, ClientOutcomeDto, ClientQueryDto, ClientQueryResultDto,
    ClientReplayVerificationDto, ClientRequestBodyDto, ClientRequestDto, ClientResponseBodyDto,
    ClientResponseDto, ClientSessionStampDto, MovementStepViewDto, PlayerUnitViewDto,
    PlayerViewPatchDto, PlayerViewSnapshotDto, ReachableTileViewDto,
};
use aonw_contracts::{CoordinateDto, UnitKindDto, UnitPostureDto};

fn coordinate(col: i32, row: i32) -> CoordinateDto {
    CoordinateDto { col, row }
}

fn stamp() -> ClientSessionStampDto {
    ClientSessionStampDto {
        behavior_version: 2,
        revision: 8,
        state_digest: "digest-8".to_owned(),
        map_hash: "map-hash".to_owned(),
        ruleset_hash: "ruleset-hash".to_owned(),
    }
}

fn unit() -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: "unit-1".to_owned(),
        owner_player_id: "player-1".to_owned(),
        kind: UnitKindDto::Commander,
        name: "Commander".to_owned(),
        coordinate: coordinate(3, 4),
        movement_units: 8,
        posture: UnitPostureDto::Active,
    }
}

fn command_result() -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(),
        accepted: true,
        rejection: None,
        events: vec![ClientEventDto::UnitMoved {
            unit_id: "unit-1".to_owned(),
            from: coordinate(1, 2),
            to: coordinate(3, 4),
        }],
        evidence: Some(ClientEvidenceDto::UnitMovement {
            unit_id: "unit-1".to_owned(),
            from: coordinate(1, 2),
            steps: vec![MovementStepViewDto {
                coordinate: coordinate(3, 4),
                enter_cost_units: 2,
                cumulative_cost_units: 2,
            }],
        }),
        view_patch: PlayerViewPatchDto {
            from_revision: 7,
            to_revision: 8,
            upserted_units: vec![unit()],
            removed_unit_ids: Vec::new(),
        },
    }
}

#[test]
fn golden_move_request_is_stable_and_strict() {
    let request = ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::MoveUnit {
                expected_revision: 7,
                unit_id: "unit-1".to_owned(),
                target: coordinate(3, 4),
            },
        },
    };
    let golden =
        include_str!("../../../../test/fixtures/client_protocol/move_unit_request.json").trim();

    assert_eq!(request.to_json().expect("request JSON"), golden);
    assert_eq!(
        ClientRequestDto::from_json(golden).expect("golden request"),
        request
    );
}

#[test]
fn golden_command_response_is_stable_and_strict() {
    let response = ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Success {
            response: Box::new(ClientResponseBodyDto::Command {
                result: command_result(),
            }),
        },
    };
    let golden =
        include_str!("../../../../test/fixtures/client_protocol/command_result_response.json")
            .trim();

    assert_eq!(response.to_json().expect("response JSON"), golden);
    assert_eq!(
        ClientResponseDto::from_json(golden).expect("golden response"),
        response
    );
}

#[test]
fn every_current_request_variant_round_trips() {
    let requests = [
        ClientRequestBodyDto::Capabilities,
        ClientRequestBodyDto::OpenSession {
            map_document: "map".to_owned(),
            scenario_document: "scenario".to_owned(),
            actor_player_id: "player-1".to_owned(),
        },
        ClientRequestBodyDto::CloseSession,
        ClientRequestBodyDto::Snapshot,
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::Reachable {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Query {
            query: ClientQueryDto::RoutePlan {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
                target: coordinate(4, 4),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::CancelUnitAction {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::SkipUnitTurn {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::Dispatch {
            command: ClientCommandDto::FortifyUnit {
                expected_revision: 8,
                unit_id: "unit-1".to_owned(),
            },
        },
        ClientRequestBodyDto::ExportSave,
        ClientRequestBodyDto::OpenSave {
            map_document: "map".to_owned(),
            save_document: "save".to_owned(),
        },
        ClientRequestBodyDto::ExportReplay,
        ClientRequestBodyDto::VerifyReplay {
            map_document: "map".to_owned(),
            replay_document: "replay".to_owned(),
        },
    ];

    for request in requests {
        let envelope = ClientRequestDto {
            api_version: CLIENT_API_VERSION,
            request,
        };
        let encoded = envelope.to_json().expect("request JSON");
        assert_eq!(
            ClientRequestDto::from_json(&encoded).expect("request"),
            envelope
        );
    }
}

#[test]
fn every_current_response_variant_round_trips() {
    let query_stamp = stamp();
    let responses = vec![
        ClientResponseBodyDto::Capabilities {
            behavior_version: 2,
            features: vec![ClientFeatureDto::Snapshot, ClientFeatureDto::MoveUnit],
        },
        ClientResponseBodyDto::SessionOpened { stamp: stamp() },
        ClientResponseBodyDto::SessionClosed,
        ClientResponseBodyDto::Snapshot {
            snapshot: PlayerViewSnapshotDto {
                stamp: stamp(),
                units: vec![unit()],
            },
        },
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::Reachable {
                stamp: query_stamp.clone(),
                unit_id: "unit-1".to_owned(),
                available_movement_units: 8,
                tiles: vec![ReachableTileViewDto {
                    coordinate: coordinate(4, 4),
                    cost_units: 2,
                    exhausts_movement: false,
                }],
            },
        },
        ClientResponseBodyDto::Query {
            result: ClientQueryResultDto::RoutePlan {
                stamp: query_stamp,
                unit_id: "unit-1".to_owned(),
                target: coordinate(4, 4),
                destination: coordinate(4, 4),
                total_cost_units: 2,
                available_movement_units: 8,
                remaining_movement_units: 6,
                steps: vec![MovementStepViewDto {
                    coordinate: coordinate(4, 4),
                    enter_cost_units: 2,
                    cumulative_cost_units: 2,
                }],
            },
        },
        ClientResponseBodyDto::Command {
            result: command_result(),
        },
        ClientResponseBodyDto::SaveExported {
            document: "save".to_owned(),
        },
        ClientResponseBodyDto::SaveOpened { stamp: stamp() },
        ClientResponseBodyDto::ReplayExported {
            document: "replay".to_owned(),
        },
        ClientResponseBodyDto::ReplayVerified {
            verification: ClientReplayVerificationDto {
                entry_count: 4,
                final_event_offset: 7,
                final_stamp: stamp(),
            },
        },
    ];

    for response in responses {
        let envelope = ClientResponseDto {
            api_version: CLIENT_API_VERSION,
            outcome: ClientOutcomeDto::Success {
                response: Box::new(response),
            },
        };
        let encoded = envelope.to_json().expect("response JSON");
        assert_eq!(
            ClientResponseDto::from_json(&encoded).expect("response"),
            envelope
        );
    }

    let failure = ClientResponseDto {
        api_version: CLIENT_API_VERSION,
        outcome: ClientOutcomeDto::Failure {
            error: ClientErrorDto {
                code: "session_not_open".to_owned(),
                message: "session is not open".to_owned(),
            },
        },
    };
    let encoded = failure.to_json().expect("failure JSON");
    assert_eq!(
        ClientResponseDto::from_json(&encoded).expect("failure"),
        failure
    );
}

#[test]
fn malformed_unknown_duplicate_and_future_documents_fail_closed() {
    let unknown = r#"{"apiVersion":1,"request":{"type":"snapshot"},"extra":true}"#;
    let duplicate = r#"{"apiVersion":1,"apiVersion":1,"request":{"type":"snapshot"}}"#;
    let future = r#"{"apiVersion":2,"request":{"type":"snapshot"}}"#;
    let malformed_nested = r#"{"apiVersion":1,"request":{"type":"query","query":{"type":"reachable","expectedRevision":0,"unitId":"u","extra":true}}}"#;

    for invalid in [unknown, duplicate, future, malformed_nested] {
        assert!(ClientRequestDto::from_json(invalid).is_err());
    }

    let future_response =
        r#"{"apiVersion":2,"outcome":{"status":"success","response":{"type":"sessionClosed"}}}"#;
    let unknown_response = r#"{"apiVersion":1,"outcome":{"status":"failure","error":{"code":"failed","message":"failed","extra":true}}}"#;
    assert!(ClientResponseDto::from_json(future_response).is_err());
    assert!(ClientResponseDto::from_json(unknown_response).is_err());
}
