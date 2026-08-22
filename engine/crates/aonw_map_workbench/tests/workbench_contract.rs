//! Contract coverage for deterministic logical-map generation.

use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;
use aonw_map_workbench::{
    GeneratedMapPackage, MAP_WORKBENCH_API_VERSION, MapGenerationSpec, MapWorkbenchProtocol,
};
use serde_json::{Value, json};

fn spec(seed: u64) -> MapGenerationSpec {
    MapGenerationSpec::try_new("generated_world", 40, 30, 1.25, 100.0, seed)
        .expect("valid generation spec")
}

#[test]
fn blank_v1_is_deterministic_and_passes_authoritative_validators() {
    let first = GeneratedMapPackage::generate(&spec(42)).expect("first package");
    let second = GeneratedMapPackage::generate(&spec(42)).expect("second package");
    assert_eq!(first, second);

    let map = MapDocument::from_json(first.map_document().as_bytes()).expect("generated map");
    let profile = TerrainAuthoringProfile::from_json(
        first.terrain_authoring_document().as_bytes(),
        map.map(),
    )
    .expect("generated terrain profile");
    assert_eq!(map.map().cols(), 40);
    assert_eq!(map.map().rows(), 30);
    assert_eq!(map.map().tiles().len(), 1_200);
    assert_eq!(
        map.map().content_hash().expect("map hash").to_string(),
        first.map_content_hash()
    );
    assert_eq!(
        profile
            .authoring_profile_hash()
            .expect("profile hash")
            .to_string(),
        first.authoring_profile_hash()
    );

    let provenance: Value = serde_json::from_str(first.generation_document()).expect("provenance");
    assert_eq!(
        provenance["generationSpecHash"],
        first.generation_spec_hash()
    );
    assert_eq!(provenance["mapContentHash"], first.map_content_hash());
    assert_eq!(
        provenance["generatedDecorationPlanHash"],
        first.generated_decoration_plan_hash()
    );
    let decorations: Value =
        serde_json::from_str(first.generated_decoration_plan_document()).expect("decorations");
    assert_eq!(
        decorations["sourceMapContentHash"],
        first.map_content_hash()
    );
    assert_eq!(decorations["placements"], json!([]));
}

#[test]
fn seed_has_provenance_even_when_blank_map_content_is_identical() {
    let first = GeneratedMapPackage::generate(&spec(1)).expect("first package");
    let second = GeneratedMapPackage::generate(&spec(2)).expect("second package");
    assert_eq!(first.map_content_hash(), second.map_content_hash());
    assert_ne!(first.generation_spec_hash(), second.generation_spec_hash());
    assert_ne!(
        first.generated_decoration_plan_hash(),
        second.generated_decoration_plan_hash()
    );
}

#[test]
fn strict_protocol_returns_documents_without_filesystem_ownership() {
    let request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "generateMap",
            "specDocument": spec(7).to_versioned_json().expect("spec JSON"),
        },
    });
    let response: Value =
        serde_json::from_str(&MapWorkbenchProtocol::dispatch_json(&request.to_string()))
            .expect("protocol response");
    assert_eq!(response["outcome"]["status"], "success");
    assert_eq!(response["outcome"]["response"]["type"], "mapGenerated");
    assert!(
        response["outcome"]["response"]["package"]["mapDocument"]
            .as_str()
            .is_some_and(|document| document.contains("generated_world"))
    );
}

#[test]
fn invalid_specs_are_rejected_before_generation() {
    let invalid = json!({
        "schemaVersion": 1,
        "generatorId": "blank",
        "generatorVersion": 1,
        "mapId": "Generated World",
        "cols": 4,
        "rows": 30,
        "defaultZoom": 1.0,
        "hexRadiusMeters": 100.0,
        "seed": "7",
    });
    assert!(MapGenerationSpec::from_json(invalid.to_string().as_bytes()).is_err());
}
