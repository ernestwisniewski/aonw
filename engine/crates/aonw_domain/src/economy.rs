use std::collections::{BTreeMap, BTreeSet};

use crate::{HexCoord, HexGridBounds, MatchIdentity, PlayerId};

/// Resource identifier preserved by canonical economy state.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, Ord, PartialEq, PartialOrd)]
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
    /// Returns whether this resource uses a transferable stockpile.
    #[must_use]
    pub const fn is_stockpiled(self) -> bool {
        matches!(self, Self::Oil | Self::Aluminium)
    }
}

/// Positive stockpiled strategic resource amounts in stable resource order.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct StrategicResourceStockpile(BTreeMap<ResourceType, i64>);

impl StrategicResourceStockpile {
    /// Validates stockpiled resource kinds and positive amounts.
    ///
    /// # Errors
    ///
    /// Returns an error for non-stockpiled resources or non-positive values.
    pub fn try_new(amounts: BTreeMap<ResourceType, i64>) -> Result<Self, EconomyStateBuildError> {
        for (resource, amount) in &amounts {
            if !resource.is_stockpiled() {
                return Err(EconomyStateBuildError::ResourceNotStockpiled(*resource));
            }
            if *amount <= 0 {
                return Err(EconomyStateBuildError::NonPositiveResourceAmount {
                    resource: *resource,
                    amount: *amount,
                });
            }
        }
        Ok(Self(amounts))
    }

    /// Returns positive amounts sorted by resource identity.
    #[must_use]
    pub const fn amounts(&self) -> &BTreeMap<ResourceType, i64> {
        &self.0
    }
}

/// One generated resource placement retained by canonical state.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct InitialResourcePlacement {
    coordinate: HexCoord,
    resource: ResourceType,
}

impl InitialResourcePlacement {
    /// Constructs one placement.
    #[must_use]
    pub const fn new(coordinate: HexCoord, resource: ResourceType) -> Self {
        Self {
            coordinate,
            resource,
        }
    }

    /// Returns map coordinate.
    #[must_use]
    pub const fn coordinate(self) -> HexCoord {
        self.coordinate
    }

    /// Returns placed resource.
    #[must_use]
    pub const fn resource(self) -> ResourceType {
        self.resource
    }
}

/// Persisted deterministic match-start resource placements.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct InitialResourceDistribution {
    seed: i64,
    placements: Box<[InitialResourcePlacement]>,
}

impl InitialResourceDistribution {
    /// Owns ordered placements and rejects duplicate coordinates.
    ///
    /// # Errors
    ///
    /// Returns an error when multiple resources use one coordinate.
    pub fn try_new(
        seed: i64,
        placements: impl IntoIterator<Item = InitialResourcePlacement>,
    ) -> Result<Self, EconomyStateBuildError> {
        let placements = placements.into_iter().collect::<Vec<_>>();
        let mut coordinates = BTreeSet::new();
        for placement in &placements {
            if !coordinates.insert(placement.coordinate()) {
                return Err(EconomyStateBuildError::DuplicateInitialResource(
                    placement.coordinate(),
                ));
            }
        }
        Ok(Self {
            seed,
            placements: placements.into_boxed_slice(),
        })
    }

    /// Returns deterministic generator seed retained for evidence.
    #[must_use]
    pub const fn seed(&self) -> i64 {
        self.seed
    }

    /// Returns placements in canonical contract order.
    #[must_use]
    pub const fn placements(&self) -> &[InitialResourcePlacement] {
        &self.placements
    }
}

/// Canonical player economy accounts and initial resource distribution.
#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct EconomyState {
    player_gold: BTreeMap<PlayerId, i64>,
    player_war_weariness: BTreeMap<PlayerId, i64>,
    player_stability_net: BTreeMap<PlayerId, i64>,
    strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
    initial_resource_distribution: InitialResourceDistribution,
}

