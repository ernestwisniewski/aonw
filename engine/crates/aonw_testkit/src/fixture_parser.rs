use std::path::Path;

use serde_json::Value;

use crate::FixtureLoadError;
use crate::fixture::{
    Fixture, FixtureInput, JsonObject, ReducerExpectedOutcome, SUPPORTED_FIXTURE_VERSION,
};

const ROOT_KEYS: &[&str] = &["expected", "family", "fixtureVersion", "id", "input"];
const INPUT_KEYS: &[&str] = &[
    "actorPlayerId",
    "command",
    "map",
    "match",
    "now",
    "rulesetId",
    "save",
    "state",
    "tick",
];
const EXPECTED_KEYS: &[&str] = &["accepted", "events", "reason", "save", "state"];

pub(super) fn parse_fixture(
    value: Value,
    path: Option<&Path>,
) -> Result<Fixture, FixtureLoadError> {
    let mut root = require_object(value, "$", path)?;
    require_exact_keys(&root, ROOT_KEYS, "$", path)?;
    let version = take_u64(&mut root, "fixtureVersion", "$.fixtureVersion", path)?;
    if version != SUPPORTED_FIXTURE_VERSION {
        return Err(FixtureLoadError::UnsupportedVersion {
            path: path.map(Path::to_path_buf),
            found: version,
            supported: SUPPORTED_FIXTURE_VERSION,
        });
    }

    let id = take_kebab_case(&mut root, "id", "$.id", path)?;
    let family = take_kebab_case(&mut root, "family", "$.family", path)?;
    let input = parse_input(take(&mut root, "input", "$.input", path)?, path)?;
    let expected = parse_expected(take(&mut root, "expected", "$.expected", path)?, path)?;
    Ok(Fixture {
        id: id.into_boxed_str(),
        family: family.into_boxed_str(),
        input,
        expected,
    })
}

fn parse_input(value: Value, path: Option<&Path>) -> Result<FixtureInput, FixtureLoadError> {
    let mut input = require_object(value, "$.input", path)?;
    require_exact_keys(&input, INPUT_KEYS, "$.input", path)?;
    let now = take_non_empty_string(&mut input, "now", "$.input.now", path)?;
    if !is_utc_timestamp(&now) {
        return Err(invalid(
            path,
            "$.input.now",
            "must use YYYY-MM-DDTHH:MM:SS.mmmZ with a valid UTC date and time",
        ));
    }
    let ruleset_id = take_non_empty_string(&mut input, "rulesetId", "$.input.rulesetId", path)?;
    if ruleset_id != "standard" {
        return Err(invalid(
            path,
            "$.input.rulesetId",
            "current reducer corpus requires the standard ruleset",
        ));
    }
    Ok(FixtureInput {
        now: now.into_boxed_str(),
        actor_player_id: take_non_empty_string(
            &mut input,
            "actorPlayerId",
            "$.input.actorPlayerId",
            path,
        )?
        .into_boxed_str(),
        tick: take_u64(&mut input, "tick", "$.input.tick", path)?,
        ruleset_id: ruleset_id.into_boxed_str(),
        map: take_object(&mut input, "map", "$.input.map", path)?,
        game_match: take_object(&mut input, "match", "$.input.match", path)?,
        save: take_object(&mut input, "save", "$.input.save", path)?,
        state: take_object(&mut input, "state", "$.input.state", path)?,
        command: take_object(&mut input, "command", "$.input.command", path)?,
    })
}

fn parse_expected(
    value: Value,
    path: Option<&Path>,
) -> Result<ReducerExpectedOutcome, FixtureLoadError> {
    let mut expected = require_object(value, "$.expected", path)?;
    require_exact_keys(&expected, EXPECTED_KEYS, "$.expected", path)?;
    let accepted = take_bool(&mut expected, "accepted", "$.expected.accepted", path)?;
    let reason = take_optional_string(&mut expected, "reason", "$.expected.reason", path)?;
    if accepted == reason.is_some() {
        return Err(invalid(
            path,
            "$.expected.reason",
            "must be null exactly when accepted is true",
        ));
    }
    Ok(ReducerExpectedOutcome {
        accepted,
        reason: reason.map(String::into_boxed_str),
        save: take_object(&mut expected, "save", "$.expected.save", path)?,
        state: take_object(&mut expected, "state", "$.expected.state", path)?,
        events: take_object_array(&mut expected, "events", "$.expected.events", path)?,
    })
}

