//! Contract coverage for deterministic logical-map generation.

use aonw_content::MapDocument;
use aonw_map_authoring::TerrainAuthoringProfile;
use aonw_map_workbench::{
    GeneratedMapPackage, MAP_WORKBENCH_API_VERSION, MapGenerationSpec, MapWorkbenchProtocol,
    UpdatedTerrainProfile,
};
use serde_json::{Value, json};

fn spec(seed: u64) -> MapGenerationSpec {
    MapGenerationSpec::try_new("generated_world", 40, 30, 1.25, 100.0, 240.0, seed)
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
    assert!((profile.max_terrain_height_meters() - 240.0).abs() <= f64::EPSILON);
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
        "maxTerrainHeightMeters": 240.0,
        "seed": "7",
    });
    assert!(MapGenerationSpec::from_json(invalid.to_string().as_bytes()).is_err());
}

#[test]
fn terrain_height_reconfiguration_is_canonical_and_rust_owned() {
    let generated = GeneratedMapPackage::generate(&spec(7)).expect("generated package");
    let update = UpdatedTerrainProfile::reconfigure(
        generated.map_document(),
        generated.terrain_authoring_document(),
        175.0,
    )
    .expect("profile update");
    let map = MapDocument::from_json(generated.map_document().as_bytes()).expect("map");
    let profile = TerrainAuthoringProfile::from_json(
        update.terrain_authoring_document().as_bytes(),
        map.map(),
    )
    .expect("updated profile");

    assert!((update.max_terrain_height_meters() - 175.0).abs() <= f64::EPSILON);
    assert!((profile.max_terrain_height_meters() - 175.0).abs() <= f64::EPSILON);
    assert_eq!(
        update.authoring_profile_hash(),
        profile.authoring_profile_hash().expect("hash").to_string(),
    );

    let request = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "reconfigureTerrainHeight",
            "mapDocument": generated.map_document(),
            "terrainAuthoringDocument": generated.terrain_authoring_document(),
            "maxTerrainHeightMeters": 175.0,
        },
    });
    let response: Value =
        serde_json::from_str(&MapWorkbenchProtocol::dispatch_json(&request.to_string()))
            .expect("protocol response");
    assert_eq!(response["outcome"]["status"], "success");
    assert_eq!(
        response["outcome"]["response"]["type"],
        "terrainHeightReconfigured"
    );
    assert_eq!(
        response["outcome"]["response"]["update"]["maxTerrainHeightMeters"],
        175.0
    );
}

#[test]
fn tile_edits_are_canonical_and_refresh_the_bound_terrain_profile() {
    let generated = GeneratedMapPackage::generate(&spec(11)).expect("generated package");
    let inspect = workbench_request(&json!({
        "type": "inspectMapTile",
        "mapDocument": generated.map_document(),
        "col": 2,
        "row": 3,
    }));
    let snapshot = &inspect["outcome"]["response"]["snapshot"];
    assert_eq!(snapshot["tile"]["displayTerrain"], "grassland");
    assert_eq!(
        snapshot["terrainOptions"].as_array().map(Vec::len),
        Some(14)
    );
    assert_eq!(
        snapshot["resourceOptions"].as_array().map(Vec::len),
        Some(29)
    );

    let terrain_edit = workbench_request(&json!({
        "type": "setTileTerrain",
        "mapDocument": generated.map_document(),
        "terrainAuthoringDocument": generated.terrain_authoring_document(),
        "col": 2,
        "row": 3,
        "terrain": "forest",
    }));
    let terrain_update = &terrain_edit["outcome"]["response"]["update"];
    assert_eq!(
        terrain_update["snapshot"]["tile"]["displayTerrain"],
        "forest"
    );
    assert_ne!(
        terrain_update["mapContentHash"],
        generated.map_content_hash()
    );
    assert_updated_documents_match_hashes(terrain_update);

    let resources_edit = workbench_request(&json!({
        "type": "setTileResources",
        "mapDocument": terrain_update["mapDocument"],
        "terrainAuthoringDocument": terrain_update["terrainAuthoringDocument"],
        "col": 2,
        "row": 3,
        "resources": ["iron", "wheat"],
    }));
    let resources_update = &resources_edit["outcome"]["response"]["update"];
    assert_eq!(
        resources_update["snapshot"]["tile"]["resources"],
        json!(["wheat", "iron"])
    );
    assert_updated_documents_match_hashes(resources_update);

    let height_edit = workbench_request(&json!({
        "type": "setTileHeight",
        "mapDocument": resources_update["mapDocument"],
        "terrainAuthoringDocument": resources_update["terrainAuthoringDocument"],
        "col": 2,
        "row": 3,
        "height": 5,
    }));
    let height_update = &height_edit["outcome"]["response"]["update"];
    assert_eq!(height_update["snapshot"]["tile"]["height"], 5);
    assert_updated_documents_match_hashes(height_update);
    let map = MapDocument::from_json(
        height_update["mapDocument"]
            .as_str()
            .expect("map document")
            .as_bytes(),
    )
    .expect("updated map");
    let profile = TerrainAuthoringProfile::from_json(
        height_update["terrainAuthoringDocument"]
            .as_str()
            .expect("terrain document")
            .as_bytes(),
        map.map(),
    )
    .expect("updated profile");
    let envelope = profile
        .hex_heights()
        .iter()
        .find(|value| value.coordinate().col() == 2 && value.coordinate().row() == 3)
        .expect("edited envelope");
    assert!(
        (envelope.base_height_meters() - profile.max_terrain_height_meters()).abs() <= f64::EPSILON
    );
}

