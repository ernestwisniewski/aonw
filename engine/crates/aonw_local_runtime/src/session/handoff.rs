use aonw_domain::PlayerId;

/// Rejection from changing the authenticated actor of a local hot-seat session.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum ActorHandoffError {
    /// No local session is open.
    SessionNotOpen,
    /// Actor handoff is restricted to an explicitly local hot-seat match.
    NotHotSeat,
    /// The requested actor is not a participant in the current match.
    UnknownPlayer(PlayerId),
}

impl core::fmt::Display for ActorHandoffError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        match self {
            Self::SessionNotOpen => formatter.write_str("session is not open"),
            Self::NotHotSeat => formatter.write_str("actor handoff requires a hot-seat match"),
            Self::UnknownPlayer(player) => write!(formatter, "unknown hot-seat actor: {player}"),
        }
    }
}

impl std::error::Error for ActorHandoffError {}
