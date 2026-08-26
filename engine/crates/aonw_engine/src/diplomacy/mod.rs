mod error;
mod message;
mod model;
mod proposal;
mod support;
mod war_gift;

pub use error::DiplomacyError;
pub use model::{
    DeclareWarCommand, RespondDiplomaticMessageCommand, RespondDiplomaticProposalCommand,
    SendDiplomaticMessageCommand, SendDiplomaticProposalCommand, SendGoldGiftCommand,
};

pub(crate) use message::{apply_respond_message, apply_send_message};
pub(crate) use model::DiplomacyMutation;
pub(crate) use proposal::{apply_respond_proposal, apply_send_proposal};
pub(crate) use war_gift::{apply_declare_war, apply_send_gold_gift};
