import 'package:aonw_core/map/domain/terrain_type.dart';

final class ResourceTradeAgreement {
  const ResourceTradeAgreement({
    required this.id,
    required this.exporterPlayerId,
    required this.importerPlayerId,
    required this.resource,
    required this.goldPerTurn,
    required this.remainingTurns,
  });

  factory ResourceTradeAgreement.fromJson(Map<String, dynamic> json) {
    return ResourceTradeAgreement(
      id: _stringField(json, 'id'),
      exporterPlayerId: _stringField(json, 'exporterPlayerId'),
      importerPlayerId: _stringField(json, 'importerPlayerId'),
      resource: ResourceType.values.byName(_stringField(json, 'resource')),
      goldPerTurn: _nonNegativeIntField(json, 'goldPerTurn'),
      remainingTurns: _positiveIntField(json, 'remainingTurns'),
    );
  }

  final String id;
  final String exporterPlayerId;
  final String importerPlayerId;
  final ResourceType resource;
  final int goldPerTurn;
  final int remainingTurns;

  bool get isActive => remainingTurns > 0;

  bool importsFor(String playerId) => isActive && importerPlayerId == playerId;

  ResourceTradeAgreement copyWith({int? remainingTurns}) {
    return ResourceTradeAgreement(
      id: id,
      exporterPlayerId: exporterPlayerId,
      importerPlayerId: importerPlayerId,
      resource: resource,
      goldPerTurn: goldPerTurn,
      remainingTurns: remainingTurns ?? this.remainingTurns,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'exporterPlayerId': exporterPlayerId,
    'importerPlayerId': importerPlayerId,
    'resource': resource.name,
    if (goldPerTurn != 0) 'goldPerTurn': goldPerTurn,
    'remainingTurns': remainingTurns,
  };

  @override
  bool operator ==(Object other) =>
      other is ResourceTradeAgreement &&
      other.id == id &&
      other.exporterPlayerId == exporterPlayerId &&
      other.importerPlayerId == importerPlayerId &&
      other.resource == resource &&
      other.goldPerTurn == goldPerTurn &&
      other.remainingTurns == remainingTurns;

  @override
  int get hashCode => Object.hash(
    ResourceTradeAgreement,
    id,
    exporterPlayerId,
    importerPlayerId,
    resource,
    goldPerTurn,
    remainingTurns,
  );

  static String _stringField(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is String && value.isNotEmpty) return value;
    throw ArgumentError.value(
      value,
      'ResourceTradeAgreement.$field',
      'Expected a non-empty String',
    );
  }

  static int _nonNegativeIntField(Map<String, dynamic> json, String field) {
    final value = json[field] ?? 0;
    if (value is num && value >= 0 && value.toInt() == value) {
      return value.toInt();
    }
    throw ArgumentError.value(
      value,
      'ResourceTradeAgreement.$field',
      'Expected a non-negative integer',
    );
  }

  static int _positiveIntField(Map<String, dynamic> json, String field) {
    final value = json[field];
    if (value is num && value > 0 && value.toInt() == value) {
      return value.toInt();
    }
    throw ArgumentError.value(
      value,
      'ResourceTradeAgreement.$field',
      'Expected a positive integer',
    );
  }
}
