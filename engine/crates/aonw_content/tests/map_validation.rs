//! Validation and canonicalization checks for map schema version 1.

use aonw_content::{
    GridLayout, MapDefinition, MapDocument, MapLoadError, MapObjective, MapObjectiveType,
    ResourceType, TerrainType, TileDefinition,
};
use aonw_domain::HexCoord;
use serde_json::{Value, json};

type Mutation = (&'static str, Box<dyn Fn(&mut Value)>);

fn document() -> Value {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                json!({
                    "col": col,
                    "row": row,
                    "terrains": ["plains"],
                    "resources": if col == 0 && row == 0 {
                        json!(["iron", "wheat"])
                    } else {
                        json!([])
                    },
                    "height": 0
                })
            })
        })
        .collect::<Vec<_>>();
    json!({
        "schemaVersion": 1,
        "gridLayout": "oddQFlatTop",
        "cols": 5,
        "rows": 5,
        "mapName": "test_map",
        "defaultZoom": 1.0,
        "objectives": [{
            "id": "center_ruins",
            "type": "ruins",
            "hex": {"col": 2, "row": 2},
            "requiredHoldTurns": 3,
            "victoryPoints": 2,
            "goldPerTurn": 1
        }],
        "tiles": tiles
    })
}

fn decode(value: &Value) -> Result<MapDocument, MapLoadError> {
    MapDocument::from_json(&serde_json::to_vec(value).expect("test JSON must encode"))
}

#[test]
fn versioned_map_normalizes_lookup_and_resource_order() {
    let document = decode(&document()).expect("valid map");
    let tile = document.map().tile_at(HexCoord::new(0, 0)).expect("tile");

    assert_eq!(tile.resources(), &[ResourceType::Wheat, ResourceType::Iron]);
    assert!(document.map().tile_at(HexCoord::new(-1, 0)).is_none());
}

#[test]
fn strict_document_requires_every_schema_field() {
    for field in ["defaultZoom", "objectives"] {
        let mut value = document();
        value.as_object_mut().expect("object").remove(field);
        assert!(
            matches!(decode(&value), Err(MapLoadError::Json(_))),
            "{field}"
        );
    }

    let mut value = document();
    value["objectives"][0]
        .as_object_mut()
        .expect("objective")
        .remove("victoryPoints");
    assert!(matches!(decode(&value), Err(MapLoadError::Json(_))));
}

#[test]
fn duplicate_json_keys_are_rejected() {
    let source = br#"{
        "schemaVersion":1,"schemaVersion":1,"gridLayout":"oddQFlatTop",
        "cols":5,"rows":5,"mapName":"test_map","defaultZoom":1,
        "objectives":[],"tiles":[]
    }"#;

    assert!(matches!(
        MapDocument::from_json(source),
        Err(MapLoadError::Json(_))
    ));
}

#[test]
fn invalid_tiles_fail_closed() {
    let cases: [Mutation; 5] = [
        (
            "duplicate coordinate",
            Box::new(|value| value["tiles"][1]["col"] = json!(0)),
        ),
        (
            "duplicate terrain",
            Box::new(|value| value["tiles"][0]["terrains"] = json!(["plains", "plains"])),
        ),
        (
            "duplicate resource",
            Box::new(|value| value["tiles"][0]["resources"] = json!(["wheat", "wheat"])),
        ),
        (
            "unknown terrain",
            Box::new(|value| value["tiles"][0]["terrains"] = json!(["volcano"])),
        ),
        (
            "height out of range",
            Box::new(|value| value["tiles"][0]["height"] = json!(6)),
        ),
    ];

    for (name, mutate) in cases {
        let mut value = document();
        mutate(&mut value);
        assert!(decode(&value).is_err(), "{name}");
    }
}

#[test]
fn invalid_map_and_objective_invariants_fail_closed() {
    let cases: [Mutation; 6] = [
        (
            "invalid id",
            Box::new(|value| value["mapName"] = json!("Bad Map")),
        ),
        (
            "invalid zoom",
            Box::new(|value| value["defaultZoom"] = json!(0)),
        ),
        (
            "invalid dimensions",
            Box::new(|value| value["cols"] = json!(4)),
        ),
        (
            "duplicate objective id",
            Box::new(|value| {
                let duplicate = value["objectives"][0].clone();
                value["objectives"]
                    .as_array_mut()
                    .expect("array")
                    .push(duplicate);
            }),
        ),
        (
            "objective collision",
            Box::new(|value| {
                let mut duplicate = value["objectives"][0].clone();
                duplicate["id"] = json!("other_ruins");
                value["objectives"]
                    .as_array_mut()
                    .expect("array")
                    .push(duplicate);
            }),
        ),
        (
            "objective outside map",
            Box::new(|value| value["objectives"][0]["hex"]["col"] = json!(8)),
        ),
    ];

    for (name, mutate) in cases {
        let mut value = document();
        mutate(&mut value);
        assert!(decode(&value).is_err(), "{name}");
    }
}

#[test]
fn canonical_hash_ignores_input_order_and_camera_zoom() {
    let original = document();
    let mut reordered = original.clone();
    reordered["tiles"].as_array_mut().expect("tiles").reverse();
    reordered["tiles"][24]["resources"] = json!(["wheat", "iron"]);
    reordered["defaultZoom"] = json!(2.5);

    let original = decode(&original).expect("original");
    let reordered = decode(&reordered).expect("reordered");

    assert_eq!(
        original.map().canonical_bytes().expect("bytes"),
        reordered.map().canonical_bytes().expect("bytes")
    );
    assert_eq!(
        original.map().content_hash().expect("hash"),
        reordered.map().content_hash().expect("hash")
    );
}

#[test]
fn canonical_hash_matches_golden_digest() {
    let document = decode(&document()).expect("valid map");

    assert_eq!(
        document.map().content_hash().expect("hash").to_string(),
        "9339e56f9d97fc06e6e6c81e44076987229b74d9e000594911ee39d3370fe5d4"
    );
}

#[test]
fn domain_content_can_be_constructed_without_a_json_adapter() {
    let tiles = (0..5)
        .flat_map(|row| {
            (0..5).map(move |col| {
                TileDefinition::try_new(
                    HexCoord::new(col, row),
                    vec![TerrainType::Plains],
                    Vec::new(),
                    0,
                )
                .expect("valid tile")
            })
        })
        .collect();
    let objective = MapObjective::try_new(
        "center_ruins",
        MapObjectiveType::Ruins,
        HexCoord::new(2, 2),
        3,
        2,
        1,
    )
    .expect("valid objective");
    let map = MapDefinition::try_new(
        "constructed_map",
        GridLayout::OddQFlatTop,
        5,
        5,
        tiles,
        vec![objective],
    )
    .expect("valid map");
    let document = MapDocument::try_new(map, 1.5).expect("valid document");

    assert_eq!(document.map().map_id(), "constructed_map");
    assert!((document.default_zoom() - 1.5).abs() < f64::EPSILON);
    assert!(
        TileDefinition::try_new(
            HexCoord::new(0, 0),
            vec![TerrainType::Plains, TerrainType::Plains],
            Vec::new(),
            0,
        )
        .is_err()
    );
}
