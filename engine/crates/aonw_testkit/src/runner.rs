use std::fmt;

use crate::{Fixture, FixtureInput, FixtureOutput, JsonDifference};

/// Engine-specific adapter executed by the independent fixture runner.
///
/// The executor receives input and metadata but never receives the committed
/// expected result. This prevents an adapter from accidentally using the oracle
/// to calculate its own output.
pub trait FixtureExecutor {
    /// Adapter-specific execution failure.
    type Error;

    /// Executes one fixture input through exactly one engine backend.
    ///
    /// # Errors
    ///
    /// Returns the adapter's [`Self::Error`] when execution cannot produce a
    /// complete output.
    fn execute(
        &self,
        fixture_id: &str,
        family: &str,
        input: &FixtureInput,
    ) -> Result<FixtureOutput, Self::Error>;
}

/// Failure produced while executing or comparing one fixture.
#[derive(Debug)]
pub enum FixtureRunError<ExecutionError> {
    /// The engine adapter failed before producing a complete output.
    Execution {
        /// Fixture identifier.
        fixture_id: Box<str>,
        /// Adapter-specific error.
        source: ExecutionError,
    },
    /// The engine output differs from the committed oracle.
    Mismatch {
        /// Fixture identifier.
        fixture_id: Box<str>,
        /// Bounded structural differences.
        differences: Vec<JsonDifference>,
    },
}

impl<ExecutionError> FixtureRunError<ExecutionError> {
    /// Returns the failing fixture identifier.
    #[must_use]
    pub fn fixture_id(&self) -> &str {
        match self {
            Self::Execution { fixture_id, .. } | Self::Mismatch { fixture_id, .. } => fixture_id,
        }
    }

    /// Returns structural differences for an oracle mismatch.
    #[must_use]
    pub fn differences(&self) -> Option<&[JsonDifference]> {
        match self {
            Self::Mismatch { differences, .. } => Some(differences),
            Self::Execution { .. } => None,
        }
    }
}

impl<ExecutionError: fmt::Display> fmt::Display for FixtureRunError<ExecutionError> {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Execution { fixture_id, source } => {
                write!(
                    formatter,
                    "fixture {fixture_id} failed to execute: {source}"
                )
            }
            Self::Mismatch {
                fixture_id,
                differences,
            } => write!(
                formatter,
                "fixture {fixture_id} differs from the oracle at {} location(s)",
                differences.len()
            ),
        }
    }
}

impl<ExecutionError> std::error::Error for FixtureRunError<ExecutionError>
where
    ExecutionError: std::error::Error + 'static,
{
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Execution { source, .. } => Some(source),
            Self::Mismatch { .. } => None,
        }
    }
}

/// Executes and verifies one fixture against its committed oracle.
///
/// # Errors
///
/// Returns [`FixtureRunError::Execution`] if the adapter fails, or
/// [`FixtureRunError::Mismatch`] if its complete output differs.
pub fn verify_fixture<Executor: FixtureExecutor>(
    fixture: &Fixture,
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    let actual = executor
        .execute(fixture.id(), fixture.family(), fixture.input())
        .map_err(|source| FixtureRunError::Execution {
            fixture_id: fixture.id().into(),
            source,
        })?;
    let differences = fixture.differences(&actual);
    if differences.is_empty() {
        return Ok(());
    }
    Err(FixtureRunError::Mismatch {
        fixture_id: fixture.id().into(),
        differences,
    })
}

/// Executes a corpus in its supplied order and stops at the first failure.
///
/// # Errors
///
/// Returns the first execution failure or oracle mismatch.
pub fn verify_corpus<Executor: FixtureExecutor>(
    fixtures: &[Fixture],
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    fixtures
        .iter()
        .try_for_each(|fixture| verify_fixture(fixture, executor))
}

#[cfg(test)]
mod tests {
    use std::convert::Infallible;

    use crate::{FixtureInput, FixtureLoader, FixtureOutput};

    use super::{FixtureExecutor, FixtureRunError, verify_corpus, verify_fixture};

    const FIXTURE: &str = r#"{
      "fixtureVersion": 1,
      "id": "movement-accepted",
      "family": "movement",
      "input": {
        "now": "2026-01-02T03:04:05.000Z",
        "actorPlayerId": "player_1",
        "tick": 3,
        "rulesetId": "standard",
        "map": {}, "match": {}, "save": {}, "state": {}, "command": {}
      },
      "expected": {
        "accepted": true,
        "reason": null,
        "save": {},
        "state": {"turn": 2},
        "events": [{"type": "UnitMoved"}]
      }
    }"#;

    struct StaticExecutor {
        output: FixtureOutput,
    }

    impl FixtureExecutor for StaticExecutor {
        type Error = Infallible;

        fn execute(
            &self,
            _fixture_id: &str,
            _family: &str,
            _input: &FixtureInput,
        ) -> Result<FixtureOutput, Self::Error> {
            Ok(self.output.clone())
        }
    }

    #[test]
    fn runner_accepts_a_complete_oracle_match() {
        let fixture = FixtureLoader::default()
            .parse(FIXTURE.as_bytes())
            .expect("valid fixture");
        let executor = StaticExecutor {
            output: fixture.expected().to_output(),
        };

        assert!(verify_fixture(&fixture, &executor).is_ok());
        assert!(verify_corpus(&[fixture], &executor).is_ok());
    }

    #[test]
    fn runner_reports_ordered_event_drift() {
        let fixture = FixtureLoader::default()
            .parse(FIXTURE.as_bytes())
            .expect("valid fixture");
        let executor = StaticExecutor {
            output: FixtureOutput::new(
                true,
                None::<Box<str>>,
                fixture.expected().save().clone(),
                fixture.expected().state().clone(),
                Vec::new(),
            ),
        };

        let error = verify_fixture(&fixture, &executor).expect_err("must detect drift");
        assert!(matches!(error, FixtureRunError::Mismatch { .. }));
        assert_eq!(
            error.differences().expect("mismatch differences")[0].path(),
            "$.events[0]"
        );
    }
}
