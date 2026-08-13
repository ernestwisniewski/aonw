//! Executes the current Dart command oracle through the canonical Rust engine.

use std::fmt;
use std::path::{Path, PathBuf};

use aonw_content::{GridLayout, MapDefinition, RulesetDefinition, TerrainType, TileDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    CURRENT_GAME_STATE_VERSION, CityDto, CoordinateDto, GameStateDto, MovementStepDto,
    PlayerFogDto, PlayerPairDto, QueuedMovePathDto, TransportConditionDto, TransportSegmentDto,
    UnitActivityDto, UnitDto, UnitKindDto, UnitOccupancyPolicyDto, UnitPostureDto,
};
use aonw_domain::{HexCoord, HexGridBounds, MovementUnits, PlayerId, UnitId};
use aonw_engine::{
    DomainCommand, DomainEvent, EngineContext, ExecutionEvidence, GameEngine, MoveUnitCommand,
    UnitActionCommand,
};
use aonw_testkit::{
    FixtureExecutor, FixtureInput, FixtureOutput, JsonObject, MovementExecution, MovementStep,
};
use serde_json::{Map, Value, json};

#[derive(Debug)]
pub(crate) struct AdapterError(String);

impl fmt::Display for AdapterError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for AdapterError {}

pub(crate) struct RustEngineFixtureExecutor;

impl FixtureExecutor for RustEngineFixtureExecutor {
    type Error = AdapterError;

