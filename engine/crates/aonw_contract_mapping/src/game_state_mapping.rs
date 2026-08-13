use aonw_contracts::{
    ArmyTroopDto, CURRENT_GAME_STATE_VERSION, CityDto, CityFoundingJobDto, CoordinateDto,
    FieldImprovementKindDto, GameStateDto, MAX_MOVEMENT_BALANCE_UNITS,
    MAX_MOVEMENT_STATE_UNIT_COUNT, MAX_QUEUED_PATH_STEP_COUNT, MerchantTradeRouteDto,
    MovementStepDto, PlayerFogDto, PlayerPairDto, TransportConditionDto, TransportSegmentDto,
    TroopKindDto, UnitActivityDto, UnitDto, UnitOccupancyPolicyDto, WorkerJobDto,
};
use aonw_domain::{
    ArmyTroop, ArtifactId, City, CityFoundingJob, CityId, Diplomacy, FieldImprovementKind,
    FogOfWar, GameState, HexCoord, HexGridBounds, MerchantTradeRoute, MovementStep, MovementUnits,
    PlayerFog, PlayerId, PlayerPair, StateRevision, TransportCondition, TransportNetwork,
    TransportSegment, TroopKind, Unit, UnitActivity, UnitId, UnitOccupancyPolicy, WorkerJob,
};

use crate::{
    decode_queued_path, decode_unit_kind, decode_unit_posture, encode_queued_path,
    encode_unit_kind, encode_unit_posture,
};

/// Failure raised while mapping the canonical game-state contract.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct GameStateMappingError {
    path: Box<str>,
    message: Box<str>,
}

impl GameStateMappingError {
    fn new(path: impl Into<Box<str>>, message: impl Into<Box<str>>) -> Self {
        Self {
            path: path.into(),
            message: message.into(),
        }
    }

    /// Returns the contract path that failed validation.
    #[must_use]
    pub fn path(&self) -> &str {
        &self.path
    }
}

impl core::fmt::Display for GameStateMappingError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        write!(formatter, "{}: {}", self.path, self.message)
    }
}

impl std::error::Error for GameStateMappingError {}

/// Validates and maps a complete game-state DTO.
///
/// # Errors
///
/// Returns a path-aware error for unsupported versions or violated invariants.
pub fn decode_game_state(dto: GameStateDto) -> Result<GameState, GameStateMappingError> {
    if dto.schema_version != CURRENT_GAME_STATE_VERSION {
        return Err(GameStateMappingError::new(
            "$.schemaVersion",
            format!(
                "unsupported version {}; expected {CURRENT_GAME_STATE_VERSION}",
                dto.schema_version
            ),
        ));
    }
    if dto.units.len() > MAX_MOVEMENT_STATE_UNIT_COUNT {
        return Err(GameStateMappingError::new(
            "$.units",
            format!(
                "contains {} units; maximum is {MAX_MOVEMENT_STATE_UNIT_COUNT}",
                dto.units.len()
            ),
        ));
    }
    let bounds = HexGridBounds::new(dto.cols, dto.rows)
        .ok_or_else(|| GameStateMappingError::new("$", "map bounds must be non-empty"))?;
    let units = dto
        .units
        .into_iter()
        .enumerate()
        .map(|(index, unit)| decode_unit(index, unit))
        .collect::<Result<Vec<_>, _>>()?;
    let cities = dto
        .cities
        .into_iter()
        .enumerate()
        .map(|(index, city)| decode_city(index, city))
        .collect::<Result<Vec<_>, _>>()?;
    let fog = FogOfWar::try_new(
        dto.fog_of_war
            .into_iter()
            .enumerate()
            .map(|(index, fog)| decode_fog(index, fog))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|player| {
        GameStateMappingError::new("$.fogOfWar", format!("duplicate player: {player}"))
    })?;
    let diplomacy = Diplomacy::new(
        dto.diplomatic_contacts
            .into_iter()
            .enumerate()
            .map(|(index, pair)| decode_pair(index, pair))
            .collect::<Result<Vec<_>, _>>()?,
    );
    let transport = TransportNetwork::try_new(
        dto.transport_network
            .into_iter()
            .enumerate()
            .map(|(index, segment)| decode_transport(index, segment))
            .collect::<Result<Vec<_>, _>>()?,
    )
    .map_err(|coordinate| {
        GameStateMappingError::new(
            "$.transportNetwork",
            format!(
                "duplicate coordinate: ({}, {})",
                coordinate.col(),
                coordinate.row()
            ),
        )
    })?;
    GameState::try_new_with_world(
        StateRevision::new(dto.revision),
        dto.turn,
        bounds,
        match dto.occupancy_policy {
            UnitOccupancyPolicyDto::Exclusive => UnitOccupancyPolicy::Exclusive,
            UnitOccupancyPolicyDto::FriendlyStacking => UnitOccupancyPolicy::FriendlyStacking,
        },
        units,
        cities,
        fog,
        diplomacy,
        transport,
    )
    .map_err(|error| GameStateMappingError::new("$", error.to_string()))
}

