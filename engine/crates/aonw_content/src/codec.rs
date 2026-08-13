use std::collections::BTreeSet;

use aonw_domain::HexCoord;
use serde::{Deserialize, Serialize};
use sha2::{Digest, Sha256};

use crate::CURRENT_MAP_SCHEMA_VERSION;
use crate::error::MapLoadError;
use crate::model::{
    ContentHash, GridLayout, MapDefinition, MapObjective, MapObjectiveType, ResourceType,
    TerrainType, TileDefinition,
};

const MAX_MAP_DOCUMENT_BYTES: usize = 8 * 1024 * 1024;
const MIN_COLS: u16 = 5;
const MAX_COLS: u16 = 40;
const MIN_ROWS: u16 = 5;
const MAX_ROWS: u16 = 30;
const MAX_HEIGHT: u8 = 5;
const MAX_CONTENT_ID_BYTES: usize = 64;

#[derive(Clone, Copy)]
enum InputMode {
    Versioned,
    Legacy,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawMapDocument {
    #[serde(default)]
    schema_version: Option<u64>,
    #[serde(default)]
    grid_layout: Option<Box<str>>,
    cols: i64,
    rows: i64,
    map_name: Box<str>,
    #[serde(default = "default_zoom")]
    default_zoom: f64,
    #[serde(default)]
    objectives: Vec<RawObjective>,
    tiles: Vec<RawTile>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct RawTile {
    col: i64,
    row: i64,
    terrains: Vec<Box<str>>,
    resources: Vec<Box<str>>,
    height: i64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct RawObjective {
    id: Box<str>,
    #[serde(rename = "type")]
    objective_type: Box<str>,
    hex: RawCoordinate,
    #[serde(default = "default_required_hold_turns")]
    required_hold_turns: i64,
    #[serde(default)]
    victory_points: i64,
    #[serde(default)]
    gold_per_turn: i64,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct RawCoordinate {
    col: i64,
    row: i64,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CanonicalMap<'a> {
    schema_version: u64,
    grid_layout: GridLayout,
    cols: u16,
    rows: u16,
    map_name: &'a str,
    default_zoom: f64,
    objectives: Vec<CanonicalObjective<'a>>,
    tiles: Vec<CanonicalTile<'a>>,
}

#[derive(Serialize)]
struct CanonicalTile<'a> {
    col: i32,
    row: i32,
    terrains: &'a [TerrainType],
    resources: &'a [ResourceType],
    height: u8,
}

#[derive(Serialize)]
#[serde(rename_all = "camelCase")]
struct CanonicalObjective<'a> {
    id: &'a str,
    #[serde(rename = "type")]
    objective_type: MapObjectiveType,
    hex: CanonicalCoordinate,
    required_hold_turns: u32,
    victory_points: u32,
    gold_per_turn: u32,
}

#[derive(Serialize)]
struct CanonicalCoordinate {
    col: i32,
    row: i32,
}

impl MapDefinition {
    /// Decodes the strict, versioned shared map format.
    ///
    /// # Errors
    ///
    /// Returns [`MapLoadError`] when the document exceeds its resource bound,
    /// has invalid JSON, uses an unsupported version, or violates an invariant.
    pub fn from_json(source: &[u8]) -> Result<Self, MapLoadError> {
        decode(source, InputMode::Versioned)
    }

    /// Decodes an existing Flutter map without version fields.
    ///
    /// This migration-only adapter injects schema version 1 and the canonical
    /// odd-q layout. Canonical serialization always emits the versioned form.
    ///
    /// # Errors
    ///
    /// Returns [`MapLoadError`] for malformed input or invariant violations.
    pub fn from_legacy_json(source: &[u8]) -> Result<Self, MapLoadError> {
        decode(source, InputMode::Legacy)
    }

    /// Serializes the normalized map with explicit fields and stable ordering.
    ///
    /// # Errors
    ///
    /// Returns an error if JSON serialization cannot complete.
    pub fn to_canonical_json(&self) -> Result<String, serde_json::Error> {
        let mut output = serde_json::to_string_pretty(&CanonicalMap::from(self))?;
        output.push('\n');
        Ok(output)
    }

    /// Computes SHA-256 over compact normalized schema-version-1 JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if canonical JSON serialization cannot complete.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let canonical = serde_json::to_vec(&CanonicalMap::from(self))?;
        Ok(ContentHash(Sha256::digest(canonical).into()))
    }
}

impl<'a> From<&'a MapDefinition> for CanonicalMap<'a> {
    fn from(map: &'a MapDefinition) -> Self {
        Self {
            schema_version: CURRENT_MAP_SCHEMA_VERSION,
            grid_layout: map.grid_layout,
            cols: map.cols,
            rows: map.rows,
            map_name: &map.map_name,
            default_zoom: map.default_zoom,
            objectives: map
                .objectives
                .iter()
                .map(CanonicalObjective::from)
                .collect(),
            tiles: map.tiles.iter().map(CanonicalTile::from).collect(),
        }
    }
}