    fn execute(
        &self,
        _fixture_id: &str,
        family: &str,
        input: &FixtureInput,
    ) -> Result<FixtureOutput, Self::Error> {
        if family != "movement" && family != "unit-actions" {
            return Err(error(format!("unsupported fixture family: {family}")));
        }

        let map = decode_map(input.map())?;
        let unit_id =
            UnitId::new(required_string(input.command(), "unitId")?).map_err(display_error)?;
        let command_type = required_string(input.command(), "type")?;
        let mut save = input.save().clone();
        save.remove("savedAt");

        let state = match decode_state(input, map.bounds(), &unit_id, family == "unit-actions")? {
            DecodedState::Valid(state) => state,
            DecodedState::CommandUnitOutOfBounds => {
                return Ok(FixtureOutput::reject(
                    "unit_out_of_bounds",
                    save,
                    input.state().clone(),
                    Vec::new(),
                    Vec::new(),
                ));
            }
        };
        let actor = PlayerId::new(input.actor_player_id()).map_err(display_error)?;
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
        let transition = match command_type {
            "MoveUnit" => {
                let target = HexCoord::new(
                    required_i32(input.command(), "targetCol")?,
                    required_i32(input.command(), "targetRow")?,
                );
                GameEngine::apply(
                    &state,
                    context,
                    DomainCommand::MoveUnit(MoveUnitCommand::new(input.tick(), &unit_id, target)),
                )
            }
            "CancelUnitAction" => GameEngine::apply(
                &state,
                context,
                DomainCommand::CancelUnitAction(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            "SkipUnitTurn" => GameEngine::apply(
                &state,
                context,
                DomainCommand::SkipUnitTurn(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            "FortifyUnit" => GameEngine::apply(
                &state,
                context,
                DomainCommand::FortifyUnit(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            _ => return Err(error(format!("unsupported command: {command_type}"))),
        }
        .map_err(display_error)?;

        if let Some(rejection) = transition.rejection() {
            return Ok(FixtureOutput::reject(
                rejection.code(),
                save,
                input.state().clone(),
                Vec::new(),
                Vec::new(),
            ));
        }

        let mut output_state = input.state().clone();
        apply_canonical_projection(&mut output_state, transition.state(), transition.evidence())?;
        Ok(FixtureOutput::accept(
            save,
            output_state,
            transition
                .events()
                .iter()
                .map(event_json)
                .collect::<Result<Vec<_>, _>>()?,
            transition
                .evidence()
                .map(evidence_execution)
                .transpose()?
                .into_iter()
                .collect::<Vec<_>>(),
        ))
    }
}

enum DecodedState {
    Valid(aonw_domain::GameState),
    CommandUnitOutOfBounds,
}

pub(crate) fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| {
            path.join("engine/Cargo.toml").is_file()
                && path.join("test/fixtures/reducer_parity_v2").is_dir()
        })
        .expect("repository root must contain engine and current reducer fixtures")
        .to_path_buf()
}

fn decode_map(raw: &JsonObject) -> Result<MapDefinition, AdapterError> {
    let cols = u16::try_from(required_u32(raw, "cols")?).map_err(display_error)?;
    let rows = u16::try_from(required_u32(raw, "rows")?).map_err(display_error)?;
    let tiles = required_array(raw, "tiles")?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("input.map.tiles[{index}]");
            let tile = object_at(value, &path)?;
            let mut terrains = required_array(tile, "terrains")?
                .iter()
                .map(|value| {
                    value
                        .as_str()
                        .ok_or_else(|| error(format!("{path}.terrains must contain strings")))
                        .and_then(parse_terrain)
                })
                .collect::<Result<Vec<_>, _>>()?;
            if terrains.first().is_some_and(|terrain| terrain.is_feature()) {
                terrains.insert(0, TerrainType::Grassland);
            }
            TileDefinition::try_new(
                coordinate_fields(tile, &path)?,
                terrains,
                Vec::new(),
                u8::try_from(required_u32_at(tile, "height", &path)?).map_err(display_error)?,
            )
            .map_err(display_error)
        })
        .collect::<Result<Vec<_>, _>>()?;
    MapDefinition::try_new(
        required_string(raw, "mapName")?,
        GridLayout::OddQFlatTop,
        cols,
        rows,
        tiles,
        Vec::new(),
    )
    .map_err(display_error)
}

fn parse_terrain(value: &str) -> Result<TerrainType, AdapterError> {
    match value {
        "ocean" => Ok(TerrainType::Ocean),
        "coast" => Ok(TerrainType::Coast),
        "lake" => Ok(TerrainType::Lake),
        "plains" => Ok(TerrainType::Plains),
        "grassland" => Ok(TerrainType::Grassland),
        "desert" => Ok(TerrainType::Desert),
        "tundra" => Ok(TerrainType::Tundra),
        "snow" => Ok(TerrainType::Snow),
        "mountain" => Ok(TerrainType::Mountain),
        "hills" => Ok(TerrainType::Hills),
        "wetlands" => Ok(TerrainType::Wetlands),
        "jungle" => Ok(TerrainType::Jungle),
        "forest" => Ok(TerrainType::Forest),
        "river" => Ok(TerrainType::River),
        _ => Err(error(format!("unknown terrain: {value}"))),
    }
}

fn decode_state(
    input: &FixtureInput,
    bounds: HexGridBounds,
    command_unit_id: &UnitId,
    include_unit_orders: bool,
) -> Result<DecodedState, AdapterError> {
    let (units, command_unit_out_of_bounds) =
        decode_units(input.state(), bounds, command_unit_id, include_unit_orders)?;
    if command_unit_out_of_bounds {
        return Ok(DecodedState::CommandUnitOutOfBounds);
    }
    let cities = decode_cities(input.state(), bounds)?;
    let fog_of_war = required_array(input.state(), "fogOfWar")?
        .iter()
        .enumerate()
        .map(|(index, value)| decode_fog(value, &format!("input.state.fogOfWar[{index}]")))
        .collect::<Result<Vec<_>, _>>()?;
    let diplomatic_contacts = decode_contacts(input.state())?;
    let transport_network = required_array(input.state(), "transportNetwork")?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            decode_transport(value, &format!("input.state.transportNetwork[{index}]"))
        })
        .collect::<Result<Vec<_>, _>>()?;
    let dto = GameStateDto {
        schema_version: CURRENT_GAME_STATE_VERSION,
        revision: input.tick(),
        turn: required_u32(input.save(), "turn")?,
        cols: bounds.cols(),
        rows: bounds.rows(),
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units,
        cities,
        fog_of_war,
        diplomatic_contacts,
        transport_network,
    };
    decode_game_state(dto)
        .map(DecodedState::Valid)
        .map_err(display_error)
}

