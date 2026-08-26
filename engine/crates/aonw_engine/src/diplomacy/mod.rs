mod error;
mod model;
mod proposal;

pub use error::DiplomacyError;
pub use model::{RespondDiplomaticProposalCommand, SendDiplomaticProposalCommand};

pub(crate) use model::DiplomacyMutation;
pub(crate) use proposal::{apply_respond_proposal, apply_send_proposal};
