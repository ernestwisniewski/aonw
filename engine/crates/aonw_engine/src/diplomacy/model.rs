use aonw_domain::{DiplomacyStateUpdate, DiplomaticProposalKind, PlayerId};

use crate::DomainEvent;

/// Revision-bound request to send one bilateral diplomatic proposal.
#[derive(Clone, Copy, Debug)]
pub struct SendDiplomaticProposalCommand<'command> {
    expected_revision: u64,
    target_player_id: &'command PlayerId,
    kind: DiplomaticProposalKind,
    proposal_id: Option<&'command str>,
    gold_payment: i64,
}

impl<'command> SendDiplomaticProposalCommand<'command> {
    /// Creates a current authenticated proposal command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        target_player_id: &'command PlayerId,
        kind: DiplomaticProposalKind,
        proposal_id: Option<&'command str>,
        gold_payment: i64,
    ) -> Self {
        Self {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn target_player_id(self) -> &'command PlayerId {
        self.target_player_id
    }
    pub(crate) const fn kind(self) -> DiplomaticProposalKind {
        self.kind
    }
    pub(crate) const fn proposal_id(self) -> Option<&'command str> {
        self.proposal_id
    }
    pub(crate) const fn gold_payment(self) -> i64 {
        self.gold_payment
    }
}

/// Revision-bound response to one recipient-owned proposal.
#[derive(Clone, Copy, Debug)]
pub struct RespondDiplomaticProposalCommand<'command> {
    expected_revision: u64,
    proposal_id: &'command str,
    accepted: bool,
}

impl<'command> RespondDiplomaticProposalCommand<'command> {
    /// Creates a current authenticated proposal response.
    #[must_use]
    pub const fn new(expected_revision: u64, proposal_id: &'command str, accepted: bool) -> Self {
        Self {
            expected_revision,
            proposal_id,
            accepted,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn proposal_id(self) -> &'command str {
        self.proposal_id
    }
    pub(crate) const fn accepted(self) -> bool {
        self.accepted
    }
}

/// Atomic replacement and ordered events produced by diplomacy rules.
pub(crate) struct DiplomacyMutation {
    pub(crate) update: DiplomacyStateUpdate,
    pub(crate) events: Box<[DomainEvent]>,
}
