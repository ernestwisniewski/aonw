use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{CityConquestAction, CityId, HexCoord, TroopKind, UnitId};
use aonw_engine::{
    AssignMerchantTradeRouteCommand, AttackHexCommand, AutoExploreUnitCommand,
    CommandRejectionCode, DetachTroopCommand, DomainEvent, ExecutionEvidence, FoundCityCommand,
    GameEngine, MoveMerchantToCityCommand, MoveUnitCommand, PlayerCommand,
    SelectCityExpansionHexCommand, ToggleWorkedHexCommand, UnitActionCommand,
};

mod artifact;
mod diplomacy;
mod disclosure;
mod production;
mod research;
mod view_diff;
mod worker;

pub use diplomacy::DiplomacyRequest;
pub(crate) use diplomacy::dispatch_diplomacy;
pub(crate) use disclosure::{RecipientDisclosure, visible_city_ids};
pub use production::ProductionCommandRequest;
pub(crate) use production::dispatch_production;
pub use research::SelectTechnologyRequest;
pub(crate) use research::dispatch_select_technology;
pub use view_diff::PlayerViewPatch;
pub(crate) use view_diff::{ProjectedView, diff_view};
pub(crate) use worker::{
    RuntimeWorkerCommandKind, dispatch_confirm_worker_improvement,
    dispatch_select_worker_improvement, dispatch_worker_unit,
};
pub use worker::{WorkerImprovementRequest, WorkerUnitRequest};

/// Current revision-bound visible attack.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AttackHexRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled attacking unit.
    pub attacker_unit_id: UnitId,
    /// Target coordinate.
    pub defender: HexCoord,
    /// Requested defeated-city disposition.
    pub city_conquest_action: CityConquestAction,
}

use crate::persistence::{replay_context, replay_entry};
use crate::player_view::{
    PlayerTurnLifecycleView, city_founding_draft, diplomacy_view, pending_action,
    visible_artifacts, visible_cities, visible_infrastructure, visible_units,
};
use crate::session::Session;
use crate::{RuntimeError, SessionStamp};

/// Current revision-bound manual-movement command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MoveUnitRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit to move.
    pub unit_id: UnitId,
    /// Requested target.
    pub target: HexCoord,
}

/// Current revision-bound city-founding command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct FoundCityRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled founder.
    pub founder_unit_id: UnitId,
    /// Complete initial non-center territory.
    pub controlled_hexes: Box<[HexCoord]>,
}

/// Current revision-bound manual worked-hex command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ToggleWorkedHexRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
    /// Non-center controlled coordinate.
    pub target: HexCoord,
}

/// Current revision-bound preferred-expansion command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SelectCityExpansionHexRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Controlled city.
    pub city_id: CityId,
    /// Current engine-owned candidate.
    pub target: HexCoord,
}

/// Current revision-bound map-independent unit action.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct UnitActionRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Unit receiving the action.
    pub unit_id: UnitId,
}

/// Current revision-bound scout auto-exploration command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct AutoExploreUnitRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Scout receiving the command.
    pub unit_id: UnitId,
}

/// Current revision-bound merchant destination command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct MerchantCityRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Merchant receiving the command.
    pub unit_id: UnitId,
    /// Owned destination city.
    pub destination_city_id: CityId,
}

/// Current revision-bound troop-detachment command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DetachTroopRequest {
    /// Expected canonical revision.
    pub expected_revision: u64,
    /// Source army unit.
    pub unit_id: UnitId,
    /// Troop kind to detach.
    pub troop_kind: TroopKind,
}

#[derive(Clone, Copy, Debug)]
pub(crate) enum RuntimeUnitActionKind {
    Cancel,
    Skip,
    Fortify,
}

/// Complete local result of one authoritative command dispatch.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct CommandResult {
    /// Version and authoritative identity metadata.
    pub stamp: SessionStamp,
    /// Stable rejection code, absent when accepted.
    pub rejection: Option<CommandRejectionCode>,
    /// Ordered authoritative events.
    pub events: Box<[DomainEvent]>,
    /// Exact execution evidence.
    pub evidence: Option<ExecutionEvidence>,
    /// Recipient-safe presentation delta.
    pub view_patch: PlayerViewPatch,
    pub(crate) recipient_disclosure: RecipientDisclosure,
}

impl CommandResult {
    /// Returns whether the command was accepted.
    #[must_use]
    pub const fn is_accepted(&self) -> bool {
        self.rejection.is_none()
    }
}

