use aonw_contract_mapping::decode_proposal_kind;
use aonw_contracts::ReplayCommandDto;
use aonw_domain::PlayerId;
use aonw_engine::{
    DomainTransition, EngineContext, GameEngine, PlayerCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticProposalCommand,
};

use super::{ExecutionError, display_error};

pub(super) fn apply(
    state: aonw_domain::GameState,
    context: EngineContext<'_>,
    command: &ReplayCommandDto,
) -> Result<DomainTransition, ExecutionError> {
    match command {
        ReplayCommandDto::SendDiplomaticProposal {
            expected_revision,
            target_player_id,
            kind,
            proposal_id,
            gold_payment,
        } => {
            let target = PlayerId::new(target_player_id.as_str()).map_err(display_error)?;
            GameEngine::apply_player_owned(
                state,
                context,
                PlayerCommand::SendDiplomaticProposal(SendDiplomaticProposalCommand::new(
                    *expected_revision,
                    &target,
                    decode_proposal_kind(*kind),
                    proposal_id.as_deref(),
                    *gold_payment,
                )),
            )
            .map_err(display_error)
        }
        ReplayCommandDto::RespondDiplomaticProposal {
            expected_revision,
            proposal_id,
            accepted,
        } => GameEngine::apply_player_owned(
            state,
            context,
            PlayerCommand::RespondDiplomaticProposal(RespondDiplomaticProposalCommand::new(
                *expected_revision,
                proposal_id,
                *accepted,
            )),
        )
        .map_err(display_error),
        _ => Err(ExecutionError("unsupported diplomacy command".to_owned())),
    }
}