fn require_exact_keys(
    object: &JsonObject,
    expected: &[&str],
    field: &str,
    path: Option<&Path>,
) -> Result<(), FixtureLoadError> {
    if object.len() == expected.len() && expected.iter().all(|key| object.contains_key(*key)) {
        return Ok(());
    }
    Err(invalid(
        path,
        field,
        format!("keys must be exactly [{}]", expected.join(", ")),
    ))
}

fn require_object(
    value: Value,
    field: &str,
    path: Option<&Path>,
) -> Result<JsonObject, FixtureLoadError> {
    match value {
        Value::Object(object) => Ok(object),
        _ => Err(invalid(path, field, "must be a JSON object")),
    }
}

fn take(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<Value, FixtureLoadError> {
    object
        .remove(key)
        .ok_or_else(|| invalid(path, field, "is required"))
}

fn take_object(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<JsonObject, FixtureLoadError> {
    require_object(take(object, key, field, path)?, field, path)
}

fn take_object_array(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<Vec<JsonObject>, FixtureLoadError> {
    match take(object, key, field, path)? {
        Value::Array(values) => values
            .into_iter()
            .enumerate()
            .map(|(index, value)| require_object(value, &format!("{field}[{index}]"), path))
            .collect(),
        _ => Err(invalid(path, field, "must be a JSON array")),
    }
}

fn take_kebab_case(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<String, FixtureLoadError> {
    let value = take_non_empty_string(object, key, field, path)?;
    if value.starts_with('-')
        || value.ends_with('-')
        || value
            .bytes()
            .any(|byte| !(byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-'))
        || value.as_bytes().windows(2).any(|pair| pair == b"--")
    {
        return Err(invalid(path, field, "must be lowercase kebab-case"));
    }
    Ok(value)
}

fn take_non_empty_string(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<String, FixtureLoadError> {
    match take(object, key, field, path)? {
        Value::String(value) if !value.is_empty() => Ok(value),
        _ => Err(invalid(path, field, "must be a non-empty string")),
    }
}

fn take_optional_string(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<Option<String>, FixtureLoadError> {
    match take(object, key, field, path)? {
        Value::Null => Ok(None),
        Value::String(value) if !value.is_empty() => Ok(Some(value)),
        _ => Err(invalid(path, field, "must be null or a non-empty string")),
    }
}

fn take_u64(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<u64, FixtureLoadError> {
    take(object, key, field, path)?
        .as_u64()
        .ok_or_else(|| invalid(path, field, "must be a non-negative integer"))
}

fn take_bool(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<bool, FixtureLoadError> {
    take(object, key, field, path)?
        .as_bool()
        .ok_or_else(|| invalid(path, field, "must be a boolean"))
}

fn is_utc_timestamp(value: &str) -> bool {
    let bytes = value.as_bytes();
    if bytes.len() != 24
        || [4, 7].into_iter().any(|index| bytes[index] != b'-')
        || bytes[10] != b'T'
        || [13, 16].into_iter().any(|index| bytes[index] != b':')
        || bytes[19] != b'.'
        || bytes[23] != b'Z'
    {
        return false;
    }
    let digits = [0, 1, 2, 3, 5, 6, 8, 9, 11, 12, 14, 15, 17, 18, 20, 21, 22];
    if digits
        .into_iter()
        .any(|index| !bytes[index].is_ascii_digit())
    {
        return false;
    }
    let year = decimal(bytes, 0, 4);
    let month = decimal(bytes, 5, 7);
    let day = decimal(bytes, 8, 10);
    let leap_year =
        year.is_multiple_of(4) && (!year.is_multiple_of(100) || year.is_multiple_of(400));
    let days_in_month = match month {
        1 | 3 | 5 | 7 | 8 | 10 | 12 => 31,
        4 | 6 | 9 | 11 => 30,
        2 if leap_year => 29,
        2 => 28,
        _ => return false,
    };
    (1..=days_in_month).contains(&day)
        && decimal(bytes, 11, 13) < 24
        && decimal(bytes, 14, 16) < 60
        && decimal(bytes, 17, 19) < 60
}

fn decimal(bytes: &[u8], start: usize, end: usize) -> u32 {
    bytes[start..end]
        .iter()
        .fold(0, |value, digit| value * 10 + u32::from(digit - b'0'))
}

fn invalid(
    path: Option<&Path>,
    field: impl Into<Box<str>>,
    message: impl Into<Box<str>>,
) -> FixtureLoadError {
    FixtureLoadError::Invalid {
        path: path.map(Path::to_path_buf),
        field: field.into(),
        message: message.into(),
    }
}
