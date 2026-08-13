use std::collections::BTreeSet;
use std::fmt;
use std::fs;
use std::io;
use std::path::{Path, PathBuf};

use serde_json::Value;

use crate::fixture::{
    Fixture, FixtureInput, JsonObject, ReducerExpectedOutcome, SUPPORTED_FIXTURE_VERSION,
};

/// Default maximum size of one fixture: one MiB.
const DEFAULT_MAX_FIXTURE_BYTES: usize = 1024 * 1024;
/// Default maximum corpus size: 64 MiB.
const DEFAULT_MAX_CORPUS_BYTES: usize = 64 * 1024 * 1024;
/// Default maximum number of fixture files.
const DEFAULT_MAX_CORPUS_FIXTURES: usize = 2048;

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

/// Resource limits applied before and during fixture loading.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct FixtureLimits {
    /// Maximum bytes accepted for one JSON fixture.
    pub max_fixture_bytes: usize,
    /// Maximum aggregate bytes accepted for one corpus.
    pub max_corpus_bytes: usize,
    /// Maximum JSON fixture count accepted for one corpus.
    pub max_corpus_fixtures: usize,
}

impl Default for FixtureLimits {
    fn default() -> Self {
        Self {
            max_fixture_bytes: DEFAULT_MAX_FIXTURE_BYTES,
            max_corpus_bytes: DEFAULT_MAX_CORPUS_BYTES,
            max_corpus_fixtures: DEFAULT_MAX_CORPUS_FIXTURES,
        }
    }
}

/// Failure raised while loading or validating a compatibility fixture.
#[derive(Debug)]
pub enum FixtureLoadError {
    /// Filesystem access failed.
    Io {
        /// Path being accessed.
        path: PathBuf,
        /// Original I/O failure.
        source: io::Error,
    },
    /// JSON syntax or numeric representation is invalid.
    Json {
        /// Optional source path for in-memory parsing.
        path: Option<PathBuf>,
        /// Original JSON error.
        source: serde_json::Error,
    },
    /// A fixture is larger than the configured limit.
    FixtureTooLarge {
        /// Optional source path.
        path: Option<PathBuf>,
        /// Observed byte count.
        actual: usize,
        /// Configured byte limit.
        limit: usize,
    },
    /// Aggregate fixture bytes exceed the corpus limit.
    CorpusTooLarge {
        /// Corpus directory.
        path: PathBuf,
        /// Observed aggregate byte count.
        actual: usize,
        /// Configured byte limit.
        limit: usize,
    },
    /// The corpus contains too many fixtures.
    TooManyFixtures {
        /// Corpus directory.
        path: PathBuf,
        /// Observed fixture count.
        actual: usize,
        /// Configured fixture limit.
        limit: usize,
    },
    /// Fixture structure violates the versioned contract.
    Invalid {
        /// Optional source path.
        path: Option<PathBuf>,
        /// JSON field or logical location.
        field: Box<str>,
        /// Validation detail.
        message: Box<str>,
    },
    /// The fixture version is not supported by this testkit build.
    UnsupportedVersion {
        /// Optional source path.
        path: Option<PathBuf>,
        /// Version found in the fixture.
        found: u64,
        /// Version supported by this build.
        supported: u64,
    },
    /// Fixture filename does not match its identifier.
    FilenameMismatch {
        /// Fixture path.
        path: PathBuf,
        /// Identifier declared in JSON.
        fixture_id: Box<str>,
    },
    /// The corpus contains an entry other than JSON fixtures and its README.
    UnexpectedCorpusEntry {
        /// Unexpected path.
        path: PathBuf,
    },
    /// No JSON fixture exists in the corpus.
    EmptyCorpus {
        /// Corpus directory.
        path: PathBuf,
    },
    /// Two corpus fixtures declare the same identifier.
    DuplicateFixtureId {
        /// Duplicate identifier.
        fixture_id: Box<str>,
    },
}

