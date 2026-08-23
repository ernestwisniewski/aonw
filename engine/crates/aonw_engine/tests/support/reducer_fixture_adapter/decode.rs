use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    CityBuildingTypeDto, CityDto, CityProductionQueueDto, CitySpecializationTypeDto, CoordinateDto,
    EconomyStateDto, FieldImprovementDto, FieldImprovementKindDto, GameModeDto, GameStateDto,
    InitialResourceDistributionDto, InteractionStateDto, MatchIdentityDto, MatchRulesDto,
    MovementStepDto, ParticipantDto, PendingInteractionDto, PlayerFogDto, PlayerPairDto,
    QueuedMovePathDto, ResearchStateDto, StrategicResourceStockpileDto, TransportConditionDto,
    TransportSegmentDto, TransportSegmentKindDto, TurnLifecycleDto, UnitActivityDto, UnitDto,
    UnitKindDto, UnitOccupancyPolicyDto, UnitPostureDto, WonderRegistryDto, WonderTypeDto,
    WorldArtifactDto, WorldArtifactLocationDto, WorldArtifactTypeDto,
};
use aonw_domain::{HexCoord, HexGridBounds, MovementUnits, UnitId};
use aonw_testkit::{FixtureInput, JsonObject};
use serde_json::{Map, Value};