pub(crate) fn dispatch_found_city(
    session: &mut Session,
    command: &FoundCityRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::FoundCity(FoundCityCommand::new(
            command.expected_revision,
            &command.founder_unit_id,
            &command.controlled_hexes,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::FoundCity {
                expected_revision: command.expected_revision,
                founder_unit_id: command.founder_unit_id.as_str().to_owned(),
                controlled_hexes: command
                    .controlled_hexes
                    .iter()
                    .map(|coordinate| aonw_contracts::CoordinateDto {
                        col: coordinate.col(),
                        row: coordinate.row(),
                    })
                    .collect(),
            },
        },
    )
}

pub(crate) fn dispatch_toggle_worked_hex(
    session: &mut Session,
    command: &ToggleWorkedHexRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::ToggleWorkedHex(ToggleWorkedHexCommand::new(
            command.expected_revision,
            &command.city_id,
            command.target,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::ToggleWorkedHex {
                expected_revision: command.expected_revision,
                city_id: command.city_id.as_str().to_owned(),
                target: aonw_contracts::CoordinateDto {
                    col: command.target.col(),
                    row: command.target.row(),
                },
            },
        },
    )
}

pub(crate) fn dispatch_select_city_expansion_hex(
    session: &mut Session,
    command: &SelectCityExpansionHexRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::SelectCityExpansionHex(SelectCityExpansionHexCommand::new(
            command.expected_revision,
            &command.city_id,
            command.target,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::SelectCityExpansionHex {
                expected_revision: command.expected_revision,
                city_id: command.city_id.as_str().to_owned(),
                target: aonw_contracts::CoordinateDto {
                    col: command.target.col(),
                    row: command.target.row(),
                },
            },
        },
    )
}

pub(crate) fn dispatch_move(
    session: &mut Session,
    command: &MoveUnitRequest,
) -> Result<CommandResult, RuntimeError> {
    let replay_command = ReplayCommandDto::MoveUnit {
        expected_revision: command.expected_revision,
        unit_id: command.unit_id.as_str().to_owned(),
        target: aonw_contracts::CoordinateDto {
            col: command.target.col(),
            row: command.target.row(),
        },
    };
    dispatch_player(
        session,
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.target,
        )),
        ReplayRecordDto::Player {
            command: replay_command,
        },
    )
}

pub(crate) fn dispatch_attack(
    session: &mut Session,
    command: &AttackHexRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::AttackHex(
            AttackHexCommand::new(
                command.expected_revision,
                &command.attacker_unit_id,
                command.defender,
            )
            .with_city_conquest_action(command.city_conquest_action),
        ),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::AttackHex {
                expected_revision: command.expected_revision,
                attacker_unit_id: command.attacker_unit_id.as_str().to_owned(),
                defender: aonw_contracts::CoordinateDto {
                    col: command.defender.col(),
                    row: command.defender.row(),
                },
                city_conquest_action: match command.city_conquest_action {
                    CityConquestAction::Capture => aonw_contracts::CityConquestActionDto::Capture,
                    CityConquestAction::Destroy => aonw_contracts::CityConquestActionDto::Destroy,
                },
            },
        },
    )
}