fn decode_units(
    state: &JsonObject,
    bounds: HexGridBounds,
    command_unit_id: &UnitId,
    include_unit_orders: bool,
) -> Result<(Vec<UnitDto>, bool), AdapterError> {
    let mut command_unit_out_of_bounds = false;
    let pending_skip = if include_unit_orders {
        pending_turn_skip(state)?
    } else {
        None
    };
    let units = required_array(state, "units")?
        .iter()
        .enumerate()
        .filter_map(|(index, value)| {
            let object = match object_at(value, &format!("input.state.units[{index}]")) {
                Ok(object) => object,
                Err(error) => return Some(Err(error)),
            };
            let path = format!("input.state.units[{index}]");
            let coordinate = match coordinate_fields(object, &path) {
                Ok(coordinate) => coordinate,
                Err(error) => return Some(Err(error)),
            };
            if !bounds.contains(coordinate) {
                if object.get("id").and_then(Value::as_str) == Some(command_unit_id.as_str()) {
                    command_unit_out_of_bounds = true;
                }
                return None;
            }
            let restore = object
                .get("id")
                .and_then(Value::as_str)
                .and_then(|id| pending_skip.as_ref().filter(|(unit_id, _)| unit_id == id))
                .map(|(_, restore)| *restore);
            Some(decode_unit(object, &path, include_unit_orders, restore))
        })
        .collect::<Result<Vec<_>, _>>()?;
    Ok((units, command_unit_out_of_bounds))
}

fn decode_cities(state: &JsonObject, bounds: HexGridBounds) -> Result<Vec<CityDto>, AdapterError> {
    required_array(state, "cities")?
        .iter()
        .enumerate()
        .filter_map(|(index, value)| {
            let path = format!("input.state.cities[{index}]");
            let object = match object_at(value, &path) {
                Ok(object) => object,
                Err(error) => return Some(Err(error)),
            };
            let center = match object
                .get("center")
                .ok_or_else(|| error(format!("{path}.center is required")))
                .and_then(|value| object_at(value, &format!("{path}.center")))
                .and_then(|center| coordinate_fields(center, &format!("{path}.center")))
            {
                Ok(center) => center,
                Err(error) => return Some(Err(error)),
            };
            let controlled = match required_array(object, "controlledHexes").and_then(|values| {
                values
                    .iter()
                    .enumerate()
                    .map(|(coordinate_index, value)| {
                        let coordinate_path = format!("{path}.controlledHexes[{coordinate_index}]");
                        object_at(value, &coordinate_path)
                            .and_then(|value| coordinate_fields(value, &coordinate_path))
                    })
                    .collect::<Result<Vec<_>, _>>()
            }) {
                Ok(controlled) => controlled,
                Err(error) => return Some(Err(error)),
            };
            if !bounds.contains(center)
                || controlled
                    .iter()
                    .any(|coordinate| !bounds.contains(*coordinate))
            {
                return None;
            }
            let id = match required_string_at(object, "id", &path) {
                Ok(value) => value.to_owned(),
                Err(error) => return Some(Err(error)),
            };
            let owner_player_id = match required_string_at(object, "ownerPlayerId", &path) {
                Ok(value) => value.to_owned(),
                Err(error) => return Some(Err(error)),
            };
            Some(Ok(CityDto {
                id,
                owner_player_id,
                center: coordinate_dto(center),
                controlled_hexes: controlled.into_iter().map(coordinate_dto).collect(),
            }))
        })
        .collect()
}

fn decode_unit(
    object: &JsonObject,
    path: &str,
    include_unit_orders: bool,
    skipped_movement_restore_units: Option<u32>,
) -> Result<UnitDto, AdapterError> {
    let movement_units = if let Some(value) = object.get("movementUnits") {
        value_to_u32(value, &format!("{path}.movementUnits"))?
    } else {
        let points = required_u32_at(object, "movementPoints", path)?;
        let subpoints = object
            .get("movementSubpoints")
            .map(|value| value_to_u32(value, &format!("{path}.movementSubpoints")))
            .transpose()?
            .unwrap_or(0);
        points
            .checked_mul(MovementUnits::PER_POINT)
            .and_then(|units| units.checked_add(subpoints))
            .ok_or_else(|| error(format!("{path}.movementPoints overflows")))?
    };
    let posture = match object.get("posture").and_then(Value::as_str) {
        None | Some("active") => UnitPostureDto::Active,
        Some("fortified") => UnitPostureDto::Fortified,
        Some("autoExploring") => UnitPostureDto::AutoExploring,
        Some("autoWorking") => UnitPostureDto::AutoWorking,
        Some(value) => return Err(error(format!("unknown unit posture: {value}"))),
    };
    Ok(UnitDto {
        id: required_string_at(object, "id", path)?.to_owned(),
        owner_player_id: required_string_at(object, "ownerPlayerId", path)?.to_owned(),
        kind: parse_unit_kind(required_string_at(object, "type", path)?)?,
        name: required_string_at(object, "name", path)?.to_owned(),
        col: required_i32_at(object, "col", path)?,
        row: required_i32_at(object, "row", path)?,
        movement_units,
        skipped_movement_restore_units,
        army: Vec::new(),
        queued_path: if include_unit_orders {
            object
                .get("queuedPath")
                .map(|value| decode_queued_path(value, path))
                .transpose()?
        } else {
            None
        },
        merchant_trade_route: None,
        activity: UnitActivityDto {
            worker_job: None,
            city_founding_job: None,
            worker_assignment: include_unit_orders
                .then(|| {
                    ["workerJob", "cityFoundingJob", "workerAssignment"]
                        .iter()
                        .any(|field| object.contains_key(*field))
                        .then_some(CoordinateDto {
                            col: required_i32_at(object, "col", path).ok()?,
                            row: required_i32_at(object, "row", path).ok()?,
                        })
                })
                .flatten(),
            excavating_artifact_id: optional_string(object, "excavatingArtifactId")?,
        },
        worker_build_charges: 0,
        hit_points: None,
        experience_points: 0,
        posture,
        carried_artifact_id: optional_string(object, "carriedArtifactId")?,
    })
}

