//! Stateless authoritative host operations for the multiplayer protocol.

#![forbid(unsafe_code)]

use std::sync::Arc;

use aonw_content::{MapDefinition, MapDocument, RulesetDefinition, ScenarioDefinition};
use aonw_contract_mapping::{
    decode_game_state, decode_match_identity, encode_client_event, encode_client_evidence,
    encode_client_stamp, encode_command_rejection, encode_game_state, encode_player_view_patch,
    encode_player_view_snapshot, encode_recipient_evidence,
};
use aonw_contracts::server::{
    CreateServerMatchRequestDto, PrepareServerWorldRequestDto, ProjectServerStateRequestDto,
    SERVER_HOST_API_VERSION, ServerCommandResultDto, ServerCreatedMatchDto, ServerHostErrorCodeDto,
    ServerProjectionResultDto, ServerRecipientOutcomeDto, ServerRecipientSnapshotDto,
    SubmitTurnServerRequestDto,
};
use aonw_domain::{GameMode, GameState, PlayerId};
use aonw_engine::{
    CanonicalEngineError, CommandRejectionCode, CompiledMovementMap, CompiledMovementMapError,
    DomainEvent, EngineContext, ExecutionEvidence, GameEngine, MovementVisibility, PlayerCommand,
    TurnCommand, start_match,
};
use aonw_projection::{
    PlayerViewPatch, PlayerViewSnapshot, ProjectedView, RecipientDisclosure, SessionStamp,
    diff_view, unchanged_view,
};

/// Immutable map and rules compiled once and shared across server commands.
///
/// This value contains no match state. A Serverpod host may safely cache it by
/// map/ruleset identity and clone the handle for concurrent transactions.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct PreparedServerWorld {
    compiled: Arc<CompiledMovementMap>,
}

impl PreparedServerWorld {
    /// Validates immutable content and prepares all reusable movement data.
    ///
    /// # Errors
    ///
    /// Returns an error when immutable content identity cannot be computed.
    pub fn try_new(
        map: MapDefinition,
        ruleset: RulesetDefinition,
    ) -> Result<Self, CompiledMovementMapError> {
        CompiledMovementMap::compile_owned(map, ruleset).map(|compiled| Self {
            compiled: Arc::new(compiled),
        })
    }

    /// Returns the exact immutable map identity.
    #[must_use]
    pub fn map_hash(&self) -> aonw_content::ContentHash {
        self.compiled.map_hash()
    }

    /// Returns the exact immutable ruleset identity.
    #[must_use]
    pub fn ruleset_hash(&self) -> aonw_content::ContentHash {
        self.compiled.ruleset_hash()
    }

    fn compiled(&self) -> &CompiledMovementMap {
        &self.compiled
    }
}

/// Failure while validating or mapping the strict current server DTO boundary.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ServerBoundaryError {
    /// The independently deployed caller uses another API version.
    UnsupportedApiVersion {
        /// Version supplied by the caller.
        actual: u16,
    },
    /// The strict authored map document could not be decoded.
    InvalidMapDocument(String),
    /// The strict authored scenario document could not be decoded.
    InvalidScenarioDocument(String),
    /// Immutable match identity violated a current domain invariant.
    InvalidMatchIdentity(String),
    /// A server-created match selected a non-multiplayer mode.
    UnsupportedGameMode,
    /// Scenario state and immutable identity could not form a valid match.
    MatchStartFailed(String),
    /// The request selected an unreviewed immutable ruleset.
    UnsupportedRuleset(String),
    /// Match content hashes do not match the prepared immutable world.
    ContentIdentityMismatch,
    /// The canonical state DTO violated a domain invariant.
    InvalidCanonicalState(String),
    /// The authenticated actor identifier was invalid.
    InvalidAuthenticatedActor(String),
    /// Stateless authoritative execution failed before persistence.
    Host(ServerHostError),
}

