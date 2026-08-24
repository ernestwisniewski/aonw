use crate::{CanonicalFixture, CanonicalFixtureInput, CanonicalFixtureOutput, FixtureRunError};

/// Engine-specific executor for the current canonical fixture contract.
///
/// The committed expected result is intentionally not passed to the executor.
pub trait CanonicalFixtureExecutor {
    /// Executor-specific failure.
    type Error;

    /// Executes one complete canonical input through exactly one engine backend.
    ///
    /// # Errors
    ///
    /// Returns [`Self::Error`] if no complete typed output can be produced.
    fn execute(
        &self,
        fixture_id: &str,
        capability: &str,
        input: &CanonicalFixtureInput,
    ) -> Result<CanonicalFixtureOutput, Self::Error>;
}

/// Executes and verifies one current canonical fixture.
///
/// # Errors
///
/// Returns an execution error or bounded structural oracle differences.
pub fn verify_canonical_fixture<Executor: CanonicalFixtureExecutor>(
    fixture: &CanonicalFixture,
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    let actual = executor
        .execute(fixture.id(), fixture.capability(), fixture.input())
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

/// Executes a canonical corpus in sorted loader order.
///
/// # Errors
///
/// Returns the first execution failure or oracle mismatch.
pub fn verify_canonical_corpus<Executor: CanonicalFixtureExecutor>(
    fixtures: &[CanonicalFixture],
    executor: &Executor,
) -> Result<(), FixtureRunError<Executor::Error>> {
    fixtures
        .iter()
        .try_for_each(|fixture| verify_canonical_fixture(fixture, executor))
}