#[test]
fn tile_edits_reject_invalid_coordinates_values_and_unknown_wire_fields() {
    let generated = GeneratedMapPackage::generate(&spec(12)).expect("generated package");
    for request in [
        json!({
            "type": "setTileTerrain",
            "mapDocument": generated.map_document(),
            "terrainAuthoringDocument": generated.terrain_authoring_document(),
            "col": 50,
            "row": 3,
            "terrain": "forest",
        }),
        json!({
            "type": "setTileTerrain",
            "mapDocument": generated.map_document(),
            "terrainAuthoringDocument": generated.terrain_authoring_document(),
            "col": 2,
            "row": 3,
            "terrain": "river",
        }),
        json!({
            "type": "setTileHeight",
            "mapDocument": generated.map_document(),
            "terrainAuthoringDocument": generated.terrain_authoring_document(),
            "col": 2,
            "row": 3,
            "height": 6,
        }),
        json!({
            "type": "setTileResources",
            "mapDocument": generated.map_document(),
            "terrainAuthoringDocument": generated.terrain_authoring_document(),
            "col": 2,
            "row": 3,
            "resources": ["iron", "iron"],
        }),
    ] {
        let envelope = json!({
            "apiVersion": MAP_WORKBENCH_API_VERSION,
            "request": request,
        });
        let response: Value =
            serde_json::from_str(&MapWorkbenchProtocol::dispatch_json(&envelope.to_string()))
                .expect("protocol response");
        assert_eq!(response["outcome"]["status"], "failure");
    }

    let unknown = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": {
            "type": "inspectMapTile",
            "mapDocument": generated.map_document(),
            "col": 2,
            "row": 3,
            "unexpected": true,
        },
    });
    let response: Value =
        serde_json::from_str(&MapWorkbenchProtocol::dispatch_json(&unknown.to_string()))
            .expect("protocol response");
    assert_eq!(response["outcome"]["status"], "failure");
    assert_eq!(
        response["outcome"]["error"]["code"],
        "invalid_workbench_request"
    );
}

fn workbench_request(request: &Value) -> Value {
    let envelope = json!({
        "apiVersion": MAP_WORKBENCH_API_VERSION,
        "request": request,
    });
    let response: Value =
        serde_json::from_str(&MapWorkbenchProtocol::dispatch_json(&envelope.to_string()))
            .expect("protocol response");
    assert_eq!(response["outcome"]["status"], "success", "{response}");
    response
}

fn assert_updated_documents_match_hashes(update: &Value) {
    let map = MapDocument::from_json(
        update["mapDocument"]
            .as_str()
            .expect("map document")
            .as_bytes(),
    )
    .expect("updated map");
    let profile = TerrainAuthoringProfile::from_json(
        update["terrainAuthoringDocument"]
            .as_str()
            .expect("terrain document")
            .as_bytes(),
        map.map(),
    )
    .expect("updated profile");
    assert_eq!(
        update["mapContentHash"],
        map.map().content_hash().expect("map hash").to_string()
    );
    assert_eq!(
        update["authoringProfileHash"],
        profile
            .authoring_profile_hash()
            .expect("profile hash")
            .to_string()
    );
}
