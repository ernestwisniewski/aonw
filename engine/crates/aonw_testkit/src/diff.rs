use std::collections::BTreeSet;

use serde_json::Value;

const MAX_DIFFERENCES: usize = 64;
const MAX_RENDERED_VALUE_BYTES: usize = 256;

/// Classification of one structural JSON mismatch.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum DifferenceKind {
    /// Expected data is absent from the implementation output.
    Missing,
    /// Implementation output contains data absent from the oracle.
    Unexpected,
    /// Both sides have values at the path, but the values differ.
    ValueMismatch,
}

/// One bounded, human-readable structural difference.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct JsonDifference {
    path: Box<str>,
    kind: DifferenceKind,
    expected: Option<Box<str>>,
    actual: Option<Box<str>>,
}

impl JsonDifference {
    /// Returns the JSONPath-like location of the mismatch.
    #[must_use]
    pub fn path(&self) -> &str {
        &self.path
    }

    /// Returns the mismatch classification.
    #[must_use]
    pub const fn kind(&self) -> DifferenceKind {
        self.kind
    }

    /// Returns the bounded expected-value rendering.
    #[must_use]
    pub fn expected(&self) -> Option<&str> {
        self.expected.as_deref()
    }

    /// Returns the bounded implementation-value rendering.
    #[must_use]
    pub fn actual(&self) -> Option<&str> {
        self.actual.as_deref()
    }
}

/// Structurally compares JSON values.
///
/// Object key order is ignored because `serde_json` objects are maps. Array
/// order is retained and therefore detects reordered domain events.
#[must_use]
pub fn compare_json(expected: &Value, actual: &Value) -> Vec<JsonDifference> {
    let mut output = Vec::new();
    collect_differences("$", expected, actual, &mut output);
    output
}

fn collect_differences(
    path: &str,
    expected: &Value,
    actual: &Value,
    output: &mut Vec<JsonDifference>,
) {
    if output.len() >= MAX_DIFFERENCES || expected == actual {
        return;
    }

    match (expected, actual) {
        (Value::Object(expected), Value::Object(actual)) => {
            let keys = expected
                .keys()
                .chain(actual.keys())
                .collect::<BTreeSet<_>>();
            for key in keys {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                let child_path = object_path(path, key);
                match (expected.get(key), actual.get(key)) {
                    (Some(expected), Some(actual)) => {
                        collect_differences(&child_path, expected, actual, output);
                    }
                    (Some(expected), None) => output.push(difference(
                        child_path,
                        DifferenceKind::Missing,
                        Some(expected),
                        None,
                    )),
                    (None, Some(actual)) => output.push(difference(
                        child_path,
                        DifferenceKind::Unexpected,
                        None,
                        Some(actual),
                    )),
                    (None, None) => unreachable!("key came from one of the maps"),
                }
            }
        }
        (Value::Array(expected), Value::Array(actual)) => {
            let common_length = expected.len().min(actual.len());
            for index in 0..common_length {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                collect_differences(
                    &format!("{path}[{index}]"),
                    &expected[index],
                    &actual[index],
                    output,
                );
            }
            for (index, expected) in expected.iter().enumerate().skip(common_length) {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                output.push(difference(
                    format!("{path}[{index}]"),
                    DifferenceKind::Missing,
                    Some(expected),
                    None,
                ));
            }
            for (index, actual) in actual.iter().enumerate().skip(common_length) {
                if output.len() >= MAX_DIFFERENCES {
                    break;
                }
                output.push(difference(
                    format!("{path}[{index}]"),
                    DifferenceKind::Unexpected,
                    None,
                    Some(actual),
                ));
            }
        }
        _ => output.push(difference(
            path.to_owned(),
            DifferenceKind::ValueMismatch,
            Some(expected),
            Some(actual),
        )),
    }
}

fn difference(
    path: String,
    kind: DifferenceKind,
    expected: Option<&Value>,
    actual: Option<&Value>,
) -> JsonDifference {
    JsonDifference {
        path: path.into_boxed_str(),
        kind,
        expected: expected.map(render_value),
        actual: actual.map(render_value),
    }
}

fn object_path(parent: &str, key: &str) -> String {
    if key
        .chars()
        .all(|character| character.is_ascii_alphanumeric() || character == '_')
    {
        format!("{parent}.{key}")
    } else {
        format!(
            "{parent}[{}]",
            serde_json::to_string(key).expect("string encoding is infallible")
        )
    }
}

fn render_value(value: &Value) -> Box<str> {
    let rendered = value.to_string();
    if rendered.len() <= MAX_RENDERED_VALUE_BYTES {
        return rendered.into_boxed_str();
    }

    let mut boundary = MAX_RENDERED_VALUE_BYTES;
    while !rendered.is_char_boundary(boundary) {
        boundary -= 1;
    }
    format!("{}…", &rendered[..boundary]).into_boxed_str()
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::{DifferenceKind, compare_json};

    #[test]
    fn object_order_is_irrelevant() {
        let expected = serde_json::from_str(r#"{"a":1,"b":2}"#).expect("valid json");
        let actual = serde_json::from_str(r#"{"b":2,"a":1}"#).expect("valid json");

        assert!(compare_json(&expected, &actual).is_empty());
    }

    #[test]
    fn array_order_remains_observable() {
        let differences = compare_json(&json!(["first", "second"]), &json!(["second", "first"]));

        assert_eq!(differences.len(), 2);
        assert_eq!(differences[0].path(), "$[0]");
        assert_eq!(differences[0].kind(), DifferenceKind::ValueMismatch);
    }

    #[test]
    fn missing_and_unexpected_fields_have_precise_paths() {
        let differences = compare_json(
            &json!({"state": {"turn": 2}}),
            &json!({"state": {"offset": 7}}),
        );

        assert_eq!(differences.len(), 2);
        assert_eq!(differences[0].path(), "$.state.offset");
        assert_eq!(differences[0].kind(), DifferenceKind::Unexpected);
        assert_eq!(differences[1].path(), "$.state.turn");
        assert_eq!(differences[1].kind(), DifferenceKind::Missing);
    }

    #[test]
    fn reported_differences_are_bounded() {
        let expected = json!((0..100).collect::<Vec<_>>());
        let actual = json!((100..200).collect::<Vec<_>>());

        assert_eq!(compare_json(&expected, &actual).len(), 64);
    }
}
