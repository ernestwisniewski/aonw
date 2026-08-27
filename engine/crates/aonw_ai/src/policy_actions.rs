use aonw_domain::{CityConquestAction, DiplomaticMessageResponse, HexCoord, UnitKind, UnitPosture};
use aonw_engine::TechnologyAvailability;
use aonw_local_runtime::{
    ArtifactCommandRequest, AttackHexRequest, AutoExploreUnitRequest, CityFoundingOptionsRequest,
    CombatPreviewRequest, DiplomacyRequest, FoundCityRequest, LocalRuntime, MerchantCityRequest,
    PendingActionView, PlayerArtifactLocationView, PlayerViewSnapshot, ResearchOptionsRequest,
    RuntimeError, RuntimeQuery, RuntimeQueryResult, SelectTechnologyRequest, TurnCommandRequest,
    UnitActionRequest, UnitLogisticsOptionsRequest, WorkerImprovementRequest,
};

use crate::{PlannedCommand, actions::best_move_command};

macro_rules! query_variant {
    ($value:expr, $pattern:pat => $result:expr, $message:literal) => {{
        match $value {
            $pattern => $result,
            _ => unreachable!($message),
        }
    }};
}

macro_rules! runtime_result {
    ($value:expr) => {{
        match $value {
            Ok(value) => value,
            Err(error) => return Err(error),
        }
    }};
}

macro_rules! some_or_continue {
    ($value:expr) => {{
        match $value {
            Some(value) => value,
            None => continue,
        }
    }};
}

mod economy;

use economy::{production_command, worker_command, worker_selection_command};

pub(crate) fn next_policy_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<PlannedCommand, RuntimeError> {
    if let Some(command) = pending_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = diplomacy_response(snapshot) {
        return Ok(command);
    }
    if let Some(command) = research_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = artifact_command(snapshot) {
        return Ok(command);
    }
    if let Some(command) = founding_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = production_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = worker_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = combat_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = logistics_command(runtime, snapshot)? {
        return Ok(command);
    }
    if let Some(command) = best_move_command(runtime, snapshot)? {
        return Ok(command);
    }
    Ok(PlannedCommand::EndTurn(TurnCommandRequest {
        expected_revision: snapshot.stamp().revision.get(),
    }))
}

fn pending_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let Some(pending) = snapshot.pending_action() else {
        return Ok(None);
    };
    let revision = snapshot.stamp().revision.get();
    match pending {
        PendingActionView::ResearchSelection => research_command(runtime, snapshot),
        PendingActionView::WorkerActionSelection {
            unit_id,
            improvement: Some(improvement),
        } => Ok(Some(PlannedCommand::ConfirmWorkerImprovement(
            WorkerImprovementRequest {
                expected_revision: revision,
                unit_id: unit_id.clone(),
                improvement: Some(*improvement),
            },
        ))),
        PendingActionView::WorkerActionSelection {
            unit_id,
            improvement: None,
        } => worker_selection_command(runtime, revision, unit_id),
        PendingActionView::MerchantTradeRouteSelection { unit_id } => {
            merchant_pending_command(runtime, revision, unit_id, true)
        }
        PendingActionView::MerchantMoveToCitySelection { unit_id } => {
            merchant_pending_command(runtime, revision, unit_id, false)
        }
        PendingActionView::UnitTurnSkip { unit_id, .. }
        | PendingActionView::AttackTargeting { unit_id, .. }
        | PendingActionView::CommanderMergeSelection { unit_id } => {
            Ok(Some(PlannedCommand::CancelUnitAction(UnitActionRequest {
                expected_revision: revision,
                unit_id: unit_id.clone(),
            })))
        }
        PendingActionView::CityWorkedHexSelection { .. }
        | PendingActionView::CityExpansionSelection { .. } => Ok(None),
    }
}

fn research_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let revision = snapshot.stamp().revision.get();
    let result = runtime_result!(runtime.query(&RuntimeQuery::ResearchOptions(
        ResearchOptionsRequest {
            expected_revision: revision,
        }
    )));
    let options = query_variant!(
        result,
        RuntimeQueryResult::ResearchOptions { options, .. } => options,
        "research query returns research options"
    );
    if options.active_technology().is_some() {
        return Ok(None);
    }
    Ok(options
        .options()
        .iter()
        .filter(|option| option.availability() == TechnologyAvailability::Available)
        .min_by_key(|option| (option.effective_cost(), option.technology()))
        .map(|option| {
            PlannedCommand::SelectTechnology(SelectTechnologyRequest {
                expected_revision: revision,
                technology: option.technology(),
            })
        }))
}

