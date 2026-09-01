use std::collections::BTreeMap;

/// Exact finite JSON number used by immutable rule configuration.
#[derive(Clone, Debug, Eq, PartialEq)]
pub struct RuleNumber(Box<str>);

/// Failure raised for a non-JSON numeric representation.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub struct RuleNumberError;

impl core::fmt::Display for RuleNumberError {
    fn fmt(&self, formatter: &mut core::fmt::Formatter<'_>) -> core::fmt::Result {
        formatter.write_str("rule number must use finite JSON number syntax")
    }
}

impl std::error::Error for RuleNumberError {}

impl RuleNumber {
    /// Preserves an exact JSON number after lexical validation.
    ///
    /// # Errors
    ///
    /// Returns [`RuleNumberError`] when the value is not a JSON number.
    pub fn new(value: impl Into<Box<str>>) -> Result<Self, RuleNumberError> {
        let value = value.into();
        if is_json_number(&value) {
            Ok(Self(value))
        } else {
            Err(RuleNumberError)
        }
    }

    /// Returns the exact JSON representation.
    #[must_use]
    pub fn as_str(&self) -> &str {
        &self.0
    }
}

/// Typed recursive value used by the open-ended match balance object.
#[derive(Clone, Debug, Eq, PartialEq)]
pub enum RuleValue {
    /// JSON null.
    Null,
    /// JSON boolean.
    Bool(bool),
    /// Exact JSON number.
    Number(RuleNumber),
    /// JSON string.
    String(Box<str>),
    /// Ordered JSON array.
    Array(Box<[Self]>),
    /// Key-sorted JSON object.
    Object(BTreeMap<Box<str>, Self>),
}

fn is_json_number(value: &str) -> bool {
    let bytes = value.as_bytes();
    let mut index = usize::from(bytes.first() == Some(&b'-'));
    if index == bytes.len() {
        return false;
    }
    match bytes[index] {
        b'0' => index += 1,
        b'1'..=b'9' => {
            index += 1;
            while bytes.get(index).is_some_and(u8::is_ascii_digit) {
                index += 1;
            }
        }
        _ => return false,
    }
    if bytes.get(index) == Some(&b'.') {
        index += 1;
        let start = index;
        while bytes.get(index).is_some_and(u8::is_ascii_digit) {
            index += 1;
        }
        if start == index {
            return false;
        }
    }
    if matches!(bytes.get(index), Some(b'e' | b'E')) {
        index += 1;
        if matches!(bytes.get(index), Some(b'+' | b'-')) {
            index += 1;
        }
        let start = index;
        while bytes.get(index).is_some_and(u8::is_ascii_digit) {
            index += 1;
        }
        if start == index {
            return false;
        }
    }
    index == bytes.len()
}

#[cfg(test)]
mod tests {
    use super::{RuleNumber, RuleNumberError};

    #[test]
    fn exact_json_numbers_are_validated_without_float_rounding() {
        assert_eq!(
            RuleNumber::new("12345678901234567890.125e-7")
                .expect("valid")
                .as_str(),
            "12345678901234567890.125e-7"
        );
        assert_eq!(RuleNumber::new("01"), Err(RuleNumberError));
        assert_eq!(RuleNumber::new("NaN"), Err(RuleNumberError));
    }
}
