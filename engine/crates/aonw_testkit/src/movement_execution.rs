use std::fmt;

use serde::Serialize;

/// One authoritative movement step in fixed-point movement units.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MovementStep {
    col: u32,
    row: u32,
    enter_cost: u32,
    cumulative_cost: u32,
}

impl MovementStep {
    /// Creates a step. The enclosing execution validates its cost sequence.
    #[must_use]
    pub const fn new(col: u32, row: u32, enter_cost: u32, cumulative_cost: u32) -> Self {
        Self {
            col,
            row,
            enter_cost,
            cumulative_cost,
        }
    }

    /// Returns the destination column.
    #[must_use]
    pub const fn col(self) -> u32 {
        self.col
    }

    /// Returns the destination row.
    #[must_use]
    pub const fn row(self) -> u32 {
        self.row
    }

    /// Returns the cost of entering this step.
    #[must_use]
    pub const fn enter_cost(self) -> u32 {
        self.enter_cost
    }

    /// Returns the cost accumulated from the execution origin.
    #[must_use]
    pub const fn cumulative_cost(self) -> u32 {
        self.cumulative_cost
    }
}

/// Exact ordered path executed by one unit transition.
#[derive(Clone, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct MovementExecution {
    unit_id: Box<str>,
    from_col: u32,
    from_row: u32,
    steps: Box<[MovementStep]>,
}

impl MovementExecution {
    /// Constructs validated authoritative movement evidence.
    ///
    /// # Errors
    ///
    /// Returns [`MovementExecutionError`] for an invalid identifier, an empty
    /// path, or a non-positive, overflowing, or inconsistent cost sequence.
    pub fn try_new(
        unit_id: impl Into<Box<str>>,
        from_col: u32,
        from_row: u32,
        steps: impl Into<Box<[MovementStep]>>,
    ) -> Result<Self, MovementExecutionError> {
        let unit_id = unit_id.into();
        if unit_id.trim().is_empty() {
            return Err(MovementExecutionError::BlankUnitId);
        }
        let steps = steps.into();
        if steps.is_empty() {
            return Err(MovementExecutionError::EmptySteps);
        }

        let mut expected_cumulative_cost = 0_u32;
        for (step_index, step) in steps.iter().enumerate() {
            if step.enter_cost == 0 {
                return Err(MovementExecutionError::ZeroEnterCost { step_index });
            }
            expected_cumulative_cost = expected_cumulative_cost
                .checked_add(step.enter_cost)
                .ok_or(MovementExecutionError::CostOverflow { step_index })?;
            if step.cumulative_cost != expected_cumulative_cost {
                return Err(MovementExecutionError::CumulativeCostMismatch {
                    step_index,
                    expected: expected_cumulative_cost,
                    actual: step.cumulative_cost,
                });
            }
        }

        Ok(Self {
            unit_id,
            from_col,
            from_row,
            steps,
        })
    }

    /// Returns the moved unit identifier.
    #[must_use]
    pub fn unit_id(&self) -> &str {
        &self.unit_id
    }

    /// Returns the origin column.
    #[must_use]
    pub const fn from_col(&self) -> u32 {
        self.from_col
    }

    /// Returns the origin row.
    #[must_use]
    pub const fn from_row(&self) -> u32 {
        self.from_row
    }

    /// Returns the non-empty ordered travel steps, excluding the origin.
    #[must_use]
    pub fn steps(&self) -> &[MovementStep] {
        &self.steps
    }
}

/// Invariant violation in authoritative movement evidence.
#[allow(missing_docs)]
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum MovementExecutionError {
    BlankUnitId,
    EmptySteps,
    ZeroEnterCost {
        step_index: usize,
    },
    CostOverflow {
        step_index: usize,
    },
    CumulativeCostMismatch {
        step_index: usize,
        expected: u32,
        actual: u32,
    },
}

impl fmt::Display for MovementExecutionError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::BlankUnitId => formatter.write_str("unit id must not be blank"),
            Self::EmptySteps => formatter.write_str("execution must contain at least one step"),
            Self::ZeroEnterCost { step_index } => {
                write!(
                    formatter,
                    "step {step_index} must have a positive entry cost"
                )
            }
            Self::CostOverflow { step_index } => {
                write!(formatter, "cost overflows at step {step_index}")
            }
            Self::CumulativeCostMismatch {
                step_index,
                expected,
                actual,
            } => write!(
                formatter,
                "step {step_index} cumulative cost must be {expected}, found {actual}"
            ),
        }
    }
}

impl std::error::Error for MovementExecutionError {}

#[cfg(test)]
mod tests {
    use super::{MovementExecution, MovementExecutionError, MovementStep};

    #[test]
    fn accepts_a_contiguous_cost_sequence() {
        let execution = MovementExecution::try_new(
            "unit_1",
            0,
            0,
            vec![
                MovementStep::new(1, 0, 50, 50),
                MovementStep::new(2, 0, 25, 75),
            ],
        )
        .expect("valid execution");

        assert_eq!(execution.unit_id(), "unit_1");
        assert_eq!(execution.steps()[1].cumulative_cost(), 75);
    }

    #[test]
    fn rejects_an_inconsistent_cost_sequence() {
        let error =
            MovementExecution::try_new("unit_1", 0, 0, vec![MovementStep::new(1, 0, 50, 60)])
                .expect_err("invalid cumulative cost must fail");

        assert_eq!(
            error,
            MovementExecutionError::CumulativeCostMismatch {
                step_index: 0,
                expected: 50,
                actual: 60,
            }
        );
    }
}
