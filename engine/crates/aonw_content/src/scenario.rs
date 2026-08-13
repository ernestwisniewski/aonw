use std::io::{self, Write};

use aonw_domain::{
    GameState, GameStateBuildError, HexCoord, PlayerId, StateRevision, Unit, UnitBuildError,
    UnitId, UnitKind,
};
use serde::ser::{SerializeSeq, SerializeStruct};
use serde::{Serialize, Serializer};
use sha2::{Digest, Sha256};

use crate::{ContentHash, MapDefinition, RulesetDefinition, validation::validate_content_id};

/// Failure raised while constructing immutable scenario content.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioValidationError {
    path: Box<str>,
    message: Box<str>,
}

impl ScenarioValidationError {
    fn new(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self {
            path: path.into(),
            message: message.into(),
        }
    }
}

impl core::fmt::Display for ScenarioValidationError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(formatter, "{}: {}", self.path, self.message)
    }
}

impl std::error::Error for ScenarioValidationError {}

/// Failure raised while materializing a scenario into canonical state.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ScenarioBootstrapError {
    /// Supplied content does not match the scenario identity.
    ContentMismatch(&'static str),
    /// A referenced content hash could not be computed.
    ContentHash(Box<str>),
    /// A unit definition disappeared from the referenced ruleset.
    MissingUnitDefinition(UnitKind),
    /// An initial unit violates entity invariants.
    InvalidUnit(UnitBuildError),
    /// Initial units violate aggregate invariants.
    InvalidState(GameStateBuildError),
}

impl core::fmt::Display for ScenarioBootstrapError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::ContentMismatch(kind) => write!(
                formatter,
                "scenario {kind} identity does not match supplied content"
            ),
            Self::ContentHash(source) => {
                write!(formatter, "cannot hash referenced content: {source}")
            }
            Self::MissingUnitDefinition(kind) => {
                write!(formatter, "ruleset has no definition for {kind:?}")
            }
            Self::InvalidUnit(source) => write!(formatter, "invalid initial unit: {source}"),
            Self::InvalidState(source) => write!(formatter, "invalid initial state: {source}"),
        }
    }
}

impl std::error::Error for ScenarioBootstrapError {}

/// Initial unit placement owned by scenario content.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioUnitDefinition {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    position: HexCoord,
}

impl ScenarioUnitDefinition {
    /// Constructs one initial placement.
    #[must_use]
    pub fn new(
        id: UnitId,
        owner_player_id: PlayerId,
        kind: UnitKind,
        name: impl Into<Box<str>>,
        position: HexCoord,
    ) -> Self {
        Self {
            id,
            owner_player_id,
            kind,
            name: name.into(),
            position,
        }
    }
    /// Returns the unit identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }
    /// Returns the owner identifier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the canonical unit kind.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }
    /// Returns the initial display name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the initial coordinate.
    #[must_use]
    pub const fn position(&self) -> HexCoord {
        self.position
    }
}

/// Immutable scenario linked to exact map and ruleset identities.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ScenarioDefinition {
    schema_version: u16,
    scenario_id: Box<str>,
    map_id: Box<str>,
    map_hash: ContentHash,
    ruleset_id: Box<str>,
    ruleset_hash: ContentHash,
    initial_units: Box<[ScenarioUnitDefinition]>,
}

impl ScenarioDefinition {
    /// Validates a scenario against its referenced map and ruleset.
    ///
    /// # Errors
    ///
    /// Returns an error for invalid IDs, placements, duplicate units or unsupported kinds.
    pub fn try_new(
        scenario_id: impl Into<Box<str>>,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
        initial_units: impl IntoIterator<Item = ScenarioUnitDefinition>,
    ) -> Result<Self, ScenarioValidationError> {
        let scenario_id = scenario_id.into();
        validate_content_id("$.scenarioId", &scenario_id)
            .map_err(|error| ScenarioValidationError::new("$.scenarioId", error.to_string()))?;
        let initial_units = initial_units.into_iter().collect::<Vec<_>>();
        for (index, unit) in initial_units.iter().enumerate() {
            if unit.name().trim().is_empty() {
                return Err(ScenarioValidationError::new(
                    format!("$.initialUnits[{index}].name"),
                    "must not be blank",
                ));
            }
            if map.tile_at(unit.position()).is_none() {
                return Err(ScenarioValidationError::new(
                    format!("$.initialUnits[{index}]"),
                    "position is outside the referenced map",
                ));
            }
            if ruleset.unit(unit.kind()).is_none() {
                return Err(ScenarioValidationError::new(
                    format!("$.initialUnits[{index}].kind"),
                    "unit kind is absent from the referenced ruleset",
                ));
            }
        }
        let mut by_id = initial_units.iter().collect::<Vec<_>>();
        by_id.sort_unstable_by(|left, right| left.id().cmp(right.id()));
        if let Some(pair) = by_id.windows(2).find(|pair| pair[0].id() == pair[1].id()) {
            return Err(ScenarioValidationError::new(
                "$.initialUnits",
                format!("duplicate unit id: {}", pair[0].id()),
            ));
        }
        let mut by_position = initial_units.iter().collect::<Vec<_>>();
        by_position.sort_unstable_by_key(|unit| unit.position());
        if let Some(pair) = by_position.windows(2).find(|pair| {
            pair[0].position() == pair[1].position()
                && !ruleset
                    .occupancy_policy()
                    .permits(pair[0].owner_player_id(), pair[1].owner_player_id())
        }) {
            return Err(ScenarioValidationError::new(
                "$.initialUnits",
                format!(
                    "disallowed shared unit position: ({}, {})",
                    pair[0].position().col(),
                    pair[0].position().row()
                ),
            ));
        }
        Ok(Self {
            schema_version: 1,
            scenario_id,
            map_id: map.map_id().into(),
            map_hash: map
                .content_hash()
                .map_err(|error| ScenarioValidationError::new("$.mapHash", error.to_string()))?,
            ruleset_id: ruleset.ruleset_id().into(),
            ruleset_hash: ruleset.content_hash().map_err(|error| {
                ScenarioValidationError::new("$.rulesetHash", error.to_string())
            })?,
            initial_units: initial_units.into_boxed_slice(),
        })
    }

