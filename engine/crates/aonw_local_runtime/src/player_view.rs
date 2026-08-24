use aonw_domain::{
    CityId, FieldImprovementKind, FogVisibility, GameState, HexCoord, PendingInteraction, PlayerId,
    Unit, UnitId, UnitKind, UnitPosture,
};

use crate::SessionStamp;

/// Recipient-safe unit view for local presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerUnitView {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    col: i32,
    row: i32,
    movement_units: u32,
    posture: UnitPosture,
}

impl PlayerUnitView {
    pub(crate) fn from_unit(unit: &Unit) -> Self {
        Self {
            id: unit.id().clone(),
            owner_player_id: unit.owner_player_id().clone(),
            kind: unit.kind(),
            name: unit.name().into(),
            col: unit.position().col(),
            row: unit.position().row(),
            movement_units: unit.movement_units().get(),
            posture: unit.posture(),
        }
    }

    /// Returns the unit identifier.
    #[must_use]
    pub const fn id(&self) -> &UnitId {
        &self.id
    }
    /// Returns the visible owner identifier.
    #[must_use]
    pub const fn owner_player_id(&self) -> &PlayerId {
        &self.owner_player_id
    }
    /// Returns the visible unit kind.
    #[must_use]
    pub const fn kind(&self) -> UnitKind {
        self.kind
    }
    /// Returns the authored display name.
    #[must_use]
    pub fn name(&self) -> &str {
        &self.name
    }
    /// Returns the map column.
    #[must_use]
    pub const fn col(&self) -> i32 {
        self.col
    }
    /// Returns the map row.
    #[must_use]
    pub const fn row(&self) -> i32 {
        self.row
    }
    /// Returns current fixed-point movement units.
    #[must_use]
    pub const fn movement_units(&self) -> u32 {
        self.movement_units
    }
    /// Returns the persistent unit posture.
    #[must_use]
    pub const fn posture(&self) -> UnitPosture {
        self.posture
    }
}

/// Recipient-owned action currently awaiting player input.
#[allow(missing_docs)]
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PendingActionView {
    ResearchSelection,
    CityWorkedHexSelection {
        city_id: CityId,
    },
    CityExpansionSelection {
        city_id: CityId,
    },
    WorkerActionSelection {
        unit_id: UnitId,
        improvement: Option<FieldImprovementKind>,
    },
    MerchantTradeRouteSelection {
        unit_id: UnitId,
    },
    MerchantMoveToCitySelection {
        unit_id: UnitId,
    },
    UnitTurnSkip {
        unit_id: UnitId,
        restore_movement_units: u32,
    },
    AttackTargeting {
        unit_id: UnitId,
        defender: Option<HexCoord>,
    },
    CommanderMergeSelection {
        unit_id: UnitId,
    },
}

/// Complete recipient-safe presentation snapshot.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewSnapshot {
    stamp: SessionStamp,
    turn: u32,
    pending_action: Option<PendingActionView>,
    units: Box<[PlayerUnitView]>,
}

impl PlayerViewSnapshot {
    pub(crate) fn new(stamp: SessionStamp, state: &GameState, actor: &PlayerId) -> Self {
        Self {
            stamp,
            turn: state.turn(),
            pending_action: pending_action(state, actor),
            units: visible_units(state, actor).into_boxed_slice(),
        }
    }

    /// Returns version and authoritative identity metadata.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }
    /// Returns the authoritative turn number.
    #[must_use]
    pub const fn turn(&self) -> u32 {
        self.turn
    }
    /// Returns the action awaiting input from this recipient.
    #[must_use]
    pub const fn pending_action(&self) -> Option<&PendingActionView> {
        self.pending_action.as_ref()
    }
    /// Returns all units visible to this local player.
    #[must_use]
    pub const fn units(&self) -> &[PlayerUnitView] {
        &self.units
    }
}