/// Encodes the movement-complete canonical state.
#[must_use]
pub fn encode_game_state(state: &GameState) -> GameStateDto {
    GameStateDto {
        schema_version: CURRENT_GAME_STATE_VERSION,
        revision: state.revision().get(),
        turn: state.turn(),
        cols: state.bounds().cols(),
        rows: state.bounds().rows(),
        occupancy_policy: match state.occupancy_policy() {
            UnitOccupancyPolicy::Exclusive => UnitOccupancyPolicyDto::Exclusive,
            UnitOccupancyPolicy::FriendlyStacking => UnitOccupancyPolicyDto::FriendlyStacking,
        },
        units: state.units().iter().map(encode_unit).collect(),
        cities: state.cities().iter().map(encode_city).collect(),
        fog_of_war: state
            .fog_of_war()
            .players()
            .iter()
            .map(encode_fog)
            .collect(),
        diplomatic_contacts: state
            .diplomacy()
            .contacts()
            .iter()
            .map(|pair| PlayerPairDto {
                first_player_id: pair.first().as_str().to_owned(),
                second_player_id: pair.second().as_str().to_owned(),
            })
            .collect(),
        transport_network: state
            .transport_network()
            .segments()
            .iter()
            .map(encode_transport)
            .collect(),
    }
}

fn decode_unit(index: usize, dto: UnitDto) -> Result<Unit, GameStateMappingError> {
    let path = format!("$.units[{index}]");
    if dto.movement_units > MAX_MOVEMENT_BALANCE_UNITS {
        return Err(GameStateMappingError::new(
            format!("{path}.movementUnits"),
            format!("exceeds {MAX_MOVEMENT_BALANCE_UNITS}"),
        ));
    }
    if dto
        .skipped_movement_restore_units
        .is_some_and(|units| units > MAX_MOVEMENT_BALANCE_UNITS)
    {
        return Err(GameStateMappingError::new(
            format!("{path}.skippedMovementRestoreUnits"),
            format!("exceeds {MAX_MOVEMENT_BALANCE_UNITS}"),
        ));
    }
    if dto
        .queued_path
        .as_ref()
        .is_some_and(|route| route.steps.len() > MAX_QUEUED_PATH_STEP_COUNT)
    {
        return Err(GameStateMappingError::new(
            format!("{path}.queuedPath.steps"),
            format!("exceeds {MAX_QUEUED_PATH_STEP_COUNT}"),
        ));
    }
    let id = UnitId::new(dto.id)
        .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?;
    let owner = PlayerId::new(dto.owner_player_id).map_err(|error| {
        GameStateMappingError::new(format!("{path}.ownerPlayerId"), error.to_string())
    })?;
    let queued_path = dto
        .queued_path
        .map(decode_queued_path)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.queuedPath"), error.to_string())
        })?;
    let merchant_route = dto
        .merchant_trade_route
        .map(|route| decode_merchant(&path, route))
        .transpose()?;
    let activity = decode_activity(&path, dto.activity)?;
    let artifact = dto
        .carried_artifact_id
        .map(ArtifactId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(format!("{path}.carriedArtifactId"), error.to_string())
        })?;
    Unit::builder(
        id,
        owner,
        decode_unit_kind(dto.kind),
        dto.name,
        HexCoord::new(dto.col, dto.row),
        MovementUnits::new(dto.movement_units),
    )
    .with_skipped_movement_restore(dto.skipped_movement_restore_units.map(MovementUnits::new))
    .with_army(
        dto.army
            .into_iter()
            .map(|troop| ArmyTroop::new(decode_troop(troop.kind), troop.count)),
    )
    .with_queued_path(queued_path)
    .with_merchant_trade_route(merchant_route)
    .with_activity(activity)
    .with_worker_build_charges(dto.worker_build_charges)
    .with_hit_points(dto.hit_points)
    .with_experience_points(dto.experience_points)
    .with_posture(decode_unit_posture(dto.posture))
    .with_carried_artifact(artifact)
    .build()
    .map_err(|error| GameStateMappingError::new(path, error.to_string()))
}

