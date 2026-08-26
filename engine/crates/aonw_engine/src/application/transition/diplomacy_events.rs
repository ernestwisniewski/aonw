use aonw_domain::{
    DiplomaticProposal, DiplomaticProposalKind, DiplomaticRelationChangeReason,
    DiplomaticRelationStatus, PlayerId, PlayerPair,
};

/// Accepted fact that one private bilateral proposal was sent.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposalSentEvent {
    proposal_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
    expires_on_turn: u32,
}

impl DiplomaticProposalSentEvent {
    pub(crate) fn from_proposal(proposal: &DiplomaticProposal) -> Self {
        Self {
            proposal_id: proposal.id().to_owned(),
            from_player_id: proposal.from_player_id().clone(),
            to_player_id: proposal.to_player_id().clone(),
            kind: proposal.kind(),
            expires_on_turn: proposal.expires_on_turn(),
        }
    }
    /// Returns the proposal identity.
    #[must_use]
    pub fn proposal_id(&self) -> &str {
        &self.proposal_id
    }
    /// Returns the sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the proposal kind.
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
    /// Returns the last actionable turn boundary.
    #[must_use]
    pub const fn expires_on_turn(&self) -> u32 {
        self.expires_on_turn
    }
}

/// Accepted fact that the proposal recipient made a decision.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticProposalRespondedEvent {
    proposal_id: String,
    from_player_id: PlayerId,
    to_player_id: PlayerId,
    kind: DiplomaticProposalKind,
    accepted: bool,
}

impl DiplomaticProposalRespondedEvent {
    pub(crate) fn from_proposal(proposal: &DiplomaticProposal, accepted: bool) -> Self {
        Self {
            proposal_id: proposal.id().to_owned(),
            from_player_id: proposal.from_player_id().clone(),
            to_player_id: proposal.to_player_id().clone(),
            kind: proposal.kind(),
            accepted,
        }
    }
    /// Returns the proposal identity.
    #[must_use]
    pub fn proposal_id(&self) -> &str {
        &self.proposal_id
    }
    /// Returns the original sender.
    #[must_use]
    pub const fn from_player_id(&self) -> &PlayerId {
        &self.from_player_id
    }
    /// Returns the responding recipient.
    #[must_use]
    pub const fn to_player_id(&self) -> &PlayerId {
        &self.to_player_id
    }
    /// Returns the original proposal kind.
    #[must_use]
    pub const fn kind(&self) -> DiplomaticProposalKind {
        self.kind
    }
    /// Returns whether the proposal was accepted.
    #[must_use]
    pub const fn accepted(&self) -> bool {
        self.accepted
    }
}

/// Accepted fact that a bilateral relation status changed.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct DiplomaticRelationChangedEvent {
    pair: PlayerPair,
    old_status: DiplomaticRelationStatus,
    new_status: DiplomaticRelationStatus,
    reason: DiplomaticRelationChangeReason,
    expires_on_turn: Option<u32>,
}

impl DiplomaticRelationChangedEvent {
    pub(crate) const fn new(
        pair: PlayerPair,
        old_status: DiplomaticRelationStatus,
        new_status: DiplomaticRelationStatus,
        reason: DiplomaticRelationChangeReason,
        expires_on_turn: Option<u32>,
    ) -> Self {
        Self {
            pair,
            old_status,
            new_status,
            reason,
            expires_on_turn,
        }
    }
    /// Returns the canonical first participant.
    #[must_use]
    pub const fn player_a_id(&self) -> &PlayerId {
        self.pair.first()
    }
    /// Returns the canonical second participant.
    #[must_use]
    pub const fn player_b_id(&self) -> &PlayerId {
        self.pair.second()
    }
    /// Returns the status before the transition.
    #[must_use]
    pub const fn old_status(&self) -> DiplomaticRelationStatus {
        self.old_status
    }
    /// Returns the status after the transition.
    #[must_use]
    pub const fn new_status(&self) -> DiplomaticRelationStatus {
        self.new_status
    }
    /// Returns why the status changed.
    #[must_use]
    pub const fn reason(&self) -> DiplomaticRelationChangeReason {
        self.reason
    }
    /// Returns an optional expiry for temporary statuses.
    #[must_use]
    pub const fn expires_on_turn(&self) -> Option<u32> {
        self.expires_on_turn
    }
}
