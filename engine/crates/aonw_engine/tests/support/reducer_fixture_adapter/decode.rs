use std::collections::BTreeMap;

use aonw_content::{GridLayout, MapDefinition, TerrainType, TileDefinition};
use aonw_contract_mapping::decode_game_state;
use aonw_contracts::{
    ArmyTroopDto, CityBuildingTypeDto, CityConquestActionDto, CityDto, CityFoundingDraftDto,
    CityFoundingJobDto, CityProductionQueueDto, CitySpecializationTypeDto, CoordinateDto,
    DiplomacyStateDto, EconomyStateDto, FieldImprovementDto, FieldImprovementKindDto, GameModeDto,
    GameStateDto, InitialResourceDistributionDto, IntendedAttackDto, InteractionStateDto,
    MapObjectiveHoldStateDto, MatchIdentityDto, MatchRulesDto, MerchantTradeRouteDto,
    MovementStepDto, ParticipantDto, PendingInteractionDto, PlayerFogDto, PlayerPairDto,
    QueuedMovePathDto, ResearchStateDto, ResourceTradeAgreementDto, StrategicResourceStockpileDto,
    TransportConditionDto, TransportSegmentDto, TransportSegmentKindDto, TroopKindDto,
    TurnLifecycleDto, UnitActivityDto, UnitDto, UnitKindDto, UnitOccupancyPolicyDto,
    UnitPostureDto, WonderRegistryDto, WonderTypeDto, WorkerJobDto, WorldArtifactDto,
    WorldArtifactLocationDto, WorldArtifactTypeDto,
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
) -> Result<DecodedState, AdapterError> {
    let (units, command_unit_out_of_bounds) = decode_units(input.state(), bounds, command_unit_id)?;
    if command_unit_out_of_bounds {
        return Ok(DecodedState::CommandUnitOutOfBounds);
    }
    let cities = decode_cities(input.state(), bounds)?;
    let artifacts = decode_referenced_artifacts(input.state(), &units, bounds)?;
    let field_improvements = decode_field_improvements(input.state(), bounds)?;
    let interaction = decode_interaction(input.state(), bounds, &units, &cities)?;
    let fog_of_war = required_array(input.state(), "fogOfWar")?
        .iter()
        .enumerate()
        .map(|(index, value)| decode_fog(value, &format!("input.state.fogOfWar[{index}]")))
        .collect::<Result<Vec<_>, _>>()?;
    let diplomacy = decode_diplomacy_state(input.state())?;
    let resource_trade_agreements = decode_resource_trade_agreements(input.state())?;
    let domination_hold_turns_by_player_id =
        decode_hold_turns(input.state(), "dominationHoldTurnsByPlayerId")?;
    let cultural_victory_hold_turns_by_player_id =
        decode_hold_turns(input.state(), "culturalVictoryHoldTurnsByPlayerId")?;
    let map_objective_hold_states = decode_map_objective_holds(input.state())?;
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
        intended_attacks: decode_intended_attacks(input.state(), bounds)?,
        cols: bounds.cols(),
        rows: bounds.rows(),
        occupancy_policy: UnitOccupancyPolicyDto::FriendlyStacking,
        units,
        cities,
        artifacts,
        field_improvements,
        interaction,
        fog_of_war,
        diplomacy,
        resource_trade_agreements,
        domination_hold_turns_by_player_id,
        cultural_victory_hold_turns_by_player_id,
        map_objective_hold_states,
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

fn decode_intended_attacks(
    state: &JsonObject,
    bounds: HexGridBounds,
) -> Result<Vec<IntendedAttackDto>, AdapterError> {
    let Some(values) = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("intendedAttacks"))
        .and_then(Value::as_array)
    else {
        return Ok(Vec::new());
    };
    values
        .iter()
        .enumerate()
        .filter_map(|(index, value)| {
            let path = format!("input.state.lifecycle.intendedAttacks[{index}]");
            let decoded = (|| {
                let object = object_at(value, &path)?;
                let defender = HexCoord::new(
                    required_i32_at(object, "defenderCol", &path)?,
                    required_i32_at(object, "defenderRow", &path)?,
                );
                if !bounds.contains(defender) {
                    return Ok(None);
                }
                let city_conquest_action = match object
                    .get("cityConquestAction")
                    .and_then(Value::as_str)
                    .unwrap_or("capture")
                {
                    "capture" => CityConquestActionDto::Capture,
                    "destroy" => CityConquestActionDto::Destroy,
                    value => return Err(error(format!("unknown city conquest action: {value}"))),
                };
                Ok(Some(IntendedAttackDto {
                    attacker_unit_id: required_string_at(object, "attackerUnitId", &path)?
                        .to_owned(),
                    defender_col: defender.col(),
                    defender_row: defender.row(),
                    declared_at_tick: u64::try_from(required_i64_at(
                        object,
                        "declaredAtTick",
                        &path,
                    )?)
                    .map_err(display_error)?,
                    declaring_player_id: required_string_at(object, "declaringPlayerId", &path)?
                        .to_owned(),
                    city_conquest_action,
                }))
            })();
            decoded.transpose()
        })
        .collect()
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
            Some(decode_unit(object, &path))
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
    bounds: HexGridBounds,
) -> Result<Vec<WorldArtifactDto>, AdapterError> {
    let artifacts = required_array(state, "artifacts")?
        .iter()
        .enumerate()
        .filter_map(|(index, value)| decode_artifact(value, index, bounds).transpose())
        .collect::<Result<Vec<_>, _>>()?;
    for unit in units {
        for (field, artifact_id) in [
            ("carriedArtifactId", unit.carried_artifact_id.as_ref()),
            (
                "excavatingArtifactId",
                unit.activity.excavating_artifact_id.as_ref(),
            ),
        ] {
            if let Some(artifact_id) = artifact_id
                && !artifacts.iter().any(|artifact| artifact.id == *artifact_id)
            {
                return Err(error(format!(
                    "input.state.units[id={}].{field} references missing artifact {artifact_id}",
                    unit.id
                )));
            }
        }
    }
    Ok(artifacts)
}

