library;

final class WireJson {
  const WireJson(this.json, this.context);

  final Map<String, dynamic> json;
  final String context;

  String requiredString(String field) =>
      requiredStringField(json, context, field);

  String? optionalString(String field) =>
      optionalStringField(json, context, field);

  int requiredInt(String field) => requiredIntField(json, context, field);

  int? optionalInt(String field) => optionalIntField(json, context, field);

  double requiredDouble(String field) =>
      requiredDoubleField(json, context, field);

  double? optionalDouble(String field) =>
      optionalDoubleField(json, context, field);

  bool requiredBool(String field) => requiredBoolField(json, context, field);

  List<dynamic> requiredList(String field) =>
      requiredListField(json, context, field);

  List<String> requiredStringList(String field) =>
      requiredStringListField(json, context, field);

  Map<String, dynamic> requiredMap(String field) =>
      requiredMapValue(json[field], '$context.$field');

  T requiredEnum<T extends Enum>(String field, Iterable<T> values) =>
      requiredEnumField(json, context, field, values);

  T? optionalEnum<T extends Enum>(String field, Iterable<T> values) =>
      optionalEnumField(json, context, field, values);
}

String requiredStringField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  return requiredStringValue(json[field], '$context.$field');
}

String requiredStringValue(Object? value, String name) {
  if (value is String && value.isNotEmpty) return value;
  throw ArgumentError.value(value, name, 'Expected a non-empty String');
}

String? optionalStringField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is String && value.isNotEmpty) return value;
  throw ArgumentError.value(
    value,
    '$context.$field',
    'Expected a non-empty String or null',
  );
}

int requiredIntField(Map<String, dynamic> json, String context, String field) {
  return requiredIntValue(json[field], '$context.$field');
}

int requiredIntValue(Object? value, String name) {
  final intValue = _intValue(value);
  if (intValue != null) return intValue;
  throw ArgumentError.value(value, name, 'Expected an int');
}

int? optionalIntField(Map<String, dynamic> json, String context, String field) {
  final value = json[field];
  if (value == null) return null;
  final intValue = _intValue(value);
  if (intValue != null) return intValue;
  throw ArgumentError.value(
    value,
    '$context.$field',
    'Expected an int or null',
  );
}

double requiredDoubleField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value is num) return value.toDouble();
  throw ArgumentError.value(value, '$context.$field', 'Expected a number');
}

double? optionalDoubleField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value == null) return null;
  if (value is num) return value.toDouble();
  throw ArgumentError.value(
    value,
    '$context.$field',
    'Expected a number or null',
  );
}

bool requiredBoolField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value is bool) return value;
  throw ArgumentError.value(value, '$context.$field', 'Expected a bool');
}

List<dynamic> requiredListField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value is List) return value;
  throw ArgumentError.value(value, '$context.$field', 'Expected a List');
}

List<String> requiredStringListField(
  Map<String, dynamic> json,
  String context,
  String field,
) {
  final value = json[field];
  if (value is! List) {
    throw ArgumentError.value(value, '$context.$field', 'Expected a list');
  }
  return [
    for (final entry in value)
      if (entry is String && entry.isNotEmpty)
        entry
      else
        throw ArgumentError.value(
          entry,
          '$context.$field',
          'Expected a list of non-empty strings',
        ),
  ];
}

Map<String, dynamic> requiredMapValue(Object? value, String name) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw ArgumentError.value(value, name, 'Expected a JSON object');
}

T requiredEnumField<T extends Enum>(
  Map<String, dynamic> json,
  String context,
  String field,
  Iterable<T> values,
) {
  return enumByName(
    requiredStringField(json, context, field),
    values,
    '$context.$field',
  );
}

T? optionalEnumField<T extends Enum>(
  Map<String, dynamic> json,
  String context,
  String field,
  Iterable<T> values,
) {
  return optionalEnumByName(
    optionalStringField(json, context, field),
    values,
    '$context.$field',
  );
}

T enumByName<T extends Enum>(Object? value, Iterable<T> values, String field) {
  if (value is! String || value.isEmpty) {
    throw ArgumentError.value(value, field, 'Expected a non-empty String');
  }
  for (final enumValue in values) {
    if (enumValue.name == value) return enumValue;
  }
  throw ArgumentError.value(value, field, 'Unknown value');
}

T? optionalEnumByName<T extends Enum>(
  Object? value,
  Iterable<T> values,
  String field,
) {
  if (value == null) return null;
  return enumByName(value, values, field);
}

int? _intValue(Object? value) {
  if (value is int) return value;
  if (value is num && value.isFinite) {
    final intValue = value.toInt();
    if (value == intValue) return intValue;
  }
  return null;
}
