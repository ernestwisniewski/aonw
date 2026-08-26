use aonw_domain::{
    DiplomacyStateUpdate, DiplomaticMessageResponse, DiplomaticMessageTopic,
    DiplomaticProposalKind, PlayerId,
};

use crate::DomainEvent;

/// Revision-bound request to declare war on one discovered participant.
#[derive(Clone, Copy, Debug)]
pub struct DeclareWarCommand<'command> {
    expected_revision: u64,
    target_player_id: &'command PlayerId,
}

impl<'command> DeclareWarCommand<'command> {
    /// Creates a current authenticated declaration-of-war command.
    #[must_use]
    pub const fn new(expected_revision: u64, target_player_id: &'command PlayerId) -> Self {
        Self {
            expected_revision,
            target_player_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn target_player_id(self) -> &'command PlayerId {
        self.target_player_id
    }
}

/// Revision-bound request to transfer a positive gold gift.
#[derive(Clone, Copy, Debug)]
pub struct SendGoldGiftCommand<'command> {
    expected_revision: u64,
    target_player_id: &'command PlayerId,
    amount: i64,
}

impl<'command> SendGoldGiftCommand<'command> {
    /// Creates a current authenticated gold-gift command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        target_player_id: &'command PlayerId,
        amount: i64,
    ) -> Self {
        Self {
            expected_revision,
            target_player_id,
            amount,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn target_player_id(self) -> &'command PlayerId {
        self.target_player_id
    }
    pub(crate) const fn amount(self) -> i64 {
        self.amount
    }
}

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

/// Revision-bound request to send one bilateral diplomatic message.
#[derive(Clone, Copy, Debug)]
pub struct SendDiplomaticMessageCommand<'command> {
    expected_revision: u64,
    target_player_id: &'command PlayerId,
    topic: DiplomaticMessageTopic,
    message_id: Option<&'command str>,
}

impl<'command> SendDiplomaticMessageCommand<'command> {
    /// Creates a current authenticated message command.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        target_player_id: &'command PlayerId,
        topic: DiplomaticMessageTopic,
        message_id: Option<&'command str>,
    ) -> Self {
        Self {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn target_player_id(self) -> &'command PlayerId {
        self.target_player_id
    }
    pub(crate) const fn topic(self) -> DiplomaticMessageTopic {
        self.topic
    }
    pub(crate) const fn message_id(self) -> Option<&'command str> {
        self.message_id
    }
}

/// Revision-bound response to one recipient-owned diplomatic message.
#[derive(Clone, Copy, Debug)]
pub struct RespondDiplomaticMessageCommand<'command> {
    expected_revision: u64,
    message_id: &'command str,
    response: DiplomaticMessageResponse,
}

impl<'command> RespondDiplomaticMessageCommand<'command> {
    /// Creates a current authenticated message response.
    #[must_use]
    pub const fn new(
        expected_revision: u64,
        message_id: &'command str,
        response: DiplomaticMessageResponse,
    ) -> Self {
        Self {
            expected_revision,
            message_id,
            response,
        }
    }

    pub(crate) const fn expected_revision(self) -> u64 {
        self.expected_revision
    }
    pub(crate) const fn message_id(self) -> &'command str {
        self.message_id
    }
    pub(crate) const fn response(self) -> DiplomaticMessageResponse {
        self.response
    }
}

/// Atomic replacement and ordered events produced by diplomacy rules.
pub(crate) struct DiplomacyMutation {
    pub(crate) update: DiplomacyStateUpdate,
    pub(crate) events: Box<[DomainEvent]>,
}