fn pending_turn_skip(state: &JsonObject) -> Result<Option<(String, u32)>, AdapterError> {
    let Some(pending) = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("pendingAction"))
        .and_then(Value::as_object)
    else {
        return Ok(None);
    };
    if pending.get("type").and_then(Value::as_str) != Some("unitTurnSkip") {
        return Ok(None);
    }
    Ok(Some((
        required_string_at(pending, "unitId", "input.state.lifecycle.pendingAction")?.to_owned(),
        required_u32_at(
            pending,
            "restoreMovementUnits",
            "input.state.lifecycle.pendingAction",
        )?,
    )))
}

fn decode_queued_path(value: &Value, unit_path: &str) -> Result<QueuedMovePathDto, AdapterError> {
    let path = format!("{unit_path}.queuedPath");
    let object = object_at(value, &path)?;
    let steps = required_array(object, "steps")?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let step_path = format!("{path}.steps[{index}]");
            let step = object_at(value, &step_path)?;
            Ok(MovementStepDto {
                col: required_i32_at(step, "col", &step_path)?,
                row: required_i32_at(step, "row", &step_path)?,
                enter_cost_units: required_u32_at(step, "enterCost", &step_path)?,
                cumulative_cost_units: required_u32_at(step, "cumulativeCost", &step_path)?,
            })
        })
        .collect::<Result<Vec<_>, AdapterError>>()?;
    Ok(QueuedMovePathDto {
        target_col: required_i32_at(object, "targetCol", &path)?,
        target_row: required_i32_at(object, "targetRow", &path)?,
        steps,
    })
}

fn parse_unit_kind(value: &str) -> Result<UnitKindDto, AdapterError> {
    match value {
        "commander" => Ok(UnitKindDto::Commander),
        "warrior" => Ok(UnitKindDto::Warrior),
        "archer" => Ok(UnitKindDto::Archer),
        "settler" => Ok(UnitKindDto::Settler),
        "worker" => Ok(UnitKindDto::Worker),
        "merchant" => Ok(UnitKindDto::Merchant),
        "scout" => Ok(UnitKindDto::Scout),
        "spearman" => Ok(UnitKindDto::Spearman),
        "cavalry" => Ok(UnitKindDto::Cavalry),
        "catapult" => Ok(UnitKindDto::Catapult),
        "heavyInfantry" => Ok(UnitKindDto::HeavyInfantry),
        "fieldCannon" => Ok(UnitKindDto::FieldCannon),
        "rifleman" => Ok(UnitKindDto::Rifleman),
        "tank" => Ok(UnitKindDto::Tank),
        "scoutShip" => Ok(UnitKindDto::ScoutShip),
        "warship" => Ok(UnitKindDto::Warship),
        "reconPlane" => Ok(UnitKindDto::ReconPlane),
        _ => Err(error(format!("unknown unit type: {value}"))),
    }
}

fn decode_fog(value: &Value, path: &str) -> Result<PlayerFogDto, AdapterError> {
    let object = object_at(value, path)?;
    Ok(PlayerFogDto {
        player_id: required_string_at(object, "playerId", path)?.to_owned(),
        discovered_hexes: decode_coordinates(required_array(object, "discoveredHexes")?, path)?,
        visible_hexes: decode_coordinates(required_array(object, "visibleHexes")?, path)?,
    })
}

