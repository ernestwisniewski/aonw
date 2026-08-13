//! Executes the reviewed movement oracle through the Rust engine.

use std::collections::BTreeSet;
use std::fmt;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_domain::{
    HexCoord, MovementState, MovementUnit, MovementUnits, PlayerId, UnitId, UnitKind,
};
use aonw_engine::{
    EngineContext, GameEngine, MoveUnitCommand, MovementPlanningView, MovementTransition,
};
use aonw_testkit::{
    FixtureExecutor, FixtureInput, FixtureLoader, FixtureOutput, JsonObject, MovementExecution,
    MovementStep, verify_corpus,
};
use serde_json::{Map, Value, json};

const FIXTURE_IDS: [&str; 3] = [
    "movement-adjacent-accepted",
    "movement-out-of-bounds-rejected",
    "movement-wrong-actor-rejected",
];

#[derive(Debug)]
struct AdapterError(String);

impl fmt::Display for AdapterError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for AdapterError {}

struct RustMovementFixtureExecutor;

impl FixtureExecutor for RustMovementFixtureExecutor {
    type Error = AdapterError;

    fn execute(
        &self,
        fixture_id: &str,
        family: &str,
        input: &FixtureInput,
    ) -> Result<FixtureOutput, Self::Error> {
        if family != "movement" || !FIXTURE_IDS.contains(&fixture_id) {
            return Err(error(format!("unsupported fixture: {fixture_id}")));
        }

        let map = decode_map(input.map())?;
        let state = decode_state(input)?;
        let actor = PlayerId::new(input.actor_player_id()).map_err(display_error)?;
        let unit_id =
            UnitId::new(required_string(input.command(), "unitId")?).map_err(display_error)?;
        let command_type = required_string(input.command(), "type")?;
        if command_type != "MoveUnit" {
            return Err(error(format!("unsupported command: {command_type}")));
        }
        let target = HexCoord::new(
            required_i32(input.command(), "targetCol")?,
            required_i32(input.command(), "targetRow")?,
        );
        let context = EngineContext::new(&actor, &map, MovementPlanningView::fog_disabled());
        let transition = GameEngine::apply_move_unit(
            &state,
            context,
            MoveUnitCommand::new(input.tick(), &unit_id, target),
        );
        let mut save = input.save().clone();
        save.remove("savedAt");

        match transition {
            Ok(transition) => accepted_output(input, &map, &transition, save),
            Err(rejection) => Ok(FixtureOutput::reject(
                rejection.code(),
                save,
                input.state().clone(),
                Vec::new(),
                Vec::new(),
            )),
        }
    }
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| {
            path.join("engine/Cargo.toml").is_file()
                && path.join("test/fixtures/reducer_parity").is_dir()
        })
        .expect("repository root must contain engine and reducer fixtures")
        .to_path_buf()
}

fn decode_map(raw: &JsonObject) -> Result<MapDefinition, AdapterError> {
    let cols = u16::try_from(required_u32(raw, "cols")?).map_err(display_error)?;
    let rows = u16::try_from(required_u32(raw, "rows")?).map_err(display_error)?;
    let map_id = required_string(raw, "mapName")?;
    let tiles = required_array(raw, "tiles")?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("input.map.tiles[{index}]");
            let tile = value
                .as_object()
                .ok_or_else(|| error(format!("{path} must be an object")))?;
            let terrains = required_array(tile, "terrains")?;
            if terrains.len() != 1 || terrains[0].as_str() != Some("grassland") {
                return Err(error(format!(
                    "{path}.terrains must contain the reviewed grassland fixture terrain"
                )));
            }
            if !required_array(tile, "resources")?.is_empty() {
                return Err(error(format!(
                    "{path}.resources must be empty in reviewed movement fixtures"
                )));
            }
            TileDefinition::try_new(
                HexCoord::new(
                    required_i32_at(tile, "col", &path)?,
                    required_i32_at(tile, "row", &path)?,
                ),
                vec![TerrainType::Grassland],
                Vec::new(),
                u8::try_from(required_u32_at(tile, "height", &path)?).map_err(display_error)?,
            )
            .map_err(display_error)
        })
        .collect::<Result<Vec<_>, _>>()?;
    MapDefinition::try_new(
        map_id,
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .map_err(display_error)
}