impl<'a> From<&'a TileDefinition> for CanonicalTile<'a> {
    fn from(tile: &'a TileDefinition) -> Self {
        Self {
            col: tile.coordinate.col(),
            row: tile.coordinate.row(),
            terrains: &tile.terrains,
            resources: &tile.resources,
            height: tile.height,
        }
    }
}

impl<'a> From<&'a MapObjective> for CanonicalObjective<'a> {
    fn from(objective: &'a MapObjective) -> Self {
        Self {
            id: &objective.id,
            objective_type: objective.objective_type,
            hex: CanonicalCoordinate {
                col: objective.coordinate.col(),
                row: objective.coordinate.row(),
            },
            required_hold_turns: objective.required_hold_turns,
            victory_points: objective.victory_points,
            gold_per_turn: objective.gold_per_turn,
        }
    }
}

fn decode(source: &[u8], mode: InputMode) -> Result<MapDefinition, MapLoadError> {
    if source.len() > MAX_MAP_DOCUMENT_BYTES {
        return Err(MapLoadError::DocumentTooLarge {
            actual: source.len(),
            limit: MAX_MAP_DOCUMENT_BYTES,
        });
    }
    let raw: RawMapDocument = serde_json::from_slice(source)?;
    validate_document_header(&raw, mode)?;
    build_map(raw)
}

fn validate_document_header(raw: &RawMapDocument, mode: InputMode) -> Result<(), MapLoadError> {
    match mode {
        InputMode::Versioned => {
            let version = raw.schema_version.ok_or_else(|| {
                MapLoadError::invalid("$.schemaVersion", "is required for versioned maps")
            })?;
            if version != CURRENT_MAP_SCHEMA_VERSION {
                return Err(MapLoadError::UnsupportedSchemaVersion {
                    found: version,
                    supported: CURRENT_MAP_SCHEMA_VERSION,
                });
            }
            if raw.grid_layout.as_deref() != Some(GridLayout::OddQFlatTop.as_str()) {
                return Err(MapLoadError::invalid("$.gridLayout", "must be oddQFlatTop"));
            }
        }
        InputMode::Legacy => {
            if raw.schema_version.is_some() || raw.grid_layout.is_some() {
                return Err(MapLoadError::invalid(
                    "$",
                    "legacy adapter accepts only documents without version fields",
                ));
            }
        }
    }
    Ok(())
}

fn build_map(raw: RawMapDocument) -> Result<MapDefinition, MapLoadError> {
    validate_content_id("$.mapName", &raw.map_name)?;
    let cols = dimension("$.cols", raw.cols, MIN_COLS, MAX_COLS)?;
    let rows = dimension("$.rows", raw.rows, MIN_ROWS, MAX_ROWS)?;
    if !raw.default_zoom.is_finite() || raw.default_zoom <= 0.0 {
        return Err(MapLoadError::invalid(
            "$.defaultZoom",
            "must be finite and positive",
        ));
    }

    let expected_tile_count = usize::from(cols) * usize::from(rows);
    if raw.tiles.len() != expected_tile_count {
        return Err(MapLoadError::invalid(
            "$.tiles",
            format!(
                "must contain exactly {expected_tile_count} tiles for a {cols}x{rows} map; found {}",
                raw.tiles.len()
            ),
        ));
    }

    let mut tiles = raw
        .tiles
        .into_iter()
        .enumerate()
        .map(|(index, tile)| build_tile(tile, index, cols, rows))
        .collect::<Result<Vec<_>, _>>()?;
    tiles.sort_unstable_by_key(|tile| (tile.coordinate.row(), tile.coordinate.col()));
    validate_complete_grid(&tiles, cols)?;

    let mut objectives = build_objectives(raw.objectives, cols, rows)?;
    objectives.sort_unstable_by(|left, right| left.id.cmp(&right.id));

    Ok(MapDefinition {
        map_name: raw.map_name,
        grid_layout: GridLayout::OddQFlatTop,
        cols,
        rows,
        default_zoom: raw.default_zoom,
        tiles: tiles.into_boxed_slice(),
        objectives: objectives.into_boxed_slice(),
    })
}

