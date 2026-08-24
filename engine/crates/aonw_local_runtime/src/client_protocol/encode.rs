use aonw_content::{
    GridLayout, MapDocument, MapObjective, MapObjectiveType, ResourceType, TerrainType,
    TileDefinition,
};
use aonw_contract_mapping::{encode_improvement, encode_unit_kind, encode_unit_posture};
use aonw_contracts::CoordinateDto;
use aonw_contracts::client::{
    ClientCommandOutcomeDto, ClientCommandRejectionCodeDto, ClientCommandResultDto, ClientEventDto,
    ClientEvidenceDto, ClientFeatureDto, ClientQueryResultDto, ClientReplayVerificationDto,
    ClientResponseBodyDto, ClientSessionStampDto, MapGridLayoutDto, MapObjectiveTypeDto,
    MapObjectiveViewDto, MapResourceDto, MapTerrainDto, MapTileViewDto, MapViewDto,
    MovementStepViewDto, PendingActionViewDto, PlayerTurnLifecycleViewDto, PlayerUnitViewDto,
    PlayerViewPatchDto, PlayerViewSnapshotDto, ReachableTileViewDto,
};
use aonw_domain::{HexCoord, PlayerTurnState};
use aonw_engine::{CommandRejectionCode, DomainEvent, ExecutionEvidence};

use crate::{
    CommandResult, LocalRuntime, PendingActionView, PlayerTurnLifecycleView, PlayerUnitView,
    PlayerViewPatch, PlayerViewSnapshot, ReplayVerification, RuntimeQueryResult, SessionStamp,
};

pub(super) fn capabilities() -> ClientResponseBodyDto {
    let capabilities = LocalRuntime::capabilities();
    let mut features = vec![ClientFeatureDto::InspectMap, ClientFeatureDto::Snapshot];
    if capabilities.reachable() {
        features.push(ClientFeatureDto::Reachable);
    }
    if capabilities.route_plan() {
        features.push(ClientFeatureDto::RoutePlan);
    }
    if capabilities.move_unit() {
        features.push(ClientFeatureDto::MoveUnit);
    }
    if capabilities.unit_actions() {
        features.push(ClientFeatureDto::UnitActions);
    }
    if capabilities.turn_kernel() {
        features.push(ClientFeatureDto::TurnKernel);
    }
    if capabilities.save_game() {
        features.push(ClientFeatureDto::SaveGame);
    }
    if capabilities.replay_verification() {
        features.push(ClientFeatureDto::ReplayVerification);
    }
    ClientResponseBodyDto::Capabilities { features }
}

pub(super) fn map(document: &MapDocument) -> Result<MapViewDto, serde_json::Error> {
    let map = document.map();
    Ok(MapViewDto {
        map_id: map.map_id().to_owned(),
        content_hash: map.content_hash()?.to_string(),
        grid_layout: grid_layout(map.grid_layout()),
        cols: map.cols(),
        rows: map.rows(),
        default_zoom: document.default_zoom(),
        tiles: map.tiles().iter().map(tile).collect(),
        objectives: map.objectives().iter().map(objective).collect(),
    })
}

const fn grid_layout(value: GridLayout) -> MapGridLayoutDto {
    match value {
        GridLayout::OddQFlatTop => MapGridLayoutDto::OddQFlatTop,
    }
}

fn tile(value: &TileDefinition) -> MapTileViewDto {
    MapTileViewDto {
        coordinate: coordinate(value.coordinate()),
        display_terrain: terrain(value.display_terrain()),
        yield_terrain: terrain(value.yield_terrain()),
        movement_terrains: value
            .movement_terrains()
            .iter()
            .copied()
            .map(terrain)
            .collect(),
        terrain_tags: value.terrain_tags().iter().copied().map(terrain).collect(),
        resources: value.resources().iter().copied().map(resource).collect(),
        height: value.height(),
    }
}

fn objective(value: &MapObjective) -> MapObjectiveViewDto {
    MapObjectiveViewDto {
        id: value.id().to_owned(),
        objective_type: objective_type(value.objective_type()),
        coordinate: coordinate(value.coordinate()),
        required_hold_turns: value.required_hold_turns(),
        victory_points: value.victory_points(),
        gold_per_turn: value.gold_per_turn(),
    }
}