fn decode_state(input: &FixtureInput) -> Result<MovementState, AdapterError> {
    let turn = required_u32(input.save(), "turn")?;
    let units = required_array(input.state(), "units")?
        .iter()
        .enumerate()
        .map(|(index, value)| decode_unit(index, value))
        .collect::<Result<Vec<_>, _>>()?;
    MovementState::try_new(input.tick(), turn, units).map_err(display_error)
}

fn decode_unit(index: usize, raw: &Value) -> Result<MovementUnit, AdapterError> {
    let object = raw
        .as_object()
        .ok_or_else(|| error(format!("state.units[{index}] must be an object")))?;
    let path = format!("state.units[{index}]");
    let id = UnitId::new(required_string_at(object, "id", &path)?).map_err(display_error)?;
    let owner = PlayerId::new(required_string_at(object, "ownerPlayerId", &path)?)
        .map_err(display_error)?;
    let kind = parse_unit_kind(required_string_at(object, "type", &path)?)?;
    let position = HexCoord::new(
        required_i32_at(object, "col", &path)?,
        required_i32_at(object, "row", &path)?,
    );
    let movement = match object.get("movementUnits") {
        Some(value) => MovementUnits::new(value_to_u32(value, &format!("{path}.movementUnits"))?),
        None => MovementUnits::checked_from_whole_points(required_u32_at(
            object,
            "movementPoints",
            &path,
        )?)
        .ok_or_else(|| error(format!("{path}.movementPoints overflows fixed-point units")))?,
    };
    let movement_blocked = [
        "workerJob",
        "cityFoundingJob",
        "workerAssignment",
        "excavatingArtifactId",
    ]
    .iter()
    .any(|field| object.get(*field).is_some_and(|value| !value.is_null()));

    Ok(MovementUnit::new(id, owner, kind, position, movement)
        .with_movement_blocked(movement_blocked))
}

fn parse_unit_kind(value: &str) -> Result<UnitKind, AdapterError> {
    match value {
        "commander" => Ok(UnitKind::Commander),
        "warrior" => Ok(UnitKind::Warrior),
        "archer" => Ok(UnitKind::Archer),
        "settler" => Ok(UnitKind::Settler),
        "worker" => Ok(UnitKind::Worker),
        "merchant" => Ok(UnitKind::Merchant),
        "scout" => Ok(UnitKind::Scout),
        "spearman" => Ok(UnitKind::Spearman),
        "cavalry" => Ok(UnitKind::Cavalry),
        "catapult" => Ok(UnitKind::Catapult),
        "heavyInfantry" => Ok(UnitKind::HeavyInfantry),
        "fieldCannon" => Ok(UnitKind::FieldCannon),
        "rifleman" => Ok(UnitKind::Rifleman),
        "tank" => Ok(UnitKind::Tank),
        "scoutShip" => Ok(UnitKind::ScoutShip),
        "warship" => Ok(UnitKind::Warship),
        "reconPlane" => Ok(UnitKind::ReconPlane),
        _ => Err(error(format!("unknown unit type: {value}"))),
    }
}

fn accepted_output(
    input: &FixtureInput,
    map: &MapDefinition,
    transition: &MovementTransition,
    save: JsonObject,
) -> Result<FixtureOutput, AdapterError> {
    let mut state = input.state().clone();
    apply_movement_projection(&mut state, transition)?;

    let mut events = Vec::new();
    if let Some(event) = transition.event() {
        events.push(json_object(&json!({
            "type": "UnitMoved",
            "unitId": event.unit_id().as_str(),
            "fromCol": event.from().col(),
            "fromRow": event.from().row(),
            "toCol": event.to().col(),
            "toRow": event.to().row(),
        }))?);
        update_fixture_fog(&mut state, map, event.unit_id())?;
    }

    let movement_executions = transition
        .execution()
        .map(to_fixture_execution)
        .transpose()?
        .into_iter()
        .collect::<Vec<_>>();
    Ok(FixtureOutput::accept(
        save,
        state,
        events,
        movement_executions,
    ))
}