impl fmt::Display for FixtureLoadError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Io { path, source } => write!(formatter, "{}: {source}", path.display()),
            Self::Json { path, source } => write_source(formatter, path.as_deref(), source),
            Self::FixtureTooLarge {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}fixture has {actual} bytes; limit is {limit}",
                path_prefix(path.as_deref())
            ),
            Self::CorpusTooLarge {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}: corpus has {actual} bytes; limit is {limit}",
                path.display()
            ),
            Self::TooManyFixtures {
                path,
                actual,
                limit,
            } => write!(
                formatter,
                "{}: corpus has {actual} fixtures; limit is {limit}",
                path.display()
            ),
            Self::Invalid {
                path,
                field,
                message,
            } => write!(
                formatter,
                "{}{field}: {message}",
                path_prefix(path.as_deref())
            ),
            Self::UnsupportedVersion {
                path,
                found,
                supported,
            } => write!(
                formatter,
                "{}unsupported fixture version {found}; supported version is {supported}",
                path_prefix(path.as_deref())
            ),
            Self::FilenameMismatch { path, fixture_id } => write!(
                formatter,
                "{}: fixture id {fixture_id:?} must match its filename",
                path.display()
            ),
            Self::UnexpectedCorpusEntry { path } => {
                write!(formatter, "unexpected corpus entry: {}", path.display())
            }
            Self::EmptyCorpus { path } => {
                write!(formatter, "fixture corpus is empty: {}", path.display())
            }
            Self::DuplicateFixtureId { fixture_id } => {
                write!(formatter, "duplicate fixture id: {fixture_id}")
            }
        }
    }
}

impl std::error::Error for FixtureLoadError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Io { source, .. } => Some(source),
            Self::Json { source, .. } => Some(source),
            _ => None,
        }
    }
}

/// Bounded loader for individual fixtures and complete corpora.
#[derive(Clone, Copy, Debug, Default)]
pub struct FixtureLoader {
    limits: FixtureLimits,
}

impl FixtureLoader {
    /// Constructs a loader with explicit resource limits.
    #[must_use]
    pub const fn new(limits: FixtureLimits) -> Self {
        Self { limits }
    }

    /// Parses one in-memory fixture.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for size, syntax, version, or structural
    /// contract violations.
    pub fn parse(self, source: &[u8]) -> Result<Fixture, FixtureLoadError> {
        self.parse_with_path(source, None)
    }

    /// Loads one fixture and verifies that its id matches the filename.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for I/O, limit, syntax, filename, version,
    /// or structural contract violations.
    pub fn load_file(self, path: impl AsRef<Path>) -> Result<Fixture, FixtureLoadError> {
        let path = path.as_ref();
        let source = read_bounded(path, self.limits.max_fixture_bytes)?;
        let fixture = self.parse_with_path(&source, Some(path))?;
        require_matching_filename(path, fixture.id())?;
        Ok(fixture)
    }

    /// Loads a sorted, non-empty corpus from a directory.
    ///
    /// `README.md` is the only permitted non-JSON entry. Fixture ids must be
    /// unique and match filenames.
    ///
    /// # Errors
    ///
    /// Returns [`FixtureLoadError`] for I/O, unexpected entries, corpus limits,
    /// duplicate ids, or any invalid fixture.
    pub fn load_corpus(
        self,
        directory: impl AsRef<Path>,
    ) -> Result<Vec<Fixture>, FixtureLoadError> {
        let directory = directory.as_ref();
        let mut files = Vec::new();
        let entries = fs::read_dir(directory).map_err(|source| FixtureLoadError::Io {
            path: directory.to_path_buf(),
            source,
        })?;

        for entry in entries {
            let entry = entry.map_err(|source| FixtureLoadError::Io {
                path: directory.to_path_buf(),
                source,
            })?;
            let path = entry.path();
            let file_type = entry.file_type().map_err(|source| FixtureLoadError::Io {
                path: path.clone(),
                source,
            })?;
            if file_type.is_file() && path.extension().is_some_and(|value| value == "json") {
                files.push(path);
            } else if !(file_type.is_file() && entry.file_name() == "README.md") {
                return Err(FixtureLoadError::UnexpectedCorpusEntry { path });
            }
        }

        files.sort_unstable();
        if files.is_empty() {
            return Err(FixtureLoadError::EmptyCorpus {
                path: directory.to_path_buf(),
            });
        }
        if files.len() > self.limits.max_corpus_fixtures {
            return Err(FixtureLoadError::TooManyFixtures {
                path: directory.to_path_buf(),
                actual: files.len(),
                limit: self.limits.max_corpus_fixtures,
            });
        }

        let mut total_bytes = 0_usize;
        let mut fixtures = Vec::with_capacity(files.len());
        let mut ids = BTreeSet::new();
        for path in files {
            let metadata = fs::metadata(&path).map_err(|source| FixtureLoadError::Io {
                path: path.clone(),
                source,
            })?;
            let bytes = usize::try_from(metadata.len()).unwrap_or(usize::MAX);
            total_bytes = total_bytes.saturating_add(bytes);
            if total_bytes > self.limits.max_corpus_bytes {
                return Err(FixtureLoadError::CorpusTooLarge {
                    path: directory.to_path_buf(),
                    actual: total_bytes,
                    limit: self.limits.max_corpus_bytes,
                });
            }

            let fixture = self.load_file(&path)?;
            if !ids.insert(fixture.id().to_owned()) {
                return Err(FixtureLoadError::DuplicateFixtureId {
                    fixture_id: fixture.id.clone(),
                });
            }
            fixtures.push(fixture);
        }
        Ok(fixtures)
    }

