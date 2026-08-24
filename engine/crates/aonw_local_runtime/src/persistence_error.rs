use aonw_contract_mapping::GameStateMappingError;
use aonw_contracts::PersistenceCodecError;
use aonw_domain::IdentifierError;

use crate::{OpenSessionError, RuntimeError};

/// Save or replay validation failure.
#[derive(Debug)]
pub enum PersistenceError {
    /// Strict JSON codec failure.
    Codec(PersistenceCodecError),
    /// JSON serialization failure.
    Serialize(String),
    /// Persisted map identifier differs from supplied content.
    MapIdMismatch,
    /// Persisted map hash differs from supplied content.
    MapHashMismatch,
    /// Persisted ruleset identifier differs from supplied content.
    RulesetIdMismatch,
    /// Persisted ruleset hash differs from supplied content.
    RulesetHashMismatch,
    /// Immutable content identity could not be computed.
    ContentHash(String),
    /// Persisted actor identifier is invalid.
    InvalidActor(IdentifierError),
    /// Persisted command unit identifier is invalid.
    InvalidUnit(IdentifierError),
    /// Persisted trusted turn time is not canonical UTC.
    InvalidTurnTime(Box<str>),
    /// Canonical state contract violates domain invariants.
    State(GameStateMappingError),
    /// Persisted state digest does not identify the decoded canonical state.
    StateDigestMismatch,
    /// Replay entry index is not contiguous.
    ReplayIndexMismatch {
        /// Required contiguous index.
        expected: u64,
        /// Index present in the document.
        found: u64,
    },
    /// A replay entry index cannot be represented by the wire contract.
    ReplayIndexOverflow,
    /// Recorded trusted context differs from the replayed session.
    ReplayContextMismatch {
        /// Zero-based replay entry.
        entry: usize,
    },
    /// Recorded outcome differs from deterministic engine execution.
    ReplayResultMismatch {
        /// Zero-based replay entry.
        entry: usize,
    },
    /// Session preparation failed.
    Open(OpenSessionError),
    /// Command replay failed internally.
    Runtime(RuntimeError),
}

impl core::fmt::Display for PersistenceError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::Codec(source) => source.fmt(formatter),
            Self::Serialize(source) => write!(formatter, "serialization failed: {source}"),
            Self::MapIdMismatch => formatter.write_str("save map id does not match content"),
            Self::MapHashMismatch => formatter.write_str("save map hash does not match content"),
            Self::RulesetIdMismatch => {
                formatter.write_str("save ruleset id does not match content")
            }
            Self::RulesetHashMismatch => {
                formatter.write_str("save ruleset hash does not match content")
            }
            Self::ContentHash(source) => write!(formatter, "content hash failed: {source}"),
            Self::InvalidActor(source) => write!(formatter, "invalid actor: {source}"),
            Self::InvalidUnit(source) => write!(formatter, "invalid unit: {source}"),
            Self::InvalidTurnTime(source) => write!(formatter, "invalid turn time: {source}"),
            Self::State(source) => write!(formatter, "invalid canonical state: {source}"),
            Self::StateDigestMismatch => {
                formatter.write_str("state digest does not match canonical state")
            }
            Self::ReplayIndexMismatch { expected, found } => write!(
                formatter,
                "replay entry index {found} is not the expected index {expected}"
            ),
            Self::ReplayIndexOverflow => {
                formatter.write_str("replay entry index exceeds the wire integer range")
            }
            Self::ReplayContextMismatch { entry } => {
                write!(formatter, "replay context differs at entry {entry}")
            }
            Self::ReplayResultMismatch { entry } => {
                write!(formatter, "replay result differs at entry {entry}")
            }
            Self::Open(source) => source.fmt(formatter),
            Self::Runtime(source) => source.fmt(formatter),
        }
    }
}

impl std::error::Error for PersistenceError {}
