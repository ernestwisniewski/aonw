use aonw_domain::{FogVisibility, GameState, PlayerId, Unit, UnitId, UnitKind, UnitPosture};

use crate::SessionStampV1;

/// Recipient-safe unit view for local presentation.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PlayerUnitViewV1 {
    id: UnitId,
    owner_player_id: PlayerId,
    kind: UnitKind,
    name: Box<str>,
    col: i32,
    row: i32,
    movement_units: u32,
    posture: UnitPosture,
}

impl PlayerUnitViewV1 {
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
pub struct PlayerViewSnapshotV1 {
    stamp: SessionStampV1,
    units: Box<[PlayerUnitViewV1]>,
}

impl PlayerViewSnapshotV1 {
    pub(crate) fn new(stamp: SessionStampV1, state: &GameState, actor: &PlayerId) -> Self {
        Self {
            stamp,
            units: visible_units(state, actor).into_boxed_slice(),
        }
    }

    /// Returns version and authoritative identity metadata.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStampV1 {
        &self.stamp
    }
    /// Returns all units visible to this local player.
    #[must_use]
    pub const fn units(&self) -> &[PlayerUnitViewV1] {
        &self.units
    }
}

pub(crate) fn visible_units(state: &GameState, actor: &PlayerId) -> Vec<PlayerUnitViewV1> {
    state
        .units()
        .iter()
        .filter(|unit| {
            unit.owner_player_id() == actor
                || state.fog_of_war().visibility(actor, unit.position()) == FogVisibility::Visible
        })
        .map(PlayerUnitViewV1::from_unit)
        .collect()
}
