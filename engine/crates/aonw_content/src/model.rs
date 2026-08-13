use std::fmt;

use aonw_domain::HexCoord;
use serde::Serialize;

/// Canonical grid geometry shared by content and presentation adapters.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum GridLayout {
    /// Odd columns are shifted down on a flat-top grid.
    OddQFlatTop,
}

impl GridLayout {
    /// Returns the stable wire name.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::OddQFlatTop => "oddQFlatTop",
        }
    }
}

/// Terrain layers accepted by map schema version 1.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum TerrainType {
    Ocean,
    Coast,
    Lake,
    Plains,
    Grassland,
    Desert,
    Tundra,
    Snow,
    Mountain,
    Hills,
    Wetlands,
    Jungle,
    Forest,
    River,
}

impl TerrainType {
    /// Returns the stable wire name.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Ocean => "ocean",
            Self::Coast => "coast",
            Self::Lake => "lake",
            Self::Plains => "plains",
            Self::Grassland => "grassland",
            Self::Desert => "desert",
            Self::Tundra => "tundra",
            Self::Snow => "snow",
            Self::Mountain => "mountain",
            Self::Hills => "hills",
            Self::Wetlands => "wetlands",
            Self::Jungle => "jungle",
            Self::Forest => "forest",
            Self::River => "river",
        }
    }
}

/// Resources accepted by map schema version 1.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum ResourceType {
    Wheat,
    Fish,
    Deer,
    Sheep,
    Rice,
    Cow,
    Apple,
    Banana,
    Citrus,
    Gold,
    Silver,
    Gems,
    Silk,
    Spices,
    Cotton,
    Grapes,
    Ivory,
    Pearls,
    Coffee,
    Cocoa,
    Tobacco,
    Sugar,
    Iron,
    Coal,
    Oil,
    Aluminium,
    Uranium,
    Horses,
    Marble,
}

impl ResourceType {
    /// Returns the stable wire name.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Wheat => "wheat",
            Self::Fish => "fish",
            Self::Deer => "deer",
            Self::Sheep => "sheep",
            Self::Rice => "rice",
            Self::Cow => "cow",
            Self::Apple => "apple",
            Self::Banana => "banana",
            Self::Citrus => "citrus",
            Self::Gold => "gold",
            Self::Silver => "silver",
            Self::Gems => "gems",
            Self::Silk => "silk",
            Self::Spices => "spices",
            Self::Cotton => "cotton",
            Self::Grapes => "grapes",
            Self::Ivory => "ivory",
            Self::Pearls => "pearls",
            Self::Coffee => "coffee",
            Self::Cocoa => "cocoa",
            Self::Tobacco => "tobacco",
            Self::Sugar => "sugar",
            Self::Iron => "iron",
            Self::Coal => "coal",
            Self::Oil => "oil",
            Self::Aluminium => "aluminium",
            Self::Uranium => "uranium",
            Self::Horses => "horses",
            Self::Marble => "marble",
        }
    }
}

/// Strategic map objective category.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd, Serialize)]
#[serde(rename_all = "camelCase")]
pub enum MapObjectiveType {
    Ruins,
    StrategicPass,
    HolySite,
    LegendaryResource,
}

impl MapObjectiveType {
    /// Returns the stable wire name.
    #[must_use]
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Ruins => "ruins",
            Self::StrategicPass => "strategicPass",
            Self::HolySite => "holySite",
            Self::LegendaryResource => "legendaryResource",
        }
    }
}

/// Immutable logical definition of one map tile.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct TileDefinition {
    pub(crate) coordinate: HexCoord,
    pub(crate) terrains: Box<[TerrainType]>,
    pub(crate) resources: Box<[ResourceType]>,
    pub(crate) height: u8,
}

#[allow(missing_docs)]
impl TileDefinition {
    #[must_use]
    pub const fn coordinate(&self) -> HexCoord {
        self.coordinate
    }

    /// Returns ordered terrain layers. The first entry is primary terrain.
    #[must_use]
    pub fn terrains(&self) -> &[TerrainType] {
        &self.terrains
    }

    /// Returns canonically sorted resources.
    #[must_use]
    pub fn resources(&self) -> &[ResourceType] {
        &self.resources
    }

    #[must_use]
    pub const fn height(&self) -> u8 {
        self.height
    }
}

/// Immutable objective embedded in a map document.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MapObjective {
    pub(crate) id: Box<str>,
    pub(crate) objective_type: MapObjectiveType,
    pub(crate) coordinate: HexCoord,
    pub(crate) required_hold_turns: u32,
    pub(crate) victory_points: u32,
    pub(crate) gold_per_turn: u32,
}

#[allow(missing_docs)]
impl MapObjective {
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

/// Validated map stored in deterministic row-major order.
#[derive(Clone, Debug, PartialEq)]
pub struct MapDefinition {
    pub(crate) map_name: Box<str>,
    pub(crate) grid_layout: GridLayout,
    pub(crate) cols: u16,
    pub(crate) rows: u16,
    pub(crate) default_zoom: f64,
    pub(crate) tiles: Box<[TileDefinition]>,
    pub(crate) objectives: Box<[MapObjective]>,
}

#[allow(missing_docs)]
impl MapDefinition {
    #[must_use]
    pub fn map_name(&self) -> &str {
        &self.map_name
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
    pub const fn default_zoom(&self) -> f64 {
        self.default_zoom
    }

    /// Returns every tile in deterministic row-major order.
    #[must_use]
    pub fn tiles(&self) -> &[TileDefinition] {
        &self.tiles
    }

    /// Returns objectives sorted by identifier.
    #[must_use]
    pub fn objectives(&self) -> &[MapObjective] {
        &self.objectives
    }

    /// Looks up a tile without allocating or hashing.
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

/// SHA-256 digest of a normalized canonical map document.
#[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
pub struct ContentHash(pub(crate) [u8; 32]);

#[allow(missing_docs)]
impl ContentHash {
    #[must_use]
    pub const fn as_bytes(&self) -> &[u8; 32] {
        &self.0
    }
}

impl fmt::Display for ContentHash {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        for byte in self.0 {
            write!(formatter, "{byte:02x}")?;
        }
        Ok(())
    }
}