const fn terrain(value: TerrainType) -> MapTerrainDto {
    match value {
        TerrainType::Ocean => MapTerrainDto::Ocean,
        TerrainType::Coast => MapTerrainDto::Coast,
        TerrainType::Lake => MapTerrainDto::Lake,
        TerrainType::Plains => MapTerrainDto::Plains,
        TerrainType::Grassland => MapTerrainDto::Grassland,
        TerrainType::Desert => MapTerrainDto::Desert,
        TerrainType::Tundra => MapTerrainDto::Tundra,
        TerrainType::Snow => MapTerrainDto::Snow,
        TerrainType::Mountain => MapTerrainDto::Mountain,
        TerrainType::Hills => MapTerrainDto::Hills,
        TerrainType::Wetlands => MapTerrainDto::Wetlands,
        TerrainType::Jungle => MapTerrainDto::Jungle,
        TerrainType::Forest => MapTerrainDto::Forest,
        TerrainType::River => MapTerrainDto::River,
    }
}

const fn resource(value: ResourceType) -> MapResourceDto {
    match value {
        ResourceType::Wheat => MapResourceDto::Wheat,
        ResourceType::Fish => MapResourceDto::Fish,
        ResourceType::Deer => MapResourceDto::Deer,
        ResourceType::Sheep => MapResourceDto::Sheep,
        ResourceType::Rice => MapResourceDto::Rice,
        ResourceType::Cow => MapResourceDto::Cow,
        ResourceType::Apple => MapResourceDto::Apple,
        ResourceType::Banana => MapResourceDto::Banana,
        ResourceType::Citrus => MapResourceDto::Citrus,
        ResourceType::Gold => MapResourceDto::Gold,
        ResourceType::Silver => MapResourceDto::Silver,
        ResourceType::Gems => MapResourceDto::Gems,
        ResourceType::Silk => MapResourceDto::Silk,
        ResourceType::Spices => MapResourceDto::Spices,
        ResourceType::Cotton => MapResourceDto::Cotton,
        ResourceType::Grapes => MapResourceDto::Grapes,
        ResourceType::Ivory => MapResourceDto::Ivory,
        ResourceType::Pearls => MapResourceDto::Pearls,
        ResourceType::Coffee => MapResourceDto::Coffee,
        ResourceType::Cocoa => MapResourceDto::Cocoa,
        ResourceType::Tobacco => MapResourceDto::Tobacco,
        ResourceType::Sugar => MapResourceDto::Sugar,
        ResourceType::Iron => MapResourceDto::Iron,
        ResourceType::Coal => MapResourceDto::Coal,
        ResourceType::Oil => MapResourceDto::Oil,
        ResourceType::Aluminium => MapResourceDto::Aluminium,
        ResourceType::Uranium => MapResourceDto::Uranium,
        ResourceType::Horses => MapResourceDto::Horses,
        ResourceType::Marble => MapResourceDto::Marble,
    }
}

const fn objective_type(value: MapObjectiveType) -> MapObjectiveTypeDto {
    match value {
        MapObjectiveType::Ruins => MapObjectiveTypeDto::Ruins,
        MapObjectiveType::StrategicPass => MapObjectiveTypeDto::StrategicPass,
        MapObjectiveType::HolySite => MapObjectiveTypeDto::HolySite,
        MapObjectiveType::LegendaryResource => MapObjectiveTypeDto::LegendaryResource,
    }
}

pub(super) fn stamp(value: SessionStamp) -> ClientSessionStampDto {
    ClientSessionStampDto {
        revision: value.revision.get(),
        state_digest: value.state_digest.to_string(),
        map_hash: value.map_hash.to_string(),
        ruleset_hash: value.ruleset_hash.to_string(),
    }
}

pub(super) fn snapshot(value: &PlayerViewSnapshot) -> PlayerViewSnapshotDto {
    PlayerViewSnapshotDto {
        stamp: stamp(*value.stamp()),
        turn: value.turn(),
        turn_lifecycle: turn_lifecycle(*value.turn_lifecycle()),
        pending_action: value.pending_action().map(pending_action),
        units: value.units().iter().map(unit).collect(),
    }
}

pub(super) fn query_result(value: &RuntimeQueryResult) -> ClientQueryResultDto {
    match value {
        RuntimeQueryResult::Reachable(value) => ClientQueryResultDto::Reachable {
            stamp: stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            available_movement_units: value.available_movement.get(),
            tiles: value
                .tiles
                .iter()
                .map(|tile| ReachableTileViewDto {
                    coordinate: coordinate(tile.coordinate),
                    cost_units: tile.cost.get(),
                    exhausts_movement: tile.exhausts_movement,
                })
                .collect(),
        },
        RuntimeQueryResult::RoutePlan(value) => ClientQueryResultDto::RoutePlan {
            stamp: stamp(value.stamp),
            unit_id: value.unit_id.as_str().to_owned(),
            target: coordinate(value.target),
            destination: coordinate(value.destination),
            total_cost_units: value.total_cost.get(),
            available_movement_units: value.available_movement.get(),
            remaining_movement_units: value.remaining_movement.get(),
            steps: value
                .steps
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate),
                    enter_cost_units: step.enter_cost.get(),
                    cumulative_cost_units: step.cumulative_cost.get(),
                })
                .collect(),
        },
    }
}

