use std::fmt;

use aonw_contracts::{
    MovementStateDto, MovementStepDto, MovementUnitDto, QueuedMovePathDto, UnitKindDto,
    UnitPostureDto,
};
use godot::prelude::GString;
use serde::Deserialize;
use serde_json::{Value, json};

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
pub(crate) struct MovementStateWire {
    schema_version: u16,
    revision: u64,
    turn: u32,
    units: Vec<MovementUnitWire>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct MovementUnitWire {
    id: String,
    owner_player_id: String,
    kind: UnitKindWire,
    col: i32,
    row: i32,
    movement_units: u32,
    posture: UnitPostureWire,
    movement_blocked: bool,
    queued_path: RequiredNullable<QueuedMovePathWire>,
    carried_artifact_id: RequiredNullable<String>,
}

#[derive(Deserialize)]
#[serde(untagged)]
enum RequiredNullable<Value> {
    Null(()),
    Value(Value),
}

impl<Value> RequiredNullable<Value> {
    fn into_option(self) -> Option<Value> {
        match self {
            Self::Null(()) => None,
            Self::Value(value) => Some(value),
        }
    }
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct QueuedMovePathWire {
    target_col: i32,
    target_row: i32,
    steps: Vec<MovementStepWire>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase", deny_unknown_fields)]
struct MovementStepWire {
    col: i32,
    row: i32,
    enter_cost_units: u32,
    cumulative_cost_units: u32,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(rename_all = "camelCase")]
enum UnitKindWire {
    Commander,
    Warrior,
    Archer,
    Settler,
    Worker,
    Merchant,
    Scout,
    Spearman,
    Cavalry,
    Catapult,
    HeavyInfantry,
    FieldCannon,
    Rifleman,
    Tank,
    ScoutShip,
    Warship,
    ReconPlane,
}

#[derive(Clone, Copy, Deserialize)]
#[serde(rename_all = "camelCase")]
enum UnitPostureWire {
    Active,
    Fortified,
    AutoExploring,
    AutoWorking,
}

impl From<MovementStateWire> for MovementStateDto {
    fn from(value: MovementStateWire) -> Self {
        Self {
            schema_version: value.schema_version,
            revision: value.revision,
            turn: value.turn,
            units: value.units.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<MovementUnitWire> for MovementUnitDto {
    fn from(value: MovementUnitWire) -> Self {
        Self {
            id: value.id,
            owner_player_id: value.owner_player_id,
            kind: value.kind.into(),
            col: value.col,
            row: value.row,
            movement_units: value.movement_units,
            posture: value.posture.into(),
            movement_blocked: value.movement_blocked,
            queued_path: value.queued_path.into_option().map(Into::into),
            carried_artifact_id: value.carried_artifact_id.into_option(),
        }
    }
}

impl From<QueuedMovePathWire> for QueuedMovePathDto {
    fn from(value: QueuedMovePathWire) -> Self {
        Self {
            target_col: value.target_col,
            target_row: value.target_row,
            steps: value.steps.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<MovementStepWire> for MovementStepDto {
    fn from(value: MovementStepWire) -> Self {
        Self {
            col: value.col,
            row: value.row,
            enter_cost_units: value.enter_cost_units,
            cumulative_cost_units: value.cumulative_cost_units,
        }
    }
}

impl From<UnitKindWire> for UnitKindDto {
    fn from(value: UnitKindWire) -> Self {
        match value {
            UnitKindWire::Commander => Self::Commander,
            UnitKindWire::Warrior => Self::Warrior,
            UnitKindWire::Archer => Self::Archer,
            UnitKindWire::Settler => Self::Settler,
            UnitKindWire::Worker => Self::Worker,
            UnitKindWire::Merchant => Self::Merchant,
            UnitKindWire::Scout => Self::Scout,
            UnitKindWire::Spearman => Self::Spearman,
            UnitKindWire::Cavalry => Self::Cavalry,
            UnitKindWire::Catapult => Self::Catapult,
            UnitKindWire::HeavyInfantry => Self::HeavyInfantry,
            UnitKindWire::FieldCannon => Self::FieldCannon,
            UnitKindWire::Rifleman => Self::Rifleman,
            UnitKindWire::Tank => Self::Tank,
            UnitKindWire::ScoutShip => Self::ScoutShip,
            UnitKindWire::Warship => Self::Warship,
            UnitKindWire::ReconPlane => Self::ReconPlane,
        }
    }
}

impl From<UnitPostureWire> for UnitPostureDto {
    fn from(value: UnitPostureWire) -> Self {
        match value {
            UnitPostureWire::Active => Self::Active,
            UnitPostureWire::Fortified => Self::Fortified,
            UnitPostureWire::AutoExploring => Self::AutoExploring,
            UnitPostureWire::AutoWorking => Self::AutoWorking,
        }
    }
}

pub(crate) fn success_json(value: &Value) -> GString {
    encode_json(&json!({"ok": true, "value": value}))
}

pub(crate) fn failure_json(code: &str, error: impl fmt::Display) -> GString {
    encode_json(&json!({
        "ok": false,
        "code": code,
        "message": error.to_string(),
    }))
}

pub(crate) fn encode_json(value: &Value) -> GString {
    let encoded = serde_json::to_string(&value).unwrap_or_else(|_| {
        r#"{"ok":false,"code":"adapter_serialization_failed","message":"adapter serialization failed"}"#.to_owned()
    });
    GString::from(&encoded)
}

#[cfg(test)]
mod tests {
    use aonw_contracts::CURRENT_MOVEMENT_STATE_VERSION;
    use serde_json::json;

    use super::MovementStateWire;

    #[test]
    fn movement_wire_requires_every_current_unit_field() {
        let state = json!({
            "schemaVersion": CURRENT_MOVEMENT_STATE_VERSION,
            "revision": 1,
            "turn": 1,
            "units": [{
                "id": "unit-1",
                "ownerPlayerId": "player-1",
                "kind": "warrior",
                "col": 0,
                "row": 0,
                "movementUnits": 4,
                "posture": "active",
                "movementBlocked": false,
                "queuedPath": null,
                "carriedArtifactId": null
            }]
        });

        serde_json::from_value::<MovementStateWire>(state.clone())
            .expect("complete movement state must decode");
        for field in [
            "posture",
            "movementBlocked",
            "queuedPath",
            "carriedArtifactId",
        ] {
            let mut incomplete = state.clone();
            incomplete["units"][0]
                .as_object_mut()
                .expect("unit must be an object")
                .remove(field);
            assert!(
                serde_json::from_value::<MovementStateWire>(incomplete).is_err(),
                "missing {field} must be rejected"
            );
        }

        for (path, field) in [
            (Vec::<&str>::new(), "unknownRoot"),
            (vec!["units", "0"], "unknownUnit"),
        ] {
            let mut invalid = state.clone();
            let mut current = &mut invalid;
            for segment in path {
                current = if let Ok(index) = segment.parse::<usize>() {
                    &mut current[index]
                } else {
                    &mut current[segment]
                };
            }
            current
                .as_object_mut()
                .expect("target must be an object")
                .insert(field.to_owned(), json!(true));
            assert!(
                serde_json::from_value::<MovementStateWire>(invalid).is_err(),
                "unknown {field} must be rejected"
            );
        }
    }
}
