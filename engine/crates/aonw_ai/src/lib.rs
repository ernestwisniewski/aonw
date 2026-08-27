//! Deterministic planners using only recipient-safe views and public runtime commands.
//!
//! This crate never mutates canonical state directly and does not contain a
//! simulation reducer. Every plan is revision-bound and execution delegates to
//! the same [`aonw_local_runtime::LocalRuntime`] boundary used by clients.

#![forbid(unsafe_code)]

mod baseline;
mod fingerprint;

pub use baseline::{BaselinePlan, BaselinePlanner, BaselinePlanningOutcome, PlannedCommand};
pub use fingerprint::PlanFingerprint;