impl ServerBoundaryError {
    /// Returns the stable current host error code for this failure.
    #[must_use]
    pub const fn code(&self) -> ServerHostErrorCodeDto {
        match self {
            Self::UnsupportedApiVersion { .. } => ServerHostErrorCodeDto::UnsupportedApiVersion,
            Self::InvalidMapDocument(_) => ServerHostErrorCodeDto::InvalidMapDocument,
            Self::InvalidScenarioDocument(_) => ServerHostErrorCodeDto::InvalidScenarioDocument,
            Self::InvalidMatchIdentity(_) => ServerHostErrorCodeDto::InvalidMatchIdentity,
            Self::UnsupportedGameMode => ServerHostErrorCodeDto::UnsupportedGameMode,
            Self::MatchStartFailed(_) => ServerHostErrorCodeDto::MatchStartFailed,
            Self::UnsupportedRuleset(_) => ServerHostErrorCodeDto::UnsupportedRuleset,
            Self::ContentIdentityMismatch => ServerHostErrorCodeDto::ContentIdentityMismatch,
            Self::InvalidCanonicalState(_) => ServerHostErrorCodeDto::InvalidCanonicalState,
            Self::InvalidAuthenticatedActor(_) => ServerHostErrorCodeDto::InvalidAuthenticatedActor,
            Self::Host(error) => match error {
                ServerHostError::EmptyParticipants => ServerHostErrorCodeDto::EmptyParticipants,
                ServerHostError::UnknownAuthenticatedActor(_) => {
                    ServerHostErrorCodeDto::UnknownAuthenticatedActor
                }
                ServerHostError::MapBoundsMismatch => ServerHostErrorCodeDto::MapBoundsMismatch,
                ServerHostError::OccupancyPolicyMismatch => {
                    ServerHostErrorCodeDto::OccupancyPolicyMismatch
                }
                ServerHostError::EventOffsetOverflow => ServerHostErrorCodeDto::EventOffsetOverflow,
                ServerHostError::EventBudgetExceeded { .. } => {
                    ServerHostErrorCodeDto::EventBudgetExceeded
                }
                ServerHostError::CompiledMovementMap(_) | ServerHostError::Engine(_) => {
                    ServerHostErrorCodeDto::EngineFailure
                }
            },
        }
    }
}

impl core::fmt::Display for ServerBoundaryError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::UnsupportedApiVersion { actual } => write!(
                formatter,
                "unsupported server host API version {actual}; expected {SERVER_HOST_API_VERSION}"
            ),
            Self::InvalidMapDocument(message) => {
                write!(formatter, "invalid map document: {message}")
            }
            Self::InvalidScenarioDocument(message) => {
                write!(formatter, "invalid scenario document: {message}")
            }
            Self::InvalidMatchIdentity(message) => {
                write!(formatter, "invalid match identity: {message}")
            }
            Self::UnsupportedGameMode => {
                formatter.write_str("server match identity must use multiplayer mode")
            }
            Self::MatchStartFailed(message) => {
                write!(formatter, "match start failed: {message}")
            }
            Self::UnsupportedRuleset(id) => write!(formatter, "unsupported ruleset `{id}`"),
            Self::ContentIdentityMismatch => {
                formatter.write_str("match content identity does not match prepared world")
            }
            Self::InvalidCanonicalState(message) => {
                write!(formatter, "invalid canonical state: {message}")
            }
            Self::InvalidAuthenticatedActor(message) => {
                write!(formatter, "invalid authenticated actor: {message}")
            }
            Self::Host(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerBoundaryError {}

/// Validates strict immutable content and prepares reusable server world data.
///
/// # Errors
///
/// Returns an error for another API version, invalid current map content, an
/// unsupported ruleset, or immutable movement compilation failure.
pub fn prepare_server_world(
    request: PrepareServerWorldRequestDto,
) -> Result<PreparedServerWorld, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    let ruleset = RulesetDefinition::standard();
    if request.ruleset_id != ruleset.ruleset_id() {
        return Err(ServerBoundaryError::UnsupportedRuleset(request.ruleset_id));
    }
    let document = MapDocument::from_json(request.map_document.as_bytes())
        .map_err(|error| ServerBoundaryError::InvalidMapDocument(error.to_string()))?;
    PreparedServerWorld::try_new(document.map().clone(), ruleset.clone())
        .map_err(|error| ServerBoundaryError::Host(ServerHostError::CompiledMovementMap(error)))
}