fn encode_unit(unit: &Unit) -> UnitDto {
    UnitDto {
        id: unit.id().as_str().to_owned(),
        owner_player_id: unit.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(unit.kind()),
        name: unit.name().to_owned(),
        col: unit.position().col(),
        row: unit.position().row(),
        movement_units: unit.movement_units().get(),
        skipped_movement_restore_units: unit.skipped_movement_restore().map(MovementUnits::get),
        army: unit
            .army()
            .iter()
            .map(|troop| ArmyTroopDto {
                kind: encode_troop(troop.kind()),
                count: troop.count(),
            })
            .collect(),
        queued_path: unit.queued_path().map(encode_queued_path),
        merchant_trade_route: unit.merchant_trade_route().map(encode_merchant),
        activity: encode_activity(unit.activity()),
        worker_build_charges: unit.worker_build_charges(),
        hit_points: unit.hit_points(),
        experience_points: unit.experience_points(),
        posture: encode_unit_posture(unit.posture()),
        carried_artifact_id: unit.carried_artifact_id().map(|id| id.as_str().to_owned()),
    }
}

fn decode_merchant(
    path: &str,
    dto: MerchantTradeRouteDto,
) -> Result<MerchantTradeRoute, GameStateMappingError> {
    if dto.steps.len() > MAX_QUEUED_PATH_STEP_COUNT {
        return Err(GameStateMappingError::new(
            format!("{path}.merchantTradeRoute.steps"),
            "route is too long",
        ));
    }
    Ok(MerchantTradeRoute::new(
        CityId::new(dto.origin_city_id).map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.merchantTradeRoute.originCityId"),
                error.to_string(),
            )
        })?,
        CityId::new(dto.destination_city_id).map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.merchantTradeRoute.destinationCityId"),
                error.to_string(),
            )
        })?,
        dto.steps.into_iter().map(decode_step),
        dto.transport_network_fingerprint,
    ))
}

fn encode_merchant(route: &MerchantTradeRoute) -> MerchantTradeRouteDto {
    MerchantTradeRouteDto {
        origin_city_id: route.origin_city_id().as_str().to_owned(),
        destination_city_id: route.destination_city_id().as_str().to_owned(),
        steps: route
            .steps()
            .iter()
            .map(|step| encode_step(*step))
            .collect(),
        transport_network_fingerprint: route.transport_network_fingerprint().to_owned(),
    }
}

fn decode_activity(
    path: &str,
    dto: UnitActivityDto,
) -> Result<UnitActivity, GameStateMappingError> {
    let worker_job = dto.worker_job.map(|job| match job {
        WorkerJobDto::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        } => WorkerJob::FieldImprovement {
            target: decode_coordinate(target),
            improvement: decode_improvement(improvement),
            remaining_turns,
            total_turns,
        },
        WorkerJobDto::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        } => WorkerJob::RoadConstruction {
            target: decode_coordinate(target),
            remaining_turns,
            total_turns,
        },
    });
    let founding = dto.city_founding_job.map(|job| {
        CityFoundingJob::new(
            decode_coordinate(job.center),
            job.controlled_hexes.into_iter().map(decode_coordinate),
            job.remaining_turns,
            job.total_turns,
        )
    });
    let excavating = dto
        .excavating_artifact_id
        .map(ArtifactId::new)
        .transpose()
        .map_err(|error| {
            GameStateMappingError::new(
                format!("{path}.activity.excavatingArtifactId"),
                error.to_string(),
            )
        })?;
    Ok(UnitActivity::new(
        worker_job,
        founding,
        dto.worker_assignment.map(decode_coordinate),
        excavating,
    ))
}

