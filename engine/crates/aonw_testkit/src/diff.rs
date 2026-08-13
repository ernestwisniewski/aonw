use serde_json::{Map, Value};

use crate::movement_execution::MovementExecution;

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

#[derive(Clone, Copy)]
pub(super) struct JsonOutcome<'a> {
    accepted: bool,
    reason: Option<&'a str>,
    save: &'a Map<String, Value>,
    state: &'a Map<String, Value>,
    events: &'a [Map<String, Value>],
    movement_executions: Option<&'a [MovementExecution]>,
}

impl<'a> JsonOutcome<'a> {
    pub(crate) const fn new(
        accepted: bool,
        reason: Option<&'a str>,
        save: &'a Map<String, Value>,
        state: &'a Map<String, Value>,
        events: &'a [Map<String, Value>],
        movement_executions: Option<&'a [MovementExecution]>,
    ) -> Self {
        Self {
            accepted,
            reason,
            save,
            state,
            events,
            movement_executions,
        }
    }
}

pub(super) fn compare_outcome(
    expected: JsonOutcome<'_>,
    actual: JsonOutcome<'_>,
) -> Vec<JsonDifference> {
    let mut output = Vec::new();
    if expected.accepted != actual.accepted {
        output.push(JsonDifference {
            path: "$.accepted".into(),
            kind: DifferenceKind::ValueMismatch,
            expected: Some(expected.accepted.to_string().into()),
            actual: Some(actual.accepted.to_string().into()),
        });
    }
    if expected.reason != actual.reason {
        output.push(JsonDifference {
            path: "$.reason".into(),
            kind: DifferenceKind::ValueMismatch,
            expected: Some(render_optional_string(expected.reason)),
            actual: Some(render_optional_string(actual.reason)),
        });
    }
    collect_object_differences("$.save", expected.save, actual.save, &mut output);
    collect_object_differences("$.state", expected.state, actual.state, &mut output);
    collect_object_array_differences("$.events", expected.events, actual.events, &mut output);
    if let Some(expected_executions) = expected.movement_executions {
        collect_movement_execution_differences(
            expected_executions,
            actual.movement_executions,
            &mut output,
        );
    }
    output
}

fn collect_movement_execution_differences(
    expected: &[MovementExecution],
    actual: Option<&[MovementExecution]>,
    output: &mut Vec<JsonDifference>,
) {
    let Some(actual) = actual else {
        output.push(JsonDifference {
            path: "$.movementExecutions".into(),
            kind: DifferenceKind::Missing,
            expected: Some(format!("array(len={})", expected.len()).into()),
            actual: None,
        });
        return;
    };
    let common_length = expected.len().min(actual.len());
    for index in 0..common_length {
        if output.len() >= MAX_DIFFERENCES {
            return;
        }
        compare_execution(index, &expected[index], &actual[index], output);
    }
    collect_typed_array_tail(
        "$.movementExecutions",
        expected.len(),
        actual.len(),
        common_length,
        output,
    );
}

fn compare_execution(
    index: usize,
    expected: &MovementExecution,
    actual: &MovementExecution,
    output: &mut Vec<JsonDifference>,
) {
    let path = format!("$.movementExecutions[{index}]");
    compare_scalar(
        format!("{path}.unitId"),
        expected.unit_id(),
        actual.unit_id(),
        output,
    );
    compare_scalar(
        format!("{path}.fromCol"),
        &expected.from_col(),
        &actual.from_col(),
        output,
    );
    compare_scalar(
        format!("{path}.fromRow"),
        &expected.from_row(),
        &actual.from_row(),
        output,
    );

    let expected_steps = expected.steps();
    let actual_steps = actual.steps();
    let common_length = expected_steps.len().min(actual_steps.len());
    for step_index in 0..common_length {
        if output.len() >= MAX_DIFFERENCES {
            return;
        }
        let step_path = format!("{path}.steps[{step_index}]");
        let expected_step = expected_steps[step_index];
        let actual_step = actual_steps[step_index];
        compare_scalar(
            format!("{step_path}.col"),
            &expected_step.col(),
            &actual_step.col(),
            output,
        );
        compare_scalar(
            format!("{step_path}.row"),
            &expected_step.row(),
            &actual_step.row(),
            output,
        );
        compare_scalar(
            format!("{step_path}.enterCost"),
            &expected_step.enter_cost(),
            &actual_step.enter_cost(),
            output,
        );
        compare_scalar(
            format!("{step_path}.cumulativeCost"),
            &expected_step.cumulative_cost(),
            &actual_step.cumulative_cost(),
            output,
        );
    }
    collect_typed_array_tail(
        &format!("{path}.steps"),
        expected_steps.len(),
        actual_steps.len(),
        common_length,
        output,
    );
}

