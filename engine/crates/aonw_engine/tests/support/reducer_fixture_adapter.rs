//! Executes the current Dart command oracle through the canonical Rust engine.

#[path = "reducer_fixture_adapter/decode.rs"]
mod decode;
#[path = "reducer_fixture_adapter/json.rs"]
mod json;
#[path = "reducer_fixture_adapter/projection.rs"]
mod projection;

use std::fmt;
use std::path::{Path, PathBuf};

use aonw_content::RulesetDefinition;
use aonw_domain::{HexCoord, PlayerId, UnitId};
use aonw_engine::{DomainCommand, EngineContext, GameEngine, MoveUnitCommand, UnitActionCommand};
use aonw_testkit::{FixtureExecutor, FixtureInput, FixtureOutput};

use decode::{DecodedState, decode_map, decode_state};
use json::{display_error, error, required_i32, required_string};
use projection::{apply_canonical_projection, event_json, evidence_execution};

#[derive(Debug)]
pub(crate) struct AdapterError(String);

impl fmt::Display for AdapterError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(&self.0)
    }
}

impl std::error::Error for AdapterError {}

pub(crate) struct RustEngineFixtureExecutor;

impl FixtureExecutor for RustEngineFixtureExecutor {
    type Error = AdapterError;

    fn execute(
        &self,
        _fixture_id: &str,
        family: &str,
        input: &FixtureInput,
    ) -> Result<FixtureOutput, Self::Error> {
        if family != "movement" && family != "unit-actions" {
            return Err(error(format!("unsupported fixture family: {family}")));
        }

        let map = decode_map(input.map())?;
        let unit_id =
            UnitId::new(required_string(input.command(), "unitId")?).map_err(display_error)?;
        let command_type = required_string(input.command(), "type")?;
        let mut save = input.save().clone();
        save.remove("savedAt");

        let state = match decode_state(input, map.bounds(), &unit_id)? {
            DecodedState::Valid(state) => state,
            DecodedState::CommandUnitOutOfBounds => {
                return Ok(FixtureOutput::reject(
                    "unit_out_of_bounds",
                    save,
                    input.state().clone(),
                    Vec::new(),
                    Vec::new(),
                ));
            }
        };
        let actor = PlayerId::new(input.actor_player_id()).map_err(display_error)?;
        let context = EngineContext::canonical(&actor, &map, RulesetDefinition::standard());
        let transition = match command_type {
            "MoveUnit" => {
                let target = HexCoord::new(
                    required_i32(input.command(), "targetCol")?,
                    required_i32(input.command(), "targetRow")?,
                );
                GameEngine::apply_owned(
                    *state,
                    context,
                    DomainCommand::MoveUnit(MoveUnitCommand::new(input.tick(), &unit_id, target)),
                )
            }
            "CancelUnitAction" => GameEngine::apply_owned(
                *state,
                context,
                DomainCommand::CancelUnitAction(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            "SkipUnitTurn" => GameEngine::apply_owned(
                *state,
                context,
                DomainCommand::SkipUnitTurn(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            "FortifyUnit" => GameEngine::apply_owned(
                *state,
                context,
                DomainCommand::FortifyUnit(UnitActionCommand::new(input.tick(), &unit_id)),
            ),
            _ => return Err(error(format!("unsupported command: {command_type}"))),
        }
        .map_err(display_error)?;

        if let Some(rejection) = transition.rejection() {
            return Ok(FixtureOutput::reject(
                rejection.code().as_str(),
                save,
                input.state().clone(),
                Vec::new(),
                Vec::new(),
            ));
        }

        let mut output_state = input.state().clone();
        apply_canonical_projection(&mut output_state, transition.state(), transition.evidence())?;
        Ok(FixtureOutput::accept(
            save,
            output_state,
            transition
                .events()
                .iter()
                .map(event_json)
                .collect::<Result<Vec<_>, _>>()?,
            transition
                .evidence()
                .map(evidence_execution)
                .transpose()?
                .into_iter()
                .collect::<Vec<_>>(),
        ))
    }
}

pub(crate) fn repository_root() -> PathBuf {
    Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .find(|path| {
            path.join("engine/Cargo.toml").is_file()
                && path.join("test/fixtures/reducer_parity_v2").is_dir()
        })
        .expect("repository root must contain engine and current reducer fixtures")
        .to_path_buf()
}