fn decode_artifact(
    value: &Value,
    index: usize,
    bounds: HexGridBounds,
) -> Result<Option<WorldArtifactDto>, AdapterError> {
    let path = format!("input.state.artifacts[{index}]");
    let object = object_at(value, &path)?;
    let location_path = format!("{path}.location");
    let location = object
        .get("location")
        .ok_or_else(|| error(format!("{location_path} is required")))
        .and_then(|value| object_at(value, &location_path))
        .and_then(|location| decode_artifact_location(location, &location_path))?;
    if artifact_coordinate(&location)
        .is_some_and(|coordinate| !bounds.contains(HexCoord::new(coordinate.col, coordinate.row)))
    {
        return Ok(None);
    }
    Ok(Some(WorldArtifactDto {
        id: required_string_at(object, "id", &path)?.to_owned(),
        artifact_type: parse_artifact_type(required_string_at(object, "type", &path)?)?,
        location,
    }))
}

fn decode_artifact_location(
    object: &JsonObject,
    path: &str,
) -> Result<WorldArtifactLocationDto, AdapterError> {
    match required_string_at(object, "kind", path)? {
        "map" => Ok(WorldArtifactLocationDto::Map {
            coordinate: coordinate_dto(coordinate_fields(object, path)?),
        }),
        "carried" => Ok(WorldArtifactLocationDto::Carried {
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
        }),
        "stored" => Ok(WorldArtifactLocationDto::Stored {
            city_id: required_string_at(object, "cityId", path)?.to_owned(),
        }),
        "excavation" => Ok(WorldArtifactLocationDto::Excavation {
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
            coordinate: coordinate_dto(coordinate_fields(object, path)?),
            remaining_turns: required_u32_at(object, "remainingTurns", path)?,
        }),
        value => Err(error(format!("unknown artifact location kind: {value}"))),
    }
}

fn artifact_coordinate(location: &WorldArtifactLocationDto) -> Option<CoordinateDto> {
    match location {
        WorldArtifactLocationDto::Map { coordinate }
        | WorldArtifactLocationDto::Excavation { coordinate, .. } => Some(*coordinate),
        WorldArtifactLocationDto::Carried { .. } | WorldArtifactLocationDto::Stored { .. } => None,
    }
}

fn parse_artifact_type(value: &str) -> Result<WorldArtifactTypeDto, AdapterError> {
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

fn decode_unit(object: &JsonObject, path: &str) -> Result<UnitDto, AdapterError> {
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
    let kind = parse_unit_kind(required_string_at(object, "type", path)?)?;
    let worker_build_charges = object
        .get("workerBuildCharges")
        .map(|value| value_to_u32(value, &format!("{path}.workerBuildCharges")))
        .transpose()?
        .unwrap_or(u32::from(kind == UnitKindDto::Worker));
    let hit_points = object
        .get("hitPoints")
        .filter(|value| !value.is_null())
        .map(|value| value_to_u32(value, &format!("{path}.hitPoints")))
        .transpose()?;
    Ok(UnitDto {
        id: required_string_at(object, "id", path)?.to_owned(),
        owner_player_id: required_string_at(object, "ownerPlayerId", path)?.to_owned(),
        kind,
        name: required_string_at(object, "name", path)?.to_owned(),
        col: required_i32_at(object, "col", path)?,
        row: required_i32_at(object, "row", path)?,
        movement_units,
        army: decode_army(object, path)?,
        queued_path: object
            .get("queuedPath")
            .filter(|value| !value.is_null())
            .map(|value| decode_queued_path(value, path))
            .transpose()?,
        merchant_trade_route: object
            .get("merchantTradeRoute")
            .filter(|value| !value.is_null())
            .map(|value| decode_merchant_trade_route(value, path))
            .transpose()?,
        activity: UnitActivityDto {
            worker_job: object
                .get("workerJob")
                .filter(|value| !value.is_null())
                .map(|value| decode_worker_job(value, path))
                .transpose()?,
            city_founding_job: object
                .get("cityFoundingJob")
                .filter(|value| !value.is_null())
                .map(|value| decode_city_founding_job(value, path))
                .transpose()?,
            worker_assignment: object
                .get("workerAssignment")
                .filter(|value| !value.is_null())
                .map(|value| decode_worker_assignment(value, path))
                .transpose()?,
            excavating_artifact_id: optional_string(object, "excavatingArtifactId")?,
        },
        worker_build_charges,
        hit_points,
        experience_points: object
            .get("experiencePoints")
            .map(|value| value_to_u32(value, &format!("{path}.experiencePoints")))
            .transpose()?
            .unwrap_or(0),
        posture,
        carried_artifact_id: optional_string(object, "carriedArtifactId")?,
    })
}

fn decode_army(object: &JsonObject, path: &str) -> Result<Vec<ArmyTroopDto>, AdapterError> {
    required_array(object, "army")?
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let troop_path = format!("{path}.army[{index}]");
            let troop = object_at(value, &troop_path)?;
            let kind = match required_string_at(troop, "type", &troop_path)? {
                "warrior" => TroopKindDto::Warrior,
                "archer" => TroopKindDto::Archer,
                "settler" => TroopKindDto::Settler,
                value => return Err(error(format!("unknown army troop type: {value}"))),
            };
            Ok(ArmyTroopDto {
                kind,
                count: required_u32_at(troop, "count", &troop_path)?,
            })
        })
        .collect()
}

