use aonw_domain::{HexCoord, UnitId, UnitKind, UnitPosture};
use aonw_engine::{DomainEvent, ExecutionEvidence};
use aonw_local_runtime::{CommandResult, PlayerUnitView, PlayerViewPatch, SessionStamp};
use serde_json::{Value, json};

pub(super) fn stamp_json(stamp: SessionStamp) -> Value {
    json!({
        "behaviorVersion": stamp.behavior_version,
        "revision": stamp.revision.get(),
        "stateDigest": stamp.state_digest.to_string(),
        "mapHash": stamp.map_hash.to_string(),
        "rulesetHash": stamp.ruleset_hash.to_string(),
    })
}

pub(super) fn with_stamp(stamp: SessionStamp, value: Value) -> Value {
    let mut result = stamp_json(stamp).as_object().cloned().unwrap_or_default();
    if let Value::Object(fields) = value {
        result.extend(fields);
    }
    Value::Object(result)
}

pub(super) fn unit_json(unit: &PlayerUnitView) -> Value {
    json!({
        "id": unit.id().as_str(),
        "ownerPlayerId": unit.owner_player_id().as_str(),
        "kind": unit_kind_name(unit.kind()),
        "name": unit.name(),
        "col": unit.col(),
        "row": unit.row(),
        "movementUnits": unit.movement_units(),
        "posture": unit_posture_name(unit.posture()),
    })
}

pub(super) fn command_result_json(result: &CommandResult) -> Value {
    with_stamp(
        result.stamp,
        json!({
            "accepted": result.is_accepted(),
            "rejection": result.rejection,
            "events": result.events.iter().map(event_json).collect::<Vec<_>>(),
            "evidence": result.evidence.as_ref().map(evidence_json),
            "viewPatch": patch_json(&result.view_patch),
        }),
    )
}

fn event_json(event: &DomainEvent) -> Value {
    match event {
        DomainEvent::UnitMoved(event) => json!({
            "type": "unitMoved",
            "unitId": event.unit_id().as_str(),
            "from": coordinate_json(event.from()),
            "to": coordinate_json(event.to()),
        }),
    }
}

fn evidence_json(evidence: &ExecutionEvidence) -> Value {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => json!({
            "type": "unitMovement",
            "unitId": execution.unit_id().as_str(),
            "from": coordinate_json(execution.from()),
            "steps": execution.steps().iter().map(|step| json!({
                "col": step.coordinate().col(),
                "row": step.coordinate().row(),
                "enterCostUnits": step.enter_cost().get(),
                "cumulativeCostUnits": step.cumulative_cost().get(),
            })).collect::<Vec<_>>(),
        }),
    }
}

fn patch_json(patch: &PlayerViewPatch) -> Value {
    json!({
        "fromRevision": patch.from_revision,
        "toRevision": patch.to_revision,
        "upsertedUnits": patch.upserted_units.iter().map(unit_json).collect::<Vec<_>>(),
        "removedUnitIds": patch.removed_unit_ids.iter().map(UnitId::as_str).collect::<Vec<_>>(),
    })
}

pub(super) fn coordinate_json(coordinate: HexCoord) -> Value {
    json!({"col": coordinate.col(), "row": coordinate.row()})
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

const fn unit_posture_name(posture: UnitPosture) -> &'static str {
    match posture {
        UnitPosture::Active => "active",
        UnitPosture::Fortified => "fortified",
        UnitPosture::AutoExploring => "autoExploring",
        UnitPosture::AutoWorking => "autoWorking",
    }
}
