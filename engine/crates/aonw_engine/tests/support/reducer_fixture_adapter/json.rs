use std::fmt;

use aonw_contracts::CoordinateDto;
use aonw_domain::HexCoord;
use aonw_testkit::{JsonObject, MovementExecution, MovementStep};
use serde_json::{Map, Value};

use super::AdapterError;

pub(super) fn decode_coordinates(
    values: &[Value],
    path: &str,
) -> Result<Vec<CoordinateDto>, AdapterError> {
    values
        .iter()
        .enumerate()
        .map(|(index, value)| {
            let path = format!("{path}[{index}]");
            object_at(value, &path)
                .and_then(|object| coordinate_fields(object, &path))
                .map(coordinate_dto)
        })
        .collect()
}

pub(super) fn coordinate_dto(coordinate: HexCoord) -> CoordinateDto {
    CoordinateDto {
        col: coordinate.col(),
        row: coordinate.row(),
    }
}

pub(super) fn coordinate_fields(object: &JsonObject, path: &str) -> Result<HexCoord, AdapterError> {
    Ok(HexCoord::new(
        required_i32_at(object, "col", path)?,
        required_i32_at(object, "row", path)?,
    ))
}

pub(super) fn object_at<'value>(
    value: &'value Value,
    path: &str,
) -> Result<&'value JsonObject, AdapterError> {
    value
        .as_object()
        .ok_or_else(|| error(format!("{path} must be an object")))
}

pub(super) fn required_array<'value>(
    object: &'value JsonObject,
    field: &str,
) -> Result<&'value Vec<Value>, AdapterError> {
    object
        .get(field)
        .and_then(Value::as_array)
        .ok_or_else(|| error(format!("{field} must be an array")))
}

pub(super) fn required_string<'value>(
    object: &'value JsonObject,
    field: &str,
) -> Result<&'value str, AdapterError> {
    required_string_at(object, field, "input")
}

pub(super) fn required_string_at<'value>(
    object: &'value Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<&'value str, AdapterError> {
    object
        .get(field)
        .and_then(Value::as_str)
        .ok_or_else(|| error(format!("{path}.{field} must be a string")))
}

pub(super) fn optional_string(
    object: &JsonObject,
    field: &str,
) -> Result<Option<String>, AdapterError> {
    match object.get(field) {
        None | Some(Value::Null) => Ok(None),
        Some(Value::String(value)) => Ok(Some(value.clone())),
        Some(_) => Err(error(format!("{field} must be a string or null"))),
    }
}

pub(super) fn required_i32(object: &JsonObject, field: &str) -> Result<i32, AdapterError> {
    required_i32_at(object, field, "input")
}

pub(super) fn required_i32_at(
    object: &Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<i32, AdapterError> {
    let value = object
        .get(field)
        .ok_or_else(|| error(format!("{path}.{field} is required")))?
        .as_i64()
        .ok_or_else(|| error(format!("{path}.{field} must be an integer")))?;
    i32::try_from(value).map_err(display_error)
}

pub(super) fn required_u32(object: &JsonObject, field: &str) -> Result<u32, AdapterError> {
    required_u32_at(object, field, "input")
}

pub(super) fn required_u32_at(
    object: &Map<String, Value>,
    field: &str,
    path: &str,
) -> Result<u32, AdapterError> {
    object
        .get(field)
        .ok_or_else(|| error(format!("{path}.{field} is required")))
        .and_then(|value| value_to_u32(value, &format!("{path}.{field}")))
}

pub(super) fn value_to_u32(value: &Value, path: &str) -> Result<u32, AdapterError> {
    value
        .as_u64()
        .ok_or_else(|| error(format!("{path} must be a non-negative integer")))
        .and_then(|value| u32::try_from(value).map_err(display_error))
}

pub(super) fn json_object(value: &Value) -> Result<JsonObject, AdapterError> {
    value
        .as_object()
        .cloned()
        .ok_or_else(|| error("event must be an object"))
}

pub(super) fn error(message: impl Into<String>) -> AdapterError {
    AdapterError(message.into())
}

pub(super) fn display_error(source: impl fmt::Display) -> AdapterError {
    error(source.to_string())
}

pub(super) fn movement_execution(
    unit_id: &str,
    from: HexCoord,
    steps: impl IntoIterator<Item = (HexCoord, u32, u32)>,
) -> Result<MovementExecution, AdapterError> {
    let steps = steps
        .into_iter()
        .map(|(coordinate, enter_cost, cumulative_cost)| {
            Ok(MovementStep::new(
                u32::try_from(coordinate.col()).map_err(display_error)?,
                u32::try_from(coordinate.row()).map_err(display_error)?,
                enter_cost,
                cumulative_cost,
            ))
        })
        .collect::<Result<Vec<_>, AdapterError>>()?;
    MovementExecution::try_new(
        unit_id,
        u32::try_from(from.col()).map_err(display_error)?,
        u32::try_from(from.row()).map_err(display_error)?,
        steps,
    )
    .map_err(display_error)
}
