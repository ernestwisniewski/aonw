use serde::Deserialize;

use crate::CURRENT_MAP_SCHEMA_VERSION;

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct VersionedMapDocument {
    pub(super) schema_version: u64,
    pub(super) grid_layout: Box<str>,
    pub(super) cols: i64,
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    pub(super) default_zoom: f64,
    pub(super) objectives: Vec<RawObjective>,
    pub(super) tiles: Vec<RawTile>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct LegacyMapDocument {
    pub(super) cols: i64,
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    #[serde(default = "default_zoom")]
    pub(super) default_zoom: f64,
    #[serde(default)]
    pub(super) objectives: Vec<LegacyObjective>,
    pub(super) tiles: Vec<RawTile>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct RawTile {
    pub(super) col: i64,
    pub(super) row: i64,
    pub(super) terrains: Vec<Box<str>>,
    pub(super) resources: Vec<Box<str>>,
    pub(super) height: i64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct RawObjective {
    pub(super) id: Box<str>,
    #[serde(rename = "type")]
    pub(super) objective_type: Box<str>,
    pub(super) hex: RawCoordinate,
    pub(super) required_hold_turns: i64,
    pub(super) victory_points: i64,
    pub(super) gold_per_turn: i64,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(super) struct LegacyObjective {
    pub(super) id: Box<str>,
    #[serde(rename = "type")]
    pub(super) objective_type: Box<str>,
    pub(super) hex: RawCoordinate,
    #[serde(default = "default_required_hold_turns")]
    pub(super) required_hold_turns: i64,
    #[serde(default)]
    pub(super) victory_points: i64,
    #[serde(default)]
    pub(super) gold_per_turn: i64,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub(super) struct RawCoordinate {
    pub(super) col: i64,
    pub(super) row: i64,
}

pub(super) struct RawMap {
    pub(super) cols: i64,
    pub(super) rows: i64,
    pub(super) map_name: Box<str>,
    pub(super) default_zoom: f64,
    pub(super) objectives: Vec<RawObjective>,
    pub(super) tiles: Vec<RawTile>,
}

impl TryFrom<VersionedMapDocument> for RawMap {
    type Error = crate::MapLoadError;

    fn try_from(raw: VersionedMapDocument) -> Result<Self, Self::Error> {
        if raw.schema_version != CURRENT_MAP_SCHEMA_VERSION {
            return Err(crate::MapLoadError::UnsupportedSchemaVersion {
                found: raw.schema_version,
                supported: CURRENT_MAP_SCHEMA_VERSION,
            });
        }
        if raw.grid_layout.as_ref() != "oddQFlatTop" {
            return Err(crate::MapLoadError::invalid(
                "$.gridLayout",
                "must be oddQFlatTop",
            ));
        }
        Ok(Self {
            cols: raw.cols,
            rows: raw.rows,
            map_name: raw.map_name,
            default_zoom: raw.default_zoom,
            objectives: raw.objectives,
            tiles: raw.tiles,
        })
    }
}

impl From<LegacyMapDocument> for RawMap {
    fn from(raw: LegacyMapDocument) -> Self {
        Self {
            cols: raw.cols,
            rows: raw.rows,
            map_name: raw.map_name,
            default_zoom: raw.default_zoom,
            objectives: raw.objectives.into_iter().map(RawObjective::from).collect(),
            tiles: raw.tiles,
        }
    }
}

impl From<LegacyObjective> for RawObjective {
    fn from(raw: LegacyObjective) -> Self {
        Self {
            id: raw.id,
            objective_type: raw.objective_type,
            hex: raw.hex,
            required_hold_turns: raw.required_hold_turns,
            victory_points: raw.victory_points,
            gold_per_turn: raw.gold_per_turn,
        }
    }
}

const fn default_zoom() -> f64 {
    1.0
}

const fn default_required_hold_turns() -> i64 {
    3
}