fn compare_scalar<Value: ToString + PartialEq + ?Sized>(
    path: String,
    expected: &Value,
    actual: &Value,
    output: &mut Vec<JsonDifference>,
) {
    if output.len() >= MAX_DIFFERENCES || expected == actual {
        return;
    }
    output.push(JsonDifference {
        path: path.into_boxed_str(),
        kind: DifferenceKind::ValueMismatch,
        expected: Some(expected.to_string().into_boxed_str()),
        actual: Some(actual.to_string().into_boxed_str()),
    });
}

fn collect_typed_array_tail(
    path: &str,
    expected_length: usize,
    actual_length: usize,
    common_length: usize,
    output: &mut Vec<JsonDifference>,
) {
    for index in common_length..expected_length {
        if output.len() >= MAX_DIFFERENCES {
            return;
        }
        output.push(JsonDifference {
            path: format!("{path}[{index}]").into_boxed_str(),
            kind: DifferenceKind::Missing,
            expected: Some("object".into()),
            actual: None,
        });
    }
    for index in common_length..actual_length {
        if output.len() >= MAX_DIFFERENCES {
            return;
        }
        output.push(JsonDifference {
            path: format!("{path}[{index}]").into_boxed_str(),
            kind: DifferenceKind::Unexpected,
            expected: None,
            actual: Some("object".into()),
        });
    }
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
            collect_object_differences(path, expected, actual, output);
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

fn collect_object_differences(
    path: &str,
    expected: &Map<String, Value>,
    actual: &Map<String, Value>,
    output: &mut Vec<JsonDifference>,
) {
    for (key, expected_value) in expected {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        let child_path = object_path(path, key);
        if let Some(actual_value) = actual.get(key) {
            collect_differences(&child_path, expected_value, actual_value, output);
        } else {
            output.push(difference(
                child_path,
                DifferenceKind::Missing,
                Some(expected_value),
                None,
            ));
        }
    }
    for (key, actual_value) in actual {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        if !expected.contains_key(key) {
            output.push(difference(
                object_path(path, key),
                DifferenceKind::Unexpected,
                None,
                Some(actual_value),
            ));
        }
    }
}

fn collect_object_array_differences(
    path: &str,
    expected: &[Map<String, Value>],
    actual: &[Map<String, Value>],
    output: &mut Vec<JsonDifference>,
) {
    if output.len() >= MAX_DIFFERENCES || expected == actual {
        return;
    }
    let common_length = expected.len().min(actual.len());
    for index in 0..common_length {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        collect_object_differences(
            &format!("{path}[{index}]"),
            &expected[index],
            &actual[index],
            output,
        );
    }
    for (index, item) in expected.iter().enumerate().skip(common_length) {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        output.push(JsonDifference {
            path: format!("{path}[{index}]").into_boxed_str(),
            kind: DifferenceKind::Missing,
            expected: Some(format!("object(len={})", item.len()).into_boxed_str()),
            actual: None,
        });
    }
    for (index, item) in actual.iter().enumerate().skip(common_length) {
        if output.len() >= MAX_DIFFERENCES {
            break;
        }
        output.push(JsonDifference {
            path: format!("{path}[{index}]").into_boxed_str(),
            kind: DifferenceKind::Unexpected,
            expected: None,
            actual: Some(format!("object(len={})", item.len()).into_boxed_str()),
        });
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
    match value {
        Value::Array(values) => format!("array(len={})", values.len()).into_boxed_str(),
        Value::Object(values) => format!("object(len={})", values.len()).into_boxed_str(),
        Value::String(value) => render_string(value),
        _ => value.to_string().into_boxed_str(),
    }
}

fn render_optional_string(value: Option<&str>) -> Box<str> {
    value.map_or_else(|| "null".into(), render_string)
}

fn render_string(value: &str) -> Box<str> {
    if value.len() <= MAX_RENDERED_VALUE_BYTES {
        return serde_json::to_string(value)
            .expect("string encoding is infallible")
            .into_boxed_str();
    }
    let mut boundary = MAX_RENDERED_VALUE_BYTES;
    while !value.is_char_boundary(boundary) {
        boundary -= 1;
    }
    format!("{:?}…", &value[..boundary]).into_boxed_str()
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
        assert_eq!(differences[0].path(), "$.state.turn");
        assert_eq!(differences[0].kind(), DifferenceKind::Missing);
        assert_eq!(differences[1].path(), "$.state.offset");
        assert_eq!(differences[1].kind(), DifferenceKind::Unexpected);
    }

    #[test]
    fn reported_differences_are_bounded() {
        let expected = json!((0..100).collect::<Vec<_>>());
        let actual = json!((100..200).collect::<Vec<_>>());

        assert_eq!(compare_json(&expected, &actual).len(), 64);
    }
}