use super::AdapterError;
use super::json::{
    coordinate_dto, coordinate_fields, decode_coordinates, display_error, error, object_at,
    optional_string, required_array, required_i32_at, required_i64_at, required_string,
    required_string_at, required_u32, required_u32_at, value_to_u32,
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
    let field_improvements = decode_field_improvements(input.state(), bounds)?;
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
        economy: decode_economy(input.state())?,
        research: decode_research(input.state())?,
        wonder_registry: decode_wonder_registry(input.state())?,
        cols: bounds.cols(),
        rows: bounds.rows(),
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units,
        cities,
        artifacts,
        field_improvements,
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

fn decode_research(state: &JsonObject) -> Result<ResearchStateDto, AdapterError> {
    let path = "input.state.research";
    let research = object_at(
        state
            .get("research")
            .ok_or_else(|| error(format!("{path} is required")))?,
        path,
    )?;
    let players_path = format!("{path}.players");
    let players = object_at(
        research
            .get("players")
            .ok_or_else(|| error(format!("{players_path} is required")))?,
        &players_path,
    )?;
    let mut normalized_players = Map::new();
    for (player, value) in players {
        let player_path = format!("{players_path}.{player}");
        let source = object_at(value, &player_path)?;
        normalized_players.insert(
            player.clone(),
            Value::Object(Map::from_iter([
                (
                    "unlockedTechnologyIds".to_owned(),
                    json_field(source, "unlockedTechnologyIds", &player_path)?,
                ),
                (
                    "activeTechnologyId".to_owned(),
                    source
                        .get("activeTechnologyId")
                        .cloned()
                        .unwrap_or(Value::Null),
                ),
                (
                    "progressByTechnologyId".to_owned(),
                    json_field(source, "progressByTechnologyId", &player_path)?,
                ),
                (
                    "scienceOverflow".to_owned(),
                    source
                        .get("scienceOverflow")
                        .cloned()
                        .unwrap_or(Value::from(0)),
                ),
            ])),
        );
    }
    serde_json::from_value(Value::Object(Map::from_iter([(
        "players".to_owned(),
        Value::Object(normalized_players),
    )])))
    .map_err(display_error)
}

fn decode_wonder_registry(state: &JsonObject) -> Result<WonderRegistryDto, AdapterError> {
    state
        .get("wonderRegistry")
        .cloned()
        .map(serde_json::from_value)
        .transpose()
        .map(Option::unwrap_or_default)
        .map_err(display_error)
}

fn decode_field_improvements(
    state: &JsonObject,
    bounds: HexGridBounds,
) -> Result<Vec<FieldImprovementDto>, AdapterError> {
    required_array(state, "fieldImprovements")?
        .iter()
        .enumerate()
        .filter_map(|(index, value)| {
            let path = format!("input.state.fieldImprovements[{index}]");
            let decoded = (|| {
                let object = object_at(value, &path)?;
                let hex_path = format!("{path}.hex");
                let coordinate = object
                    .get("hex")
                    .ok_or_else(|| error(format!("{hex_path} is required")))
                    .and_then(|value| object_at(value, &hex_path))
                    .and_then(|value| coordinate_fields(value, &hex_path))?;
                if !bounds.contains(coordinate) {
                    return Ok(None);
                }
                let kind = serde_json::from_value::<FieldImprovementKindDto>(Value::String(
                    required_string_at(object, "type", &path)?.to_owned(),
                ))
                .map_err(display_error)?;
                Ok(Some(FieldImprovementDto {
                    coordinate: coordinate_dto(coordinate),
                    kind,
                    built_by_city_id: optional_string(object, "builtByCityId")?,
                }))
            })();
            decoded.transpose()
        })
        .collect()
}

fn decode_economy(state: &JsonObject) -> Result<EconomyStateDto, AdapterError> {
    let initial_resource_distribution = match state.get("initialResourceDistribution") {
        None | Some(Value::Null) => InitialResourceDistributionDto::default(),
        Some(value) => {
            let source = object_at(value, "input.state.initialResourceDistribution")?;
            let selected = Value::Object(Map::from_iter([
                (
                    "seed".to_owned(),
                    json_field(source, "seed", "input.state.initialResourceDistribution")?,
                ),
                (
                    "placements".to_owned(),
                    json_field(
                        source,
                        "placements",
                        "input.state.initialResourceDistribution",
                    )?,
                ),
            ]));
            serde_json::from_value(selected).map_err(display_error)?
        }
    };
    Ok(EconomyStateDto {
        player_gold: serde_json::from_value(json_field(state, "playerGold", "input.state")?)
            .map_err(display_error)?,
        player_war_weariness: serde_json::from_value(json_field(
            state,
            "playerWarWeariness",
            "input.state",
        )?)
        .map_err(display_error)?,
        player_stability_net: serde_json::from_value(json_field(
            state,
            "playerStabilityNet",
            "input.state",
        )?)
        .map_err(display_error)?,
        strategic_resources: state
            .get("strategicResources")
            .cloned()
            .map(
                serde_json::from_value::<
                    std::collections::BTreeMap<String, StrategicResourceStockpileDto>,
                >,
            )
            .transpose()
            .map_err(display_error)?
            .unwrap_or_default(),
        initial_resource_distribution,
    })
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
        .filter_map(|(index, value)| decode_city(value, index, bounds).transpose())
        .collect()
}

fn decode_city(
    value: &Value,
    index: usize,
    bounds: HexGridBounds,
) -> Result<Option<CityDto>, AdapterError> {
    let path = format!("input.state.cities[{index}]");
    let object = object_at(value, &path)?;
    let center_path = format!("{path}.center");
    let center = object
        .get("center")
        .ok_or_else(|| error(format!("{center_path} is required")))
        .and_then(|value| object_at(value, &center_path))
        .and_then(|center| coordinate_fields(center, &center_path))?;
    let controlled = required_array(object, "controlledHexes")
        .and_then(|values| decode_city_coordinates(values, &format!("{path}.controlledHexes")))?;
    let worked = required_array(object, "workedHexes")
        .and_then(|values| decode_city_coordinates(values, &format!("{path}.workedHexes")))?;
    if !city_coordinates_fit(bounds, center, &controlled, &worked) {
        return Ok(None);
    }
    let preferred_expansion_hex = object
        .get("preferredExpansionHex")
        .map(|value| {
            let preferred_path = format!("{path}.preferredExpansionHex");
            object_at(value, &preferred_path)
                .and_then(|value| coordinate_fields(value, &preferred_path))
                .map(coordinate_dto)
        })
        .transpose()?;
    if preferred_expansion_hex
        .is_some_and(|coordinate| !bounds.contains(HexCoord::new(coordinate.col, coordinate.row)))
    {
        return Ok(None);
    }
    let hit_points = match object.get("hitPoints") {
        None | Some(Value::Null) => None,
        Some(value) => Some(
            value
                .as_i64()
                .ok_or_else(|| error(format!("{path}.hitPoints must be an integer")))?,
        ),
    };
    Ok(Some(CityDto {
        id: required_string_at(object, "id", &path)?.to_owned(),
        owner_player_id: required_string_at(object, "ownerPlayerId", &path)?.to_owned(),
        founding_owner_player_id: optional_string(object, "foundingOwnerPlayerId")?,
        name: required_string_at(object, "name", &path)?.to_owned(),
        population: required_i64_at(object, "population", &path)?,
        stored_food: required_i64_at(object, "storedFood", &path)?,
        max_hexes: required_i64_at(object, "maxHexes", &path)?,
        territory_radius: required_i64_at(object, "territoryRadius", &path)?,
        center: coordinate_dto(center),
        controlled_hexes: controlled.into_iter().map(coordinate_dto).collect(),
        worked_hexes: worked.into_iter().map(coordinate_dto).collect(),
        buildings: decode_city_buildings(object, &path)?,
        wonders: decode_city_wonders(object)?,
        production_queue: object
            .get("productionQueue")
            .map(|value| decode_city_production_queue(value, &path))
            .transpose()?,
        production_overflow: required_i64_at(object, "productionOverflow", &path)?,
        specialization: object
            .get("specialization")
            .cloned()
            .map(serde_json::from_value::<CitySpecializationTypeDto>)
            .transpose()
            .map_err(display_error)?,
        preferred_expansion_hex,
        hit_points,
    }))
}

fn city_coordinates_fit(
    bounds: HexGridBounds,
    center: HexCoord,
    controlled: &[HexCoord],
    worked: &[HexCoord],
) -> bool {
    bounds.contains(center)
        && controlled
            .iter()
            .all(|coordinate| bounds.contains(*coordinate))
        && worked.iter().all(|coordinate| bounds.contains(*coordinate))
}

fn decode_city_coordinates(values: &[Value], path: &str) -> Result<Vec<HexCoord>, AdapterError> {
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("{path}[{index}]");
            object_at(value, &path).and_then(|value| coordinate_fields(value, &path))
        })
        .collect()
}

