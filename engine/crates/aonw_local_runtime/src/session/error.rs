use aonw_engine::{CanonicalEngineError, CanonicalQueryError};

/// Failure from an operation requiring a valid local session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuntimeError {
    /// No session is open.
    SessionNotOpen,
    /// A read-only query was rejected.
    Query(CanonicalQueryError),
    /// Canonical transition construction failed.
    Engine(CanonicalEngineError),
    /// Authoritative event offset exhausted its integer range.
    EventOffsetOverflow,
}

impl RuntimeError {
    /// Returns a stable adapter code.
    #[must_use]
    pub const fn code(&self) -> &'static str {
        match self {
            Self::SessionNotOpen => "session_not_open",
            Self::Query(error) => error.code(),
            Self::Engine(_) => "canonical_engine_failed",
            Self::EventOffsetOverflow => "event_offset_overflow",
        }
    }
}

impl core::fmt::Display for RuntimeError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::Query(source) => source.fmt(formatter),
            Self::Engine(source) => source.fmt(formatter),
            Self::EventOffsetOverflow => formatter.write_str("event offset overflow"),
        }
    }
}

impl std::error::Error for RuntimeError {}
