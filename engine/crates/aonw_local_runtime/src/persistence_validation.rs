use aonw_content::{MapDefinition, RulesetDefinition};
use aonw_contracts::{
    CURRENT_REPLAY_LOG_VERSION, CURRENT_SAVE_GAME_VERSION, ReplayLogDto, SaveGameDto,
};
use aonw_engine::ENGINE_BEHAVIOR_VERSION;

use crate::persistence_error::PersistenceError;

pub(crate) fn validate_save_header(
    save: &SaveGameDto,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if save.schema_version != CURRENT_SAVE_GAME_VERSION {
        return Err(PersistenceError::UnsupportedSaveVersion {
            found: save.schema_version,
            supported: CURRENT_SAVE_GAME_VERSION,
        });
    }
    validate_identity(
        save.behavior_version,
        &save.map_id,
        &save.map_hash,
        &save.ruleset_id,
        &save.ruleset_hash,
        map,
        ruleset,
    )
}

pub(crate) fn validate_replay_header(
    replay: &ReplayLogDto,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if replay.schema_version != CURRENT_REPLAY_LOG_VERSION {
        return Err(PersistenceError::UnsupportedReplayVersion {
            found: replay.schema_version,
            supported: CURRENT_REPLAY_LOG_VERSION,
        });
    }
    validate_identity(
        replay.behavior_version,
        &replay.map_id,
        &replay.map_hash,
        &replay.ruleset_id,
        &replay.ruleset_hash,
        map,
        ruleset,
    )
}

#[allow(clippy::too_many_arguments)]
fn validate_identity(
    behavior_version: u16,
    map_id: &str,
    map_hash: &str,
    ruleset_id: &str,
    ruleset_hash: &str,
    map: &MapDefinition,
    ruleset: &RulesetDefinition,
) -> Result<(), PersistenceError> {
    if behavior_version != ENGINE_BEHAVIOR_VERSION {
        return Err(PersistenceError::BehaviorVersionMismatch {
            found: behavior_version,
            required: ENGINE_BEHAVIOR_VERSION,
        });
    }
    if map_id != map.map_id() {
        return Err(PersistenceError::MapIdMismatch);
    }
    let actual_map_hash = map
        .content_hash()
        .map_err(|error| PersistenceError::ContentHash(error.to_string()))?;
    if map_hash != actual_map_hash.to_string() {
        return Err(PersistenceError::MapHashMismatch);
    }
    if ruleset_id != ruleset.ruleset_id() {
        return Err(PersistenceError::RulesetIdMismatch);
    }
    let actual_ruleset_hash = ruleset
        .content_hash()
        .map_err(|error| PersistenceError::ContentHash(error.to_string()))?;
    if ruleset_hash != actual_ruleset_hash.to_string() {
        return Err(PersistenceError::RulesetHashMismatch);
    }
    Ok(())
}
