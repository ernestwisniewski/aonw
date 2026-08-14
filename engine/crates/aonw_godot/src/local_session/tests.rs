use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    CLIENT_API_VERSION, ClientCommandDto, ClientOutcomeDto, ClientRequestBodyDto, ClientRequestDto,
    ClientResponseBodyDto, ClientResponseDto,
};
use aonw_local_runtime::LocalRuntime;
use serde_json::json;

use super::dispatch_json;

fn map_json(cols: u16, rows: u16, map_id: &str) -> String {
    let tiles = (0..rows)
        .flat_map(|row| {
            (0..cols).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrains": ["grassland"],
                    "resources": [],
                    "height": 0,
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": cols,
        "rows": rows,
        "mapName": map_id,
        "defaultZoom": 1.0,
        "objectives": [],
        "tiles": tiles,
    })
    .to_string()
}

fn scenario_json(unit_count: usize, scenario_id: &str, map_id: &str) -> String {
    let units = (0..unit_count)
        .map(|index| {
            json!({
                "id": format!("unit-{index}"),
                "ownerPlayerId": "player-1",
                "kind": "commander",
                "name": "Commander",
                "col": index % 40,
                "row": index / 40,
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "scenarioId": scenario_id,
        "mapId": map_id,
        "rulesetId": "aonw-standard",
        "initialUnits": units,
    })
    .to_string()
}

fn request(body: ClientRequestBodyDto) -> String {
    ClientRequestDto {
        api_version: CLIENT_API_VERSION,
        request: body,
    }
    .to_json()
    .expect("client request")
}

fn response(runtime: &mut LocalRuntime, body: ClientRequestBodyDto) -> ClientResponseBodyDto {
    let response = ClientResponseDto::from_json(&dispatch_json(runtime, &request(body)))
        .expect("client response");
    let ClientOutcomeDto::Success { response } = response.outcome else {
        panic!("successful client response")
    };
    *response
}

#[test]
fn native_adapter_uses_the_shared_client_protocol_end_to_end() {
    let map = map_json(5, 5, "session-test");
    let scenario = scenario_json(1, "session-test", "session-test");
    let mut runtime = LocalRuntime::default();

    assert!(matches!(
        response(
            &mut runtime,
            ClientRequestBodyDto::OpenSession {
                map_document: map,
                scenario_document: scenario,
                actor_player_id: "player-1".to_owned(),
            }
        ),
        ClientResponseBodyDto::SessionOpened { .. }
    ));
    assert!(matches!(
        response(&mut runtime, ClientRequestBodyDto::Snapshot),
        ClientResponseBodyDto::Snapshot { .. }
    ));
    assert!(matches!(
        response(
            &mut runtime,
            ClientRequestBodyDto::Dispatch {
                command: ClientCommandDto::MoveUnit {
                    expected_revision: 0,
                    unit_id: "unit-0".to_owned(),
                    target: CoordinateDto { col: 1, row: 0 },
                },
            }
        ),
        ClientResponseBodyDto::Command { .. }
    ));
}

#[test]
fn native_adapter_rejects_non_protocol_and_foreign_version_documents() {
    let mut runtime = LocalRuntime::default();
    for input in [
        "{}".to_owned(),
        json!({"apiVersion": 2, "request": {"type": "capabilities"}}).to_string(),
    ] {
        let response = ClientResponseDto::from_json(&dispatch_json(&mut runtime, &input))
            .expect("failure response");
        assert!(matches!(response.outcome, ClientOutcomeDto::Failure { .. }));
    }
}
