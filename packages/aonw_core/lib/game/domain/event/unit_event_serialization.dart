import 'package:aonw_core/game/domain/event/game_event.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:aonw_core/util/wire_json.dart';

abstract final class UnitEventSerializer {
  static Map<String, dynamic> toJson(UnitPresentationEvent event) {
    return switch (event) {
      UnitMovedEvent(
        :final unitId,
        :final fromCol,
        :final fromRow,
        :final toCol,
        :final toRow,
      ) =>
        {
          'type': 'UnitMoved',
          'unitId': unitId,
          'fromCol': fromCol,
          'fromRow': fromRow,
          'toCol': toCol,
          'toRow': toRow,
        },
      FortifiedUnitThreatenedEvent(
        :final unitId,
        :final ownerPlayerId,
        :final targets,
      ) =>
        {
          'type': 'FortifiedUnitThreatened',
          'unitId': unitId,
          'ownerPlayerId': ownerPlayerId,
          'targets': [
            for (final target in targets)
              {'unitId': target.unitId, 'col': target.col, 'row': target.row},
          ],
        },
      UnitGainedExperienceEvent(
        :final unitId,
        :final ownerPlayerId,
        :final amount,
        :final totalExperience,
        :final rank,
        :final promoted,
      ) =>
        {
          'type': 'UnitGainedExperience',
          'unitId': unitId,
          'ownerPlayerId': ownerPlayerId,
          'amount': amount,
          'totalExperience': totalExperience,
          'rank': rank.name,
          'promoted': promoted,
        },
    };
  }

  static GameEvent? tryFromJson(Map<String, dynamic> json, String type) {
    return switch (type) {
      'UnitMoved' => UnitMovedEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        fromCol: requiredIntField(json, type, 'fromCol'),
        fromRow: requiredIntField(json, type, 'fromRow'),
        toCol: requiredIntField(json, type, 'toCol'),
        toRow: requiredIntField(json, type, 'toRow'),
      ),
      'FortifiedUnitThreatened' => FortifiedUnitThreatenedEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        targets: [
          for (final value in requiredListField(json, type, 'targets'))
            _targetFromJson(
              requiredMapValue(value, '$type.targets[]'),
              '$type.targets[]',
            ),
        ],
      ),
      'UnitGainedExperience' => UnitGainedExperienceEvent(
        unitId: requiredStringField(json, type, 'unitId'),
        ownerPlayerId: requiredStringField(json, type, 'ownerPlayerId'),
        amount: requiredIntField(json, type, 'amount'),
        totalExperience: requiredIntField(json, type, 'totalExperience'),
        rank: requiredEnumField(json, type, 'rank', UnitVeterancyRank.values),
        promoted: requiredBoolField(json, type, 'promoted'),
      ),
      _ => null,
    };
  }

  static FortifiedUnitThreatTarget _targetFromJson(
    Map<String, dynamic> json,
    String context,
  ) {
    return FortifiedUnitThreatTarget(
      unitId: requiredStringField(json, context, 'unitId'),
      col: requiredIntField(json, context, 'col'),
      row: requiredIntField(json, context, 'row'),
    );
  }
}
