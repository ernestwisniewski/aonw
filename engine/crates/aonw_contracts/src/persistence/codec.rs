use serde::{Deserialize, Serialize};

use super::{
    MAX_REPLAY_ENTRY_COUNT, MAX_REPLAY_LOG_JSON_BYTES, MAX_SAVE_GAME_JSON_BYTES,
    PersistenceCodecError, ReplayLogDto, SaveGameDto,
};

impl SaveGameDto {
    /// Parses a bounded strict save document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized or structurally invalid input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        parse_bounded(input, MAX_SAVE_GAME_JSON_BYTES)
    }

    /// Serializes compact save JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        serialize_bounded(self, MAX_SAVE_GAME_JSON_BYTES)
    }
}

impl ReplayLogDto {
    /// Parses a bounded strict replay document.
    ///
    /// # Errors
    ///
    /// Returns an error for oversized, structurally invalid, or unbounded input.
    pub fn from_json(input: &str) -> Result<Self, PersistenceCodecError> {
        let replay: Self = parse_bounded(input, MAX_REPLAY_LOG_JSON_BYTES)?;
        if replay.entries.len() > MAX_REPLAY_ENTRY_COUNT {
            return Err(PersistenceCodecError::TooManyReplayEntries {
                actual: replay.entries.len(),
                maximum: MAX_REPLAY_ENTRY_COUNT,
            });
        }
        Ok(replay)
    }

    /// Serializes compact replay JSON.
    ///
    /// # Errors
    ///
    /// Returns an error if serialization fails.
    pub fn to_json(&self) -> Result<String, PersistenceCodecError> {
        if self.entries.len() > MAX_REPLAY_ENTRY_COUNT {
            return Err(PersistenceCodecError::TooManyReplayEntries {
                actual: self.entries.len(),
                maximum: MAX_REPLAY_ENTRY_COUNT,
            });
        }
        serialize_bounded(self, MAX_REPLAY_LOG_JSON_BYTES)
    }
}

fn parse_bounded<T>(input: &str, maximum: usize) -> Result<T, PersistenceCodecError>
where
    T: for<'input> Deserialize<'input>,
{
    if input.len() > maximum {
        return Err(PersistenceCodecError::TooLarge {
            actual: input.len(),
            maximum,
        });
    }
    serde_json::from_str(input).map_err(PersistenceCodecError::Json)
}

fn serialize_bounded<T>(value: &T, maximum: usize) -> Result<String, PersistenceCodecError>
where
    T: Serialize,
{
    let output = serde_json::to_string(value).map_err(PersistenceCodecError::Json)?;
    if output.len() > maximum {
        return Err(PersistenceCodecError::TooLarge {
            actual: output.len(),
            maximum,
        });
    }
    Ok(output)
}