fn build_tile(
    raw: RawTile,
    index: usize,
    cols: u16,
    rows: u16,
) -> Result<TileDefinition, MapLoadError> {
    let base_path = format!("$.tiles[{index}]");
    let coordinate = coordinate(
        &format!("{base_path}.col"),
        &format!("{base_path}.row"),
        raw.col,
        raw.row,
        cols,
        rows,
    )?;
    let height = u8::try_from(raw.height).map_err(|_| {
        MapLoadError::invalid(
            format!("{base_path}.height"),
            format!("must be in range 0..={MAX_HEIGHT}"),
        )
    })?;
    if height > MAX_HEIGHT {
        return Err(MapLoadError::invalid(
            format!("{base_path}.height"),
            format!("must be in range 0..={MAX_HEIGHT}"),
        ));
    }
    if raw.terrains.is_empty() {
        return Err(MapLoadError::invalid(
            format!("{base_path}.terrains"),
            "must contain at least one terrain",
        ));
    }

    let terrains = parse_unique_values(
        raw.terrains,
        &format!("{base_path}.terrains"),
        parse_terrain,
    )?;
    let mut resources = parse_unique_values(
        raw.resources,
        &format!("{base_path}.resources"),
        parse_resource,
    )?;
    resources.sort_unstable();

    Ok(TileDefinition {
        coordinate,
        terrains: terrains.into_boxed_slice(),
        resources: resources.into_boxed_slice(),
        height,
    })
}

fn parse_unique_values<Value: Copy + Ord>(
    raw_values: Vec<Box<str>>,
    path: &str,
    parse: fn(&str, &str) -> Result<Value, MapLoadError>,
) -> Result<Vec<Value>, MapLoadError> {
    let mut unique = BTreeSet::new();
    let mut values = Vec::with_capacity(raw_values.len());
    for (index, raw) in raw_values.into_iter().enumerate() {
        let item_path = format!("{path}[{index}]");
        let value = parse(&raw, &item_path)?;
        if !unique.insert(value) {
            return Err(MapLoadError::invalid(
                item_path,
                format!("duplicate value {raw:?}"),
            ));
        }
        values.push(value);
    }
    Ok(values)
}

fn validate_complete_grid(tiles: &[TileDefinition], cols: u16) -> Result<(), MapLoadError> {
    for (index, tile) in tiles.iter().enumerate() {
        let expected = HexCoord::new(
            i32::try_from(index % usize::from(cols)).unwrap_or(i32::MAX),
            i32::try_from(index / usize::from(cols)).unwrap_or(i32::MAX),
        );
        if tile.coordinate != expected {
            return Err(MapLoadError::invalid(
                "$.tiles",
                format!(
                    "tile coverage is incomplete or duplicated; expected ({}, {})",
                    expected.col(),
                    expected.row()
                ),
            ));
        }
    }
    Ok(())
}

fn build_objectives(
    raw_objectives: Vec<RawObjective>,
    cols: u16,
    rows: u16,
) -> Result<Vec<MapObjective>, MapLoadError> {
    let mut ids = BTreeSet::new();
    let mut coordinates = BTreeSet::new();
    let mut objectives = Vec::with_capacity(raw_objectives.len());
    for (index, raw) in raw_objectives.into_iter().enumerate() {
        let base_path = format!("$.objectives[{index}]");
        validate_content_id(&format!("{base_path}.id"), &raw.id)?;
        if !ids.insert(raw.id.clone()) {
            return Err(MapLoadError::invalid(
                format!("{base_path}.id"),
                format!("duplicate objective id {:?}", raw.id),
            ));
        }
        let coordinate = coordinate(
            &format!("{base_path}.hex.col"),
            &format!("{base_path}.hex.row"),
            raw.hex.col,
            raw.hex.row,
            cols,
            rows,
        )?;
        if !coordinates.insert(coordinate) {
            return Err(MapLoadError::invalid(
                format!("{base_path}.hex"),
                "only one objective may occupy a tile",
            ));
        }
        objectives.push(MapObjective {
            id: raw.id,
            objective_type: parse_objective_type(
                &raw.objective_type,
                &format!("{base_path}.type"),
            )?,
            coordinate,
            required_hold_turns: positive_u32(
                &format!("{base_path}.requiredHoldTurns"),
                raw.required_hold_turns,
            )?,
            victory_points: non_negative_u32(
                &format!("{base_path}.victoryPoints"),
                raw.victory_points,
            )?,
            gold_per_turn: non_negative_u32(
                &format!("{base_path}.goldPerTurn"),
                raw.gold_per_turn,
            )?,
        });
    }
    Ok(objectives)
}

