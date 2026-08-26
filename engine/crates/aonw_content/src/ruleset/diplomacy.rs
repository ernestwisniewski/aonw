use serde::Serialize;

use aonw_domain::DiplomaticMessageResponse;

/// Immutable proposal and truce balance characterized from the frozen oracle.
#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "camelCase")]
pub struct DiplomacyBalance {
    proposal_duration_turns: u32,
    message_duration_turns: u32,
    message_cooldown_turns: u32,
    promise_duration_turns: u32,
    truce_duration_turns: u32,
    friendship_accept_score_delta: i64,
    truce_accept_score_delta: i64,
    proposal_reject_score_delta: i64,
}

impl DiplomacyBalance {
    pub(super) const STANDARD: Self = Self {
        proposal_duration_turns: 5,
        message_duration_turns: 5,
        message_cooldown_turns: 5,
        promise_duration_turns: 3,
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

    /// Returns how long an unanswered message remains actionable.
    #[must_use]
    pub const fn message_duration_turns(self) -> u32 {
        self.message_duration_turns
    }

    /// Returns the cooldown for another message in the same category.
    #[must_use]
    pub const fn message_cooldown_turns(self) -> u32 {
        self.message_cooldown_turns
    }

    /// Returns how long a conciliatory withdrawal promise remains active.
    #[must_use]
    pub const fn promise_duration_turns(self) -> u32 {
        self.promise_duration_turns
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

    /// Returns the base relation-score effect of a message response tone.
    #[must_use]
    pub const fn message_response_score_delta(self, response: DiplomaticMessageResponse) -> i64 {
        match response {
            DiplomaticMessageResponse::Conciliatory => 12,
            DiplomaticMessageResponse::Neutral => 2,
            DiplomaticMessageResponse::Evasive => -8,
            DiplomaticMessageResponse::Aggressive => -18,
        }
    }

    /// Returns the extra response score for cooperation against a shared enemy.
    #[must_use]
    pub const fn common_enemy_cooperation_bonus(self, response: DiplomaticMessageResponse) -> i64 {
        match response {
            DiplomaticMessageResponse::Conciliatory => 8,
            DiplomaticMessageResponse::Neutral => 4,
            DiplomaticMessageResponse::Evasive | DiplomaticMessageResponse::Aggressive => 0,
        }
    }
}