pub(crate) fn dispatch_auto_explore(
    session: &mut Session,
    command: &AutoExploreUnitRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::AutoExploreUnit(AutoExploreUnitCommand::new(
            command.expected_revision,
            &command.unit_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::AutoExploreUnit {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        },
    )
}

pub(crate) fn dispatch_assign_merchant_route(
    session: &mut Session,
    command: &MerchantCityRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::AssignMerchantTradeRoute(AssignMerchantTradeRouteCommand::new(
            command.expected_revision,
            &command.unit_id,
            &command.destination_city_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::AssignMerchantTradeRoute {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
                destination_city_id: command.destination_city_id.as_str().to_owned(),
            },
        },
    )
}

pub(crate) fn dispatch_move_merchant_to_city(
    session: &mut Session,
    command: &MerchantCityRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::MoveMerchantToCity(MoveMerchantToCityCommand::new(
            command.expected_revision,
            &command.unit_id,
            &command.destination_city_id,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::MoveMerchantToCity {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
                destination_city_id: command.destination_city_id.as_str().to_owned(),
            },
        },
    )
}

pub(crate) fn dispatch_detach_troop(
    session: &mut Session,
    command: &DetachTroopRequest,
) -> Result<CommandResult, RuntimeError> {
    dispatch_player(
        session,
        PlayerCommand::DetachTroop(DetachTroopCommand::new(
            command.expected_revision,
            &command.unit_id,
            command.troop_kind,
        )),
        ReplayRecordDto::Player {
            command: ReplayCommandDto::DetachTroop {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
                troop_kind: aonw_contract_mapping::encode_troop(command.troop_kind),
            },
        },
    )
}

pub(crate) fn dispatch_unit_action(
    session: &mut Session,
    command: &UnitActionRequest,
    kind: RuntimeUnitActionKind,
) -> Result<CommandResult, RuntimeError> {
    let engine_command = UnitActionCommand::new(command.expected_revision, &command.unit_id);
    let (player_command, replay_command) = match kind {
        RuntimeUnitActionKind::Cancel => (
            PlayerCommand::CancelUnitAction(engine_command),
            ReplayCommandDto::CancelUnitAction {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Skip => (
            PlayerCommand::SkipUnitTurn(engine_command),
            ReplayCommandDto::SkipUnitTurn {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
        RuntimeUnitActionKind::Fortify => (
            PlayerCommand::FortifyUnit(engine_command),
            ReplayCommandDto::FortifyUnit {
                expected_revision: command.expected_revision,
                unit_id: command.unit_id.as_str().to_owned(),
            },
        ),
    };
    dispatch_player(
        session,
        player_command,
        ReplayRecordDto::Player {
            command: replay_command,
        },
    )
}

pub(crate) fn dispatch_player(
    session: &mut Session,
    command: PlayerCommand<'_>,
    replay_record: ReplayRecordDto,
) -> Result<CommandResult, RuntimeError> {
    let event_reservation =
        session.reserve_event_capacity(command.event_budget(session.state()))?;
    session.prepare_replay_segment();
    let before_context = replay_context(session, Some(session.actor()));
    let before_revision = session.state().revision().get();
    let before_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let before_diplomacy = diplomacy_view(session.state(), session.actor());
    let before_view = visible_units(session.state(), session.actor());
    let before_city_view = visible_cities(session.state(), session.actor());
    let before_artifacts = visible_artifacts(session.state(), session.actor());
    let (before_improvements, before_roads) =
        visible_infrastructure(session.state(), session.actor());
    let before_visible_city_ids = visible_city_ids(session.state(), session.actor());
    let state = session.take_state();
    let transition = GameEngine::apply_player_owned(state, session.context(), command)
        .map_err(RuntimeError::Engine)?;
    let parts = transition.into_parts();
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let events = parts.events;
    let evidence = parts.evidence;
    session.commit_event_reservation(event_reservation, events.len())?;
    session.replace_state(parts.state, parts.digest);
    let after_view = visible_units(session.state(), session.actor());
    let after_city_view = visible_cities(session.state(), session.actor());
    let after_artifacts = visible_artifacts(session.state(), session.actor());
    let (after_improvements, after_roads) =
        visible_infrastructure(session.state(), session.actor());
    let after_turn = PlayerTurnLifecycleView::new(session.state(), session.actor());
    let after_diplomacy = diplomacy_view(session.state(), session.actor());
    let after_pending = pending_action(session.state(), session.actor());
    let after_founding_draft = city_founding_draft(session.state(), session.actor());
    let recipient_disclosure = RecipientDisclosure::new(
        session.actor().clone(),
        &before_view,
        &before_visible_city_ids,
        evidence.as_ref(),
    );
    let view_patch = diff_view(
        before_revision,
        session.state().revision().get(),
        ProjectedView::new(
            before_turn,
            before_diplomacy,
            before_view,
            before_city_view,
            before_artifacts,
            before_improvements,
            before_roads,
        ),
        ProjectedView::new(
            after_turn,
            after_diplomacy,
            after_view,
            after_city_view,
            after_artifacts,
            after_improvements,
            after_roads,
        ),
        after_pending,
        after_founding_draft,
    );
    let result = CommandResult {
        stamp: session.stamp(),
        rejection,
        events,
        evidence,
        view_patch,
        recipient_disclosure,
    };
    let replay = replay_entry(session, replay_record, before_context, &result);
    session.push_replay(replay);
    Ok(result)
}
pub use artifact::ArtifactCommandRequest;
pub(crate) use artifact::dispatch_artifact;
