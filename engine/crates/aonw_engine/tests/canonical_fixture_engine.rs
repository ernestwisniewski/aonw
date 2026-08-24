//! Executes current canonical fixtures without a historical reducer adapter.

use std::collections::BTreeSet;
use std::fmt;
use std::fs;
use std::path::{Path, PathBuf};

use aonw_content::RulesetDefinition;
use aonw_contract_mapping::{canonicalize_game_state, decode_game_state, encode_game_state};
use aonw_contracts::{
    CoordinateDto, GameStateDto, MovementStepDto, ReplayCommandDto, ReplayEventDto,
    ReplayEvidenceDto,
};
use aonw_domain::{HexCoord, PlayerId, UnitId};
use aonw_engine::{
    DomainEvent, EngineContext, ExecutionEvidence, GameEngine, MoveUnitCommand, PlayerCommand,
    UnitActionCommand,
};
use aonw_testkit::{
    CanonicalFixtureExecutor, CanonicalFixtureInput, CanonicalFixtureLoader,
    CanonicalFixtureOutput, verify_canonical_corpus, verify_canonical_fixture,
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

const CANONICAL_COMMAND_FIXTURE_COUNT: usize = 44;

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
        let map = input.map();
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
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::MoveUnit(MoveUnitCommand::new(
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
        FixtureUnitAction::Cancel => PlayerCommand::CancelUnitAction(command),
        FixtureUnitAction::Skip => PlayerCommand::SkipUnitTurn(command),
        FixtureUnitAction::Fortify => PlayerCommand::FortifyUnit(command),
    };
    GameEngine::apply_player_owned(state, context, command).map_err(display_error)
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

    assert_eq!(fixtures.len(), CANONICAL_COMMAND_FIXTURE_COUNT);
    assert!(
        fixtures
            .iter()
            .all(|fixture| fixture.fixture_version() == 3)
    );
    for fixture in &fixtures {
        assert_eq!(
            canonicalize_game_state(fixture.input().state().clone())
                .expect("valid canonical input state"),
            *fixture.input().state(),
            "fixture {} input state is not canonically ordered",
            fixture.id()
        );
        assert_eq!(
            canonicalize_game_state(fixture.expected().state().clone())
                .expect("valid canonical expected state"),
            *fixture.expected().state(),
            "fixture {} expected state is not canonically ordered",
            fixture.id()
        );
    }
    verify_canonical_corpus(&fixtures, &CanonicalRustEngineExecutor)
        .unwrap_or_else(|failure| panic!("{failure:?}"));
}

#[test]
fn invalid_origin_is_rejected_at_the_canonical_state_boundary() {
    let path = repository_root()
        .join("engine/fixtures/canonical_state_rejections/unit-out-of-bounds.json");
    let source = fs::read(path).expect("canonical state rejection fixture");
    let dto = serde_json::from_slice::<GameStateDto>(&source).expect("strict current state DTO");
    let error = decode_game_state(dto).expect_err("out-of-bounds state must fail closed");

    assert_eq!(error.path(), "$");
    assert!(error.to_string().contains("outside the map"));
}

#[derive(Debug)]
struct ReviewedExecutionDisposition {
    id: Box<str>,
    command: Box<str>,
    accepted: bool,
    rejection: Option<Box<str>>,
    canonical_artifact: Box<str>,
}

#[test]
fn reviewed_reducer_dispositions_gate_execution_by_capability() {
    let root = repository_root();
    let manifest = fs::read_to_string(root.join("engine/migration/reducer_fixture_dispositions"))
        .expect("reviewed disposition manifest");
    let dispositions = manifest
        .lines()
        .filter_map(reviewed_execution_disposition)
        .collect::<Vec<_>>();

    assert_eq!(dispositions.len(), 9);
    assert_eq!(
        dispositions
            .iter()
            .map(|entry| entry.command.as_ref())
            .collect::<BTreeSet<_>>(),
        BTreeSet::from([
            "CancelUnitAction",
            "FortifyUnit",
            "MoveUnit",
            "SkipUnitTurn"
        ])
    );

    for disposition in dispositions {
        let fixture = CanonicalFixtureLoader::default()
            .load_file(root.join(disposition.canonical_artifact.as_ref()))
            .expect("strict current canonical fixture");
        assert_eq!(fixture.id(), disposition.id.as_ref());
        assert_eq!(
            command_name(fixture.input().command()),
            disposition.command.as_ref()
        );
        assert_eq!(fixture.expected().accepted(), disposition.accepted);
        assert_eq!(
            fixture.expected().rejection(),
            disposition.rejection.as_deref()
        );
        assert_eq!(
            canonicalize_game_state(fixture.input().state().clone())
                .expect("canonical input round-trip"),
            *fixture.input().state()
        );
        assert_eq!(
            canonicalize_game_state(fixture.expected().state().clone())
                .expect("canonical output round-trip"),
            *fixture.expected().state()
        );
        verify_canonical_fixture(&fixture, &CanonicalRustEngineExecutor)
            .unwrap_or_else(|failure| panic!("{failure:?}"));
    }
}

fn reviewed_execution_disposition(line: &str) -> Option<ReviewedExecutionDisposition> {
    let line = line.split('#').next().unwrap_or_default().trim();
    if !line.starts_with("case ") {
        return None;
    }
    let fields = line.split_whitespace().collect::<Vec<_>>();
    assert_eq!(fields.len(), 11, "malformed reviewed disposition: {line}");
    if fields[7] != "engine-parity" {
        return None;
    }
    assert_eq!(fields[6], "round-trip");
    assert_eq!(fields[8], "current");
    assert_eq!(fields[9], "-");
    let accepted = match fields[4] {
        "accepted" => true,
        "rejected" => false,
        value => panic!("unknown oracle outcome: {value}"),
    };
    let rejection = (fields[5] != "-").then(|| fields[5].into());
    Some(ReviewedExecutionDisposition {
        id: fields[1].into(),
        command: fields[3].into(),
        accepted,
        rejection,
        canonical_artifact: fields[10].into(),
    })
}

const fn command_name(command: &ReplayCommandDto) -> &'static str {
    match command {
        ReplayCommandDto::MoveUnit { .. } => "MoveUnit",
        ReplayCommandDto::CancelUnitAction { .. } => "CancelUnitAction",
        ReplayCommandDto::SkipUnitTurn { .. } => "SkipUnitTurn",
        ReplayCommandDto::FortifyUnit { .. } => "FortifyUnit",
    }
}
