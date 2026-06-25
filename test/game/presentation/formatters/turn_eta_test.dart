import 'package:aonw/game/presentation/formatters/turn_eta.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TurnEtaFormatter', () {
    final l10n = AppLocalizationsEn();

    test('formats remaining turns and expected completion turn', () {
      final eta = TurnEtaFormatter.fromTurns(turnsRemaining: 3, currentTurn: 5);

      expect(eta.turnsLabel(l10n), '3 turns');
      expect(eta.completionTurnLabel(l10n), 'T8');
      expect(eta.compactLabel(l10n), '3 turns • T8');
      expect(eta.detailLabel(l10n), '3 turns • turn 8');
    });

    test('uses blocked label when there is no progress', () {
      final eta = TurnEtaFormatter.fromProgress(
        remaining: 12,
        perTurn: 0,
        currentTurn: 5,
        blockedLabel: 'stagnation',
      );

      expect(eta.hasTurns, isFalse);
      expect(eta.compactLabel(l10n), 'stagnation');
      expect(eta.completionTurnLabel(l10n), isNull);
    });

    test('uses ready label for completed progress', () {
      final eta = TurnEtaFormatter.fromProgress(
        remaining: 0,
        perTurn: 4,
        currentTurn: 5,
      );

      expect(eta.turnsLabel(l10n), 'ready');
      expect(eta.compactLabel(l10n), 'ready • T5');
    });
  });
}
