use aonw_domain::{HexCoord, MovementUnits, PendingInteraction, UnitId};
use aonw_engine::{DomainEvent, ExecutionEvidence};
use aonw_testkit::{JsonObject, MovementExecution};
use serde_json::{Value, json};

use super::AdapterError;
use super::json::{error, json_object, movement_execution};

pub(super) fn apply_canonical_projection(
    state: &mut JsonObject,
    canonical: &aonw_domain::GameState,
    evidence: Option<&ExecutionEvidence>,
) -> Result<(), AdapterError> {
    let units = state
        .get_mut("units")
        .and_then(Value::as_array_mut)
        .ok_or_else(|| error("state.units must be an array"))?;
    for unit in canonical.units() {
        let raw = units
            .iter_mut()
            .find(|value| value.get("id").and_then(Value::as_str) == Some(unit.id().as_str()))
            .and_then(Value::as_object_mut)
            .ok_or_else(|| error(format!("missing canonical unit: {}", unit.id())))?;
        project_unit(raw, unit, evidence);
    }
    project_artifacts(state, canonical)?;

    state.insert(
        "fogOfWar".into(),
        Value::Array(
            canonical
                .fog_of_war()
                .players()
                .iter()
                .map(|fog| {
                    json!({
                        "playerId": fog.player_id().as_str(),
                        "discoveredHexes": coordinate_values(fog.discovered_hexes()),
                        "visibleHexes": coordinate_values(fog.visible_hexes()),
                    })
                })
                .collect(),
        ),
    );
    let lifecycle = state
        .get_mut("lifecycle")
        .and_then(Value::as_object_mut)
        .ok_or_else(|| error("state.lifecycle must be an object"))?;
    project_pending_turn_skip(lifecycle, canonical);
    if canonical.diplomacy().contacts().is_empty() {
        lifecycle.remove("diplomacy");
    } else {
        lifecycle.insert(
            "diplomacy".into(),
            json!({
                "contacts": canonical.diplomacy().contacts().iter().map(|pair| {
                    format!("{}|{}", pair.first(), pair.second())
                }).collect::<Vec<_>>(),
            }),
        );
    }
    Ok(())
}

fn project_unit(
    raw: &mut JsonObject,
    unit: &aonw_domain::Unit,
    evidence: Option<&ExecutionEvidence>,
) {
    raw.insert("col".into(), unit.position().col().into());
    raw.insert("row".into(), unit.position().row().into());
    let movement = unit.movement_units().get();
    raw.insert(
        "movementPoints".into(),
        (movement / MovementUnits::PER_POINT).into(),
    );
    if movement.is_multiple_of(MovementUnits::PER_POINT) {
        raw.remove("movementSubpoints");
    } else {
        raw.insert(
            "movementSubpoints".into(),
            (movement % MovementUnits::PER_POINT).into(),
        );
    }
    match unit.posture() {
        aonw_domain::UnitPosture::Active => raw.remove("posture"),
        aonw_domain::UnitPosture::Fortified => raw.insert("posture".into(), "fortified".into()),
        aonw_domain::UnitPosture::AutoExploring => {
            raw.insert("posture".into(), "autoExploring".into())
        }
        aonw_domain::UnitPosture::AutoWorking => raw.insert("posture".into(), "autoWorking".into()),
    };
    match unit.queued_path() {
        Some(path) => {
            let steps = dart_queued_path_steps(unit.id(), path, evidence);
            raw.insert(
                "queuedPath".into(),
                json!({
                    "targetCol": path.target().col(),
                    "targetRow": path.target().row(),
                    "steps": steps,
                }),
            );
        }
        None => {
            raw.remove("queuedPath");
        }
    }
    if unit.merchant_trade_route().is_none() {
        raw.remove("merchantTradeRoute");
    }
    let activity = unit.activity();
    for (field, active) in [
        ("workerJob", activity.worker_job().is_some()),
        ("cityFoundingJob", activity.city_founding_job().is_some()),
        ("workerAssignment", activity.worker_assignment().is_some()),
        (
            "excavatingArtifactId",
            activity.excavating_artifact_id().is_some(),
        ),
    ] {
        if !active {
            raw.remove(field);
        }
    }
}

