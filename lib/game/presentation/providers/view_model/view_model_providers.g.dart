// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'view_model_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(technologyPanelViewModel)
final technologyPanelViewModelProvider = TechnologyPanelViewModelFamily._();

final class TechnologyPanelViewModelProvider
    extends
        $FunctionalProvider<
          TechnologyPanelViewModel,
          TechnologyPanelViewModel,
          TechnologyPanelViewModel
        >
    with $Provider<TechnologyPanelViewModel> {
  TechnologyPanelViewModelProvider._({
    required TechnologyPanelViewModelFamily super.from,
    required (String, String) super.argument,
  }) : super(
         retry: null,
         name: r'technologyPanelViewModelProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = gameStateProvider;
  static final $allTransitiveDependencies1 =
      GameStateNotifierProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies2 =
      GameStateNotifierProvider.$allTransitiveDependencies1;
  static final $allTransitiveDependencies3 =
      GameStateNotifierProvider.$allTransitiveDependencies2;
  static final $allTransitiveDependencies4 =
      GameStateNotifierProvider.$allTransitiveDependencies3;

  @override
  String debugGetCreateSourceHash() => _$technologyPanelViewModelHash();

  @override
  String toString() {
    return r'technologyPanelViewModelProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $ProviderElement<TechnologyPanelViewModel> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TechnologyPanelViewModel create(Ref ref) {
    final argument = this.argument as (String, String);
    return technologyPanelViewModel(ref, argument.$1, argument.$2);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TechnologyPanelViewModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TechnologyPanelViewModel>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TechnologyPanelViewModelProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$technologyPanelViewModelHash() =>
    r'f115d174e7f90514df9d040603cbdf237a3cce39';

final class TechnologyPanelViewModelFamily extends $Family
    with $FunctionalFamilyOverride<TechnologyPanelViewModel, (String, String)> {
  TechnologyPanelViewModelFamily._()
    : super(
        retry: null,
        name: r'technologyPanelViewModelProvider',
        dependencies: <ProviderOrFamily>[
          gameStateProvider,
          activeGameSessionProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          TechnologyPanelViewModelProvider.$allTransitiveDependencies0,
          TechnologyPanelViewModelProvider.$allTransitiveDependencies1,
          TechnologyPanelViewModelProvider.$allTransitiveDependencies2,
          TechnologyPanelViewModelProvider.$allTransitiveDependencies3,
          TechnologyPanelViewModelProvider.$allTransitiveDependencies4,
        },
        isAutoDispose: true,
      );

  TechnologyPanelViewModelProvider call(String saveId, String playerId) =>
      TechnologyPanelViewModelProvider._(
        argument: (saveId, playerId),
        from: this,
      );

  @override
  String toString() => r'technologyPanelViewModelProvider';
}
