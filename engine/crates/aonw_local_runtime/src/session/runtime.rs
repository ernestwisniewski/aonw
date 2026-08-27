use aonw_engine::MovementSearchWorkspace;
mod artifact;
mod diplomacy;
mod research;

use crate::command_dispatch::{
    RuntimeUnitActionKind, RuntimeWorkerCommandKind, dispatch_assign_merchant_route,
    dispatch_attack, dispatch_auto_explore, dispatch_confirm_worker_improvement,
    dispatch_detach_troop, dispatch_found_city, dispatch_move, dispatch_move_merchant_to_city,
    dispatch_production, dispatch_select_city_expansion_hex, dispatch_select_worker_improvement,
    dispatch_toggle_worked_hex, dispatch_unit_action, dispatch_worker_unit,
};
use crate::player_view::PlayerViewSnapshot;
use crate::query_cache::{QueryCache, QueryCacheStats};
use crate::query_dispatch::dispatch_query;
use crate::turn_dispatch::{
    FinalizeTimedOutTurnRequest, KickParticipantRequest, RuntimeTurnKind, TurnCommandRequest,
    dispatch_kick, dispatch_timeout, dispatch_turn,
};
use crate::{
    AttackHexRequest, AutoExploreUnitRequest, CommandResult, DetachTroopRequest, FoundCityRequest,
    MerchantCityRequest, MoveUnitRequest, ProductionCommandRequest, RuntimeQuery,
    RuntimeQueryResult, SelectCityExpansionHexRequest, ToggleWorkedHexRequest, UnitActionRequest,
    WorkerImprovementRequest, WorkerUnitRequest,
};

use super::{OpenSession, OpenSessionError, RuntimeError, Session, SessionStamp};
/// Mutable owner of at most one local game session.
#[derive(Clone, Debug, Default)]
pub struct LocalRuntime {
    session: Option<Session>,
    workspace: MovementSearchWorkspace,
    query_cache: QueryCache,
}

