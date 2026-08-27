use aonw_content::{ContentHash, MapDefinition, RulesetDefinition};
use aonw_domain::{GameState, PlayerId, StateRevision};
use aonw_engine::{
    EngineContext, EventBudget, GameEngine, MovementVisibility, StateDigest, SystemContext,
};
use std::sync::Arc;

use crate::command_dispatch::ProjectedView;
use crate::persistence::ReplayRecorder;
use crate::prepared_world::PreparedWorld;

use super::{OpenSession, OpenSessionError, RuntimeError};

/// Identity metadata carried by every session response.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct SessionStamp {
    /// Canonical state revision.
    pub revision: StateRevision,
    /// Canonical state digest.
    pub state_digest: StateDigest,
    /// Validated map hash.
    pub map_hash: ContentHash,
    /// Validated ruleset hash.
    pub ruleset_hash: ContentHash,
}

#[derive(Clone, Debug)]
pub(crate) struct Session {
    world: PreparedWorld,
    state: Option<GameState>,
    actor: Arc<PlayerId>,
    state_digest: StateDigest,
    visibility: MovementVisibility,
    event_offset: u64,
    replay: ReplayRecorder,
    projection: ProjectedView,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub(crate) struct EventReservation {
    initial_offset: u64,
    budget: EventBudget,
}

impl EventReservation {
    fn try_new(initial_offset: u64, budget: EventBudget) -> Result<Self, RuntimeError> {
        initial_offset
            .checked_add(budget.maximum())
            .ok_or(RuntimeError::EventOffsetOverflow)?;
        Ok(Self {
            initial_offset,
            budget,
        })
    }

    fn committed_offset(self, actual: usize) -> Result<u64, RuntimeError> {
        let actual = u64::try_from(actual).map_err(|_| RuntimeError::EventBudgetExceeded {
            maximum: self.budget.maximum(),
            actual: u64::MAX,
        })?;
        if !self.budget.accepts(actual) {
            return Err(RuntimeError::EventBudgetExceeded {
                maximum: self.budget.maximum(),
                actual,
            });
        }
        self.initial_offset
            .checked_add(actual)
            .ok_or(RuntimeError::EventOffsetOverflow)
    }
}

impl Session {
    pub(super) fn try_open(request: OpenSession) -> Result<Self, OpenSessionError> {
        let world = PreparedWorld::try_new(request.map, request.ruleset, &request.state)?;
        let actor = Arc::new(request.actor);
        let state_digest = GameEngine::state_digest(&request.state);
        let visibility =
            MovementVisibility::for_player(&request.state, world.map(), actor.as_ref());
        let replay = ReplayRecorder::new(&request.state, state_digest, request.event_offset);
        let projection = ProjectedView::for_recipient(&request.state, actor.clone());
        Ok(Self {
            world,
            state: Some(request.state),
            actor,
            state_digest,
            visibility,
            event_offset: request.event_offset,
            replay,
            projection,
        })
    }

    pub(crate) const fn state(&self) -> &GameState {
        self.state.as_ref().expect("open session owns state")
    }

    pub(crate) fn actor(&self) -> &PlayerId {
        self.actor.as_ref()
    }

    pub(crate) fn shared_actor(&self) -> Arc<PlayerId> {
        self.actor.clone()
    }

    pub(crate) fn handoff_actor(&mut self, actor: PlayerId) {
        let actor = Arc::new(actor);
        self.visibility =
            MovementVisibility::for_player(self.state(), self.world.map(), actor.as_ref());
        self.projection = ProjectedView::for_recipient(self.state(), actor.clone());
        self.actor = actor;
    }

    pub(crate) const fn map(&self) -> &MapDefinition {
        self.world.map()
    }

    pub(crate) const fn ruleset(&self) -> &RulesetDefinition {
        self.world.ruleset()
    }

    pub(crate) const fn event_offset(&self) -> u64 {
        self.event_offset
    }

    pub(crate) fn reserve_event_capacity(
        &self,
        budget: EventBudget,
    ) -> Result<EventReservation, RuntimeError> {
        EventReservation::try_new(self.event_offset, budget)
    }

