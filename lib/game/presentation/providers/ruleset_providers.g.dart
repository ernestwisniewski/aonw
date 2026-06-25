// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ruleset_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(cityRuleset)
final cityRulesetProvider = CityRulesetProvider._();

final class CityRulesetProvider
    extends $FunctionalProvider<CityRuleset, CityRuleset, CityRuleset>
    with $Provider<CityRuleset> {
  CityRulesetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cityRulesetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cityRulesetHash();

  @$internal
  @override
  $ProviderElement<CityRuleset> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CityRuleset create(Ref ref) {
    return cityRuleset(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CityRuleset value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CityRuleset>(value),
    );
  }
}

String _$cityRulesetHash() => r'f6179fb99a8e0529625f33fd798a14872580dca1';

@ProviderFor(technologyRuleset)
final technologyRulesetProvider = TechnologyRulesetProvider._();

final class TechnologyRulesetProvider
    extends
        $FunctionalProvider<
          TechnologyRuleset,
          TechnologyRuleset,
          TechnologyRuleset
        >
    with $Provider<TechnologyRuleset> {
  TechnologyRulesetProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'technologyRulesetProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$technologyRulesetHash();

  @$internal
  @override
  $ProviderElement<TechnologyRuleset> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnologyRuleset create(Ref ref) {
    return technologyRuleset(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnologyRuleset value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnologyRuleset>(value),
    );
  }
}

String _$technologyRulesetHash() => r'ed1867aaa2f45814be512d2b2aa2978eff056bef';
