use aonw_contracts::client::ClientCommandDto;
use aonw_domain::PlayerId;

use crate::DiplomacyProposalRequest;

use super::ClientDecodeError;

pub(super) fn command(
    command: ClientCommandDto,
) -> Result<DiplomacyProposalRequest, ClientDecodeError> {
    match command {
        ClientCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => Ok(DiplomacyProposalRequest::Send {
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
        } => Ok(DiplomacyProposalRequest::Respond {
            expected_revision,
            proposal_id,
            accepted,
        }),
        _ => unreachable!("diplomacy decoder receives only diplomacy commands"),
    }
}