impl LocalRuntime {
    /// Schedules a validated city-founding job.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn found_city(
        &mut self,
        command: &FoundCityRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_found_city(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Toggles one manually worked city coordinate.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn toggle_worked_hex(
        &mut self,
        command: &ToggleWorkedHexRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_toggle_worked_hex(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Selects one current territory-expansion candidate.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn select_city_expansion_hex(
        &mut self,
        command: &SelectCityExpansionHexRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_select_city_expansion_hex(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Executes one current city-production or specialization command.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn production(
        &mut self,
        command: &ProductionCommandRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_production(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Starts one explicitly selected field improvement.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn select_worker_improvement(
        &mut self,
        command: &WorkerImprovementRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_select_worker_improvement(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Confirms an explicit or matching pending field improvement.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn confirm_worker_improvement(
        &mut self,
        command: &WorkerImprovementRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_confirm_worker_improvement(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Cancels current worker construction.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn cancel_worker_job(
        &mut self,
        command: &WorkerUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_worker(command, RuntimeWorkerCommandKind::CancelJob)
    }

    /// Assigns a worker to its current improved coordinate.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn assign_worker_to_hex(
        &mut self,
        command: &WorkerUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_worker(command, RuntimeWorkerCommandKind::Assign)
    }

    /// Cancels a worker assignment.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn cancel_worker_assignment(
        &mut self,
        command: &WorkerUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_worker(command, RuntimeWorkerCommandKind::CancelAssignment)
    }

    /// Starts road construction at the current coordinate.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn build_road(
        &mut self,
        command: &WorkerUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_worker(command, RuntimeWorkerCommandKind::BuildRoad)
    }

    /// Starts or continues deterministic worker automation.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn automate_worker(
        &mut self,
        command: &WorkerUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_worker(command, RuntimeWorkerCommandKind::Automate)
    }

    /// Resolves one visible unit or city attack.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn attack_hex(
        &mut self,
        command: &AttackHexRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_attack(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Transactionally opens a new session.
    ///
    /// A failed reopen preserves the previous valid session.
    ///
    /// # Errors
    ///
    /// Returns an error when map, ruleset, scenario, or state identities differ.
    pub fn open(&mut self, request: OpenSession) -> Result<SessionStamp, OpenSessionError> {
        let candidate = Session::try_open(request)?;
        let stamp = candidate.stamp();
        self.session = Some(candidate);
        self.query_cache.clear();
        Ok(stamp)
    }

    pub(crate) fn session_ref(&self) -> Result<&Session, RuntimeError> {
        self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)
    }

    /// Closes the current session. Repeated calls are harmless.
    pub fn close(&mut self) {
        self.session = None;
        self.query_cache.clear();
    }

    /// Returns a full recipient-safe view.
    ///
    /// # Errors
    ///
    /// Returns [`RuntimeError::SessionNotOpen`] when closed.
    pub fn snapshot(&self) -> Result<PlayerViewSnapshot, RuntimeError> {
        let session = self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)?;
        Ok(session.projection().snapshot(session.stamp()))
    }

    /// Executes a versioned read-only query.
    ///
    /// # Errors
    ///
    /// Returns a stable query rejection or session error.
    pub fn query(&mut self, request: &RuntimeQuery) -> Result<RuntimeQueryResult, RuntimeError> {
        let stamp = self
            .session
            .as_ref()
            .ok_or(RuntimeError::SessionNotOpen)?
            .stamp();
        if let Some(result) = self.query_cache.get(stamp, request) {
            return Ok(result);
        }
        let session = self.session.as_ref().ok_or(RuntimeError::SessionNotOpen)?;
        let result = dispatch_query(session, request.clone(), &mut self.workspace)?;
        self.query_cache.insert(stamp, request, &result);
        Ok(result)
    }

    /// Executes independent queries while reusing runtime caches and buffers.
    pub fn query_batch(
        &mut self,
        requests: &[RuntimeQuery],
    ) -> Vec<Result<RuntimeQueryResult, RuntimeError>> {
        requests.iter().map(|request| self.query(request)).collect()
    }

    /// Returns diagnostic query-cache counters.
    #[must_use]
    pub const fn query_cache_stats(&self) -> QueryCacheStats {
        self.query_cache.stats()
    }

    /// Dispatches one revision-bound manual movement command.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error. Domain rejections are
    /// successful typed results with a rejection code.
    pub fn dispatch(&mut self, command: &MoveUnitRequest) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_move(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Starts or continues deterministic scout auto-exploration.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn auto_explore_unit(
        &mut self,
        command: &AutoExploreUnitRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_auto_explore(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Assigns a cyclic route to one merchant.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn assign_merchant_trade_route(
        &mut self,
        command: &MerchantCityRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_assign_merchant_route(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Queues explicit merchant travel to one owned city.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn move_merchant_to_city(
        &mut self,
        command: &MerchantCityRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_move_merchant_to_city(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Detaches one troop into an engine-selected adjacent tile.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn detach_troop(
        &mut self,
        command: &DetachTroopRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_detach_troop(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Clears cancellable orders owned by one controlled unit.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn cancel_unit_action(
        &mut self,
        command: &UnitActionRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_unit_action(command, RuntimeUnitActionKind::Cancel)
    }

    /// Consumes one controlled unit's movement for the current turn.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn skip_unit_turn(
        &mut self,
        command: &UnitActionRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_unit_action(command, RuntimeUnitActionKind::Skip)
    }

    /// Fortifies one idle controlled unit.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn fortify_unit(
        &mut self,
        command: &UnitActionRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_unit_action(command, RuntimeUnitActionKind::Fortify)
    }

    /// Completes the local actor's sequential turn through the partial T1 kernel.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn end_turn(&mut self, command: TurnCommandRequest) -> Result<CommandResult, RuntimeError> {
        self.dispatch_turn(command, RuntimeTurnKind::End)
    }

    /// Submits the local actor's simultaneous turn through the partial T1 kernel.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn submit_turn(
        &mut self,
        command: TurnCommandRequest,
    ) -> Result<CommandResult, RuntimeError> {
        self.dispatch_turn(command, RuntimeTurnKind::Submit)
    }

    /// Finalizes an expired turn through the trusted host-only boundary.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn finalize_timed_out_turn(
        &mut self,
        command: &FinalizeTimedOutTurnRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_timeout(session, command)
        };
        self.complete_dispatch(result)
    }

    /// Removes a participant through the trusted host-only boundary.
    ///
    /// # Errors
    ///
    /// Returns an internal transition or session error.
    pub fn kick_participant(
        &mut self,
        command: &KickParticipantRequest,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_kick(session, command)
        };
        self.complete_dispatch(result)
    }

    fn dispatch_turn(
        &mut self,
        command: TurnCommandRequest,
        kind: RuntimeTurnKind,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_turn(session, command, kind)
        };
        self.complete_dispatch(result)
    }

    fn dispatch_unit_action(
        &mut self,
        command: &UnitActionRequest,
        kind: RuntimeUnitActionKind,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_unit_action(session, command, kind)
        };
        self.complete_dispatch(result)
    }

    fn dispatch_worker(
        &mut self,
        command: &WorkerUnitRequest,
        kind: RuntimeWorkerCommandKind,
    ) -> Result<CommandResult, RuntimeError> {
        let result = {
            let session = self.session.as_mut().ok_or(RuntimeError::SessionNotOpen)?;
            dispatch_worker_unit(session, command, kind)
        };
        self.complete_dispatch(result)
    }

    fn complete_dispatch(
        &mut self,
        result: Result<CommandResult, RuntimeError>,
    ) -> Result<CommandResult, RuntimeError> {
        if self
            .session
            .as_ref()
            .is_some_and(|session| !session.is_valid())
        {
            self.session = None;
        }
        result
    }
}
