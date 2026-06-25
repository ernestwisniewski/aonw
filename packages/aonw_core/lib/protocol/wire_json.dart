import 'package:aonw_core/protocol/protocol_version.dart';

abstract final class WireJson {
  static int readVersion(Map<String, dynamic> json, String type) {
    final version = requiredInt(json, type, 'v');
    if (version != kProtocolVersion) {
      throw ArgumentError.value(
        version,
        '$type.v',
        'Unsupported protocol version; expected $kProtocolVersion',
      );
    }
    return version;
  }

  static String requiredString(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      '$type.$field',
      'Expected a non-empty String',
    );
  }

  static String? optionalString(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return null;
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      '$type.$field',
      'Expected a non-empty String or null',
    );
  }

  static int requiredInt(Map<String, dynamic> json, String type, String field) {
    final value = json[field];
    if (value is int) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected an int');
  }

  static int? optionalInt(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return null;
    if (value is int) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected an int or null');
  }

  static bool? optionalBool(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = json[field];
    if (value == null) return null;
    if (value is bool) return value;
    throw ArgumentError.value(value, '$type.$field', 'Expected a bool or null');
  }

  static Map<String, dynamic> requiredMap(Object? value, String field) {
    if (value is Map<Object?, Object?>) {
      return Map.unmodifiable(Map<String, dynamic>.from(value));
    }
    throw ArgumentError.value(value, field, 'Expected a JSON object');
  }

  static List<dynamic> requiredList(Object? value, String field) {
    if (value is List<dynamic>) return List.unmodifiable(value);
    throw ArgumentError.value(value, field, 'Expected a JSON array');
  }

  static DateTime requiredDateTimeUtc(
    Map<String, dynamic> json,
    String type,
    String field,
  ) {
    final value = requiredString(json, type, field);
    return DateTime.parse(value).toUtc();
  }

  static T requiredEnum<T extends Enum>(
    Map<String, dynamic> json,
    String type,
    String field,
    Iterable<T> values,
  ) {
    final name = requiredString(json, type, field);
    for (final value in values) {
      if (value.name == name) return value;
    }
    throw ArgumentError.value(name, '$type.$field', 'Unknown value');
  }
}