pub(super) fn command_result(value: &CommandResult) -> ClientCommandResultDto {
    ClientCommandResultDto {
        stamp: stamp(value.stamp),
        outcome: value
            .rejection
            .map_or(ClientCommandOutcomeDto::Accepted, |code| {
                ClientCommandOutcomeDto::Rejected {
                    code: rejection(code),
                }
            }),
        events: value.events.iter().map(event).collect(),
        evidence: value.evidence.as_ref().map(evidence),
        view_patch: patch(&value.view_patch),
    }
}

const fn rejection(value: CommandRejectionCode) -> ClientCommandRejectionCodeDto {
    match value {
        CommandRejectionCode::StaleRevision => ClientCommandRejectionCodeDto::StaleRevision,
        CommandRejectionCode::UnitNotFound => ClientCommandRejectionCodeDto::UnitNotFound,
        CommandRejectionCode::UnitNotControlled => ClientCommandRejectionCodeDto::UnitNotControlled,
        CommandRejectionCode::UnitUnavailable => ClientCommandRejectionCodeDto::UnitUnavailable,
        CommandRejectionCode::UnitUsesTradeRoutes => {
            ClientCommandRejectionCodeDto::UnitUsesTradeRoutes
        }
        CommandRejectionCode::UnitOutOfBounds => ClientCommandRejectionCodeDto::UnitOutOfBounds,
        CommandRejectionCode::MoveTargetOutOfBounds => {
            ClientCommandRejectionCodeDto::MoveTargetOutOfBounds
        }
        CommandRejectionCode::MoveTargetIsCurrentTile => {
            ClientCommandRejectionCodeDto::MoveTargetIsCurrentTile
        }
        CommandRejectionCode::MoveTargetIsForeignCityCenter => {
            ClientCommandRejectionCodeDto::MoveTargetIsForeignCityCenter
        }
        CommandRejectionCode::MoveTargetOccupied => {
            ClientCommandRejectionCodeDto::MoveTargetOccupied
        }
        CommandRejectionCode::UnitMovementCapacityInsufficient => {
            ClientCommandRejectionCodeDto::UnitMovementCapacityInsufficient
        }
        CommandRejectionCode::MovePathNotFound => ClientCommandRejectionCodeDto::MovePathNotFound,
        CommandRejectionCode::UnitBusy => ClientCommandRejectionCodeDto::UnitBusy,
        CommandRejectionCode::UnitDefinitionMissing => {
            ClientCommandRejectionCodeDto::UnitDefinitionMissing
        }
        CommandRejectionCode::StateRevisionOverflow => {
            ClientCommandRejectionCodeDto::StateRevisionOverflow
        }
        CommandRejectionCode::InvalidQueuedMovementPath => {
            ClientCommandRejectionCodeDto::InvalidQueuedMovementPath
        }
        CommandRejectionCode::InvalidUnit => ClientCommandRejectionCodeDto::InvalidUnit,
        CommandRejectionCode::MovementUnitUpdateFailed => {
            ClientCommandRejectionCodeDto::MovementUnitUpdateFailed
        }
        CommandRejectionCode::TurnPlayerNotControlled => {
            ClientCommandRejectionCodeDto::TurnPlayerNotControlled
        }
        CommandRejectionCode::TurnPlayerNotActive => {
            ClientCommandRejectionCodeDto::TurnPlayerNotActive
        }
        CommandRejectionCode::TurnScopeInvalid => ClientCommandRejectionCodeDto::TurnScopeInvalid,
        CommandRejectionCode::TurnProcessorUnsupported => {
            ClientCommandRejectionCodeDto::TurnProcessorUnsupported
        }
        CommandRejectionCode::TurnNumberOverflow => {
            ClientCommandRejectionCodeDto::TurnNumberOverflow
        }
    }
}

pub(super) fn replay_verification(value: ReplayVerification) -> ClientReplayVerificationDto {
    ClientReplayVerificationDto {
        entry_count: u64::try_from(value.entry_count).unwrap_or(u64::MAX),
        final_event_offset: value.final_event_offset,
        final_stamp: stamp(value.final_stamp),
    }
}

fn unit(value: &PlayerUnitView) -> PlayerUnitViewDto {
    PlayerUnitViewDto {
        id: value.id().as_str().to_owned(),
        owner_player_id: value.owner_player_id().as_str().to_owned(),
        kind: encode_unit_kind(value.kind()),
        name: value.name().to_owned(),
        coordinate: CoordinateDto {
            col: value.col(),
            row: value.row(),
        },
        movement_units: value.movement_units(),
        posture: encode_unit_posture(value.posture()),
    }
}

