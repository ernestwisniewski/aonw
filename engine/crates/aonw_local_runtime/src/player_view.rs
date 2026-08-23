use aonw_domain::{FogVisibility, GameState, PlayerId, Unit, UnitId, UnitKind, UnitPosture};

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

/// Complete recipient-safe presentation snapshot.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerViewSnapshot {
    stamp: SessionStamp,
    units: Box<[PlayerUnitView]>,
}

impl PlayerViewSnapshot {
    pub(crate) fn new(stamp: SessionStamp, state: &GameState, actor: &PlayerId) -> Self {
        Self {
            stamp,
            units: visible_units(state, actor).into_boxed_slice(),
        }
    }

    /// Returns version and authoritative identity metadata.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }
    /// Returns all units visible to this local player.
    #[must_use]
    pub const fn units(&self) -> &[PlayerUnitView] {
        &self.units
    }
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
        Diplomacy, FogOfWar, GameState, HexCoord, HexGridBounds, InteractionState, MovementUnits,
        PlayerFog, PlayerId, StateRevision, TransportNetwork, Unit, UnitId, UnitKind,
        UnitOccupancyPolicy,
    };

    use super::visible_units;

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
        let state = GameState::try_new_with_world(
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
            [],
            [],
            InteractionState::default(),
            fog,
            Diplomacy::default(),
            TransportNetwork::default(),
        )
        .expect("state");

        let identifiers = visible_units(&state, &actor)
            .into_iter()
            .map(|unit| unit.id().as_str().to_owned())
            .collect::<Vec<_>>();

        assert_eq!(identifiers, ["foreign-visible", "owned-hidden"]);
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
