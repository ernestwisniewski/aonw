use aonw_map_workbench::MAP_WORKBENCH_API_VERSION;
use serde_json::{Value, json};

use super::dispatch_json;

#[test]
fn native_workbench_bridge_returns_rust_generated_documents() {
    let spec = json!({
        "schemaVersion": 1,
        "generatorId": "blank",
        "generatorVersion": 1,
        "mapId": "native_generated",
        "cols": 5,
        "rows": 5,
        "defaultZoom": 1.0,
        "hexRadiusMeters": 100.0,
        "seed": "42",
    });
    let request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "generateMap",
            "specDocument": serde_json::to_string_pretty(&spec).expect("spec"),
        },
    });
    let response: Value =
        serde_json::from_str(&dispatch_json(&request.to_string())).expect("response");
    let package = &response["outcome"]["response"]["package"];
    assert_eq!(response["outcome"]["status"], "success");
    assert!(package["mapDocument"].as_str().is_some());
    assert!(package["terrainAuthoringDocument"].as_str().is_some());
    assert!(package["generationDocument"].as_str().is_some());
    assert!(
        package["generatedDecorationPlanDocument"]
            .as_str()
            .is_some()
    );
}