    /// Returns the scenario identifier.
    #[must_use]
    pub fn scenario_id(&self) -> &str {
        &self.scenario_id
    }
    /// Returns the referenced map hash.
    #[must_use]
    pub const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }
    /// Returns the referenced ruleset hash.
    #[must_use]
    pub const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }
    /// Returns initial units in authored order.
    #[must_use]
    pub const fn initial_units(&self) -> &[ScenarioUnitDefinition] {
        &self.initial_units
    }
    /// Computes SHA-256 over stable canonical scenario bytes.
    ///
    /// # Errors
    ///
    /// Returns an error when canonical serialization fails.
    pub fn content_hash(&self) -> Result<ContentHash, serde_json::Error> {
        let mut writer = HashWriter(Sha256::new());
        serde_json::to_writer(&mut writer, &CanonicalScenario(self))?;
        Ok(ContentHash(writer.0.finalize().into()))
    }

    /// Materializes the scenario as revision-zero canonical state.
    ///
    /// # Errors
    ///
    /// Returns an error if referenced content differs from the validated scenario
    /// or if a unit/state invariant cannot be established.
    pub fn bootstrap(
        &self,
        map: &MapDefinition,
        ruleset: &RulesetDefinition,
    ) -> Result<GameState, ScenarioBootstrapError> {
        let map_hash = map
            .content_hash()
            .map_err(|error| ScenarioBootstrapError::ContentHash(error.to_string().into()))?;
        if map.map_id() != &*self.map_id || map_hash != self.map_hash {
            return Err(ScenarioBootstrapError::ContentMismatch("map"));
        }
        let ruleset_hash = ruleset
            .content_hash()
            .map_err(|error| ScenarioBootstrapError::ContentHash(error.to_string().into()))?;
        if ruleset.ruleset_id() != &*self.ruleset_id || ruleset_hash != self.ruleset_hash {
            return Err(ScenarioBootstrapError::ContentMismatch("ruleset"));
        }
        let units = self
            .initial_units
            .iter()
            .map(|initial| {
                let definition = ruleset.unit(initial.kind()).ok_or(
                    ScenarioBootstrapError::MissingUnitDefinition(initial.kind()),
                )?;
                Unit::builder(
                    initial.id().clone(),
                    initial.owner_player_id().clone(),
                    initial.kind(),
                    initial.name(),
                    initial.position(),
                    definition.maximum_movement(false),
                )
                .build()
                .map_err(ScenarioBootstrapError::InvalidUnit)
            })
            .collect::<Result<Vec<_>, _>>()?;
        GameState::try_new(
            StateRevision::INITIAL,
            0,
            map.bounds(),
            ruleset.occupancy_policy(),
            units,
        )
        .map_err(ScenarioBootstrapError::InvalidState)
    }
}

struct CanonicalScenario<'a>(&'a ScenarioDefinition);
impl Serialize for CanonicalScenario<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let scenario = self.0;
        let mut value = serializer.serialize_struct("CanonicalScenario", 7)?;
        value.serialize_field("schemaVersion", &scenario.schema_version)?;
        value.serialize_field("scenarioId", &scenario.scenario_id)?;
        value.serialize_field("mapId", &scenario.map_id)?;
        value.serialize_field("mapHash", scenario.map_hash.as_bytes())?;
        value.serialize_field("rulesetId", &scenario.ruleset_id)?;
        value.serialize_field("rulesetHash", scenario.ruleset_hash.as_bytes())?;
        value.serialize_field("initialUnits", &CanonicalUnits(&scenario.initial_units))?;
        value.end()
    }
}

struct CanonicalUnits<'a>(&'a [ScenarioUnitDefinition]);
impl Serialize for CanonicalUnits<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let mut sequence = serializer.serialize_seq(Some(self.0.len()))?;
        for unit in self.0 {
            sequence.serialize_element(&CanonicalUnit(unit))?;
        }
        sequence.end()
    }
}