/// Applies one strict current DTO request and maps the all-or-nothing result.
///
/// # Errors
///
/// Returns an error before persistence for invalid identity, canonical state,
/// authenticated ownership, offset capacity, or engine failure.
pub fn apply_submit_turn_dto(
    world: PreparedServerWorld,
    request: SubmitTurnServerRequestDto,
) -> Result<ServerCommandResultDto, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    validate_content_identity(&world, &request.map_hash, &request.ruleset_hash)?;
    let actor = PlayerId::new(request.authenticated_actor_player_id)
        .map_err(|error| ServerBoundaryError::InvalidAuthenticatedActor(error.to_string()))?;
    let state = decode_game_state(request.state)
        .map_err(|error| ServerBoundaryError::InvalidCanonicalState(error.to_string()))?;
    let outcome = apply_submit_turn(SubmitTurnRequest {
        state,
        world,
        authenticated_actor: actor,
        expected_revision: request.expected_revision,
        initial_event_offset: request.initial_event_offset,
    })
    .map_err(ServerBoundaryError::Host)?;
    Ok(encode_server_command_result(&outcome))
}

/// Validates and projects a strict current canonical state for every participant.
///
/// This is used when a match is created so the database can store only
/// recipient-safe initial snapshots for reconnect and resynchronization.
///
/// # Errors
///
/// Returns an error for another API version, mismatched immutable identity, an
/// invalid canonical state, or state/content invariant mismatch.
pub fn project_server_state_dto(
    world: PreparedServerWorld,
    request: ProjectServerStateRequestDto,
) -> Result<ServerProjectionResultDto, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    validate_content_identity(&world, &request.map_hash, &request.ruleset_hash)?;
    let state = decode_game_state(request.state)
        .map_err(|error| ServerBoundaryError::InvalidCanonicalState(error.to_string()))?;
    project_server_state(&world, &state)
}

/// Constructs one new multiplayer match from authored content and immutable identity.
///
/// # Errors
///
/// Returns an error for invalid current content, another API version, a
/// non-multiplayer identity, or a state that cannot satisfy engine invariants.
pub fn create_server_match_dto(
    world: PreparedServerWorld,
    request: CreateServerMatchRequestDto,
) -> Result<ServerCreatedMatchDto, ServerBoundaryError> {
    require_api_version(request.api_version)?;
    validate_content_identity(&world, &request.map_hash, &request.ruleset_hash)?;
    let compiled = world.compiled();
    let scenario = ScenarioDefinition::from_json(
        request.scenario_document.as_bytes(),
        compiled.map(),
        compiled.ruleset(),
    )
    .map_err(|error| ServerBoundaryError::InvalidScenarioDocument(error.to_string()))?;
    let identity = decode_match_identity(request.match_identity)
        .map_err(|error| ServerBoundaryError::InvalidMatchIdentity(error.to_string()))?;
    if identity.game_mode() != GameMode::Multiplayer {
        return Err(ServerBoundaryError::UnsupportedGameMode);
    }
    let seed = scenario
        .bootstrap(compiled.map(), compiled.ruleset())
        .map_err(|error| ServerBoundaryError::InvalidScenarioDocument(error.to_string()))?;
    let state = start_match(seed, compiled.map(), identity, request.fog_enabled)
        .map_err(|error| ServerBoundaryError::MatchStartFailed(error.to_string()))?;
    let projection = project_server_state(&world, &state)?;
    Ok(ServerCreatedMatchDto {
        state: encode_game_state(&state),
        projection,
    })
}

