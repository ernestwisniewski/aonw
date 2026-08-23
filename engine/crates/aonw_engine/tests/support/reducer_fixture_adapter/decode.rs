use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    CityDto, CoordinateDto, GameModeDto, GameStateDto, InteractionStateDto, MatchIdentityDto,
    MatchRulesDto, MovementStepDto, ParticipantDto, PendingInteractionDto, PlayerFogDto,
    PlayerPairDto, QueuedMovePathDto, TransportConditionDto, TransportSegmentDto, TurnLifecycleDto,
    UnitActivityDto, UnitDto, UnitKindDto, UnitOccupancyPolicyDto, UnitPostureDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};
use aonw_domain::{HexGridBounds, MovementUnits, UnitId};
use aonw_testkit::{FixtureInput, JsonObject};
use serde_json::{Map, Value};

use super::AdapterError;
use super::json::{
    coordinate_dto, coordinate_fields, decode_coordinates, display_error, error, object_at,
    optional_string, required_array, required_i32_at, required_string, required_string_at,
    required_u32, required_u32_at, value_to_u32,
};

pub(super) enum DecodedState {
    Valid(Box<aonw_domain::GameState>),
    CommandUnitOutOfBounds,
}

pub(super) fn decode_map(raw: &JsonObject) -> Result<MapDefinition, AdapterError> {
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
            TileDefinition::try_new_for_simulation(
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

pub(super) fn decode_state(
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
    let artifacts = decode_referenced_artifacts(input.state(), &units)?;
    let interaction = decode_interaction(input.state())?;
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
        revision: input.tick(),
        turn: required_u32(input.save(), "turn")?,
        match_identity: decode_match_identity(input.save())?,
        turn_lifecycle: decode_turn_lifecycle(input.save(), input.state())?,
        cols: bounds.cols(),
        rows: bounds.rows(),
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units,
        cities,
        artifacts,
        interaction,
        fog_of_war,
        diplomatic_contacts,
        transport_network,
    };
    decode_game_state(dto)
        .map(Box::new)
        .map(DecodedState::Valid)
        .map_err(display_error)
}

fn decode_match_identity(save: &JsonObject) -> Result<MatchIdentityDto, AdapterError> {
    Ok(MatchIdentityDto {
        match_rules: serde_json::from_value::<MatchRulesDto>(json_field(
            save,
            "ruleset",
            "input.save",
        )?)
        .map_err(display_error)?,
        participants: serde_json::from_value::<Vec<ParticipantDto>>(json_field(
            save,
            "players",
            "input.save",
        )?)
        .map_err(display_error)?,
        game_mode: serde_json::from_value::<GameModeDto>(json_field(
            save,
            "gameMode",
            "input.save",
        )?)
        .map_err(display_error)?,
    })
}

fn decode_turn_lifecycle(
    save: &JsonObject,
    state: &JsonObject,
) -> Result<TurnLifecycleDto, AdapterError> {
    let lifecycle = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .ok_or_else(|| error("input.state.lifecycle must be an object"))?;
    let mut selected = Map::from_iter([
        (
            "turnStatesByPlayerId".to_owned(),
            json_field(save, "playerStates", "input.save")?,
        ),
        ("submittedPlayerIds".to_owned(), Value::Array(Vec::new())),
        (
            "timeoutStreaksByPlayerId".to_owned(),
            Value::Object(Map::new()),
        ),
        ("afkPlayerIds".to_owned(), Value::Array(Vec::new())),
        ("kickedPlayerIds".to_owned(), Value::Array(Vec::new())),
        ("turnStartedAt".to_owned(), Value::Null),
    ]);
    for field in [
        "submittedPlayerIds",
        "timeoutStreaksByPlayerId",
        "afkPlayerIds",
        "kickedPlayerIds",
        "turnStartedAt",
    ] {
        if let Some(value) = lifecycle.get(field) {
            selected.insert(field.to_owned(), value.clone());
        }
    }
    serde_json::from_value::<TurnLifecycleDto>(Value::Object(selected)).map_err(display_error)
}

fn json_field(object: &JsonObject, field: &str, path: &str) -> Result<Value, AdapterError> {
    object
        .get(field)
        .cloned()
        .ok_or_else(|| error(format!("{path}.{field} is required")))
}

fn decode_units(
    state: &JsonObject,
    bounds: HexGridBounds,
    command_unit_id: &UnitId,
    include_unit_orders: bool,
) -> Result<(Vec<UnitDto>, bool), AdapterError> {
    let mut command_unit_out_of_bounds = false;
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
            Some(decode_unit(object, &path, include_unit_orders))
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

fn decode_referenced_artifacts(
    state: &JsonObject,
    units: &[UnitDto],
) -> Result<Vec<WorldArtifactDto>, AdapterError> {
    let raw_artifacts = required_array(state, "artifacts")?;
    let mut artifacts = Vec::new();
    for unit in units {
        if let Some(artifact_id) = &unit.carried_artifact_id {
            artifacts.push(WorldArtifactDto {
                id: artifact_id.clone(),
                artifact_type: referenced_artifact_type(raw_artifacts, artifact_id)?,
                location: WorldArtifactLocationDto::Carried {
                    unit_id: unit.id.clone(),
                },
            });
        }
        if let Some(artifact_id) = &unit.activity.excavating_artifact_id {
            let raw_location = raw_artifacts
                .iter()
                .find(|value| value.get("id").and_then(Value::as_str) == Some(artifact_id))
                .and_then(|value| value.get("location"))
                .and_then(Value::as_object);
            let coordinate = raw_location
                .filter(|location| {
                    location.get("kind").and_then(Value::as_str) == Some("excavation")
                })
                .map(|location| {
                    Ok(CoordinateDto {
                        col: required_i32_at(location, "col", "input.state.artifacts[].location")?,
                        row: required_i32_at(location, "row", "input.state.artifacts[].location")?,
                    })
                })
                .transpose()?
                .unwrap_or(CoordinateDto {
                    col: unit.col,
                    row: unit.row,
                });
            let remaining_turns = raw_location
                .filter(|location| {
                    location.get("kind").and_then(Value::as_str) == Some("excavation")
                })
                .and_then(|location| location.get("remainingTurns"))
                .map(|value| value_to_u32(value, "input.state.artifacts[].location.remainingTurns"))
                .transpose()?
                .unwrap_or(1);
            artifacts.push(WorldArtifactDto {
                id: artifact_id.clone(),
                artifact_type: referenced_artifact_type(raw_artifacts, artifact_id)?,
                location: WorldArtifactLocationDto::Excavation {
                    unit_id: unit.id.clone(),
                    coordinate,
                    remaining_turns,
                },
            });
        }
    }
    Ok(artifacts)
}

fn referenced_artifact_type(
    raw_artifacts: &[Value],
    artifact_id: &str,
) -> Result<WorldArtifactTypeDto, AdapterError> {
    let Some(value) = raw_artifacts
        .iter()
        .find(|value| value.get("id").and_then(Value::as_str) == Some(artifact_id))
        .and_then(|value| value.get("type"))
        .and_then(Value::as_str)
    else {
        return Ok(WorldArtifactTypeDto::AstronomersTablets);
    };
    match value {
        "ancientImperialCrown" => Ok(WorldArtifactTypeDto::AncientImperialCrown),
        "astronomersTablets" => Ok(WorldArtifactTypeDto::AstronomersTablets),
        "prophetMask" => Ok(WorldArtifactTypeDto::ProphetMask),
        "heroSword" => Ok(WorldArtifactTypeDto::HeroSword),
        "merchantsSeal" => Ok(WorldArtifactTypeDto::MerchantsSeal),
        "firstPeoplesChronicle" => Ok(WorldArtifactTypeDto::FirstPeoplesChronicle),
        "templeReliquary" => Ok(WorldArtifactTypeDto::TempleReliquary),
        "queensMirror" => Ok(WorldArtifactTypeDto::QueensMirror),
        _ => Err(error(format!("unknown artifact type: {value}"))),
    }
}

fn decode_unit(
    object: &JsonObject,
    path: &str,
    include_unit_orders: bool,
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

fn decode_interaction(state: &JsonObject) -> Result<InteractionStateDto, AdapterError> {
    let Some(pending) = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("pendingAction"))
        .and_then(Value::as_object)
    else {
        return Ok(InteractionStateDto::default());
    };
    if pending.get("type").and_then(Value::as_str) != Some("unitTurnSkip") {
        return Ok(InteractionStateDto::default());
    }
    let path = "input.state.lifecycle.pendingAction";
    Ok(InteractionStateDto {
        city_founding_draft: None,
        pending: Some(PendingInteractionDto::UnitTurnSkip {
            owner_player_id: required_string_at(pending, "ownerPlayerId", path)?.to_owned(),
            unit_id: required_string_at(pending, "unitId", path)?.to_owned(),
            restore_movement_units: required_u32_at(pending, "restoreMovementUnits", path)?,
        }),
    })
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