fn encode_activity(activity: &UnitActivity) -> UnitActivityDto {
    let worker_job = activity.worker_job().map(|job| match job {
        WorkerJob::FieldImprovement {
            target,
            improvement,
            remaining_turns,
            total_turns,
        } => WorkerJobDto::FieldImprovement {
            target: encode_coordinate(*target),
            improvement: encode_improvement(*improvement),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
        WorkerJob::RoadConstruction {
            target,
            remaining_turns,
            total_turns,
        } => WorkerJobDto::RoadConstruction {
            target: encode_coordinate(*target),
            remaining_turns: *remaining_turns,
            total_turns: *total_turns,
        },
    });
    UnitActivityDto {
        worker_job,
        city_founding_job: activity.city_founding_job().map(|job| CityFoundingJobDto {
            center: encode_coordinate(job.center()),
            controlled_hexes: job
                .controlled_hexes()
                .iter()
                .copied()
                .map(encode_coordinate)
                .collect(),
            remaining_turns: job.remaining_turns(),
            total_turns: job.total_turns(),
        }),
        worker_assignment: activity.worker_assignment().map(encode_coordinate),
        excavating_artifact_id: activity
            .excavating_artifact_id()
            .map(|id| id.as_str().to_owned()),
    }
}

fn decode_city(index: usize, dto: CityDto) -> Result<City, GameStateMappingError> {
    let path = format!("$.cities[{index}]");
    Ok(City::new(
        CityId::new(dto.id)
            .map_err(|error| GameStateMappingError::new(format!("{path}.id"), error.to_string()))?,
        PlayerId::new(dto.owner_player_id).map_err(|error| {
            GameStateMappingError::new(format!("{path}.ownerPlayerId"), error.to_string())
        })?,
        decode_coordinate(dto.center),
        dto.controlled_hexes.into_iter().map(decode_coordinate),
    ))
}

fn encode_city(city: &City) -> CityDto {
    CityDto {
        id: city.id().as_str().to_owned(),
        owner_player_id: city.owner_player_id().as_str().to_owned(),
        center: encode_coordinate(city.center()),
        controlled_hexes: city
            .controlled_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
    }
}

fn decode_fog(index: usize, dto: PlayerFogDto) -> Result<PlayerFog, GameStateMappingError> {
    let player = PlayerId::new(dto.player_id).map_err(|error| {
        GameStateMappingError::new(format!("$.fogOfWar[{index}].playerId"), error.to_string())
    })?;
    Ok(PlayerFog::new(
        player,
        dto.discovered_hexes.into_iter().map(decode_coordinate),
        dto.visible_hexes.into_iter().map(decode_coordinate),
    ))
}

fn encode_fog(fog: &PlayerFog) -> PlayerFogDto {
    PlayerFogDto {
        player_id: fog.player_id().as_str().to_owned(),
        discovered_hexes: fog
            .discovered_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
        visible_hexes: fog
            .visible_hexes()
            .iter()
            .copied()
            .map(encode_coordinate)
            .collect(),
    }
}

fn decode_pair(index: usize, dto: PlayerPairDto) -> Result<PlayerPair, GameStateMappingError> {
    let first = PlayerId::new(dto.first_player_id).map_err(|error| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}].firstPlayerId"),
            error.to_string(),
        )
    })?;
    let second = PlayerId::new(dto.second_player_id).map_err(|error| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}].secondPlayerId"),
            error.to_string(),
        )
    })?;
    PlayerPair::new(first, second).ok_or_else(|| {
        GameStateMappingError::new(
            format!("$.diplomaticContacts[{index}]"),
            "self-contact is invalid",
        )
    })
}

fn decode_transport(
    index: usize,
    dto: TransportSegmentDto,
) -> Result<TransportSegment, GameStateMappingError> {
    let path = format!("$.transportNetwork[{index}]");
    Ok(TransportSegment::road(
        decode_coordinate(dto.coordinate),
        match dto.condition {
            TransportConditionDto::Operational => TransportCondition::Operational,
            TransportConditionDto::Pillaged => TransportCondition::Pillaged,
        },
        PlayerId::new(dto.built_by_player_id).map_err(|error| {
            GameStateMappingError::new(format!("{path}.builtByPlayerId"), error.to_string())
        })?,
        dto.built_by_city_id
            .map(CityId::new)
            .transpose()
            .map_err(|error| {
                GameStateMappingError::new(format!("{path}.builtByCityId"), error.to_string())
            })?,
    ))
}

fn encode_transport(segment: &TransportSegment) -> TransportSegmentDto {
    TransportSegmentDto {
        coordinate: encode_coordinate(segment.coordinate()),
        condition: match segment.condition() {
            TransportCondition::Operational => TransportConditionDto::Operational,
            TransportCondition::Pillaged => TransportConditionDto::Pillaged,
        },
        built_by_player_id: segment.built_by_player_id().as_str().to_owned(),
        built_by_city_id: segment.built_by_city_id().map(|id| id.as_str().to_owned()),
    }
}