impl EconomyState {
    /// Validates participant ownership and generated placement bounds.
    ///
    /// # Errors
    ///
    /// Returns an error for an unknown player or out-of-bounds placement.
    pub fn try_new(
        identity: &MatchIdentity,
        bounds: HexGridBounds,
        player_gold: BTreeMap<PlayerId, i64>,
        player_war_weariness: BTreeMap<PlayerId, i64>,
        player_stability_net: BTreeMap<PlayerId, i64>,
        strategic_resources: BTreeMap<PlayerId, StrategicResourceStockpile>,
        initial_resource_distribution: InitialResourceDistribution,
    ) -> Result<Self, EconomyStateBuildError> {
        let state = Self {
            player_gold,
            player_war_weariness,
            player_stability_net,
            strategic_resources,
            initial_resource_distribution,
        };
        state.validate_for(identity, bounds)?;
        Ok(state)
    }

    pub(crate) fn validate_for(
        &self,
        identity: &MatchIdentity,
        bounds: HexGridBounds,
    ) -> Result<(), EconomyStateBuildError> {
        for player in self
            .player_gold
            .keys()
            .chain(self.player_war_weariness.keys())
            .chain(self.player_stability_net.keys())
            .chain(self.strategic_resources.keys())
        {
            if !identity.contains(player) {
                return Err(EconomyStateBuildError::UnknownPlayer(player.clone()));
            }
        }
        for placement in self.initial_resource_distribution.placements() {
            if !bounds.contains(placement.coordinate()) {
                return Err(EconomyStateBuildError::InitialResourceOutOfBounds(
                    placement.coordinate(),
                ));
            }
        }
        Ok(())
    }

    /// Returns gold accounts sorted by player identity.
    #[must_use]
    pub const fn player_gold(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_gold
    }
    /// Returns war-weariness accounts sorted by player identity.
    #[must_use]
    pub const fn player_war_weariness(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_war_weariness
    }
    /// Returns stability values sorted by player identity.
    #[must_use]
    pub const fn player_stability_net(&self) -> &BTreeMap<PlayerId, i64> {
        &self.player_stability_net
    }
    /// Returns strategic stockpiles sorted by player identity.
    #[must_use]
    pub const fn strategic_resources(&self) -> &BTreeMap<PlayerId, StrategicResourceStockpile> {
        &self.strategic_resources
    }
    /// Returns persisted initial resource placements.
    #[must_use]
    pub const fn initial_resource_distribution(&self) -> &InitialResourceDistribution {
        &self.initial_resource_distribution
    }
}

/// Structural economy-state failure.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum EconomyStateBuildError {
    /// Economy data references someone outside match participants.
    UnknownPlayer(PlayerId),
    /// A stockpile contains a resource using another economy mode.
    ResourceNotStockpiled(ResourceType),
    /// Canonical stockpiles contain positive entries only.
    NonPositiveResourceAmount {
        /// Invalid resource.
        resource: ResourceType,
        /// Invalid amount.
        amount: i64,
    },
    /// Multiple generated resources occupy one coordinate.
    DuplicateInitialResource(HexCoord),
    /// A generated resource is outside logical map bounds.
    InitialResourceOutOfBounds(HexCoord),
}

impl core::fmt::Display for EconomyStateBuildError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::UnknownPlayer(player) => {
                write!(formatter, "economy player is not a participant: {player}")
            }
            Self::ResourceNotStockpiled(resource) => {
                write!(formatter, "resource is not stockpiled: {resource:?}")
            }
            Self::NonPositiveResourceAmount { resource, amount } => write!(
                formatter,
                "resource {resource:?} amount must be positive, got {amount}"
            ),
            Self::DuplicateInitialResource(coordinate) => write!(
                formatter,
                "duplicate initial resource at ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
            Self::InitialResourceOutOfBounds(coordinate) => write!(
                formatter,
                "initial resource at ({}, {}) is outside the map",
                coordinate.col(),
                coordinate.row()
            ),
        }
    }
}

impl std::error::Error for EconomyStateBuildError {}

#[cfg(test)]
mod tests {
    use std::collections::BTreeMap;

    use super::{EconomyStateBuildError, ResourceType, StrategicResourceStockpile};

    #[test]
    fn stockpiles_accept_only_positive_oil_and_aluminium() {
        assert!(
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 2)])).is_ok()
        );
        assert_eq!(
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Iron, 2)])),
            Err(EconomyStateBuildError::ResourceNotStockpiled(
                ResourceType::Iron
            ))
        );
        assert!(
            StrategicResourceStockpile::try_new(BTreeMap::from([(ResourceType::Oil, 0)])).is_err()
        );
    }
}
