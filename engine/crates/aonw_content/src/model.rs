use aonw_domain::HexCoord;

use crate::catalog::{GridLayout, MapObjectiveType, ResourceType, TerrainType};
use crate::validation::{MapValidationError, validate_content_id};

const MIN_COLS: u16 = 1;
const MAX_COLS: u16 = 40;
const MIN_ROWS: u16 = 1;
const MAX_ROWS: u16 = 30;
const MAX_HEIGHT: u8 = 5;
const MAX_TILE_COUNT: usize = MAX_COLS as usize * MAX_ROWS as usize;
const OBJECTIVE_OCCUPANCY_WORDS: usize = MAX_TILE_COUNT.div_ceil(u64::BITS as usize);

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TileDefinition {
    coordinate: HexCoord,
    terrains: Box<[TerrainType]>,
    resources: Box<[ResourceType]>,
    height: u8,
}

#[allow(missing_docs)]
impl TileDefinition {
    /// Constructs a validated logical map tile.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for empty or duplicate terrain data,
    /// duplicate resources, or unsupported height.
    pub fn try_new(
        coordinate: HexCoord,
        terrains: Vec<TerrainType>,
        resources: Vec<ResourceType>,
        height: u8,
    ) -> Result<Self, MapValidationError> {
        Self::try_new_at("$", coordinate, terrains, resources, height)
    }

    pub(crate) fn try_new_at(
        path: &str,
        coordinate: HexCoord,
        terrains: Vec<TerrainType>,
        mut resources: Vec<ResourceType>,
        height: u8,
    ) -> Result<Self, MapValidationError> {
        if terrains.is_empty() {
            return Err(MapValidationError::new(
                format!("{path}.terrains"),
                "must contain at least one terrain",
            ));
        }
        validate_unique_values(
            &format!("{path}.terrains"),
            &terrains,
            TerrainType::canonical_rank,
        )?;
        validate_unique_values(
            &format!("{path}.resources"),
            &resources,
            ResourceType::canonical_rank,
        )?;
        if height > MAX_HEIGHT {
            return Err(MapValidationError::new(
                format!("{path}.height"),
                format!("must be in range 0..={MAX_HEIGHT}"),
            ));
        }
        resources.sort_unstable_by_key(|resource| resource.canonical_rank());
        Ok(Self {
            coordinate,
            terrains: terrains.into_boxed_slice(),
            resources: resources.into_boxed_slice(),
            height,
        })
    }

    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    #[must_use]
    pub fn terrains(&self) -> &[TerrainType] {
        &self.terrains
    }

    #[must_use]
    pub fn resources(&self) -> &[ResourceType] {
        &self.resources
    }

    #[must_use]
    pub const fn height(&self) -> u8 {
        self.height
    }
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjective {
    id: Box<str>,
    objective_type: MapObjectiveType,
    coordinate: HexCoord,
    required_hold_turns: u32,
    victory_points: u32,
    gold_per_turn: u32,
}

#[allow(missing_docs)]
impl MapObjective {
    /// Constructs a validated logical map objective.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for an invalid identifier or zero hold duration.
    #[allow(clippy::too_many_arguments)]
    pub fn try_new(
        id: impl Into<Box<str>>,
        objective_type: MapObjectiveType,
        coordinate: HexCoord,
        required_hold_turns: u32,
        victory_points: u32,
        gold_per_turn: u32,
    ) -> Result<Self, MapValidationError> {
        Self::try_new_at(
            "$",
            id.into(),
            objective_type,
            coordinate,
            required_hold_turns,
            victory_points,
            gold_per_turn,
        )
    }

    #[allow(clippy::too_many_arguments)]
    pub(crate) fn try_new_at(
        path: &str,
        id: Box<str>,
        objective_type: MapObjectiveType,
        coordinate: HexCoord,
        required_hold_turns: u32,
        victory_points: u32,
        gold_per_turn: u32,
    ) -> Result<Self, MapValidationError> {
        validate_content_id(&format!("{path}.id"), &id)?;
        if required_hold_turns == 0 {
            return Err(MapValidationError::new(
                format!("{path}.requiredHoldTurns"),
                "must be positive",
            ));
        }
        Ok(Self {
            id,
            objective_type,
            coordinate,
            required_hold_turns,
            victory_points,
            gold_per_turn,
        })
    }

    #[must_use]
    pub fn id(&self) -> &str {
        &self.id
    }

    #[must_use]
    pub const fn objective_type(&self) -> MapObjectiveType {
        self.objective_type
    }

    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    #[must_use]
    pub const fn required_hold_turns(&self) -> u32 {
        self.required_hold_turns
    }

    #[must_use]
    pub const fn victory_points(&self) -> u32 {
        self.victory_points
    }

    #[must_use]
    pub const fn gold_per_turn(&self) -> u32 {
        self.gold_per_turn
    }
}

#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapDefinition {
    map_id: Box<str>,
    grid_layout: GridLayout,
    cols: u16,
    rows: u16,
    tiles: Box<[TileDefinition]>,
    objectives: Box<[MapObjective]>,
}

