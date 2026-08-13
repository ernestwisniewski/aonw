use std::fmt;

use godot::prelude::GString;
use serde_json::{Value, json};

pub(crate) fn success_json(value: &Value) -> GString {
    encode_json(&json!({"ok": true, "value": value}))
}

pub(crate) fn failure_json(code: &str, error: impl fmt::Display) -> GString {
    encode_json(&json!({
        "ok": false,
        "code": code,
        "message": error.to_string(),
    }))
}

fn encode_json(value: &Value) -> GString {
    let encoded = serde_json::to_string(value).unwrap_or_else(|_| {
        r#"{"ok":false,"code":"adapter_serialization_failed","message":"adapter serialization failed"}"#.to_owned()
    });
    GString::from(&encoded)
}