fn diplomacy_response(snapshot: &PlayerViewSnapshot) -> Option<PlannedCommand> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    if let Some(proposal) = snapshot
        .diplomacy()
        .proposals()
        .iter()
        .find(|proposal| proposal.to_player_id() == actor)
    {
        return Some(PlannedCommand::Diplomacy(DiplomacyRequest::Respond {
            expected_revision: revision,
            proposal_id: proposal.id().to_owned(),
            accepted: true,
        }));
    }
    snapshot
        .diplomacy()
        .messages()
        .iter()
        .find(|message| message.to_player_id() == actor && message.response().is_none())
        .map(|message| {
            PlannedCommand::Diplomacy(DiplomacyRequest::RespondMessage {
                expected_revision: revision,
                message_id: message.id().to_owned(),
                response: DiplomaticMessageResponse::Conciliatory,
            })
        })
}

fn artifact_command(snapshot: &PlayerViewSnapshot) -> Option<PlannedCommand> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    let owned_units = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() == actor)
        .collect::<Vec<_>>();
    let owned_cities = snapshot
        .cities()
        .iter()
        .filter(|city| city.owner_player_id() == actor)
        .collect::<Vec<_>>();
    for artifact in snapshot.artifacts() {
        if let PlayerArtifactLocationView::Carried(unit_id) = artifact.location()
            && let Some(unit) = owned_units.iter().find(|unit| unit.id() == unit_id)
            && let Some(city) = owned_cities.iter().find(|city| {
                city.center() == HexCoord::new(unit.col(), unit.row())
                    && !snapshot.artifacts().iter().any(|artifact| {
                        matches!(artifact.location(), PlayerArtifactLocationView::Stored(city_id) if city_id == city.id())
                    })
            })
        {
            let request = ArtifactCommandRequest::StoreInCity {
                expected_revision: revision,
                unit_id: unit_id.clone(),
                city_id: Some(city.id().clone()),
            };
            return Some(PlannedCommand::Artifact(request));
        }
    }
    for artifact in snapshot.artifacts() {
        if let PlayerArtifactLocationView::Map(coordinate) = artifact.location()
            && let Some(unit) = owned_units.iter().find(|unit| {
                HexCoord::new(unit.col(), unit.row()) == *coordinate
                    && unit.posture() == UnitPosture::Active
                    && !snapshot.artifacts().iter().any(|artifact| {
                        matches!(artifact.location(), PlayerArtifactLocationView::Carried(carrier) if carrier == unit.id())
                    })
            })
        {
            let request = ArtifactCommandRequest::StartExcavation {
                expected_revision: revision,
                unit_id: unit.id().clone(),
            };
            return Some(PlannedCommand::Artifact(request));
        }
    }
    None
}

fn founding_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && matches!(unit.kind(), UnitKind::Settler | UnitKind::Commander)
            && unit.posture() == UnitPosture::Active
    }) {
        let result = runtime_result!(optional_query(
            runtime,
            &RuntimeQuery::CityFoundingOptions(CityFoundingOptionsRequest {
                expected_revision: revision,
                founder_unit_id: unit.id().clone(),
            }),
        ));
        let result = some_or_continue!(result);
        let options = query_variant!(
            result,
            RuntimeQueryResult::CityFoundingOptions { options, .. } => options,
            "city-founding query returns city-founding options"
        );
        let controlled_hexes = some_or_continue!(complete_controlled_hexes(
            options.required_controlled_hexes(),
            options.selected_controlled_hexes(),
            options.available_controlled_hexes(),
        ));
        let request = FoundCityRequest {
            expected_revision: revision,
            founder_unit_id: unit.id().clone(),
            controlled_hexes,
        };
        return Ok(Some(PlannedCommand::FoundCity(request)));
    }
    Ok(None)
}

fn combat_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    let targets = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != actor)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != actor)
                .map(aonw_local_runtime::PlayerCityView::center),
        )
        .collect::<std::collections::BTreeSet<_>>();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && unit.movement_units() > 0
            && unit.posture() == UnitPosture::Active
    }) {
        for target in &targets {
            let query = RuntimeQuery::CombatPreview(CombatPreviewRequest {
                expected_revision: revision,
                attacker_unit_id: unit.id().clone(),
                defender: *target,
            });
            let Some(RuntimeQueryResult::CombatPreview { preview, .. }) =
                optional_query(runtime, &query)?
            else {
                continue;
            };
            let retaliation = preview.retaliation_damage.map_or(0, |(_, maximum)| maximum);
            if preview.outgoing_damage.1 >= retaliation {
                let request = AttackHexRequest {
                    expected_revision: revision,
                    attacker_unit_id: unit.id().clone(),
                    defender: *target,
                    city_conquest_action: CityConquestAction::Capture,
                };
                return Ok(Some(PlannedCommand::AttackHex(request)));
            }
        }
    }
    Ok(None)
}