fn project_server_state(
    world: &PreparedServerWorld,
    state: &GameState,
) -> Result<ServerProjectionResultDto, ServerBoundaryError> {
    validate_state(state, world).map_err(ServerBoundaryError::Host)?;
    let stamp = SessionStamp {
        revision: state.revision(),
        state_digest: GameEngine::state_digest(state),
        map_hash: world.map_hash(),
        ruleset_hash: world.ruleset_hash(),
    };
    let recipients = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(|participant| {
            let recipient = participant.id().clone();
            let snapshot =
                ProjectedView::for_recipient(state, Arc::new(recipient.clone())).snapshot(stamp);
            ServerRecipientSnapshotDto {
                recipient_player_id: recipient.as_str().to_owned(),
                snapshot: encode_player_view_snapshot(&snapshot),
            }
        })
        .collect();
    Ok(ServerProjectionResultDto {
        stamp: encode_client_stamp(stamp),
        recipients,
    })
}

fn require_api_version(actual: u16) -> Result<(), ServerBoundaryError> {
    if actual == SERVER_HOST_API_VERSION {
        Ok(())
    } else {
        Err(ServerBoundaryError::UnsupportedApiVersion { actual })
    }
}

fn validate_content_identity(
    world: &PreparedServerWorld,
    map_hash: &str,
    ruleset_hash: &str,
) -> Result<(), ServerBoundaryError> {
    if map_hash == world.map_hash().to_string() && ruleset_hash == world.ruleset_hash().to_string()
    {
        Ok(())
    } else {
        Err(ServerBoundaryError::ContentIdentityMismatch)
    }
}

fn encode_server_command_result(outcome: &ServerCommandOutcome) -> ServerCommandResultDto {
    ServerCommandResultDto {
        state: encode_game_state(&outcome.state),
        rejection: outcome.rejection.map(encode_command_rejection),
        events: outcome.events.iter().map(encode_client_event).collect(),
        evidence: outcome.evidence.as_ref().map(encode_client_evidence),
        stamp: encode_client_stamp(outcome.stamp),
        initial_event_offset: outcome.initial_event_offset,
        final_event_offset: outcome.final_event_offset,
        recipients: outcome
            .recipients
            .iter()
            .map(|recipient| ServerRecipientOutcomeDto {
                recipient_player_id: recipient.recipient_player_id.as_str().to_owned(),
                snapshot: encode_player_view_snapshot(&recipient.snapshot),
                patch: encode_player_view_patch(&recipient.patch),
                events: recipient.events.iter().map(encode_client_event).collect(),
                evidence: outcome.evidence.as_ref().and_then(|evidence| {
                    encode_recipient_evidence(evidence, &recipient.disclosure)
                }),
            })
            .collect(),
    }
}

/// Complete trusted input for one authenticated simultaneous-turn submission.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct SubmitTurnRequest {
    /// Canonical state locked by the server transaction.
    pub state: GameState,
    /// Immutable map and rules prepared outside the match transaction.
    pub world: PreparedServerWorld,
    /// Player identity derived from the authenticated server session.
    pub authenticated_actor: PlayerId,
    /// Revision supplied by the remote command.
    pub expected_revision: u64,
    /// Durable offset immediately before this command.
    pub initial_event_offset: u64,
}

/// Recipient-safe output ready for persistence and delivery by the server.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RecipientOutcome {
    /// Recipient derived from canonical match participants.
    pub recipient_player_id: PlayerId,
    /// Complete post-command view used by reconnect and resynchronization.
    pub snapshot: PlayerViewSnapshot,
    /// Delta from the request state to the returned state.
    pub patch: PlayerViewPatch,
    /// Ordered events safe to disclose to this recipient.
    pub events: Box<[DomainEvent]>,
    disclosure: RecipientDisclosure,
}

