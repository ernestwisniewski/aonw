use aonw_domain::{MovementUnit, UnitId};

/// Actor-visible unit occupancy used by movement planning.
///
/// A fog-aware adapter supplies the identifiers visible to the actor. The
/// explicit fog-disabled constructor is intended for local games and tests
/// where every unit is legitimately known.
#[derive(Clone, Copy, Debug)]
pub struct MovementPlanningView<'view> {
    known_unit_ids: Option<&'view [UnitId]>,
}

impl<'view> MovementPlanningView<'view> {
    /// Builds a fog-aware view from unit identifiers known to the actor.
    #[must_use]
    pub const fn known_units(known_unit_ids: &'view [UnitId]) -> Self {
        Self {
            known_unit_ids: Some(known_unit_ids),
        }
    }

    /// Builds an explicit fog-disabled view in which every unit is known.
    #[must_use]
    pub const fn fog_disabled() -> Self {
        Self {
            known_unit_ids: None,
        }
    }

    pub(super) fn knows(self, unit_id: &UnitId) -> bool {
        self.known_unit_ids
            .is_none_or(|known| known.iter().any(|candidate| candidate == unit_id))
    }

    pub(super) fn observes_occupancy(
        self,
        moving_unit: &MovementUnit,
        candidate: &MovementUnit,
    ) -> bool {
        candidate.owner_player_id() == moving_unit.owner_player_id() || self.knows(candidate.id())
    }
}