#[allow(missing_docs)]
impl MapDefinition {
    /// Constructs a complete validated logical map.
    ///
    /// # Errors
    ///
    /// Returns [`MapValidationError`] for invalid dimensions, identifiers,
    /// tile coverage, objective identifiers, positions, or occupancy.
    pub fn try_new(
        map_id: impl Into<Box<str>>,
        grid_layout: GridLayout,
        cols: u16,
        rows: u16,
        mut tiles: Vec<TileDefinition>,
        mut objectives: Vec<MapObjective>,
    ) -> Result<Self, MapValidationError> {
        let map_id = map_id.into();
        validate_content_id("$.mapName", &map_id)?;
        validate_dimension("$.cols", cols, MIN_COLS, MAX_COLS)?;
        validate_dimension("$.rows", rows, MIN_ROWS, MAX_ROWS)?;
        validate_tiles(&mut tiles, cols, rows)?;
        validate_objectives(&mut objectives, cols, rows)?;
        Ok(Self {
            map_id,
            grid_layout,
            cols,
            rows,
            tiles: tiles.into_boxed_slice(),
            objectives: objectives.into_boxed_slice(),
        })
    }

    #[must_use]
    pub fn map_id(&self) -> &str {
        &self.map_id
    }

    #[must_use]
    pub const fn grid_layout(&self) -> GridLayout {
        self.grid_layout
    }

    #[must_use]
    pub const fn cols(&self) -> u16 {
        self.cols
    }

    #[must_use]
    pub const fn rows(&self) -> u16 {
        self.rows
    }

    #[must_use]
    pub fn tiles(&self) -> &[TileDefinition] {
        &self.tiles
    }

    #[must_use]
    pub fn objectives(&self) -> &[MapObjective] {
        &self.objectives
    }

    #[must_use]
    pub fn tile_at(&self, coordinate: HexCoord) -> Option<&TileDefinition> {
        let col = usize::try_from(coordinate.col()).ok()?;
        let row = usize::try_from(coordinate.row()).ok()?;
        if col >= usize::from(self.cols) || row >= usize::from(self.rows) {
            return None;
        }
        self.tiles
            .get(row * usize::from(self.cols) + col)
            .filter(|tile| tile.coordinate == coordinate)
    }
}

fn validate_tiles(
    tiles: &mut [TileDefinition],
    cols: u16,
    rows: u16,
) -> Result<(), MapValidationError> {
    let expected_count = usize::from(cols) * usize::from(rows);
    if tiles.len() != expected_count {
        return Err(MapValidationError::new(
            "$.tiles",
            format!(
                "must contain exactly {expected_count} tiles for a {cols}x{rows} map; found {}",
                tiles.len()
            ),
        ));
    }
    tiles.sort_unstable_by_key(|tile| (tile.coordinate.row(), tile.coordinate.col()));
    for (index, tile) in tiles.iter().enumerate() {
        let expected = HexCoord::new(
            i32::try_from(index % usize::from(cols)).expect("map width fits i32"),
            i32::try_from(index / usize::from(cols)).expect("map height fits i32"),
        );
        if tile.coordinate != expected {
            return Err(MapValidationError::new(
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

fn validate_objectives(
    objectives: &mut [MapObjective],
    cols: u16,
    rows: u16,
) -> Result<(), MapValidationError> {
    objectives.sort_unstable_by(|left, right| left.id.cmp(&right.id));
    if let Some(pair) = objectives.windows(2).find(|pair| pair[0].id == pair[1].id) {
        return Err(MapValidationError::new(
            "$.objectives",
            format!("duplicate objective id {:?}", pair[0].id),
        ));
    }
    let mut occupied = [0_u64; OBJECTIVE_OCCUPANCY_WORDS];
    for objective in objectives {
        let col = usize::try_from(objective.coordinate.col()).map_err(|_| {
            MapValidationError::new("$.objectives", "objective coordinate is outside map bounds")
        })?;
        let row = usize::try_from(objective.coordinate.row()).map_err(|_| {
            MapValidationError::new("$.objectives", "objective coordinate is outside map bounds")
        })?;
        if col >= usize::from(cols) || row >= usize::from(rows) {
            return Err(MapValidationError::new(
                "$.objectives",
                "objective coordinate is outside map bounds",
            ));
        }
        let index = row * usize::from(cols) + col;
        let bit = 1_u64 << (index % u64::BITS as usize);
        let word = &mut occupied[index / u64::BITS as usize];
        if *word & bit != 0 {
            return Err(MapValidationError::new(
                "$.objectives",
                "only one objective may occupy a tile",
            ));
        }
        *word |= bit;
    }
    Ok(())
}

fn validate_unique_values<Value: Copy>(
    path: &str,
    values: &[Value],
    rank: fn(Value) -> u8,
) -> Result<(), MapValidationError> {
    let mut seen = 0_u64;
    for value in values {
        let bit = 1_u64 << rank(*value);
        if seen & bit != 0 {
            return Err(MapValidationError::new(path, "must not contain duplicates"));
        }
        seen |= bit;
    }
    Ok(())
}

fn validate_dimension(
    path: &str,
    value: u16,
    minimum: u16,
    maximum: u16,
) -> Result<(), MapValidationError> {
    if (minimum..=maximum).contains(&value) {
        return Ok(());
    }
    Err(MapValidationError::new(
        path,
        format!("must be in range {minimum}..={maximum}"),
    ))
}
