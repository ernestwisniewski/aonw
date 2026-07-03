import 'package:aonw/game/domain/city.dart';
import 'package:aonw_core/game/domain/stability.dart';
import 'package:aonw_core/game/domain/technology.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ruleset_providers.g.dart';

@riverpod
CityRuleset cityRuleset(Ref ref) {
  return CityRulesets.standard;
}

@riverpod
TechnologyRuleset technologyRuleset(Ref ref) {
  return TechnologyRulesets.standard;
}

@riverpod
StabilityRuleset stabilityRuleset(Ref ref) {
  return StabilityRuleset.standard;
}