fn dimension(path: &str, value: i64, minimum: u16, maximum: u16) -> Result<u16, MapLoadError> {
    let value = u16::try_from(value).map_err(|_| {
        MapLoadError::invalid(path, format!("must be in range {minimum}..={maximum}"))
    })?;
    if !(minimum..=maximum).contains(&value) {
        return Err(MapLoadError::invalid(
            path,
            format!("must be in range {minimum}..={maximum}"),
        ));
    }
    Ok(value)
}

fn coordinate(
    col_path: &str,
    row_path: &str,
    col: i64,
    row: i64,
    cols: u16,
    rows: u16,
) -> Result<HexCoord, MapLoadError> {
    if !(0..i64::from(cols)).contains(&col) {
        return Err(MapLoadError::invalid(
            col_path,
            format!("must be in range 0..{cols}"),
        ));
    }
    if !(0..i64::from(rows)).contains(&row) {
        return Err(MapLoadError::invalid(
            row_path,
            format!("must be in range 0..{rows}"),
        ));
    }
    let col = i32::try_from(col)
        .map_err(|_| MapLoadError::invalid(col_path, "coordinate does not fit i32"))?;
    let row = i32::try_from(row)
        .map_err(|_| MapLoadError::invalid(row_path, "coordinate does not fit i32"))?;
    Ok(HexCoord::new(col, row))
}

fn positive_u32(path: &str, value: i64) -> Result<u32, MapLoadError> {
    let value = non_negative_u32(path, value)?;
    if value == 0 {
        return Err(MapLoadError::invalid(path, "must be positive"));
    }
    Ok(value)
}

fn non_negative_u32(path: &str, value: i64) -> Result<u32, MapLoadError> {
    u32::try_from(value).map_err(|_| MapLoadError::invalid(path, "must be a non-negative u32"))
}

fn validate_content_id(path: &str, value: &str) -> Result<(), MapLoadError> {
    let bytes = value.as_bytes();
    let is_alphanumeric = |byte: u8| byte.is_ascii_lowercase() || byte.is_ascii_digit();
    let valid = !bytes.is_empty()
        && bytes.len() <= MAX_CONTENT_ID_BYTES
        && bytes.first().copied().is_some_and(is_alphanumeric)
        && bytes.last().copied().is_some_and(is_alphanumeric)
        && bytes
            .iter()
            .copied()
            .all(|byte| is_alphanumeric(byte) || byte == b'_' || byte == b'-');
    if valid {
        return Ok(());
    }
    Err(MapLoadError::invalid(
        path,
        "must be 1-64 lowercase ASCII letters, digits, underscores, or hyphens and start and end alphanumerically",
    ))
}

fn parse_terrain(value: &str, path: &str) -> Result<TerrainType, MapLoadError> {
    let terrain = match value {
        "ocean" => TerrainType::Ocean,
        "coast" => TerrainType::Coast,
        "lake" => TerrainType::Lake,
        "plains" => TerrainType::Plains,
        "grassland" => TerrainType::Grassland,
        "desert" => TerrainType::Desert,
        "tundra" => TerrainType::Tundra,
        "snow" => TerrainType::Snow,
        "mountain" => TerrainType::Mountain,
        "hills" => TerrainType::Hills,
        "wetlands" => TerrainType::Wetlands,
        "jungle" => TerrainType::Jungle,
        "forest" => TerrainType::Forest,
        "river" => TerrainType::River,
        _ => {
            return Err(MapLoadError::invalid(
                path,
                format!("unknown terrain {value:?}"),
            ));
        }
    };
    Ok(terrain)
}