pub(crate) fn pending_action(state: &GameState, actor: &PlayerId) -> Option<PendingActionView> {
    let pending = state.interaction().pending()?;
    if pending.owner_player_id() != actor {
        return None;
    }
    Some(match pending {
        PendingInteraction::ResearchSelection { .. } => PendingActionView::ResearchSelection,
        PendingInteraction::CityWorkedHexSelection { city_id, .. } => {
            PendingActionView::CityWorkedHexSelection {
                city_id: city_id.clone(),
            }
        }
        PendingInteraction::CityExpansionSelection { city_id, .. } => {
            PendingActionView::CityExpansionSelection {
                city_id: city_id.clone(),
            }
        }
        PendingInteraction::WorkerActionSelection {
            unit_id,
            improvement,
            ..
        } => PendingActionView::WorkerActionSelection {
            unit_id: unit_id.clone(),
            improvement: *improvement,
        },
        PendingInteraction::MerchantTradeRouteSelection { unit_id, .. } => {
            PendingActionView::MerchantTradeRouteSelection {
                unit_id: unit_id.clone(),
            }
        }
        PendingInteraction::MerchantMoveToCitySelection { unit_id, .. } => {
            PendingActionView::MerchantMoveToCitySelection {
                unit_id: unit_id.clone(),
            }
        }
        PendingInteraction::UnitTurnSkip {
            unit_id,
            restore_movement,
            ..
        } => PendingActionView::UnitTurnSkip {
            unit_id: unit_id.clone(),
            restore_movement_units: restore_movement.get(),
        },
        PendingInteraction::AttackTargeting {
            unit_id, defender, ..
        } => PendingActionView::AttackTargeting {
            unit_id: unit_id.clone(),
            defender: *defender,
        },
        PendingInteraction::CommanderMergeSelection { unit_id, .. } => {
            PendingActionView::CommanderMergeSelection {
                unit_id: unit_id.clone(),
            }
        }
    })
}

pub(crate) fn visible_units(state: &GameState, actor: &PlayerId) -> Vec<PlayerUnitView> {
    let mut units = state
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, unit.position()) == FogVisibility::Visible
        })
        .map(PlayerUnitView::from_unit)
        .collect::<Vec<_>>();
    units.sort_unstable_by(|left, right| left.id().cmp(right.id()));
    units
}

#[cfg(test)]
mod tests {
    use aonw_domain::{
        FogOfWar, GameState, HexCoord, HexGridBounds, InteractionState, MovementUnits, PlayerFog,
        PlayerId, StateRevision, Unit, UnitId, UnitKind, UnitOccupancyPolicy,
    };

    use super::{PendingActionView, pending_action, visible_units};

    #[test]
    fn visible_units_have_stable_identifier_order() {
        let actor = PlayerId::new("player-1").expect("player id");
        let state = GameState::try_new(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(5, 5).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [
                unit("unit-z", &actor, HexCoord::new(1, 1)),
                unit("unit-a", &actor, HexCoord::new(2, 1)),
            ],
        )
        .expect("state");

        let identifiers = visible_units(&state, &actor)
            .into_iter()
            .map(|unit| unit.id().as_str().to_owned())
            .collect::<Vec<_>>();

        assert_eq!(identifiers, ["unit-a", "unit-z"]);
    }

    #[test]
    fn visible_units_never_leak_foreign_units_through_fog() {
        let actor = PlayerId::new("player-1").expect("actor id");
        let foreign = PlayerId::new("player-2").expect("foreign id");
        let visible = HexCoord::new(2, 1);
        let discovered = HexCoord::new(3, 1);
        let owned_hidden = HexCoord::new(4, 1);
        let foreign_hidden = HexCoord::new(5, 1);
        let fog = FogOfWar::try_new([PlayerFog::new(actor.clone(), [discovered], [visible])])
            .expect("fog");
        let state = GameState::builder(
            StateRevision::INITIAL,
            0,
            HexGridBounds::new(6, 4).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [
                unit("owned-hidden", &actor, owned_hidden),
                unit("foreign-visible", &foreign, visible),
                unit("foreign-discovered", &foreign, discovered),
                unit("foreign-hidden", &foreign, foreign_hidden),
            ],
        )
        .with_fog_of_war(fog)
        .try_build()
        .expect("state");

        let identifiers = visible_units(&state, &actor)
            .into_iter()
            .map(|unit| unit.id().as_str().to_owned())
            .collect::<Vec<_>>();

        assert_eq!(identifiers, ["foreign-visible", "owned-hidden"]);
    }

    #[test]
    fn pending_action_is_visible_only_to_its_owner() {
        let actor = PlayerId::new("player-1").expect("actor id");
        let foreign = PlayerId::new("player-2").expect("foreign id");
        let state = GameState::builder(
            StateRevision::INITIAL,
            1,
            HexGridBounds::new(2, 2).expect("bounds"),
            UnitOccupancyPolicy::Exclusive,
            [],
        )
        .with_interaction(InteractionState::new(
            None,
            Some(aonw_domain::PendingInteraction::ResearchSelection {
                owner_player_id: actor.clone(),
            }),
        ))
        .try_build()
        .expect("state");

        assert_eq!(
            pending_action(&state, &actor),
            Some(PendingActionView::ResearchSelection)
        );
        assert_eq!(pending_action(&state, &foreign), None);
    }

    fn unit(id: &str, actor: &PlayerId, position: HexCoord) -> Unit {
        Unit::builder(
            UnitId::new(id).expect("unit id"),
            actor.clone(),
            UnitKind::Commander,
            "Commander",
            position,
            MovementUnits::new(10),
        )
        .build()
        .expect("unit")
    }
}