fn decode_merchant_trade_route(
    value: &Value,
    unit_path: &str,
) -> Result<MerchantTradeRouteDto, AdapterError> {
    let path = format!("{unit_path}.merchantTradeRoute");
    let object = object_at(value, &path)?;
    let transport_network_fingerprint = match object.get("transportNetworkFingerprint") {
        None => String::new(),
        Some(Value::String(value)) => value.clone(),
        Some(_) => {
            return Err(error(format!(
                "{path}.transportNetworkFingerprint must be a string"
            )));
        }
    };
    Ok(MerchantTradeRouteDto {
        origin_city_id: required_string_at(object, "originCityId", &path)?.to_owned(),
        destination_city_id: required_string_at(object, "destinationCityId", &path)?.to_owned(),
        steps: decode_movement_steps(required_array(object, "steps")?, &format!("{path}.steps"))?,
        transport_network_fingerprint,
    })
}

fn decode_worker_job(value: &Value, unit_path: &str) -> Result<WorkerJobDto, AdapterError> {
    let path = format!("{unit_path}.workerJob");
    let object = object_at(value, &path)?;
    let target = coordinate_field_alias(object, "target", "targetHex", &path)?;
    let remaining_turns = required_u32_at(object, "remainingTurns", &path)?;
    let total_turns = required_u32_at(object, "totalTurns", &path)?;
    match required_string_at(object, "kind", &path)? {
        "fieldImprovement" => {
            let improvement = object
                .get("improvement")
                .or_else(|| object.get("improvementType"))
                .and_then(Value::as_str)
                .ok_or_else(|| {
                    error(format!(
                        "{path}.improvement or {path}.improvementType must be a string"
                    ))
                })?;
            Ok(WorkerJobDto::FieldImprovement {
                target,
                improvement: parse_improvement_kind(improvement, &path)?,
                remaining_turns,
                total_turns,
            })
        }
        "roadConstruction" => Ok(WorkerJobDto::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        }),
        value => Err(error(format!("unknown worker job kind: {value}"))),
    }
}

fn decode_city_founding_job(
    value: &Value,
    unit_path: &str,
) -> Result<CityFoundingJobDto, AdapterError> {
    let path = format!("{unit_path}.cityFoundingJob");
    let object = object_at(value, &path)?;
    Ok(CityFoundingJobDto {
        center: coordinate_field(object, "center", &path)?,
        controlled_hexes: decode_coordinates(
            required_array(object, "controlledHexes")?,
            &format!("{path}.controlledHexes"),
        )?,
        remaining_turns: required_u32_at(object, "remainingTurns", &path)?,
        total_turns: required_u32_at(object, "totalTurns", &path)?,
    })
}

fn decode_worker_assignment(value: &Value, unit_path: &str) -> Result<CoordinateDto, AdapterError> {
    let path = format!("{unit_path}.workerAssignment");
    let object = object_at(value, &path)?;
    if object.contains_key("col") || object.contains_key("row") {
        return coordinate_fields(object, &path).map(coordinate_dto);
    }
    coordinate_field_alias(object, "target", "targetHex", &path)
}

fn coordinate_field(
    object: &JsonObject,
    field: &str,
    path: &str,
) -> Result<CoordinateDto, AdapterError> {
    let coordinate_path = format!("{path}.{field}");
    object
        .get(field)
        .ok_or_else(|| error(format!("{coordinate_path} is required")))
        .and_then(|value| object_at(value, &coordinate_path))
        .and_then(|coordinate| coordinate_fields(coordinate, &coordinate_path))
        .map(coordinate_dto)
}

fn coordinate_field_alias(
    object: &JsonObject,
    field: &str,
    legacy_field: &str,
    path: &str,
) -> Result<CoordinateDto, AdapterError> {
    if object.contains_key(field) {
        coordinate_field(object, field, path)
    } else {
        coordinate_field(object, legacy_field, path)
    }
}

fn parse_improvement_kind(
    value: &str,
    path: &str,
) -> Result<FieldImprovementKindDto, AdapterError> {
    serde_json::from_value(Value::String(value.to_owned()))
        .map_err(|source| error(format!("{path}: {source}")))
}

fn decode_interaction(
    state: &JsonObject,
    bounds: HexGridBounds,
    units: &[UnitDto],
    cities: &[CityDto],
) -> Result<InteractionStateDto, AdapterError> {
    let Some(lifecycle) = state.get("lifecycle").and_then(Value::as_object) else {
        return Ok(InteractionStateDto::default());
    };
    let city_founding_draft = lifecycle
        .get("cityFoundingDraft")
        .filter(|value| !value.is_null())
        .map(decode_city_founding_draft)
        .transpose()?
        .filter(|draft| city_founding_draft_in_scope(draft, bounds, units, state));
    let pending = lifecycle
        .get("pendingAction")
        .filter(|value| !value.is_null())
        .map(decode_pending_interaction)
        .transpose()?
        .filter(|pending| pending_interaction_in_scope(pending, bounds, units, cities, state));
    Ok(InteractionStateDto {
        city_founding_draft,
        pending,
    })
}

fn decode_city_founding_draft(value: &Value) -> Result<CityFoundingDraftDto, AdapterError> {
    let path = "input.state.lifecycle.cityFoundingDraft";
    let object = object_at(value, path)?;
    Ok(CityFoundingDraftDto {
        unit_id: required_string_at(object, "unitId", path)?.to_owned(),
        owner_player_id: required_string_at(object, "ownerPlayerId", path)?.to_owned(),
        center: coordinate_field(object, "center", path)?,
        controlled_hexes: decode_coordinates(
            required_array(object, "controlledHexes")?,
            &format!("{path}.controlledHexes"),
        )?,
    })
}

