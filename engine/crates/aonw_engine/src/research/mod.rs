mod commands;
mod error;
mod model;
mod rules;

pub use error::ResearchError;
pub use model::{ResearchOption, ResearchOptions, ResearchOptionsQuery, SelectTechnologyCommand};

pub(crate) use commands::{ResearchMutation, apply_select_technology};
pub(crate) use rules::query_options;
