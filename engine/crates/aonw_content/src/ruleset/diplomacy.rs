use serde::Serialize;

/// Immutable proposal and truce balance characterized from the frozen oracle.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiplomacyBalance {
    proposal_duration_turns: u32,
    truce_duration_turns: u32,
    friendship_accept_score_delta: i64,
    truce_accept_score_delta: i64,
    proposal_reject_score_delta: i64,
}

impl DiplomacyBalance {
    pub(super) const STANDARD: Self = Self {
        proposal_duration_turns: 5,
        truce_duration_turns: 10,
        friendship_accept_score_delta: 18,
        truce_accept_score_delta: 10,
        proposal_reject_score_delta: -6,
    };

    /// Returns how long a pending proposal remains actionable.
    #[must_use]
    pub const fn proposal_duration_turns(self) -> u32 {
        self.proposal_duration_turns
    }

    /// Returns how long an accepted truce protects both participants.
    #[must_use]
    pub const fn truce_duration_turns(self) -> u32 {
        self.truce_duration_turns
    }

    /// Returns the relation-score reward for accepted friendship.
    #[must_use]
    pub const fn friendship_accept_score_delta(self) -> i64 {
        self.friendship_accept_score_delta
    }

    /// Returns the relation-score reward for accepted truce.
    #[must_use]
    pub const fn truce_accept_score_delta(self) -> i64 {
        self.truce_accept_score_delta
    }

    /// Returns the relation-score penalty for rejecting a proposal.
    #[must_use]
    pub const fn proposal_reject_score_delta(self) -> i64 {
        self.proposal_reject_score_delta
    }
}
