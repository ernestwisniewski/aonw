// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_actions_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Coordinates player commands with the active save and renderer view model.

@ProviderFor(GameCommandController)
final gameCommandControllerProvider = GameCommandControllerProvider._();

/// Coordinates player commands with the active save and renderer view model.
final class GameCommandControllerProvider
    extends $NotifierProvider<GameCommandController, void> {
  /// Coordinates player commands with the active save and renderer view model.
  GameCommandControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameCommandControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          activeGameSessionProvider,
          activeRendererViewModelProvider,
          gameStateProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          GameCommandControllerProvider.$allTransitiveDependencies0,
          GameCommandControllerProvider.$allTransitiveDependencies1,
          GameCommandControllerProvider.$allTransitiveDependencies2,
          GameCommandControllerProvider.$allTransitiveDependencies3,
          GameCommandControllerProvider.$allTransitiveDependencies4,
        },
      );

  static final $allTransitiveDependencies0 = activeGameSessionProvider;
  static final $allTransitiveDependencies1 = activeRendererViewModelProvider;
  static final $allTransitiveDependencies2 =
      ActiveRendererViewModelProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies3 = gameStateProvider;
  static final $allTransitiveDependencies4 =
      GameStateNotifierProvider.$allTransitiveDependencies1;

  @override
  String debugGetCreateSourceHash() => _$gameCommandControllerHash();

  @$internal
  @override
  GameCommandController create() => GameCommandController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$gameCommandControllerHash() =>
    r'5e2a0cbe9fb3b1eb36f7b10e985829a213f4a24d';

/// Coordinates player commands with the active save and renderer view model.

abstract class _$GameCommandController extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