fn parse_resource(value: &str, path: &str) -> Result<ResourceType, MapLoadError> {
    let resource = match value {
        "wheat" => ResourceType::Wheat,
        "fish" => ResourceType::Fish,
        "deer" => ResourceType::Deer,
        "sheep" => ResourceType::Sheep,
        "rice" => ResourceType::Rice,
        "cow" => ResourceType::Cow,
        "apple" => ResourceType::Apple,
        "banana" => ResourceType::Banana,
        "citrus" => ResourceType::Citrus,
        "gold" => ResourceType::Gold,
        "silver" => ResourceType::Silver,
        "gems" => ResourceType::Gems,
        "silk" => ResourceType::Silk,
        "spices" => ResourceType::Spices,
        "cotton" => ResourceType::Cotton,
        "grapes" => ResourceType::Grapes,
        "ivory" => ResourceType::Ivory,
        "pearls" => ResourceType::Pearls,
        "coffee" => ResourceType::Coffee,
        "cocoa" => ResourceType::Cocoa,
        "tobacco" => ResourceType::Tobacco,
        "sugar" => ResourceType::Sugar,
        "iron" => ResourceType::Iron,
        "coal" => ResourceType::Coal,
        "oil" => ResourceType::Oil,
        "aluminium" => ResourceType::Aluminium,
        "uranium" => ResourceType::Uranium,
        "horses" => ResourceType::Horses,
        "marble" => ResourceType::Marble,
        _ => {
            return Err(MapLoadError::invalid(
                path,
                format!("unknown resource {value:?}"),
            ));
        }
    };
    Ok(resource)
}

fn parse_objective_type(value: &str, path: &str) -> Result<MapObjectiveType, MapLoadError> {
    let objective_type = match value {
        "ruins" => MapObjectiveType::Ruins,
        "strategicPass" => MapObjectiveType::StrategicPass,
        "holySite" => MapObjectiveType::HolySite,
        "legendaryResource" => MapObjectiveType::LegendaryResource,
        _ => {
            return Err(MapLoadError::invalid(
                path,
                format!("unknown objective type {value:?}"),
            ));
        }
    };
    Ok(objective_type)
}

const fn default_zoom() -> f64 {
    1.0
}

const fn default_required_hold_turns() -> i64 {
    3
}

#[cfg(test)]
mod tests {
    use aonw_domain::HexCoord;
    use serde_json::{Value, json};

    use crate::{CURRENT_MAP_SCHEMA_VERSION, MapDefinition, MapLoadError, ResourceType};

    fn versioned_document() -> Value {
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
            "schemaVersion": CURRENT_MAP_SCHEMA_VERSION,
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

    fn encoded(value: &Value) -> Vec<u8> {
        serde_json::to_vec(value).expect("test document must serialize")
    }

    #[test]
    fn versioned_map_normalizes_for_constant_time_lookup() {
        let map =
            MapDefinition::from_json(&encoded(&versioned_document())).expect("valid map must load");

        assert_eq!(map.tiles().len(), 25);
        assert_eq!(map.tile_at(HexCoord::new(4, 3)).expect("tile").height(), 0);
        assert_eq!(
            map.tile_at(HexCoord::new(0, 0)).expect("tile").resources(),
            &[ResourceType::Wheat, ResourceType::Iron]
        );
        assert!(map.tile_at(HexCoord::new(-1, 0)).is_none());
    }

    #[test]
    fn canonical_hash_ignores_input_tile_and_resource_order() {
        let original = versioned_document();
        let mut reordered = original.clone();
        reordered["tiles"].as_array_mut().expect("tiles").reverse();
        reordered["tiles"][24]["resources"] = json!(["wheat", "iron"]);

        let original = MapDefinition::from_json(&encoded(&original)).expect("original");
        let reordered = MapDefinition::from_json(&encoded(&reordered)).expect("reordered");

        assert_eq!(
            original.content_hash().expect("hash"),
            reordered.content_hash().expect("hash")
        );
        assert_eq!(
            original.to_canonical_json().expect("json"),
            reordered.to_canonical_json().expect("json")
        );
    }

    #[test]
    fn missing_tile_fails_closed() {
        let mut document = versioned_document();
        document["tiles"].as_array_mut().expect("tiles").pop();

        assert!(matches!(
            MapDefinition::from_json(&encoded(&document)),
            Err(MapLoadError::Invalid { ref path, .. }) if path.as_ref() == "$.tiles"
        ));
    }

    #[test]
    fn unsupported_version_fails_closed() {
        let mut document = versioned_document();
        document["schemaVersion"] = json!(2);

        assert!(matches!(
            MapDefinition::from_json(&encoded(&document)),
            Err(MapLoadError::UnsupportedSchemaVersion { found: 2, .. })
        ));
    }

    #[test]
    fn legacy_adapter_is_explicit() {
        let mut document = versioned_document();
        document
            .as_object_mut()
            .expect("object")
            .remove("schemaVersion");
        document
            .as_object_mut()
            .expect("object")
            .remove("gridLayout");
        let source = encoded(&document);

        assert!(MapDefinition::from_json(&source).is_err());
        assert!(MapDefinition::from_legacy_json(&source).is_ok());
    }
}