fn decode_pending_interaction(value: &Value) -> Result<PendingInteractionDto, AdapterError> {
    let path = "input.state.lifecycle.pendingAction";
    let object = object_at(value, path)?;
    let owner_player_id = required_string_at(object, "ownerPlayerId", path)?.to_owned();
    match required_string_at(object, "type", path)? {
        "researchSelection" => Ok(PendingInteractionDto::ResearchSelection { owner_player_id }),
        "cityWorkedHexSelection" => Ok(PendingInteractionDto::CityWorkedHexSelection {
            owner_player_id,
            city_id: required_string_at(object, "cityId", path)?.to_owned(),
        }),
        "cityExpansionSelection" => Ok(PendingInteractionDto::CityExpansionSelection {
            owner_player_id,
            city_id: required_string_at(object, "cityId", path)?.to_owned(),
        }),
        "workerActionSelection" => Ok(PendingInteractionDto::WorkerActionSelection {
            owner_player_id,
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
            improvement: optional_improvement_kind(object, path)?,
        }),
        "merchantTradeRouteSelection" => Ok(PendingInteractionDto::MerchantTradeRouteSelection {
            owner_player_id,
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
        }),
        "merchantMoveToCitySelection" => Ok(PendingInteractionDto::MerchantMoveToCitySelection {
            owner_player_id,
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
        }),
        "unitTurnSkip" => Ok(PendingInteractionDto::UnitTurnSkip {
            owner_player_id,
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
            restore_movement_units: required_u32_at(object, "restoreMovementUnits", path)?,
        }),
        "attackTargeting" => Ok(PendingInteractionDto::AttackTargeting {
            owner_player_id,
            unit_id: required_string_alias(object, "unitId", "attackerUnitId", path)?.to_owned(),
            defender: optional_defender(object, path)?,
        }),
        "commanderMergeSelection" => Ok(PendingInteractionDto::CommanderMergeSelection {
            owner_player_id,
            unit_id: required_string_at(object, "unitId", path)?.to_owned(),
        }),
        value => Err(error(format!("unknown pending interaction type: {value}"))),
    }
}

fn optional_improvement_kind(
    object: &JsonObject,
    path: &str,
) -> Result<Option<FieldImprovementKindDto>, AdapterError> {
    match object
        .get("improvement")
        .or_else(|| object.get("improvementType"))
    {
        None | Some(Value::Null) => Ok(None),
        Some(Value::String(value)) => parse_improvement_kind(value, path).map(Some),
        Some(_) => Err(error(format!(
            "{path}.improvement or {path}.improvementType must be a string or null"
        ))),
    }
}

fn optional_defender(
    object: &JsonObject,
    path: &str,
) -> Result<Option<CoordinateDto>, AdapterError> {
    if let Some(value) = object.get("defender") {
        if value.is_null() {
            return Ok(None);
        }
        let defender_path = format!("{path}.defender");
        return object_at(value, &defender_path)
            .and_then(|defender| coordinate_fields(defender, &defender_path))
            .map(coordinate_dto)
            .map(Some);
    }
    match (object.get("defenderCol"), object.get("defenderRow")) {
        (None, None) => Ok(None),
        (Some(_), Some(_)) => Ok(Some(CoordinateDto {
            col: required_i32_at(object, "defenderCol", path)?,
            row: required_i32_at(object, "defenderRow", path)?,
        })),
        _ => Err(error(format!(
            "{path}.defenderCol and {path}.defenderRow must be provided together"
        ))),
    }
}

fn required_string_alias<'value>(
    object: &'value JsonObject,
    field: &str,
    legacy_field: &str,
    path: &str,
) -> Result<&'value str, AdapterError> {
    object
        .get(field)
        .or_else(|| object.get(legacy_field))
        .and_then(Value::as_str)
        .ok_or_else(|| {
            error(format!(
                "{path}.{field} or {path}.{legacy_field} must be a string"
            ))
        })
}

fn city_founding_draft_in_scope(
    draft: &CityFoundingDraftDto,
    bounds: HexGridBounds,
    units: &[UnitDto],
    state: &JsonObject,
) -> bool {
    unit_reference_in_scope(state, bounds, units, &draft.unit_id)
        && core::iter::once(draft.center)
            .chain(draft.controlled_hexes.iter().copied())
            .all(|coordinate| bounds.contains(HexCoord::new(coordinate.col, coordinate.row)))
}

fn pending_interaction_in_scope(
    pending: &PendingInteractionDto,
    bounds: HexGridBounds,
    units: &[UnitDto],
    cities: &[CityDto],
    state: &JsonObject,
) -> bool {
    let unit_in_scope = |unit_id: &str| unit_reference_in_scope(state, bounds, units, unit_id);
    let city_in_scope = |city_id: &str| city_reference_in_scope(state, bounds, cities, city_id);
    match pending {
        PendingInteractionDto::ResearchSelection { .. } => true,
        PendingInteractionDto::CityWorkedHexSelection { city_id, .. }
        | PendingInteractionDto::CityExpansionSelection { city_id, .. } => city_in_scope(city_id),
        PendingInteractionDto::WorkerActionSelection { unit_id, .. }
        | PendingInteractionDto::MerchantTradeRouteSelection { unit_id, .. }
        | PendingInteractionDto::MerchantMoveToCitySelection { unit_id, .. }
        | PendingInteractionDto::UnitTurnSkip { unit_id, .. }
        | PendingInteractionDto::CommanderMergeSelection { unit_id, .. } => unit_in_scope(unit_id),
        PendingInteractionDto::AttackTargeting {
            unit_id, defender, ..
        } => {
            unit_in_scope(unit_id)
                && defender.is_none_or(|coordinate| {
                    bounds.contains(HexCoord::new(coordinate.col, coordinate.row))
                })
        }
    }
}