fn decode_contacts(state: &JsonObject) -> Result<Vec<PlayerPairDto>, AdapterError> {
    let Some(contacts) = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("diplomacy"))
        .and_then(Value::as_object)
        .and_then(|diplomacy| diplomacy.get("contacts"))
        .and_then(Value::as_array)
    else {
        return Ok(Vec::new());
    };
    contacts
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let value = value.as_str().ok_or_else(|| {
                error(format!(
                    "input.state.lifecycle.diplomacy.contacts[{index}] must be a string"
                ))
            })?;
            let (first, second) = value
                .split_once('|')
                .ok_or_else(|| error(format!("invalid diplomacy contact: {value}")))?;
            Ok(PlayerPairDto {
                first_player_id: first.to_owned(),
                second_player_id: second.to_owned(),
            })
        })
        .collect()
}

fn decode_transport(value: &Value, path: &str) -> Result<TransportSegmentDto, AdapterError> {
    let object = object_at(value, path)?;
    if required_string_at(object, "kind", path)? != "road" {
        return Err(error(format!("{path}.kind must be road")));
    }
    let condition = match required_string_at(object, "condition", path)? {
        "operational" => TransportConditionDto::Operational,
        "pillaged" => TransportConditionDto::Pillaged,
        value => return Err(error(format!("unknown transport condition: {value}"))),
    };
    Ok(TransportSegmentDto {
        coordinate: coordinate_dto(coordinate_fields(object, path)?),
        condition,
        built_by_player_id: required_string_at(object, "builtByPlayerId", path)?.to_owned(),
        built_by_city_id: optional_string(object, "builtByCityId")?,
    })
}

fn apply_canonical_projection(
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
    if let Some(unit) = state
        .units()
        .iter()
        .find(|unit| unit.skipped_movement_restore().is_some())
    {
        lifecycle.insert(
            "pendingAction".into(),
            json!({
                "type": "unitTurnSkip",
                "ownerPlayerId": unit.owner_player_id().as_str(),
                "unitId": unit.id().as_str(),
                "restoreMovementUnits": unit
                    .skipped_movement_restore()
                    .expect("matched skipped unit")
                    .get(),
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

fn event_json(event: &DomainEvent) -> Result<JsonObject, AdapterError> {
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

fn evidence_execution(evidence: &ExecutionEvidence) -> Result<MovementExecution, AdapterError> {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => {
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
            MovementExecution::try_new(
                execution.unit_id().as_str(),
                u32::try_from(execution.from().col()).map_err(display_error)?,
                u32::try_from(execution.from().row()).map_err(display_error)?,
                steps,
            )
            .map_err(display_error)
        }
    }
}

fn decode_coordinates(values: &[Value], path: &str) -> Result<Vec<CoordinateDto>, AdapterError> {
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("{path}[{index}]");
            object_at(value, &path)
                .and_then(|object| coordinate_fields(object, &path))
                .map(coordinate_dto)
        })
        .collect()
}

fn coordinate_values(coordinates: &[HexCoord]) -> Vec<Value> {
    coordinates
        .iter()
        .map(|coordinate| json!({"col": coordinate.col(), "row": coordinate.row()}))
        .collect()
}

fn coordinate_dto(coordinate: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: coordinate.col(),
        row: coordinate.row(),
    }
}

fn coordinate_fields(object: &JsonObject, path: &str) -> Result<HexCoord, AdapterError> {
    Ok(HexCoord::new(
        required_i32_at(object, "col", path)?,
        required_i32_at(object, "row", path)?,
    ))
}

fn object_at<'value>(value: &'value Value, path: &str) -> Result<&'value JsonObject, AdapterError> {
    value
        .as_object()
        .ok_or_else(|| error(format!("{path} must be an object")))
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

fn optional_string(object: &JsonObject, field: &str) -> Result<Option<String>, AdapterError> {
    match object.get(field) {
        None | Some(Value::Null) => Ok(None),
        Some(Value::String(value)) => Ok(Some(value.clone())),
        Some(_) => Err(error(format!("{field} must be a string or null"))),
    }
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
        .ok_or_else(|| error(format!("{path}.{field} is required")))?
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
    object
        .get(field)
        .ok_or_else(|| error(format!("{path}.{field} is required")))
        .and_then(|value| value_to_u32(value, &format!("{path}.{field}")))
}

fn value_to_u32(value: &Value, path: &str) -> Result<u32, AdapterError> {
    value
        .as_u64()
        .ok_or_else(|| error(format!("{path} must be a non-negative integer")))
        .and_then(|value| u32::try_from(value).map_err(display_error))
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