fn project_pending_turn_skip(lifecycle: &mut JsonObject, state: &aonw_domain::GameState) {
    if let Some(PendingInteraction::UnitTurnSkip {
        owner_player_id,
        unit_id,
        restore_movement,
    }) = state.interaction().pending()
    {
        lifecycle.insert(
            "pendingAction".into(),
            json!({
                "type": "unitTurnSkip",
                "ownerPlayerId": owner_player_id.as_str(),
                "unitId": unit_id.as_str(),
                "restoreMovementUnits": restore_movement.get(),
            }),
        );
        return;
    }
    if lifecycle
        .get("pendingAction")
        .and_then(Value::as_object)
        .and_then(|pending| pending.get("type"))
        .and_then(Value::as_str)
        == Some("unitTurnSkip")
    {
        lifecycle.remove("pendingAction");
    }
}

fn project_artifacts(
    state: &mut JsonObject,
    canonical: &aonw_domain::GameState,
) -> Result<(), AdapterError> {
    let artifacts = state
        .get_mut("artifacts")
        .and_then(Value::as_array_mut)
        .ok_or_else(|| error("state.artifacts must be an array"))?;
    for artifact in canonical.artifacts() {
        let Some(raw) = artifacts
            .iter_mut()
            .find(|value| value.get("id").and_then(Value::as_str) == Some(artifact.id().as_str()))
            .and_then(Value::as_object_mut)
        else {
            continue;
        };
        let location = match artifact.location() {
            aonw_domain::WorldArtifactLocation::Map(coordinate) => json!({
                "kind": "map",
                "col": coordinate.col(),
                "row": coordinate.row(),
            }),
            aonw_domain::WorldArtifactLocation::Carried(unit_id) => json!({
                "kind": "carried",
                "unitId": unit_id.as_str(),
            }),
            aonw_domain::WorldArtifactLocation::Stored(city_id) => json!({
                "kind": "stored",
                "cityId": city_id.as_str(),
            }),
            aonw_domain::WorldArtifactLocation::Excavation {
                unit_id,
                coordinate,
                remaining_turns,
            } => json!({
                "kind": "excavation",
                "unitId": unit_id.as_str(),
                "col": coordinate.col(),
                "row": coordinate.row(),
                "remainingTurns": remaining_turns,
            }),
        };
        raw.insert("location".into(), location);
    }
    Ok(())
}

fn dart_queued_path_steps(
    unit_id: &UnitId,
    path: &aonw_domain::QueuedMovePath,
    evidence: Option<&ExecutionEvidence>,
) -> Vec<Value> {
    let Some(ExecutionEvidence::UnitMovement(execution)) = evidence else {
        return movement_steps_json(path.steps(), MovementUnits::ZERO);
    };
    if execution.unit_id() != unit_id || execution.steps().is_empty() {
        return movement_steps_json(path.steps(), MovementUnits::ZERO);
    }
    let mut steps = vec![json!({
        "col": execution.from().col(),
        "row": execution.from().row(),
        "enterCost": 0,
        "cumulativeCost": 0,
    })];
    steps.extend(movement_steps_json(execution.steps(), MovementUnits::ZERO));
    let executed_cost = execution
        .steps()
        .last()
        .map_or(MovementUnits::ZERO, |step| step.cumulative_cost());
    steps.extend(movement_steps_json(&path.steps()[1..], executed_cost));
    steps
}

fn movement_steps_json(
    steps: &[aonw_domain::MovementStep],
    cumulative_offset: MovementUnits,
) -> Vec<Value> {
    steps
        .iter()
        .map(|step| {
            json!({
                "col": step.coordinate().col(),
                "row": step.coordinate().row(),
                "enterCost": step.enter_cost().get(),
                "cumulativeCost": step.cumulative_cost().get() + cumulative_offset.get(),
            })
        })
        .collect()
}

pub(super) fn event_json(event: &DomainEvent) -> Result<JsonObject, AdapterError> {
    match event {
        DomainEvent::UnitMoved(event) => json_object(&json!({
            "type": "UnitMoved",
            "unitId": event.unit_id().as_str(),
            "fromCol": event.from().col(),
            "fromRow": event.from().row(),
            "toCol": event.to().col(),
            "toRow": event.to().row(),
        })),
    }
}

pub(super) fn evidence_execution(
    evidence: &ExecutionEvidence,
) -> Result<MovementExecution, AdapterError> {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => movement_execution(
            execution.unit_id().as_str(),
            execution.from(),
            execution.steps().iter().map(|step| {
                (
                    step.coordinate(),
                    step.enter_cost().get(),
                    step.cumulative_cost().get(),
                )
            }),
        ),
    }
}

fn coordinate_values(coordinates: &[HexCoord]) -> Vec<Value> {
    coordinates
        .iter()
        .map(|coordinate| json!({"col": coordinate.col(), "row": coordinate.row()}))
        .collect()
}
