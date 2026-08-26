use aonw_contracts::client::ClientCommandDto;
use aonw_domain::PlayerId;

use crate::DiplomacyRequest;

use super::ClientDecodeError;

pub(super) fn command(command: ClientCommandDto) -> Result<DiplomacyRequest, ClientDecodeError> {
    match command {
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => Ok(DiplomacyRequest::Send {
            expected_revision,
            target_player_id: PlayerId::new(target_player_id)
                .map_err(|error| ClientDecodeError::new("invalid_target_player_id", error))?,
            kind: aonw_contract_mapping::decode_proposal_kind(kind),
            proposal_id,
            gold_payment,
        }),
        ClientCommandDto::RespondDiplomaticProposal {
            expected_revision,
            proposal_id,
            accepted,
        } => Ok(DiplomacyRequest::Respond {
            expected_revision,
            proposal_id,
            accepted,
        }),
        ClientCommandDto::SendDiplomaticMessage {
            expected_revision,
            target_player_id,
            topic,
            message_id,
        } => Ok(DiplomacyRequest::SendMessage {
            expected_revision,
            target_player_id: PlayerId::new(target_player_id)
                .map_err(|error| ClientDecodeError::new("invalid_target_player_id", error))?,
            topic: aonw_contract_mapping::decode_message_topic(topic),
            message_id,
        }),
        ClientCommandDto::RespondDiplomaticMessage {
            expected_revision,
            message_id,
            response,
        } => Ok(DiplomacyRequest::RespondMessage {
            expected_revision,
            message_id,
            response: aonw_contract_mapping::decode_message_response(response),
        }),
        _ => unreachable!("diplomacy decoder receives only diplomacy commands"),
    }
}