fn decode_city_production_queue(
    value: &Value,
    city_path: &str,
) -> Result<CityProductionQueueDto, AdapterError> {
    let path = format!("{city_path}.productionQueue");
    let object = object_at(value, &path)?;
    serde_json::from_value(Value::Object(Map::from_iter([
        ("target".to_owned(), json_field(object, "target", &path)?),
        (
            "investedProduction".to_owned(),
            json_field(object, "investedProduction", &path)?,
        ),
        (
            "resourceAllocation".to_owned(),
            object
                .get("resourceAllocation")
                .cloned()
                .unwrap_or_else(|| Value::Object(Map::new())),
        ),
    ])))
    .map_err(display_error)
}

fn decode_city_buildings(
    object: &JsonObject,
    path: &str,
) -> Result<Vec<CityBuildingTypeDto>, AdapterError> {
    match object.get("buildings") {
        Some(value) => serde_json::from_value(value.clone()).map_err(display_error),
        None => Err(error(format!("{path}.buildings is required"))),
    }
}

fn decode_city_wonders(object: &JsonObject) -> Result<Vec<WonderTypeDto>, AdapterError> {
    match object.get("wonders") {
        Some(value) => serde_json::from_value(value.clone()).map_err(display_error),
        None => Ok(Vec::new()),
    }
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
        kind: TransportSegmentKindDto::Road,
        condition,
        built_by_player_id: required_string_at(object, "builtByPlayerId", path)?.to_owned(),
        built_by_city_id: optional_string(object, "builtByCityId")?,
    })
}

#[cfg(test)]
mod tests {
    use aonw_contracts::{
        FieldImprovementKindDto, ResourceTypeDto, TechnologyIdDto, WonderTypeDto,
    };
    use aonw_domain::HexGridBounds;
    use serde_json::json;

    use super::{
        decode_economy, decode_field_improvements, decode_research, decode_wonder_registry,
    };

    #[test]
    fn legacy_knowledge_adapter_preserves_research_and_wonder_ownership() {
        let source = json!({
            "research": {
                "players": {
                    "player-1": {
                        "unlockedTechnologyIds": ["logistics"],
                        "activeTechnologyId": "agriculture",
                        "progressByTechnologyId": {"agriculture": 4},
                        "scienceOverflow": 3
                    }
                }
            },
            "wonderRegistry": {"centralBank": "player-2"}
        });
        let state = source.as_object().expect("state object");
        let research = decode_research(state).expect("decode research");
        let wonders = decode_wonder_registry(state).expect("decode wonder registry");
        let player = &research.players["player-1"];

        assert_eq!(player.unlocked_technology_ids, [TechnologyIdDto::Logistics]);
        assert_eq!(
            player.active_technology_id,
            Some(TechnologyIdDto::Agriculture)
        );
        assert_eq!(
            player.progress_by_technology_id[&TechnologyIdDto::Agriculture],
            4
        );
        assert_eq!(player.science_overflow, 3);
        assert_eq!(wonders.0[&WonderTypeDto::CentralBank], "player-2");
    }

    #[test]
    fn legacy_economy_adapter_uses_placements_without_internal_generator_version() {
        let source = json!({
            "playerGold": {"player_1": 17},
            "playerWarWeariness": {"player_1": -2},
            "playerStabilityNet": {"player_1": 4},
            "strategicResources": {"player_1": {"oil": 3}},
            "initialResourceDistribution": {
                "seed": -41,
                "algorithmVersion": 999,
                "placements": [{"col": 2, "row": 1, "resource": "wheat"}]
            }
        });
        let economy = decode_economy(source.as_object().expect("state object"))
            .expect("decode legacy economy");

        assert_eq!(economy.player_gold["player_1"], 17);
        assert_eq!(
            economy.strategic_resources["player_1"].0[&ResourceTypeDto::Oil],
            3
        );
        assert_eq!(economy.initial_resource_distribution.seed, -41);
        assert_eq!(
            economy.initial_resource_distribution.placements[0].resource,
            ResourceTypeDto::Wheat
        );
    }

    #[test]
    fn legacy_infrastructure_adapter_reads_complete_in_bounds_improvements() {
        let source = json!({
            "fieldImprovements": [
                {
                    "hex": {"col": 1, "row": 2},
                    "type": "oilWell",
                    "builtByCityId": "city-1"
                },
                {
                    "hex": {"col": 99, "row": 99},
                    "type": "farm"
                }
            ]
        });
        let improvements = decode_field_improvements(
            source.as_object().expect("state object"),
            HexGridBounds::new(3, 3).expect("bounds"),
        )
        .expect("decode improvements");

        assert_eq!(improvements.len(), 1);
        assert_eq!(improvements[0].kind, FieldImprovementKindDto::OilWell);
        assert_eq!(improvements[0].built_by_city_id.as_deref(), Some("city-1"));
    }
}