fn apply_movement_projection(
    state: &mut JsonObject,
    transition: &MovementTransition,
) -> Result<(), AdapterError> {
    let units = state
        .get_mut("units")
        .and_then(Value::as_array_mut)
        .ok_or_else(|| error("state.units must be an array"))?;
    for projected in transition.state().units() {
        let raw = units
            .iter_mut()
            .find(|value| value.get("id").and_then(Value::as_str) == Some(projected.id().as_str()))
            .and_then(Value::as_object_mut)
            .ok_or_else(|| error(format!("missing canonical unit: {}", projected.id())))?;
        raw.insert("col".into(), projected.position().col().into());
        raw.insert("row".into(), projected.position().row().into());
        if raw.contains_key("movementUnits") {
            raw.insert(
                "movementUnits".into(),
                projected.movement_units().get().into(),
            );
        } else {
            let units = projected.movement_units().get();
            if units % MovementUnits::PER_POINT != 0 {
                return Err(error("fixture movementPoints cannot represent half points"));
            }
            raw.insert(
                "movementPoints".into(),
                (units / MovementUnits::PER_POINT).into(),
            );
        }
    }
    Ok(())
}

fn update_fixture_fog(
    state: &mut JsonObject,
    map: &MapDefinition,
    moved_unit_id: &UnitId,
) -> Result<(), AdapterError> {
    let units = required_array(state, "units")?;
    let moved = units
        .iter()
        .find(|value| value.get("id").and_then(Value::as_str) == Some(moved_unit_id.as_str()))
        .and_then(Value::as_object)
        .ok_or_else(|| error(format!("missing moved unit: {moved_unit_id}")))?;
    let player_id = required_string_at(moved, "ownerPlayerId", "moved unit")?.to_owned();
    let origin = HexCoord::new(
        required_i32_at(moved, "col", "moved unit")?,
        required_i32_at(moved, "row", "moved unit")?,
    );
    let height = u32::from(
        map.tile_at(origin)
            .ok_or_else(|| error("moved unit is outside the map"))?
            .height(),
    );
    let range = (2 + height / 2).min(3);
    let visible = map
        .tiles()
        .iter()
        .map(aonw_content::TileDefinition::coordinate)
        .filter(|coordinate| origin.distance_to(*coordinate) <= u64::from(range))
        .collect::<BTreeSet<_>>();

    let fog = state
        .get_mut("fogOfWar")
        .and_then(Value::as_array_mut)
        .ok_or_else(|| error("state.fogOfWar must be an array"))?;
    let existing_index = fog
        .iter()
        .position(|value| value.get("playerId").and_then(Value::as_str) == Some(&player_id));
    let mut discovered = existing_index
        .and_then(|index| fog[index].get("discoveredHexes"))
        .and_then(Value::as_array)
        .map(|values| decode_coordinates(values, "fogOfWar.discoveredHexes"))
        .transpose()?
        .unwrap_or_default();
    discovered.extend(visible.iter().copied());
    let value = json!({
        "playerId": player_id,
        "discoveredHexes": coordinates_json(&discovered),
        "visibleHexes": coordinates_json(&visible),
    });
    if let Some(index) = existing_index {
        fog[index] = value;
    } else {
        fog.push(value);
    }
    Ok(())
}

fn to_fixture_execution(
    execution: &aonw_engine::UnitMovementExecution,
) -> Result<MovementExecution, AdapterError> {
    let from_col = u32::try_from(execution.from().col()).map_err(display_error)?;
    let from_row = u32::try_from(execution.from().row()).map_err(display_error)?;
    let steps = execution
        .steps()
        .iter()
        .map(|step| {
            Ok(MovementStep::new(
                u32::try_from(step.coordinate().col()).map_err(display_error)?,
                u32::try_from(step.coordinate().row()).map_err(display_error)?,
                step.enter_cost().get(),
                step.cumulative_cost().get(),
            ))
        })
        .collect::<Result<Vec<_>, AdapterError>>()?;
    MovementExecution::try_new(execution.unit_id().as_str(), from_col, from_row, steps)
        .map_err(display_error)
}