fn unit_reference_in_scope(
    state: &JsonObject,
    bounds: HexGridBounds,
    units: &[UnitDto],
    unit_id: &str,
) -> bool {
    units.iter().any(|unit| unit.id == unit_id)
        || state
            .get("units")
            .and_then(Value::as_array)
            .and_then(|values| {
                values
                    .iter()
                    .find(|value| value.get("id").and_then(Value::as_str) == Some(unit_id))
            })
            .and_then(Value::as_object)
            .and_then(|unit| coordinate_fields(unit, "input.state.units[]").ok())
            .is_none_or(|coordinate| bounds.contains(coordinate))
}

fn city_reference_in_scope(
    state: &JsonObject,
    bounds: HexGridBounds,
    cities: &[CityDto],
    city_id: &str,
) -> bool {
    cities.iter().any(|city| city.id == city_id)
        || state
            .get("cities")
            .and_then(Value::as_array)
            .and_then(|values| {
                values
                    .iter()
                    .find(|value| value.get("id").and_then(Value::as_str) == Some(city_id))
            })
            .and_then(Value::as_object)
            .and_then(|city| city.get("center"))
            .and_then(Value::as_object)
            .and_then(|center| coordinate_fields(center, "input.state.cities[].center").ok())
            .is_none_or(|coordinate| bounds.contains(coordinate))
}

fn decode_queued_path(value: &Value, unit_path: &str) -> Result<QueuedMovePathDto, AdapterError> {
    let path = format!("{unit_path}.queuedPath");
    let object = object_at(value, &path)?;
    let steps = decode_movement_steps(required_array(object, "steps")?, &format!("{path}.steps"))?;
    Ok(QueuedMovePathDto {
        target_col: required_i32_at(object, "targetCol", &path)?,
        target_row: required_i32_at(object, "targetRow", &path)?,
        steps,
    })
}

fn decode_movement_steps(
    values: &[Value],
    path: &str,
) -> Result<Vec<MovementStepDto>, AdapterError> {
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let step_path = format!("{path}[{index}]");
            let step = object_at(value, &step_path)?;
            Ok(MovementStepDto {
                col: required_i32_at(step, "col", &step_path)?,
                row: required_i32_at(step, "row", &step_path)?,
                enter_cost_units: required_u32_at(step, "enterCost", &step_path)?,
                cumulative_cost_units: required_u32_at(step, "cumulativeCost", &step_path)?,
            })
        })
        .collect()
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

fn decode_diplomacy_state(state: &JsonObject) -> Result<DiplomacyStateDto, AdapterError> {
    let source = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("diplomacy"))
        .and_then(Value::as_object);
    let contacts = serde_json::to_value(decode_contacts(state)?).map_err(display_error)?;
    let relations = normalize_records(
        source.and_then(|value| value.get("relations")),
        "input.state.lifecycle.diplomacy.relations",
        &[
            ("relationScore", Value::from(0)),
            ("statusExpiresOnTurn", Value::Null),
            ("lastChangedTurn", Value::Null),
            ("lastChangeReason", Value::Null),
        ],
    )?;
    let proposals = normalize_records(
        source.and_then(|value| value.get("pendingProposals")),
        "input.state.lifecycle.diplomacy.pendingProposals",
        &[("goldPayment", Value::from(0))],
    )?;
    let messages = normalize_records(
        source.and_then(|value| value.get("messages")),
        "input.state.lifecycle.diplomacy.messages",
        &[
            ("response", Value::Null),
            ("respondedTurn", Value::Null),
            ("relationScoreDelta", Value::from(0)),
            ("relationScoreAfter", Value::Null),
            ("promiseDueTurn", Value::Null),
            ("promiseBroken", Value::Bool(false)),
        ],
    )?;
    let history = normalize_records(
        source.and_then(|value| value.get("scoreHistory")),
        "input.state.lifecycle.diplomacy.scoreHistory",
        &[
            ("delta", Value::from(0)),
            ("scoreAfter", Value::from(0)),
            ("sourceId", Value::Null),
        ],
    )?;
    serde_json::from_value(Value::Object(Map::from_iter([
        ("contacts".to_owned(), contacts),
        ("relations".to_owned(), Value::Array(relations)),
        ("pendingProposals".to_owned(), Value::Array(proposals)),
        ("messages".to_owned(), Value::Array(messages)),
        ("scoreHistory".to_owned(), Value::Array(history)),
    ])))
    .map_err(display_error)
}

fn decode_resource_trade_agreements(
    state: &JsonObject,
) -> Result<Vec<ResourceTradeAgreementDto>, AdapterError> {
    let value = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("resourceTradeAgreements"));
    serde_json::from_value(Value::Array(normalize_records(
        value,
        "input.state.lifecycle.resourceTradeAgreements",
        &[
            ("goldPerTurn", Value::from(0)),
            ("amountPerTurn", Value::from(1)),
            ("exchangeGroupId", Value::Null),
        ],
    )?))
    .map_err(display_error)
}

fn decode_hold_turns(
    state: &JsonObject,
    field: &str,
) -> Result<BTreeMap<String, i64>, AdapterError> {
    let value = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get(field))
        .cloned()
        .unwrap_or_else(|| Value::Object(Map::new()));
    serde_json::from_value(value).map_err(display_error)
}

fn decode_map_objective_holds(
    state: &JsonObject,
) -> Result<Vec<MapObjectiveHoldStateDto>, AdapterError> {
    let value = state
        .get("lifecycle")
        .and_then(Value::as_object)
        .and_then(|lifecycle| lifecycle.get("mapObjectiveHoldStates"))
        .cloned()
        .unwrap_or_else(|| Value::Array(Vec::new()));
    serde_json::from_value(value).map_err(display_error)
}

