use aonw_contract_mapping::{encode_message_response, encode_message_topic, encode_proposal_kind};
use aonw_contracts::{ReplayCommandDto, ReplayRecordDto};
use aonw_domain::{
    DiplomaticMessageResponse, DiplomaticMessageTopic, DiplomaticProposalKind, PlayerId,
};
use aonw_engine::{
    PlayerCommand, RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand,
};

use super::{CommandResult, dispatch_player};
use crate::RuntimeError;
use crate::session::Session;

/// Current authenticated proposal command.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum DiplomacyRequest {
    /// Sends one friendship or truce proposal.
    Send {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
        /// Friendship or truce.
        kind: DiplomaticProposalKind,
        /// Optional proposal identity; omission selects an engine-generated identity.
        proposal_id: Option<String>,
        /// Requested truce payment.
        gold_payment: i64,
    },
    /// Accepts or rejects one proposal addressed to the actor.
    Respond {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Existing proposal identity.
        proposal_id: String,
        /// Recipient decision.
        accepted: bool,
    },
    /// Sends one private bilateral message.
    SendMessage {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Discovered bilateral target.
        target_player_id: PlayerId,
        /// Current message topic.
        topic: DiplomaticMessageTopic,
        /// Optional deterministic identity.
        message_id: Option<String>,
    },
    /// Responds to one recipient-owned message.
    RespondMessage {
        /// Expected canonical revision.
        expected_revision: u64,
        /// Existing message identity.
        message_id: String,
        /// Selected response tone.
        response: DiplomaticMessageResponse,
    },
}

pub(crate) fn dispatch_diplomacy(
    session: &mut Session,
    command: &DiplomacyRequest,
) -> Result<CommandResult, RuntimeError> {
    match command {
        DiplomacyRequest::Send {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => dispatch_player(
            session,
            PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
                *expected_revision,
                target_player_id,
                *kind,
                proposal_id.as_deref(),
                *gold_payment,
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::SendDiplomaticProposal {
                    expected_revision: *expected_revision,
                    target_player_id: target_player_id.as_str().to_owned(),
                    kind: encode_proposal_kind(*kind),
                    proposal_id: proposal_id.clone(),
                    gold_payment: *gold_payment,
                },
            },
        ),
        DiplomacyRequest::Respond {
            expected_revision,
            proposal_id,
            accepted,
        } => dispatch_player(
            session,
            PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
                *expected_revision,
                proposal_id,
                *accepted,
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::RespondDiplomaticProposal {
                    expected_revision: *expected_revision,
                    proposal_id: proposal_id.clone(),
                    accepted: *accepted,
                },
            },
        ),
        DiplomacyRequest::SendMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => dispatch_player(
            session,
            PlayerCommand::SendDiplomaticMessage(SendDiplomaticMessageCommand::new(
                *expected_revision,
                target_player_id,
                *topic,
                message_id.as_deref(),
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::SendDiplomaticMessage {
                    expected_revision: *expected_revision,
                    target_player_id: target_player_id.as_str().to_owned(),
                    topic: encode_message_topic(*topic),
                    message_id: message_id.clone(),
                },
            },
        ),
        DiplomacyRequest::RespondMessage {
            expected_revision,
            message_id,
            response,
        } => dispatch_player(
            session,
            PlayerCommand::RespondDiplomaticMessage(RespondDiplomaticMessageCommand::new(
                *expected_revision,
                message_id,
                *response,
            )),
            ReplayRecordDto::Player {
                command: ReplayCommandDto::RespondDiplomaticMessage {
                    expected_revision: *expected_revision,
                    message_id: message_id.clone(),
                    response: encode_message_response(*response),
                },
            },
        ),
    }
}