fn logistics_command(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let actor = snapshot.recipient_player_id();
    let revision = snapshot.stamp().revision.get();
    for unit in snapshot.units().iter().filter(|unit| {
        unit.owner_player_id() == actor
            && unit.movement_units() > 0
            && unit.posture() == UnitPosture::Active
            && matches!(unit.kind(), UnitKind::Scout | UnitKind::Merchant)
    }) {
        let result = runtime_result!(optional_query(
            runtime,
            &RuntimeQuery::UnitLogisticsOptions(UnitLogisticsOptionsRequest {
                expected_revision: revision,
                unit_id: unit.id().clone(),
            }),
        ));
        let result = some_or_continue!(result);
        let options = query_variant!(
            result,
            RuntimeQueryResult::UnitLogisticsOptions(options) => options,
            "logistics query returns logistics options"
        );
        if unit.kind() == UnitKind::Merchant {
            if let Some(destination) = options.merchant_route_destinations.first() {
                let request = MerchantCityRequest {
                    expected_revision: revision,
                    unit_id: unit.id().clone(),
                    destination_city_id: destination.city_id.clone(),
                };
                return Ok(Some(PlannedCommand::AssignMerchantTradeRoute(request)));
            }
            if let Some(destination) = options.merchant_travel_destinations.first() {
                let request = MerchantCityRequest {
                    expected_revision: revision,
                    unit_id: unit.id().clone(),
                    destination_city_id: destination.city_id.clone(),
                };
                return Ok(Some(PlannedCommand::MoveMerchantToCity(request)));
            }
        } else if options.auto_explore.is_some() {
            let request = AutoExploreUnitRequest {
                expected_revision: revision,
                unit_id: unit.id().clone(),
            };
            return Ok(Some(PlannedCommand::AutoExploreUnit(request)));
        }
    }
    Ok(None)
}

fn merchant_pending_command(
    runtime: &mut LocalRuntime,
    revision: u64,
    unit_id: &aonw_domain::UnitId,
    route: bool,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let result = runtime_result!(runtime.query(&RuntimeQuery::UnitLogisticsOptions(
        UnitLogisticsOptionsRequest {
            expected_revision: revision,
            unit_id: unit_id.clone(),
        }
    ),));
    let options = query_variant!(
        result,
        RuntimeQueryResult::UnitLogisticsOptions(options) => options,
        "logistics query returns logistics options"
    );
    let destination = if route {
        options.merchant_route_destinations.first()
    } else {
        options.merchant_travel_destinations.first()
    };
    Ok(Some(destination.map_or_else(
        || {
            PlannedCommand::CancelUnitAction(UnitActionRequest {
                expected_revision: revision,
                unit_id: unit_id.clone(),
            })
        },
        |destination| {
            let request = MerchantCityRequest {
                expected_revision: revision,
                unit_id: unit_id.clone(),
                destination_city_id: destination.city_id.clone(),
            };
            if route {
                PlannedCommand::AssignMerchantTradeRoute(request)
            } else {
                PlannedCommand::MoveMerchantToCity(request)
            }
        },
    )))
}

fn complete_controlled_hexes(
    required: u32,
    selected: &[HexCoord],
    available: &[HexCoord],
) -> Option<Box<[HexCoord]>> {
    let required = usize::try_from(required).unwrap_or(usize::MAX);
    let mut controlled = selected.to_vec();
    controlled.extend(
        available
            .iter()
            .copied()
            .take(required.saturating_sub(controlled.len())),
    );
    (controlled.len() == required).then(|| controlled.into_boxed_slice())
}

pub(super) fn optional_query(
    runtime: &mut LocalRuntime,
    query: &RuntimeQuery,
) -> Result<Option<RuntimeQueryResult>, RuntimeError> {
    match runtime.query(query) {
        Ok(result) => Ok(Some(result)),
        Err(RuntimeError::Query(_)) => Ok(None),
        Err(error) => Err(error),
    }
}

#[cfg(test)]
mod tests {
    use aonw_domain::HexCoord;
    use aonw_domain::UnitId;
    use aonw_local_runtime::{LocalRuntime, ReachableRequest, RuntimeError, RuntimeQuery};

    use super::{complete_controlled_hexes, optional_query};

    #[test]
    fn controlled_hex_completion_is_exact_and_bounded() {
        let selected = [HexCoord::new(0, 0)];
        let available = [HexCoord::new(1, 0), HexCoord::new(2, 0)];
        assert_eq!(
            complete_controlled_hexes(2, &selected, &available).as_deref(),
            Some(
                &selected
                    .into_iter()
                    .chain([available[0]])
                    .collect::<Vec<_>>()[..]
            )
        );
        assert_eq!(complete_controlled_hexes(4, &selected, &available), None);
    }

    #[test]
    fn optional_query_only_suppresses_typed_query_rejections() {
        let mut runtime = LocalRuntime::default();
        let error = optional_query(
            &mut runtime,
            &RuntimeQuery::Reachable(ReachableRequest {
                expected_revision: 0,
                unit_id: UnitId::new("unit-1").expect("unit"),
            }),
        )
        .expect_err("closed session is not an optional query rejection");
        assert_eq!(error, RuntimeError::SessionNotOpen);
    }
}
