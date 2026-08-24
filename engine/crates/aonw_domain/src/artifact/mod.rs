use crate::{ArtifactId, CityId, HexCoord, UnitId};

/// Stable artifact category.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
pub enum WorldArtifactType {
    AncientImperialCrown,
    AstronomersTablets,
    ProphetMask,
    HeroSword,
    MerchantsSeal,
    FirstPeoplesChronicle,
    TempleReliquary,
    QueensMirror,
}

impl WorldArtifactType {
    /// Returns the city defense and hit-point bonus while stored in a city.
    #[must_use]
    pub const fn stored_city_defense_bonus(self) -> i32 {
        match self {
            Self::AncientImperialCrown | Self::TempleReliquary => 1,
            Self::AstronomersTablets
            | Self::ProphetMask
            | Self::HeroSword
            | Self::MerchantsSeal
            | Self::FirstPeoplesChronicle
            | Self::QueensMirror => 0,
        }
    }
}

/// Canonical location of one world artifact.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum WorldArtifactLocation {
    /// Artifact placed on the map.
    Map(HexCoord),
    /// Artifact carried by a unit.
    Carried(UnitId),
    /// Artifact stored in a city.
    Stored(CityId),
    /// Artifact currently excavated by a unit.
    Excavation {
        /// Excavating unit.
        unit_id: UnitId,
        /// Original map coordinate.
        coordinate: HexCoord,
        /// Turns remaining.
        remaining_turns: u32,
    },
}

impl WorldArtifactLocation {
    /// Returns a map coordinate when the artifact occupies a tile.
    #[must_use]
    pub const fn map_coordinate(&self) -> Option<HexCoord> {
        match self {
            Self::Map(coordinate) | Self::Excavation { coordinate, .. } => Some(*coordinate),
            Self::Carried(_) | Self::Stored(_) => None,
        }
    }
}

/// Artifact entity owned by the canonical game aggregate.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct WorldArtifact {
    id: ArtifactId,
    artifact_type: WorldArtifactType,
    location: WorldArtifactLocation,
}

impl WorldArtifact {
    /// Creates an artifact from validated value objects.
    #[must_use]
    pub const fn new(
        id: ArtifactId,
        artifact_type: WorldArtifactType,
        location: WorldArtifactLocation,
    ) -> Self {
        Self {
            id,
            artifact_type,
            location,
        }
    }

    /// Returns the artifact identifier.
    #[must_use]
    pub const fn id(&self) -> &ArtifactId {
        &self.id
    }

    /// Returns the stable category.
    #[must_use]
    pub const fn artifact_type(&self) -> WorldArtifactType {
        self.artifact_type
    }

    /// Returns the canonical location.
    #[must_use]
    pub const fn location(&self) -> &WorldArtifactLocation {
        &self.location
    }

    /// Drops an artifact when its combat carrier or storage city was defeated.
    #[must_use]
    pub fn after_combat_loss(
        &self,
        unit_id: Option<&UnitId>,
        city_id: Option<&CityId>,
        coordinate: HexCoord,
    ) -> Self {
        let should_drop = match &self.location {
            WorldArtifactLocation::Carried(value)
            | WorldArtifactLocation::Excavation { unit_id: value, .. } => unit_id == Some(value),
            WorldArtifactLocation::Stored(value) => city_id == Some(value),
            WorldArtifactLocation::Map(_) => false,
        };
        let mut updated = self.clone();
        if should_drop {
            updated.location = WorldArtifactLocation::Map(coordinate);
        }
        updated
    }

    pub(crate) fn restore_excavation(&mut self, unit_id: &UnitId) {
        let WorldArtifactLocation::Excavation {
            unit_id: excavator,
            coordinate,
            ..
        } = &self.location
        else {
            return;
        };
        if excavator == unit_id {
            self.location = WorldArtifactLocation::Map(*coordinate);
        }
    }
}
