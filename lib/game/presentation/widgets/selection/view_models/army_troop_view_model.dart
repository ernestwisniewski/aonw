import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw_core/game/domain/unit.dart';

class ArmyTroopViewModel {
  final TroopType type;
  final String name;
  final GameIconData icon;
  final int count;

  const ArmyTroopViewModel({
    required this.type,
    required this.name,
    required this.icon,
    required this.count,
  });

  factory ArmyTroopViewModel.fromTroop(ArmyTroop troop, AppLocalizations l10n) {
    return ArmyTroopViewModel(
      type: troop.type,
      name: GameDisplayNames.troopType(l10n, troop.type),
      icon: _iconFor(troop.type),
      count: troop.count,
    );
  }

  static GameIconData _iconFor(TroopType type) {
    return switch (type) {
      TroopType.warrior => GameIcons.warrior,
      TroopType.archer => GameIcons.archer,
      TroopType.settler => GameIcons.settler,
    };
  }
}