/// All-or-nothing result returned to the transactional Serverpod boundary.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ServerCommandOutcome {
    /// Unchanged rejected state or accepted next canonical state.
    pub state: GameState,
    /// Stable player-facing rejection, absent for an accepted command.
    pub rejection: Option<CommandRejectionCode>,
    /// Full authoritative events for server-side persistence.
    pub events: Box<[DomainEvent]>,
    /// Full execution evidence for server-side persistence and diagnostics.
    pub evidence: Option<ExecutionEvidence>,
    /// Canonical identity and immutable-content hashes.
    pub stamp: SessionStamp,
    /// Durable offset immediately before the command.
    pub initial_event_offset: u64,
    /// Durable offset immediately after the command.
    pub final_event_offset: u64,
    /// Projection, patch, and filtered events for every canonical participant.
    pub recipients: Box<[RecipientOutcome]>,
}

/// Failure before an outcome can be safely persisted.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ServerHostError {
    /// Canonical multiplayer state has no participants.
    EmptyParticipants,
    /// The authenticated account does not own a participant in this match.
    UnknownAuthenticatedActor(PlayerId),
    /// Canonical state bounds do not match immutable map content.
    MapBoundsMismatch,
    /// Canonical occupancy policy does not match immutable rules.
    OccupancyPolicyMismatch,
    /// The maximum possible event range cannot fit in the durable offset.
    EventOffsetOverflow,
    /// The engine emitted more events than the reviewed command budget permits.
    EventBudgetExceeded {
        /// Reviewed maximum for this command and state.
        maximum: u64,
        /// Actual event count returned by the engine.
        actual: u64,
    },
    /// Immutable movement content could not be prepared.
    CompiledMovementMap(CompiledMovementMapError),
    /// The engine encountered corrupt canonical state or content.
    Engine(CanonicalEngineError),
}