fn decode_coordinates(values: &[Value], path: &str) -> Result<BTreeSet<HexCoord>, AdapterError> {
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let object = value
                .as_object()
                .ok_or_else(|| error(format!("{path}[{index}] must be an object")))?;
            Ok(HexCoord::new(
                required_i32_at(object, "col", path)?,
                required_i32_at(object, "row", path)?,
            ))
        })
        .collect()
}

fn coordinates_json(coordinates: &BTreeSet<HexCoord>) -> Vec<Value> {
    let mut sorted = coordinates.iter().copied().collect::<Vec<_>>();
    sorted.sort_unstable_by_key(|coordinate| (coordinate.col(), coordinate.row()));
    sorted
        .into_iter()
        .map(|coordinate| json!({"col": coordinate.col(), "row": coordinate.row()}))
        .collect()
}

fn required_array<'value>(
    object: &'value JsonObject,
    field: &str,
) -> Result<&'value Vec<Value>, AdapterError> {
    object
        .get(field)
        .and_then(Value::as_array)
        .ok_or_else(|| error(format!("{field} must be an array")))
}

fn required_string<'value>(
    object: &'value JsonObject,
    field: &str,
) -> Result<&'value str, AdapterError> {
    required_string_at(object, field, "input")
}

fn required_string_at<'value>(
    object: &'value Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<&'value str, AdapterError> {
    object
        .get(field)
        .and_then(Value::as_str)
        .ok_or_else(|| error(format!("{path}.{field} must be a string")))
}

fn required_i32(object: &JsonObject, field: &str) -> Result<i32, AdapterError> {
    required_i32_at(object, field, "input")
}

fn required_i32_at(
    object: &Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<i32, AdapterError> {
    let value = object
        .get(field)
        .ok_or_else(|| error(format!("{path}.{field} is required")))?;
    let value = value
        .as_i64()
        .ok_or_else(|| error(format!("{path}.{field} must be an integer")))?;
    i32::try_from(value).map_err(display_error)
}

fn required_u32(object: &JsonObject, field: &str) -> Result<u32, AdapterError> {
    required_u32_at(object, field, "input")
}

fn required_u32_at(
    object: &Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<u32, AdapterError> {
    let value = object
        .get(field)
        .ok_or_else(|| error(format!("{path}.{field} is required")))?;
    value_to_u32(value, &format!("{path}.{field}"))
}

fn value_to_u32(value: &Value, path: &str) -> Result<u32, AdapterError> {
    let value = value
        .as_u64()
        .ok_or_else(|| error(format!("{path} must be a non-negative integer")))?;
    u32::try_from(value).map_err(display_error)
}

fn json_object(value: &Value) -> Result<JsonObject, AdapterError> {
    value
        .as_object()
        .cloned()
        .ok_or_else(|| error("event must be an object"))
}

fn error(message: impl Into<String>) -> AdapterError {
    AdapterError(message.into())
}

fn display_error(source: impl fmt::Display) -> AdapterError {
    error(source.to_string())
}

#[test]
fn rust_executes_reviewed_movement_v2_fixtures() {
    let fixture_dir = repository_root().join("test/fixtures/reducer_parity");
    let loader = FixtureLoader::default();
    let selected = FIXTURE_IDS
        .iter()
        .map(|fixture_id| {
            loader
                .load_file(fixture_dir.join(format!("{fixture_id}.json")))
                .expect("current reducer-parity fixture must load")
        })
        .collect::<Vec<_>>();

    assert_eq!(
        selected
            .iter()
            .map(aonw_testkit::Fixture::id)
            .collect::<BTreeSet<_>>(),
        FIXTURE_IDS.into_iter().collect()
    );
    assert!(
        selected
            .iter()
            .all(|fixture| fixture.fixture_version() == 2)
    );
    verify_corpus(&selected, &RustMovementFixtureExecutor)
        .unwrap_or_else(|failure| panic!("{failure:?}"));
}