const fn decode_coordinate(value: CoordinateDto) -> HexCoord {
    HexCoord::new(value.col, value.row)
}
const fn encode_coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
fn decode_step(step: MovementStepDto) -> MovementStep {
    MovementStep::new(
        HexCoord::new(step.col, step.row),
        MovementUnits::new(step.enter_cost_units),
        MovementUnits::new(step.cumulative_cost_units),
    )
}
fn encode_step(step: MovementStep) -> MovementStepDto {
    MovementStepDto {
        col: step.coordinate().col(),
        row: step.coordinate().row(),
        enter_cost_units: step.enter_cost().get(),
        cumulative_cost_units: step.cumulative_cost().get(),
    }
}
const fn decode_troop(kind: TroopKindDto) -> TroopKind {
    match kind {
        TroopKindDto::Warrior => TroopKind::Warrior,
        TroopKindDto::Archer => TroopKind::Archer,
        TroopKindDto::Settler => TroopKind::Settler,
    }
}
const fn encode_troop(kind: TroopKind) -> TroopKindDto {
    match kind {
        TroopKind::Warrior => TroopKindDto::Warrior,
        TroopKind::Archer => TroopKindDto::Archer,
        TroopKind::Settler => TroopKindDto::Settler,
    }
}

macro_rules! improvement_mapping { ($value:expr, $source:path => $target:path, $($rest_source:path => $rest_target:path),+ $(,)?) => { match $value { $source => $target, $($rest_source => $rest_target),+ } }; }
const fn decode_improvement(kind: FieldImprovementKindDto) -> FieldImprovementKind {
    improvement_mapping!(kind, FieldImprovementKindDto::Farm => FieldImprovementKind::Farm, FieldImprovementKindDto::RiverFarm => FieldImprovementKind::RiverFarm, FieldImprovementKindDto::Mine => FieldImprovementKind::Mine, FieldImprovementKindDto::LumberMill => FieldImprovementKind::LumberMill, FieldImprovementKindDto::Pasture => FieldImprovementKind::Pasture, FieldImprovementKindDto::Camp => FieldImprovementKind::Camp, FieldImprovementKindDto::Quarry => FieldImprovementKind::Quarry, FieldImprovementKindDto::FishingBoats => FieldImprovementKind::FishingBoats, FieldImprovementKindDto::Orchard => FieldImprovementKind::Orchard, FieldImprovementKindDto::Plantation => FieldImprovementKind::Plantation, FieldImprovementKindDto::Vineyard => FieldImprovementKind::Vineyard, FieldImprovementKindDto::TradingPost => FieldImprovementKind::TradingPost, FieldImprovementKindDto::ProspectorCamp => FieldImprovementKind::ProspectorCamp, FieldImprovementKindDto::HorseRanch => FieldImprovementKind::HorseRanch, FieldImprovementKindDto::PearlDivers => FieldImprovementKind::PearlDivers, FieldImprovementKindDto::CoalShaft => FieldImprovementKind::CoalShaft, FieldImprovementKindDto::OilWell => FieldImprovementKind::OilWell, FieldImprovementKindDto::BauxiteMine => FieldImprovementKind::BauxiteMine, FieldImprovementKindDto::UraniumMine => FieldImprovementKind::UraniumMine)
}
const fn encode_improvement(kind: FieldImprovementKind) -> FieldImprovementKindDto {
    improvement_mapping!(kind, FieldImprovementKind::Farm => FieldImprovementKindDto::Farm, FieldImprovementKind::RiverFarm => FieldImprovementKindDto::RiverFarm, FieldImprovementKind::Mine => FieldImprovementKindDto::Mine, FieldImprovementKind::LumberMill => FieldImprovementKindDto::LumberMill, FieldImprovementKind::Pasture => FieldImprovementKindDto::Pasture, FieldImprovementKind::Camp => FieldImprovementKindDto::Camp, FieldImprovementKind::Quarry => FieldImprovementKindDto::Quarry, FieldImprovementKind::FishingBoats => FieldImprovementKindDto::FishingBoats, FieldImprovementKind::Orchard => FieldImprovementKindDto::Orchard, FieldImprovementKind::Plantation => FieldImprovementKindDto::Plantation, FieldImprovementKind::Vineyard => FieldImprovementKindDto::Vineyard, FieldImprovementKind::TradingPost => FieldImprovementKindDto::TradingPost, FieldImprovementKind::ProspectorCamp => FieldImprovementKindDto::ProspectorCamp, FieldImprovementKind::HorseRanch => FieldImprovementKindDto::HorseRanch, FieldImprovementKind::PearlDivers => FieldImprovementKindDto::PearlDivers, FieldImprovementKind::CoalShaft => FieldImprovementKindDto::CoalShaft, FieldImprovementKind::OilWell => FieldImprovementKindDto::OilWell, FieldImprovementKind::BauxiteMine => FieldImprovementKindDto::BauxiteMine, FieldImprovementKind::UraniumMine => FieldImprovementKindDto::UraniumMine)
}
