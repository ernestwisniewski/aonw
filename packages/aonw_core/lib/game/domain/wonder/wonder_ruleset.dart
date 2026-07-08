import 'package:aonw_core/game/domain/wonder/wonder_catalog.dart';
import 'package:aonw_core/game/domain/wonder/wonder_definition.dart';
import 'package:aonw_core/game/domain/wonder/wonder_type.dart';

class WonderRuleset {
  const WonderRuleset({required this.wonders});

  static const standard = WonderRuleset(wonders: WonderCatalog.standard);

  final Map<WonderType, WonderDefinition> wonders;

  WonderDefinition definitionFor(WonderType type) {
    final definition = wonders[type];
    if (definition == null) {
      throw ArgumentError('Missing wonder definition for: ${type.name}');
    }
    return definition;
  }
}