fn patch(value: &PlayerViewPatch) -> PlayerViewPatchDto {
    PlayerViewPatchDto {
        from_revision: value.from_revision,
        to_revision: value.to_revision,
        turn_lifecycle: value.turn_lifecycle.map(turn_lifecycle),
        upserted_units: value.upserted_units.iter().map(unit).collect(),
        removed_unit_ids: value
            .removed_unit_ids
            .iter()
            .map(|id| id.as_str().to_owned())
            .collect(),
        pending_action: value.pending_action.as_ref().map(pending_action),
    }
}

fn pending_action(value: &PendingActionView) -> PendingActionViewDto {
    match value {
        PendingActionView::ResearchSelection => PendingActionViewDto::ResearchSelection,
        PendingActionView::CityWorkedHexSelection { city_id } => {
            PendingActionViewDto::CityWorkedHexSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::CityExpansionSelection { city_id } => {
            PendingActionViewDto::CityExpansionSelection {
                city_id: city_id.as_str().to_owned(),
            }
        }
        PendingActionView::WorkerActionSelection {
            unit_id,
            improvement,
        } => PendingActionViewDto::WorkerActionSelection {
            unit_id: unit_id.as_str().to_owned(),
            improvement: (*improvement).map(encode_improvement),
        },
        PendingActionView::MerchantTradeRouteSelection { unit_id } => {
            PendingActionViewDto::MerchantTradeRouteSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::MerchantMoveToCitySelection { unit_id } => {
            PendingActionViewDto::MerchantMoveToCitySelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
        PendingActionView::UnitTurnSkip {
            unit_id,
            restore_movement_units,
        } => PendingActionViewDto::UnitTurnSkip {
            unit_id: unit_id.as_str().to_owned(),
            restore_movement_units: *restore_movement_units,
        },
        PendingActionView::AttackTargeting { unit_id, defender } => {
            PendingActionViewDto::AttackTargeting {
                unit_id: unit_id.as_str().to_owned(),
                defender: (*defender).map(coordinate),
            }
        }
        PendingActionView::CommanderMergeSelection { unit_id } => {
            PendingActionViewDto::CommanderMergeSelection {
                unit_id: unit_id.as_str().to_owned(),
            }
        }
    }
}

fn event(value: &DomainEvent) -> ClientEventDto {
    match value {
        DomainEvent::UnitMoved(value) => ClientEventDto::UnitMoved {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            to: coordinate(value.to()),
        },
        DomainEvent::TurnEnded(value) => ClientEventDto::TurnEnded {
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::AllPlayersSubmitted(value) => ClientEventDto::AllPlayersSubmitted {
            turn: value.turn(),
            player_ids: value
                .player_ids()
                .iter()
                .map(|player| player.as_str().to_owned())
                .collect(),
        },
        DomainEvent::PlayerTimedOut(value) => ClientEventDto::PlayerTimedOut {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
        },
        DomainEvent::PlayerKicked(value) => ClientEventDto::PlayerKicked {
            turn: value.turn(),
            player_id: value.player_id().as_str().to_owned(),
            reason: value.reason().to_owned(),
            timeout_streak: value.timeout_streak(),
        },
    }
}

fn evidence(value: &ExecutionEvidence) -> ClientEvidenceDto {
    match value {
        ExecutionEvidence::UnitMovement(value) => ClientEvidenceDto::UnitMovement {
            unit_id: value.unit_id().as_str().to_owned(),
            from: coordinate(value.from()),
            steps: value
                .steps()
                .iter()
                .map(|step| MovementStepViewDto {
                    coordinate: coordinate(step.coordinate()),
                    enter_cost_units: step.enter_cost().get(),
                    cumulative_cost_units: step.cumulative_cost().get(),
                })
                .collect(),
        },
        ExecutionEvidence::TurnKernel(value) => ClientEvidenceDto::TurnKernel {
            processors: value
                .processors()
                .iter()
                .map(|processor| processor.as_str().to_owned())
                .collect(),
            reset_unit_ids: value
                .reset_unit_ids()
                .iter()
                .map(|unit| unit.as_str().to_owned())
                .collect(),
        },
    }
}

fn turn_lifecycle(value: PlayerTurnLifecycleView) -> PlayerTurnLifecycleViewDto {
    PlayerTurnLifecycleViewDto {
        own_state: value.own_state().map(|state| match state {
            PlayerTurnState::Active => aonw_contracts::PlayerTurnStateDto::Active,
            PlayerTurnState::Finished => aonw_contracts::PlayerTurnStateDto::Finished,
        }),
        own_submitted: value.own_submitted(),
        required_submission_count: value.required_submission_count(),
        submitted_count: value.submitted_count(),
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}
