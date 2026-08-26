mod error;
mod message;
mod model;
mod proposal;
mod support;

pub use error::DiplomacyError;
pub use model::{
    RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand,
};

pub(crate) use message::{apply_respond_message, apply_send_message};
pub(crate) use model::DiplomacyMutation;
pub(crate) use proposal::{apply_respond_proposal, apply_send_proposal};
