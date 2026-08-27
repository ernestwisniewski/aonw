use core::cmp::Ordering;

use aonw_domain::{HexCoord, MovementUnits, PlayerId, StateRevision, UnitId};
use aonw_engine::StateDigest;
use aonw_local_runtime::{
    CommandResult, LocalRuntime, MoveUnitRequest, PlayerViewSnapshot, ReachableRequest,
    RuntimeError, RuntimeQuery, RuntimeQueryResult, SessionStamp,
};

use crate::PlanFingerprint;

/// One standard public runtime command selected by a planner.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum PlannedCommand {
    /// Revision-bound manual movement selected from `Reachable` query output.
    MoveUnit(MoveUnitRequest),
}

impl PlannedCommand {
    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        match self {
            Self::MoveUnit(request) => runtime.dispatch(request),
        }
    }

    /// Returns the revision observed while this command was planned.
    #[must_use]
    pub const fn expected_revision(&self) -> u64 {
        match self {
            Self::MoveUnit(request) => request.expected_revision,
        }
    }
}

/// One deterministic command and the canonical identity it was planned from.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct BaselinePlan {
    stamp: SessionStamp,
    command: PlannedCommand,
    fingerprint: PlanFingerprint,
}

impl BaselinePlan {
    fn new(stamp: SessionStamp, recipient: &PlayerId, command: PlannedCommand) -> Self {
        let fingerprint = PlanFingerprint::for_command(stamp, recipient, &command);
        Self {
            stamp,
            command,
            fingerprint,
        }
    }

    /// Returns the canonical state digest read by the planner.
    #[must_use]
    pub const fn state_digest(&self) -> StateDigest {
        self.stamp.state_digest
    }

    /// Returns the full authoritative state/content identity read by the planner.
    #[must_use]
    pub const fn stamp(&self) -> &SessionStamp {
        &self.stamp
    }

    /// Returns the standard runtime command selected by the planner.
    #[must_use]
    pub const fn command(&self) -> &PlannedCommand {
        &self.command
    }

    /// Returns the stable identity of the state/command pair.
    #[must_use]
    pub const fn fingerprint(&self) -> PlanFingerprint {
        self.fingerprint
    }

    /// Executes the plan through the normal authoritative runtime boundary.
    ///
    /// # Errors
    ///
    /// Returns the same session or engine error as a client-issued command.
    pub fn execute(&self, runtime: &mut LocalRuntime) -> Result<CommandResult, RuntimeError> {
        self.command.execute(runtime)
    }
}

/// Result of asking the baseline planner for one command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum BaselinePlanningOutcome {
    /// One executable command was selected.
    Planned(BaselinePlan),
    /// This planner instance already produced its decision for the revision.
    AlreadyPlanned {
        /// Canonical revision already inspected by this planner instance.
        revision: StateRevision,
    },
    /// Recipient-safe state and authoritative queries exposed no legal move.
    NoLegalCommand {
        /// Canonical revision for which no legal command was found.
        revision: StateRevision,
    },
}

/// Deterministic one-command-per-revision baseline planner.
#[derive(Clone, Debug, Default)]
pub struct BaselinePlanner {
    last_planned_identity: Option<PlanningIdentity>,
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct PlanningIdentity {
    stamp: SessionStamp,
    recipient_player_id: PlayerId,
}

impl BaselinePlanner {
    /// Plans at most one normal runtime command for the current revision.
    ///
    /// Known foreign units and cities act as movement targets. Without a known
    /// target the planner uses canonical unit and coordinate ordering. All
    /// legal movement choices come from the authoritative `Reachable` query.
    ///
    /// # Errors
    ///
    /// Returns a public runtime error when the session is closed or a query
    /// cannot be evaluated.
    pub fn plan(
        &mut self,
        runtime: &mut LocalRuntime,
    ) -> Result<BaselinePlanningOutcome, RuntimeError> {
        let snapshot = runtime.snapshot()?;
        let revision = snapshot.stamp().revision;
        let identity = PlanningIdentity {
            stamp: *snapshot.stamp(),
            recipient_player_id: snapshot.recipient_player_id().clone(),
        };
        if self.last_planned_identity.as_ref() == Some(&identity) {
            return Ok(BaselinePlanningOutcome::AlreadyPlanned { revision });
        }

        let command = select_move(runtime, &snapshot)?;
        let outcome = command.map_or(
            BaselinePlanningOutcome::NoLegalCommand { revision },
            |command| {
                BaselinePlanningOutcome::Planned(BaselinePlan::new(
                    identity.stamp,
                    &identity.recipient_player_id,
                    command,
                ))
            },
        );
        self.last_planned_identity = Some(identity);
        Ok(outcome)
    }
}

#[derive(Clone, Debug, Eq, PartialEq)]
struct MoveCandidate {
    unit_id: UnitId,
    target: HexCoord,
    distance_to_known_opponent: Option<u64>,
    cost: MovementUnits,
}

fn select_move(
    runtime: &mut LocalRuntime,
    snapshot: &PlayerViewSnapshot,
) -> Result<Option<PlannedCommand>, RuntimeError> {
    let recipient = snapshot.recipient_player_id();
    let known_opponents = snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() != recipient)
        .map(|unit| HexCoord::new(unit.col(), unit.row()))
        .chain(
            snapshot
                .cities()
                .iter()
                .filter(|city| city.owner_player_id() != recipient)
                .map(aonw_local_runtime::PlayerCityView::center),
        )
        .collect::<Vec<_>>();
    let revision = snapshot.stamp().revision.get();
    let mut selected: Option<MoveCandidate> = None;

    for unit in snapshot
        .units()
        .iter()
        .filter(|unit| unit.owner_player_id() == recipient && unit.movement_units() > 0)
    {
        let origin = HexCoord::new(unit.col(), unit.row());
        let response = runtime.query(&RuntimeQuery::Reachable(ReachableRequest {
            expected_revision: revision,
            unit_id: unit.id().clone(),
        }))?;
        let RuntimeQueryResult::Reachable(reachable) = response else {
            unreachable!("reachable query returns reachable response")
        };
        for tile in reachable
            .tiles
            .iter()
            .filter(|tile| tile.coordinate != origin)
        {
            let candidate = MoveCandidate {
                unit_id: unit.id().clone(),
                target: tile.coordinate,
                distance_to_known_opponent: known_opponents
                    .iter()
                    .map(|target| tile.coordinate.distance_to(*target))
                    .min(),
                cost: tile.cost,
            };
            if selected
                .as_ref()
                .is_none_or(|current| compare_candidates(&candidate, current).is_lt())
            {
                selected = Some(candidate);
            }
        }
    }

    Ok(selected.map(|candidate| {
        PlannedCommand::MoveUnit(MoveUnitRequest {
            expected_revision: revision,
            unit_id: candidate.unit_id,
            target: candidate.target,
        })
    }))
}

fn compare_candidates(left: &MoveCandidate, right: &MoveCandidate) -> Ordering {
    left.distance_to_known_opponent
        .unwrap_or(u64::MAX)
        .cmp(&right.distance_to_known_opponent.unwrap_or(u64::MAX))
        .then_with(|| left.cost.cmp(&right.cost))
        .then_with(|| left.unit_id.cmp(&right.unit_id))
        .then_with(|| left.target.cmp(&right.target))
}
