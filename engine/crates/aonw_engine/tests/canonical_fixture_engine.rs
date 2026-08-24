//! Executes current canonical fixtures without a historical reducer adapter.

use std::fmt;
use std::path::{Path, PathBuf};

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::{decode_game_state, encode_game_state};
use aonw_contracts::{
    CoordinateDto, MovementStepDto, ReplayCommandDto, ReplayEventDto, ReplayEvidenceDto,
};
use aonw_domain::{HexCoord, PlayerId, UnitId};
use aonw_engine::{
    DomainCommand, DomainEvent, EngineContext, ExecutionEvidence, GameEngine, MoveUnitCommand,
    UnitActionCommand,
};
use aonw_testkit::{
    CanonicalFixtureExecutor, CanonicalFixtureInput, CanonicalFixtureLoader,
    CanonicalFixtureOutput, verify_canonical_corpus,
};

#[derive(Debug)]
struct ExecutionError(String);

impl fmt::Display for ExecutionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for ExecutionError {}

struct CanonicalRustEngineExecutor;

impl CanonicalFixtureExecutor for CanonicalRustEngineExecutor {
    type Error = ExecutionError;

    fn execute(
        &self,
        _fixture_id: &str,
        _capability: &str,
        input: &CanonicalFixtureInput,
    ) -> Result<CanonicalFixtureOutput, Self::Error> {
        let state = decode_game_state(input.state().clone()).map_err(display_error)?;
        let actor = PlayerId::new(input.actor_player_id()).map_err(display_error)?;
        let map = input.map().map();
        let context = EngineContext::canonical(&actor, map, RulesetDefinition::standard());
        let transition = apply_command(state, context, input.command())?;
        let output_state = encode_game_state(transition.state());
        if let Some(rejection) = transition.rejection() {
            return Ok(CanonicalFixtureOutput::reject(
                rejection.code().as_str(),
                output_state,
            ));
        }
        Ok(CanonicalFixtureOutput::accept(
            output_state,
            transition
                .events()
                .iter()
                .map(encode_event)
                .collect::<Vec<_>>(),
            transition.evidence().map(encode_evidence),
        ))
    }
}

fn apply_command(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::MoveUnit {
            expected_revision,
            unit_id,
            target,
        } => {
            let unit_id = UnitId::new(unit_id.as_str()).map_err(display_error)?;
            GameEngine::apply_owned(
                state,
                context,
                DomainCommand::MoveUnit(MoveUnitCommand::new(
                    *expected_revision,
                    &unit_id,
                    HexCoord::new(target.col, target.row),
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::CancelUnitAction {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Cancel,
        ),
        ReplayCommandDto::SkipUnitTurn {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Skip,
        ),
        ReplayCommandDto::FortifyUnit {
            expected_revision,
            unit_id,
        } => apply_unit_action(
            state,
            context,
            *expected_revision,
            unit_id,
            FixtureUnitAction::Fortify,
        ),
    }
}

#[derive(Clone, Copy)]
enum FixtureUnitAction {
    Cancel,
    Skip,
    Fortify,
}

fn apply_unit_action(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    expected_revision: u64,
    unit_id: &str,
    action: FixtureUnitAction,
) -> Result<aonw_engine::DomainTransition, ExecutionError> {
    let unit_id = UnitId::new(unit_id).map_err(display_error)?;
    let command = UnitActionCommand::new(expected_revision, &unit_id);
    let command = match action {
        FixtureUnitAction::Cancel => DomainCommand::CancelUnitAction(command),
        FixtureUnitAction::Skip => DomainCommand::SkipUnitTurn(command),
        FixtureUnitAction::Fortify => DomainCommand::FortifyUnit(command),
    };
    GameEngine::apply_owned(state, context, command).map_err(display_error)
}

fn encode_event(event: &DomainEvent) -> ReplayEventDto {
    match event {
        DomainEvent::UnitMoved(event) => ReplayEventDto::UnitMoved {
            unit_id: event.unit_id().as_str().to_owned(),
            from: coordinate(event.from()),
            to: coordinate(event.to()),
        },
    }
}

fn encode_evidence(evidence: &ExecutionEvidence) -> ReplayEvidenceDto {
    match evidence {
        ExecutionEvidence::UnitMovement(execution) => ReplayEvidenceDto::UnitMovement {
            unit_id: execution.unit_id().as_str().to_owned(),
            from: coordinate(execution.from()),
            steps: execution
                .steps()
                .iter()
                .map(|step| MovementStepDto {
                    col: step.coordinate().col(),
                    row: step.coordinate().row(),
                    enter_cost_units: step.enter_cost().get(),
                    cumulative_cost_units: step.cumulative_cost().get(),
                })
                .collect(),
        },
    }
}

const fn coordinate(value: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: value.col(),
        row: value.row(),
    }
}

fn display_error(error: impl fmt::Display) -> ExecutionError {
    ExecutionError(error.to_string())
}

fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| path.join("engine/fixtures/canonical_commands").is_dir())
        .expect("repository root must contain canonical engine fixtures")
        .to_path_buf()
}

#[test]
fn rust_executes_current_canonical_command_corpus() {
    let fixture_dir = repository_root().join("engine/fixtures/canonical_commands");
    let fixtures = CanonicalFixtureLoader::default()
        .load_corpus(fixture_dir)
        .expect("canonical command corpus must load");

    assert_eq!(fixtures.len(), 1);
    verify_canonical_corpus(&fixtures, &CanonicalRustEngineExecutor)
        .unwrap_or_else(|failure| panic!("{failure:?}"));
}