    pub(crate) fn commit_event_reservation(
        &mut self,
        reservation: EventReservation,
        actual: usize,
    ) -> Result<(), RuntimeError> {
        debug_assert_eq!(reservation.initial_offset, self.event_offset);
        self.event_offset = reservation.committed_offset(actual)?;
        Ok(())
    }

    pub(crate) const fn replay(&self) -> &ReplayRecorder {
        &self.replay
    }

    pub(crate) const fn projection(&self) -> &ProjectedView {
        &self.projection
    }

    pub(crate) fn prepare_replay_segment(&mut self) {
        if self.replay.is_full() {
            let checkpoint =
                ReplayRecorder::checkpoint(self.state(), self.state_digest, self.event_offset);
            self.replay.rollover(checkpoint);
        }
    }

    pub(crate) fn push_replay(&mut self, entry: aonw_contracts::ReplayEntryDto) {
        self.replay.push(entry);
    }

    pub(crate) fn context(&self) -> EngineContext<'_> {
        EngineContext::canonical(self.actor(), self.world.map(), self.world.ruleset())
            .with_compiled_movement_map(self.world.movement_map())
            .with_movement_visibility(&self.visibility)
    }

    pub(crate) fn system_context(&self) -> SystemContext<'_> {
        SystemContext::canonical(self.world.map(), self.world.ruleset())
    }

    pub(crate) fn replace_state(
        &mut self,
        state: GameState,
        state_digest: StateDigest,
        projection: ProjectedView,
    ) {
        self.state_digest = state_digest;
        self.visibility =
            MovementVisibility::for_player(&state, self.world.map(), self.actor.as_ref());
        self.state = Some(state);
        self.projection = projection;
    }

    pub(crate) fn restore_rejected_state(&mut self, state: GameState) {
        self.state = Some(state);
    }

    pub(crate) fn take_state(&mut self) -> GameState {
        self.state.take().expect("open session owns state")
    }

    pub(crate) const fn is_valid(&self) -> bool {
        self.state.is_some()
    }

    pub(crate) fn stamp(&self) -> SessionStamp {
        SessionStamp {
            revision: self.state().revision(),
            state_digest: self.state_digest,
            map_hash: self.world.map_hash(),
            ruleset_hash: self.world.ruleset_hash(),
        }
    }
}

#[cfg(test)]
mod tests {
    use aonw_engine::{EventBudget, MoveUnitCommand, PlayerCommand};

    use super::EventReservation;
    use crate::RuntimeError;

    fn movement_budget() -> EventBudget {
        let unit_id = aonw_domain::UnitId::new("unit-1").expect("unit id");
        PlayerCommand::MoveUnit(MoveUnitCommand::new(
            0,
            &unit_id,
            aonw_domain::HexCoord::new(1, 0),
        ))
        .event_budget(
            &aonw_domain::GameState::try_new(
                aonw_domain::StateRevision::INITIAL,
                1,
                aonw_domain::HexGridBounds::new(1, 1).expect("bounds"),
                aonw_domain::UnitOccupancyPolicy::Exclusive,
                [],
            )
            .expect("state"),
        )
    }

    #[test]
    fn reservation_preflights_offset_and_enforces_actual_count() {
        let budget = movement_budget();
        assert_eq!(
            EventReservation::try_new(u64::MAX, budget),
            Err(RuntimeError::EventOffsetOverflow)
        );

        let reservation = EventReservation::try_new(7, budget).expect("reserve");
        assert_eq!(reservation.committed_offset(1), Ok(8));

        let reservation = EventReservation::try_new(7, budget).expect("reserve");
        assert_eq!(
            reservation.committed_offset(2),
            Err(RuntimeError::EventBudgetExceeded {
                maximum: 1,
                actual: 2,
            })
        );

        let reservation = EventReservation::try_new(7, EventBudget::new(3)).expect("reserve");
        assert_eq!(reservation.committed_offset(2), Ok(9));
    }
}
