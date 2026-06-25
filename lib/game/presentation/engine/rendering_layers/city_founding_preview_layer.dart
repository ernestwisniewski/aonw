import 'dart:async';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city_founding_preview.dart';
import 'package:aonw/map/domain/map_data.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class CityFoundingPreviewLayer extends Component with LayerAttachment {
  final int Function(String playerId) colorForPlayer;
  CityFoundingPreview? _component;
  String? _signature;

  CityFoundingPreviewLayer({required this.colorForPlayer}) {
    priority = MapPriority.intentOverlay;
  }

  void sync({
    required Component parent,
    required CityFoundingDraft? draft,
    required MapData mapData,
    required Iterable<GameCity> cities,
    bool Function(CityHex hex)? canShowHex,
  }) {
    ensureAttachedTo(parent);
    if (draft == null) {
      clear();
      return;
    }

    final controlled = draft.controlledHexes.toSet();
    final candidateHexes =
        <_FoundingCandidateHex>[
          for (final tile in mapData.tiles)
            if (CityFoundingRules.isControlledHexCandidate(
                  draft: draft,
                  tile: tile,
                  mapData: mapData,
                  cities: cities,
                ) &&
                !controlled.contains(CityHex(col: tile.col, row: tile.row)) &&
                (canShowHex?.call(CityHex(col: tile.col, row: tile.row)) ??
                    true))
              _FoundingCandidateHex(
                hex: CityHex(col: tile.col, row: tile.row),
                score: CityExpansionSelector.score(
                  tile,
                  ruleset: CityRulesets.standard,
                ),
              ),
        ]..sort((a, b) {
          final scoreCompare = b.score.compareTo(a.score);
          if (scoreCompare != 0) return scoreCompare;
          final colCompare = a.hex.col.compareTo(b.hex.col);
          if (colCompare != 0) return colCompare;
          return a.hex.row.compareTo(b.hex.row);
        });
    final recommendedCount =
        CityFoundingDraft.requiredControlledHexes -
        draft.controlledHexes.length;
    final signature = _signatureFor(
      draft: draft,
      candidateHexes: candidateHexes,
      recommendedCount: recommendedCount,
    );
    if (_component != null && _signature == signature) return;
    clear();

    final component = CityFoundingPreview(
      draft: draft,
      candidateHexes: [
        for (var i = 0; i < candidateHexes.length; i++)
          CityFoundingCandidateHex(
            hex: candidateHexes[i].hex,
            recommended: i < recommendedCount,
          ),
      ],
      controlledHexes: draft.controlledHexes,
      cityColor: Color(colorForPlayer(draft.ownerPlayerId)),
    );
    _component = component;
    _signature = signature;
    unawaited(Future<void>.value(add(component)));
  }

  void clear() {
    _component?.removeFromParent();
    _component = null;
    _signature = null;
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  String _signatureFor({
    required CityFoundingDraft draft,
    required List<_FoundingCandidateHex> candidateHexes,
    required int recommendedCount,
  }) {
    final buffer = StringBuffer()
      ..write(draft.ownerPlayerId)
      ..write('|')
      ..write(draft.center.col)
      ..write(',')
      ..write(draft.center.row)
      ..write('|')
      ..write(colorForPlayer(draft.ownerPlayerId))
      ..write('|controlled:');
    for (final hex in draft.controlledHexes) {
      buffer
        ..write(hex.col)
        ..write(',')
        ..write(hex.row)
        ..write(';');
    }
    buffer
      ..write('|candidates:')
      ..write(recommendedCount)
      ..write(':');
    for (final candidate in candidateHexes) {
      buffer
        ..write(candidate.hex.col)
        ..write(',')
        ..write(candidate.hex.row)
        ..write(';');
    }
    return buffer.toString();
  }

  CityFoundingPreview? get componentForTesting => _component;
}

class _FoundingCandidateHex {
  final CityHex hex;
  final int score;

  const _FoundingCandidateHex({required this.hex, required this.score});
}
