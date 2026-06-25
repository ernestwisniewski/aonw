import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/presentation/widgets/city/city_production_item_view_model.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations_en.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CityProductionItem.project exposes continuous project labels', () {
    final item = CityProductionItem.project(
      type: CityProjectType.research,
      productionPerTurn: 5,
      active: true,
      l10n: AppLocalizationsEn(),
    );

    expect(item.title, 'Research');
    expect(item.icon, GameIcons.science);
    expect(item.continuous, isTrue);
    expect(item.progress, 0);
    expect(item.canBeRushed, isFalse);
    expect(item.metaLabels, ['continuous', '+1 science / turn']);
  });

  test('CityProductionItem.unit exposes progress and rush state', () {
    final l10n = AppLocalizationsEn();
    final item = CityProductionItem.unit(
      l10n: l10n,
      type: GameUnitType.warrior,
      title: 'Warrior',
      active: true,
      investedProduction: 10,
      totalCost: 20,
      productionPerTurn: 5,
      turnsRemaining: 2,
      currentTurn: 6,
    );

    expect(item.icon, GameIcons.warrior);
    expect(item.progress, 0.5);
    expect(item.canBeRushed, isTrue);
    expect(item.effectiveEta.compactLabel(l10n), '2 turns • T8');
  });
}