    fn parse_with_path(
        self,
        source: &[u8],
        path: Option<&Path>,
    ) -> Result<Fixture, FixtureLoadError> {
        if source.len() > self.limits.max_fixture_bytes {
            return Err(FixtureLoadError::FixtureTooLarge {
                path: path.map(Path::to_path_buf),
                actual: source.len(),
                limit: self.limits.max_fixture_bytes,
            });
        }
        let value = serde_json::from_slice(source).map_err(|source| FixtureLoadError::Json {
            path: path.map(Path::to_path_buf),
            source,
        })?;
        parse_fixture(value, path)
    }
}

fn parse_fixture(value: Value, path: Option<&Path>) -> Result<Fixture, FixtureLoadError> {
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

    let id = take_non_empty_string(&mut root, "id", "$.id", path)?;
    if !is_kebab_case(&id) {
        return Err(invalid(path, "$.id", "must be lowercase kebab-case"));
    }
    let family = take_non_empty_string(&mut root, "family", "$.family", path)?;
    if !is_kebab_case(&family) {
        return Err(invalid(path, "$.family", "must be lowercase kebab-case"));
    }

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
    if !now.ends_with('Z') {
        return Err(invalid(path, "$.input.now", "must be serialized as UTC"));
    }
    let actor_player_id =
        take_non_empty_string(&mut input, "actorPlayerId", "$.input.actorPlayerId", path)?;
    let tick = take_u64(&mut input, "tick", "$.input.tick", path)?;
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
        actor_player_id: actor_player_id.into_boxed_str(),
        tick,
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
    let events = take_object_array(&mut expected, "events", "$.expected.events", path)?;

    Ok(ReducerExpectedOutcome {
        accepted,
        reason: reason.map(String::into_boxed_str),
        save: take_object(&mut expected, "save", "$.expected.save", path)?,
        state: take_object(&mut expected, "state", "$.expected.state", path)?,
        events,
    })
}

fn read_bounded(path: &Path, limit: usize) -> Result<Vec<u8>, FixtureLoadError> {
    let metadata = fs::metadata(path).map_err(|source| FixtureLoadError::Io {
        path: path.to_path_buf(),
        source,
    })?;
    let metadata_size = usize::try_from(metadata.len()).unwrap_or(usize::MAX);
    if metadata_size > limit {
        return Err(FixtureLoadError::FixtureTooLarge {
            path: Some(path.to_path_buf()),
            actual: metadata_size,
            limit,
        });
    }
    let source = fs::read(path).map_err(|source| FixtureLoadError::Io {
        path: path.to_path_buf(),
        source,
    })?;
    if source.len() > limit {
        return Err(FixtureLoadError::FixtureTooLarge {
            path: Some(path.to_path_buf()),
            actual: source.len(),
            limit,
        });
    }
    Ok(source)
}