impl core::fmt::Display for ServerHostError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::EmptyParticipants => formatter.write_str("match has no participants"),
            Self::UnknownAuthenticatedActor(actor) => {
                write!(
                    formatter,
                    "authenticated actor `{actor}` is not a participant"
                )
            }
            Self::MapBoundsMismatch => {
                formatter.write_str("canonical state and map bounds do not match")
            }
            Self::OccupancyPolicyMismatch => {
                formatter.write_str("canonical state and rules occupancy do not match")
            }
            Self::EventOffsetOverflow => formatter.write_str("event offset overflow"),
            Self::EventBudgetExceeded { maximum, actual } => write!(
                formatter,
                "event budget exceeded: maximum {maximum}, actual {actual}"
            ),
            Self::CompiledMovementMap(source) => source.fmt(formatter),
            Self::Engine(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for ServerHostError {}

/// Applies one authenticated `SubmitTurn` without retaining process-local session state.
///
/// The caller must hold the match transaction and persist the returned state, offsets,
/// and recipient outputs atomically. An error means that nothing may be persisted.
///
/// # Errors
///
/// Returns an error for inconsistent trusted inputs, offset overflow, invalid immutable
/// content, or an internal engine failure.
pub fn apply_submit_turn(
    request: SubmitTurnRequest,
) -> Result<ServerCommandOutcome, ServerHostError> {
    validate_request(&request)?;
    let SubmitTurnRequest {
        state,
        world,
        authenticated_actor,
        expected_revision,
        initial_event_offset,
    } = request;
    let command =
        PlayerCommand::SubmitTurn(TurnCommand::new(expected_revision, &authenticated_actor));
    let budget = command.event_budget(&state);
    initial_event_offset
        .checked_add(budget.maximum())
        .ok_or(ServerHostError::EventOffsetOverflow)?;

    let compiled = world.compiled();
    let visibility = MovementVisibility::for_player(&state, compiled.map(), &authenticated_actor);
    let before_digest = GameEngine::state_digest(&state);
    let before_revision = state.revision().get();
    let before_views = state
        .match_lifecycle()
        .identity()
        .participants()
        .iter()
        .map(|participant| {
            let recipient = Arc::new(participant.id().clone());
            let view = ProjectedView::for_recipient(&state, recipient);
            (participant.id().clone(), view)
        })
        .collect::<Vec<_>>();

    let context =
        EngineContext::canonical(&authenticated_actor, compiled.map(), compiled.ruleset())
            .with_compiled_movement_map(&compiled)
            .with_movement_visibility(&visibility);
    let parts = GameEngine::apply_player_owned(state, context, command)
        .map_err(ServerHostError::Engine)?
        .into_parts();
    let final_event_offset =
        checked_final_event_offset(initial_event_offset, budget, parts.events.len())?;
    let rejection = parts.rejection.map(aonw_engine::DomainRejection::code);
    let accepted = rejection.is_none();
    let state_digest = parts.digest.unwrap_or(before_digest);
    let stamp = SessionStamp {
        revision: parts.state.revision(),
        state_digest,
        map_hash: parts.map_hash,
        ruleset_hash: parts.ruleset_hash,
    };
    let recipients = before_views
        .into_iter()
        .map(|(recipient, before)| {
            recipient_outcome(
                recipient,
                &before,
                &parts.state,
                &parts.events,
                parts.evidence.as_ref(),
                accepted,
                before_revision,
                stamp,
            )
        })
        .collect::<Vec<_>>()
        .into_boxed_slice();

    Ok(ServerCommandOutcome {
        state: parts.state,
        rejection,
        events: parts.events,
        evidence: parts.evidence,
        stamp,
        initial_event_offset,
        final_event_offset,
        recipients,
    })
}

fn validate_request(request: &SubmitTurnRequest) -> Result<(), ServerHostError> {
    validate_state(&request.state, &request.world)?;
    let identity = request.state.match_lifecycle().identity();
    if !identity.contains(&request.authenticated_actor) {
        return Err(ServerHostError::UnknownAuthenticatedActor(
            request.authenticated_actor.clone(),
        ));
    }
    Ok(())
}

fn validate_state(state: &GameState, world: &PreparedServerWorld) -> Result<(), ServerHostError> {
    if state.match_lifecycle().identity().participants().is_empty() {
        return Err(ServerHostError::EmptyParticipants);
    }
    if state.bounds() != world.compiled().bounds() {
        return Err(ServerHostError::MapBoundsMismatch);
    }
    if state.occupancy_policy() != world.compiled().ruleset().occupancy_policy() {
        return Err(ServerHostError::OccupancyPolicyMismatch);
    }
    Ok(())
}

fn checked_final_event_offset(
    initial: u64,
    budget: aonw_engine::EventBudget,
    actual: usize,
) -> Result<u64, ServerHostError> {
    let actual = u64::try_from(actual).map_err(|_| ServerHostError::EventBudgetExceeded {
        maximum: budget.maximum(),
        actual: u64::MAX,
    })?;
    if !budget.accepts(actual) {
        return Err(ServerHostError::EventBudgetExceeded {
            maximum: budget.maximum(),
            actual,
        });
    }
    initial
        .checked_add(actual)
        .ok_or(ServerHostError::EventOffsetOverflow)
}

#[allow(clippy::too_many_arguments)]
fn recipient_outcome(
    recipient: PlayerId,
    before: &ProjectedView,
    state: &GameState,
    events: &[DomainEvent],
    evidence: Option<&ExecutionEvidence>,
    accepted: bool,
    before_revision: u64,
    stamp: SessionStamp,
) -> RecipientOutcome {
    let disclosure = if accepted {
        RecipientDisclosure::new(recipient.clone(), before.units(), before.cities(), evidence)
    } else {
        RecipientDisclosure::empty(recipient.clone())
    };
    let after = accepted.then(|| ProjectedView::for_recipient(state, Arc::new(recipient.clone())));
    let patch = after.as_ref().map_or_else(
        || unchanged_view(before_revision, before),
        |after| diff_view(before_revision, state.revision().get(), before, after),
    );
    let snapshot = after.as_ref().unwrap_or(before).snapshot(stamp);
    let events = events
        .iter()
        .filter(|event| disclosure.allows_event(event))
        .cloned()
        .collect();
    RecipientOutcome {
        recipient_player_id: recipient,
        snapshot,
        patch,
        events,
        disclosure,
    }
}