fn normalize_records(
    value: Option<&Value>,
    path: &str,
    defaults: &[(&str, Value)],
) -> Result<Vec<Value>, AdapterError> {
    let Some(value) = value else {
        return Ok(Vec::new());
    };
    let values = value
        .as_array()
        .ok_or_else(|| error(format!("{path} must be an array")))?;
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let item_path = format!("{path}[{index}]");
            let mut object = object_at(value, &item_path)?.clone();
            for (field, default) in defaults {
                object
                    .entry((*field).to_owned())
                    .or_insert_with(|| default.clone());
            }
            Ok(Value::Object(object))
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
        CityConquestActionDto, DiplomaticMessageCategoryDto, DiplomaticMessageTopicDto,
        DiplomaticProposalKindDto, DiplomaticRelationStatusDto, DiplomaticScoreChangeReasonDto,
        FieldImprovementKindDto, PendingInteractionDto, ResourceTypeDto, TechnologyIdDto,
        TroopKindDto, UnitKindDto, UnitPostureDto, WonderTypeDto, WorkerJobDto,
        WorldArtifactLocationDto, WorldArtifactTypeDto,
    };
    use aonw_domain::{HexGridBounds, MovementUnits};
    use serde_json::json;

    use super::{
        decode_diplomacy_state, decode_economy, decode_field_improvements, decode_hold_turns,
        decode_intended_attacks, decode_interaction, decode_map_objective_holds,
        decode_pending_interaction, decode_referenced_artifacts, decode_research,
        decode_resource_trade_agreements, decode_unit, decode_wonder_registry,
    };

    #[test]
    fn legacy_unit_adapter_preserves_complete_state_and_serializer_omissions() {
        let source = json!({
            "id": "worker-1",
            "ownerPlayerId": "player-1",
            "type": "worker",
            "name": "Worker",
            "col": 1,
            "row": 1,
            "movementPoints": 2,
            "movementSubpoints": 1,
            "army": [{"type": "warrior", "count": 2}],
            "queuedPath": {
                "targetCol": 2,
                "targetRow": 1,
                "steps": [
                    {"col": 1, "row": 1, "enterCost": 0, "cumulativeCost": 0},
                    {"col": 2, "row": 1, "enterCost": 2, "cumulativeCost": 2}
                ]
            },
            "merchantTradeRoute": {
                "originCityId": "city-1",
                "destinationCityId": "city-2",
                "steps": [
                    {"col": 1, "row": 1, "enterCost": 0, "cumulativeCost": 0},
                    {"col": 2, "row": 1, "enterCost": 2, "cumulativeCost": 2}
                ]
            },
            "workerJob": {
                "kind": "fieldImprovement",
                "targetHex": {"col": 2, "row": 1},
                "improvementType": "farm",
                "remainingTurns": 2,
                "totalTurns": 3
            },
            "cityFoundingJob": {
                "center": {"col": 1, "row": 1},
                "controlledHexes": [{"col": 2, "row": 1}],
                "remainingTurns": 1,
                "totalTurns": 2
            },
            "workerAssignment": {"targetHex": {"col": 2, "row": 1}},
            "excavatingArtifactId": "artifact-dig",
            "workerBuildCharges": 3,
            "hitPoints": 7,
            "experiencePoints": 11,
            "posture": "autoWorking",
            "carriedArtifactId": "artifact-carry"
        });
        let path = "input.state.units[0]";
        let unit = decode_unit(source.as_object().expect("unit object"), path)
            .expect("decode complete unit");

        assert_eq!(unit.kind, UnitKindDto::Worker);
        assert_eq!(unit.movement_units, 2 * MovementUnits::PER_POINT + 1);
        assert_eq!(unit.army[0].kind, TroopKindDto::Warrior);
        assert_eq!(unit.army[0].count, 2);
        assert_eq!(
            unit.queued_path.as_ref().expect("queued path").steps.len(),
            2
        );
        let route = unit.merchant_trade_route.as_ref().expect("merchant route");
        assert_eq!(route.origin_city_id, "city-1");
        assert_eq!(route.destination_city_id, "city-2");
        assert_eq!(route.steps.len(), 2);
        assert_eq!(route.transport_network_fingerprint, "");
        assert_eq!(
            unit.activity.worker_job,
            Some(WorkerJobDto::FieldImprovement {
                target: aonw_contracts::CoordinateDto { col: 2, row: 1 },
                improvement: FieldImprovementKindDto::Farm,
                remaining_turns: 2,
                total_turns: 3,
            })
        );
        assert_eq!(
            unit.activity
                .city_founding_job
                .as_ref()
                .expect("founding job")
                .controlled_hexes,
            [aonw_contracts::CoordinateDto { col: 2, row: 1 }]
        );
        assert_eq!(
            unit.activity.worker_assignment,
            Some(aonw_contracts::CoordinateDto { col: 2, row: 1 })
        );
        assert_eq!(
            unit.activity.excavating_artifact_id.as_deref(),
            Some("artifact-dig")
        );
        assert_eq!(unit.worker_build_charges, 3);
        assert_eq!(unit.hit_points, Some(7));
        assert_eq!(unit.experience_points, 11);
        assert_eq!(unit.posture, UnitPostureDto::AutoWorking);
        assert_eq!(unit.carried_artifact_id.as_deref(), Some("artifact-carry"));

        let mut omitted = source.as_object().expect("unit object").clone();
        omitted.remove("workerBuildCharges");
        let unit = decode_unit(&omitted, path).expect("decode omitted worker charge");
        assert_eq!(unit.worker_build_charges, 1);
    }

    #[test]
    fn legacy_artifact_adapter_requires_explicit_referenced_records() {
        let unit_source = json!({
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "type": "commander",
            "name": "Commander",
            "col": 1,
            "row": 1,
            "movementPoints": 1,
            "army": [],
            "carriedArtifactId": "artifact-1"
        });
        let unit = decode_unit(
            unit_source.as_object().expect("unit object"),
            "input.state.units[0]",
        )
        .expect("decode unit");
        let source = json!({
            "artifacts": [{
                "id": "artifact-1",
                "type": "heroSword",
                "location": {"kind": "carried", "unitId": "unit-1"}
            }]
        });
        let bounds = HexGridBounds::new(3, 3).expect("bounds");
        let artifacts = decode_referenced_artifacts(
            source.as_object().expect("state object"),
            core::slice::from_ref(&unit),
            bounds,
        )
        .expect("decode artifacts");

        assert_eq!(artifacts.len(), 1);
        assert_eq!(artifacts[0].artifact_type, WorldArtifactTypeDto::HeroSword);
        assert_eq!(
            artifacts[0].location,
            WorldArtifactLocationDto::Carried {
                unit_id: "unit-1".to_owned()
            }
        );

        let missing = json!({"artifacts": []});
        let error = decode_referenced_artifacts(
            missing.as_object().expect("state object"),
            &[unit],
            bounds,
        )
        .expect_err("missing artifact must fail");
        assert!(
            error
                .to_string()
                .contains("references missing artifact artifact-1")
        );
    }

    #[test]
    fn legacy_interaction_adapter_preserves_draft_and_legacy_aliases() {
        let unit_source = json!({
            "id": "unit-1",
            "ownerPlayerId": "player-1",
            "type": "settler",
            "name": "Settler",
            "col": 1,
            "row": 1,
            "movementPoints": 1,
            "army": []
        });
        let unit = decode_unit(
            unit_source.as_object().expect("unit object"),
            "input.state.units[0]",
        )
        .expect("decode unit");
        let source = json!({
            "lifecycle": {
                "cityFoundingDraft": {
                    "unitId": "unit-1",
                    "ownerPlayerId": "player-1",
                    "center": {"col": 1, "row": 1},
                    "controlledHexes": [{"col": 2, "row": 1}]
                },
                "pendingAction": {
                    "type": "attackTargeting",
                    "ownerPlayerId": "player-1",
                    "attackerUnitId": "unit-1",
                    "defenderCol": 2,
                    "defenderRow": 2
                }
            }
        });
        let interaction = decode_interaction(
            source.as_object().expect("state object"),
            HexGridBounds::new(3, 3).expect("bounds"),
            &[unit],
            &[],
        )
        .expect("decode interaction");

        let draft = interaction.city_founding_draft.expect("founding draft");
        assert_eq!(draft.unit_id, "unit-1");
        assert_eq!(
            draft.controlled_hexes,
            [aonw_contracts::CoordinateDto { col: 2, row: 1 }]
        );
        assert_eq!(
            interaction.pending,
            Some(PendingInteractionDto::AttackTargeting {
                owner_player_id: "player-1".to_owned(),
                unit_id: "unit-1".to_owned(),
                defender: Some(aonw_contracts::CoordinateDto { col: 2, row: 2 }),
            })
        );
    }

    #[test]
    fn legacy_pending_adapter_decodes_owner_and_city_variants() {
        let cases = [
            (
                json!({"type": "researchSelection", "ownerPlayerId": "player-1"}),
                PendingInteractionDto::ResearchSelection {
                    owner_player_id: "player-1".to_owned(),
                },
            ),
            (
                json!({
                    "type": "cityWorkedHexSelection",
                    "ownerPlayerId": "player-1",
                    "cityId": "city-1"
                }),
                PendingInteractionDto::CityWorkedHexSelection {
                    owner_player_id: "player-1".to_owned(),
                    city_id: "city-1".to_owned(),
                },
            ),
            (
                json!({
                    "type": "cityExpansionSelection",
                    "ownerPlayerId": "player-1",
                    "cityId": "city-1"
                }),
                PendingInteractionDto::CityExpansionSelection {
                    owner_player_id: "player-1".to_owned(),
                    city_id: "city-1".to_owned(),
                },
            ),
        ];

        for (source, expected) in cases {
            assert_eq!(
                decode_pending_interaction(&source).expect("decode pending interaction"),
                expected
            );
        }
    }

    #[test]
    fn legacy_pending_adapter_decodes_unit_variants() {
        let cases = [
            (
                json!({
                    "type": "workerActionSelection",
                    "ownerPlayerId": "player-1",
                    "unitId": "unit-1",
                    "improvementType": "mine"
                }),
                PendingInteractionDto::WorkerActionSelection {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                    improvement: Some(FieldImprovementKindDto::Mine),
                },
            ),
            (
                json!({
                    "type": "merchantTradeRouteSelection",
                    "ownerPlayerId": "player-1",
                    "unitId": "unit-1"
                }),
                PendingInteractionDto::MerchantTradeRouteSelection {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                },
            ),
            (
                json!({
                    "type": "merchantMoveToCitySelection",
                    "ownerPlayerId": "player-1",
                    "unitId": "unit-1"
                }),
                PendingInteractionDto::MerchantMoveToCitySelection {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                },
            ),
            (
                json!({
                    "type": "unitTurnSkip",
                    "ownerPlayerId": "player-1",
                    "unitId": "unit-1",
                    "restoreMovementUnits": 3
                }),
                PendingInteractionDto::UnitTurnSkip {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                    restore_movement_units: 3,
                },
            ),
            (
                json!({
                    "type": "attackTargeting",
                    "ownerPlayerId": "player-1",
                    "attackerUnitId": "unit-1"
                }),
                PendingInteractionDto::AttackTargeting {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                    defender: None,
                },
            ),
            (
                json!({
                    "type": "commanderMergeSelection",
                    "ownerPlayerId": "player-1",
                    "unitId": "unit-1"
                }),
                PendingInteractionDto::CommanderMergeSelection {
                    owner_player_id: "player-1".to_owned(),
                    unit_id: "unit-1".to_owned(),
                },
            ),
        ];

        for (source, expected) in cases {
            assert_eq!(
                decode_pending_interaction(&source).expect("decode pending interaction"),
                expected
            );
        }
    }

    #[test]
    fn legacy_combat_adapter_preserves_in_bounds_intents_and_filters_fixture_sentinels() {
        let source = json!({
            "lifecycle": {
                "intendedAttacks": [
                    {
                        "attackerUnitId": "unit-1",
                        "defenderCol": 1,
                        "defenderRow": 0,
                        "declaredAtTick": 41,
                        "declaringPlayerId": "player-1",
                        "cityConquestAction": "destroy"
                    },
                    {
                        "attackerUnitId": "sentinel",
                        "defenderCol": 30,
                        "defenderRow": 30,
                        "declaredAtTick": 42,
                        "declaringPlayerId": "player-2"
                    }
                ]
            }
        });
        let attacks = decode_intended_attacks(
            source.as_object().expect("state object"),
            HexGridBounds::new(2, 1).expect("bounds"),
        )
        .expect("decode attacks");

        assert_eq!(attacks.len(), 1);
        assert_eq!(attacks[0].attacker_unit_id, "unit-1");
        assert_eq!(attacks[0].declared_at_tick, 41);
        assert_eq!(
            attacks[0].city_conquest_action,
            CityConquestActionDto::Destroy
        );
    }

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

    #[test]
    fn legacy_diplomacy_adapter_preserves_records_and_supplies_legacy_defaults() {
        let source = json!({
            "lifecycle": {
                "diplomacy": {
                    "contacts": ["player-1|player-2"],
                    "relations": [{
                        "playerAId": "player-1",
                        "playerBId": "player-2",
                        "status": "war"
                    }],
                    "pendingProposals": [{
                        "id": "proposal-1",
                        "fromPlayerId": "player-1",
                        "toPlayerId": "player-2",
                        "kind": "truce",
                        "createdTurn": 4,
                        "expiresOnTurn": 6
                    }],
                    "messages": [{
                        "id": "message-1",
                        "fromPlayerId": "player-2",
                        "toPlayerId": "player-1",
                        "topic": "blockedRoutes",
                        "category": "request",
                        "createdTurn": 4,
                        "expiresOnTurn": 6
                    }],
                    "scoreHistory": [{
                        "playerAId": "player-1",
                        "playerBId": "player-2",
                        "turn": 4,
                        "reason": "manual"
                    }]
                },
                "resourceTradeAgreements": [{
                    "id": "trade-1",
                    "exporterPlayerId": "player-1",
                    "importerPlayerId": "player-2",
                    "resource": "coal",
                    "remainingTurns": 3
                }]
            }
        });
        let state = source.as_object().expect("state object");
        let diplomacy = decode_diplomacy_state(state).expect("decode diplomacy");
        let trades = decode_resource_trade_agreements(state).expect("decode trades");

        assert_eq!(diplomacy.contacts.len(), 1);
        assert_eq!(
            diplomacy.relations[0].status,
            DiplomaticRelationStatusDto::War
        );
        assert_eq!(diplomacy.relations[0].relation_score, 0);
        assert_eq!(
            diplomacy.pending_proposals[0].kind,
            DiplomaticProposalKindDto::Truce
        );
        assert_eq!(diplomacy.pending_proposals[0].gold_payment, 0);
        assert_eq!(
            diplomacy.messages[0].topic,
            DiplomaticMessageTopicDto::BlockedRoutes
        );
        assert_eq!(
            diplomacy.messages[0].category,
            DiplomaticMessageCategoryDto::Request
        );
        assert_eq!(diplomacy.messages[0].response, None);
        assert_eq!(diplomacy.messages[0].relation_score_delta, 0);
        assert_eq!(
            diplomacy.score_history[0].reason,
            DiplomaticScoreChangeReasonDto::Manual
        );
        assert_eq!(diplomacy.score_history[0].score_after, 0);
        assert_eq!(trades[0].resource, ResourceTypeDto::Coal);
        assert_eq!(trades[0].gold_per_turn, 0);
        assert_eq!(trades[0].amount_per_turn, 1);
        assert_eq!(trades[0].exchange_group_id, None);
    }

    #[test]
    fn legacy_objective_adapter_preserves_sparse_outcome_progress() {
        let source = json!({
            "lifecycle": {
                "dominationHoldTurnsByPlayerId": {"player-1": 2},
                "culturalVictoryHoldTurnsByPlayerId": {"player-2": 4},
                "mapObjectiveHoldStates": [{
                    "objectiveId": "strategic-pass-1",
                    "playerId": "player-1",
                    "holdTurns": 3
                }]
            }
        });
        let state = source.as_object().expect("state object");
        let domination =
            decode_hold_turns(state, "dominationHoldTurnsByPlayerId").expect("decode domination");
        let cultural = decode_hold_turns(state, "culturalVictoryHoldTurnsByPlayerId")
            .expect("decode cultural");
        let holds = decode_map_objective_holds(state).expect("decode map objectives");

        assert_eq!(domination["player-1"], 2);
        assert_eq!(cultural["player-2"], 4);
        assert_eq!(holds[0].objective_id, "strategic-pass-1");
        assert_eq!(holds[0].player_id, "player-1");
        assert_eq!(holds[0].hold_turns, 3);

        let empty = json!({});
        let empty_state = empty.as_object().expect("empty state object");
        assert!(
            decode_hold_turns(empty_state, "dominationHoldTurnsByPlayerId")
                .expect("omitted domination")
                .is_empty()
        );
        assert!(
            decode_map_objective_holds(empty_state)
                .expect("omitted objectives")
                .is_empty()
        );
    }
}