fn require_matching_filename(path: &Path, fixture_id: &str) -> Result<(), FixtureLoadError> {
    if path.file_stem().and_then(|value| value.to_str()) == Some(fixture_id) {
        return Ok(());
    }
    Err(FixtureLoadError::FilenameMismatch {
        path: path.to_path_buf(),
        fixture_id: fixture_id.into(),
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

fn take_non_empty_string(
    object: &mut JsonObject,
    key: &str,
    field: &str,
    path: Option<&Path>,
) -> Result<String, FixtureLoadError> {
    let value = take(object, key, field, path)?;
    match value {
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

fn is_kebab_case(value: &str) -> bool {
    !value.is_empty()
        && !value.starts_with('-')
        && !value.ends_with('-')
        && value
            .bytes()
            .all(|byte| byte.is_ascii_lowercase() || byte.is_ascii_digit() || byte == b'-')
        && !value.as_bytes().windows(2).any(|pair| pair == b"--")
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

fn path_prefix(path: Option<&Path>) -> String {
    path.map_or_else(String::new, |path| format!("{}: ", path.display()))
}

fn write_source(
    formatter: &mut fmt::Formatter<'_>,
    path: Option<&Path>,
    source: &dyn fmt::Display,
) -> fmt::Result {
    write!(formatter, "{}{source}", path_prefix(path))
}

#[cfg(test)]
mod tests {
    use serde_json::{Value, json};

    use super::{FixtureLimits, FixtureLoadError, FixtureLoader};

    fn fixture_json() -> Value {
        json!({
            "fixtureVersion": 1,
            "id": "movement-accepted",
            "family": "movement",
            "input": {
                "now": "2026-01-02T03:04:05.000Z",
                "actorPlayerId": "player_1",
                "tick": 3,
                "rulesetId": "standard",
                "map": {},
                "match": {},
                "save": {},
                "state": {},
                "command": {}
            },
            "expected": {
                "accepted": true,
                "reason": null,
                "save": {},
                "state": {},
                "events": []
            }
        })
    }

    fn encoded(value: &Value) -> Vec<u8> {
        serde_json::to_vec(value).expect("fixture JSON must encode")
    }

    #[test]
    fn parser_retains_typed_metadata_and_opaque_payloads() {
        let fixture = FixtureLoader::default()
            .parse(&encoded(&fixture_json()))
            .expect("valid fixture");

        assert_eq!(fixture.id(), "movement-accepted");
        assert_eq!(fixture.family(), "movement");
        assert_eq!(fixture.input().tick(), 3);
        assert_eq!(fixture.input().actor_player_id(), "player_1");
        assert!(fixture.expected().accepted());
    }

    #[test]
    fn unsupported_fixture_versions_fail_closed() {
        let mut value = fixture_json();
        value["fixtureVersion"] = json!(2);

        assert!(matches!(
            FixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::UnsupportedVersion {
                found: 2,
                supported: 1,
                ..
            })
        ));
    }

    #[test]
    fn structural_contract_rejects_unknown_root_fields() {
        let mut value = fixture_json();
        value["generatedBy"] = json!("rust");

        assert!(matches!(
            FixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::Invalid { ref field, .. }) if field.as_ref() == "$"
        ));
    }

    #[test]
    fn accepted_and_reason_must_be_coherent() {
        let mut value = fixture_json();
        value["expected"]["reason"] = json!("command_rejected");

        assert!(matches!(
            FixtureLoader::default().parse(&encoded(&value)),
            Err(FixtureLoadError::Invalid { ref field, .. })
                if field.as_ref() == "$.expected.reason"
        ));
    }

    #[test]
    fn fixture_size_is_checked_before_json_parsing() {
        let source = encoded(&fixture_json());
        let loader = FixtureLoader::new(FixtureLimits {
            max_fixture_bytes: source.len() - 1,
            ..FixtureLimits::default()
        });

        assert!(matches!(
            loader.parse(&source),
            Err(FixtureLoadError::FixtureTooLarge { .. })
        ));
    }
}