struct CanonicalUnit<'a>(&'a ScenarioUnitDefinition);
impl Serialize for CanonicalUnit<'_> {
    fn serialize<S: Serializer>(&self, serializer: S) -> Result<S::Ok, S::Error> {
        let unit = self.0;
        let mut value = serializer.serialize_struct("CanonicalScenarioUnit", 6)?;
        value.serialize_field("id", unit.id().as_str())?;
        value.serialize_field("ownerPlayerId", unit.owner_player_id().as_str())?;
        value.serialize_field("kind", unit_kind_name(unit.kind()))?;
        value.serialize_field("name", unit.name())?;
        value.serialize_field("col", &unit.position().col())?;
        value.serialize_field("row", &unit.position().row())?;
        value.end()
    }
}

const fn unit_kind_name(kind: UnitKind) -> &'static str {
    match kind {
        UnitKind::Commander => "commander",
        UnitKind::Warrior => "warrior",
        UnitKind::Archer => "archer",
        UnitKind::Settler => "settler",
        UnitKind::Worker => "worker",
        UnitKind::Merchant => "merchant",
        UnitKind::Scout => "scout",
        UnitKind::Spearman => "spearman",
        UnitKind::Cavalry => "cavalry",
        UnitKind::Catapult => "catapult",
        UnitKind::HeavyInfantry => "heavyInfantry",
        UnitKind::FieldCannon => "fieldCannon",
        UnitKind::Rifleman => "rifleman",
        UnitKind::Tank => "tank",
        UnitKind::ScoutShip => "scoutShip",
        UnitKind::Warship => "warship",
        UnitKind::ReconPlane => "reconPlane",
    }
}

struct HashWriter(Sha256);
impl Write for HashWriter {
    fn write(&mut self, buffer: &[u8]) -> io::Result<usize> {
        self.0.update(buffer);
        Ok(buffer.len())
    }
    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::{HexCoord, PlayerId, UnitId, UnitKind};

    use crate::{
        GridLayout, MapDefinition, RulesetDefinition, ScenarioDefinition, ScenarioUnitDefinition,
        TerrainType, TileDefinition,
    };

    fn map() -> MapDefinition {
        let tiles = (0..2)
            .flat_map(|row| {
                (0..2).map(move |col| {
                    TileDefinition::try_new(
                        HexCoord::new(col, row),
                        vec![TerrainType::Plains],
                        Vec::new(),
                        0,
                    )
                    .expect("tile")
                })
            })
            .collect();
        MapDefinition::try_new(
            "scenario-map",
            GridLayout::OddQFlatTop,
            2,
            2,
            tiles,
            Vec::new(),
        )
        .expect("map")
    }

    fn initial(id: &str, owner: &str, position: HexCoord) -> ScenarioUnitDefinition {
        ScenarioUnitDefinition::new(
            UnitId::new(id).expect("unit id"),
            PlayerId::new(owner).expect("owner id"),
            UnitKind::Commander,
            "unit.commander",
            position,
        )
    }

    #[test]
    fn scenario_bootstraps_full_state_from_map_and_ruleset() {
        let map = map();
        let ruleset = RulesetDefinition::standard();
        let scenario = ScenarioDefinition::try_new(
            "duel",
            &map,
            &ruleset,
            [
                initial("unit-1", "player-1", HexCoord::new(0, 0)),
                initial("unit-2", "player-2", HexCoord::new(1, 1)),
            ],
        )
        .expect("scenario");

        let state = scenario.bootstrap(&map, &ruleset).expect("state");
        assert_eq!(state.units().len(), 2);
        assert_eq!(
            state.units()[0].movement_units(),
            ruleset
                .unit(UnitKind::Commander)
                .expect("definition")
                .maximum_movement(false)
        );
        assert_ne!(
            scenario.content_hash().expect("scenario hash"),
            scenario.map_hash()
        );
        assert_ne!(scenario.ruleset_hash(), scenario.map_hash());
        assert_eq!(
            scenario.content_hash().expect("hash").to_string(),
            "d3f37241a2c47f183891761c1409d0e1107b0c31cf486b8260e45ea6b06031ba"
        );
    }

    #[test]
    fn scenario_rejects_hostile_stacking_but_allows_friendly_stacking() {
        let map = map();
        let ruleset = RulesetDefinition::standard();
        let position = HexCoord::new(0, 0);
        assert!(
            ScenarioDefinition::try_new(
                "friendly",
                &map,
                &ruleset,
                [
                    initial("one", "player-1", position),
                    initial("two", "player-1", position)
                ]
            )
            .is_ok()
        );
        assert!(
            ScenarioDefinition::try_new(
                "hostile",
                &map,
                &ruleset,
                [
                    initial("one", "player-1", position),
                    initial("two", "player-2", position)
                ]
            )
            .is_err()
        );
    }
}
