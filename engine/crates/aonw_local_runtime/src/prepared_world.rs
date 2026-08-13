use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::GameState;

use crate::OpenSessionError;

#[derive(Clone, Debug)]
pub(crate) struct PreparedWorld {
    map: MapDefinition,
    ruleset: RulesetDefinition,
    map_hash: ContentHash,
    ruleset_hash: ContentHash,
}

impl PreparedWorld {
    pub(crate) fn try_new(
        map: MapDefinition,
        ruleset: RulesetDefinition,
        state: &GameState,
    ) -> Result<Self, OpenSessionError> {
        if map.bounds() != state.bounds() {
            return Err(OpenSessionError::MapBoundsMismatch);
        }
        if ruleset.occupancy_policy() != state.occupancy_policy() {
            return Err(OpenSessionError::OccupancyPolicyMismatch);
        }
        let map_hash = map
            .content_hash()
            .map_err(|error| OpenSessionError::ContentHash(error.to_string().into()))?;
        let ruleset_hash = ruleset
            .content_hash()
            .map_err(|error| OpenSessionError::ContentHash(error.to_string().into()))?;
        Ok(Self {
            map,
            ruleset,
            map_hash,
            ruleset_hash,
        })
    }

    pub(crate) const fn map(&self) -> &MapDefinition {
        &self.map
    }

    pub(crate) const fn ruleset(&self) -> &RulesetDefinition {
        &self.ruleset
    }

    pub(crate) const fn map_hash(&self) -> ContentHash {
        self.map_hash
    }

    pub(crate) const fn ruleset_hash(&self) -> ContentHash {
        self.ruleset_hash
    }
}
