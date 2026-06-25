// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_control_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Scoped HUD-level provider holding the current [GameSave] for player control.

@ProviderFor(gamePlayerControlSave)
final gamePlayerControlSaveProvider = GamePlayerControlSaveProvider._();

/// Scoped HUD-level provider holding the current [GameSave] for player control.

final class GamePlayerControlSaveProvider
    extends $FunctionalProvider<GameSave?, GameSave?, GameSave?>
    with $Provider<GameSave?> {
  /// Scoped HUD-level provider holding the current [GameSave] for player control.
  GamePlayerControlSaveProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamePlayerControlSaveProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$gamePlayerControlSaveHash();

  @$internal
  @override
  $ProviderElement<GameSave?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameSave? create(Ref ref) {
    return gamePlayerControlSave(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSave? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSave?>(value),
    );
  }
}

String _$gamePlayerControlSaveHash() =>
    r'f943fd8f31e4b4c5c9eca824a4cbf6b8e254fbbf';

@ProviderFor(GamePlayerControlController)
final gamePlayerControlControllerProvider =
    GamePlayerControlControllerProvider._();

final class GamePlayerControlControllerProvider
    extends $NotifierProvider<GamePlayerControlController, PlayerControlState> {
  GamePlayerControlControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gamePlayerControlControllerProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[
          gamePlayerControlSaveProvider,
          activeGameSessionProvider,
          activeRendererViewModelProvider,
          gameCommandControllerProvider,
          gameStateProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          GamePlayerControlControllerProvider.$allTransitiveDependencies0,
          GamePlayerControlControllerProvider.$allTransitiveDependencies1,
          GamePlayerControlControllerProvider.$allTransitiveDependencies2,
          GamePlayerControlControllerProvider.$allTransitiveDependencies3,
          GamePlayerControlControllerProvider.$allTransitiveDependencies4,
          GamePlayerControlControllerProvider.$allTransitiveDependencies5,
          GamePlayerControlControllerProvider.$allTransitiveDependencies6,
        },
      );

  static final $allTransitiveDependencies0 = gamePlayerControlSaveProvider;
  static final $allTransitiveDependencies1 = activeGameSessionProvider;
  static final $allTransitiveDependencies2 = activeRendererViewModelProvider;
  static final $allTransitiveDependencies3 =
      ActiveRendererViewModelProvider.$allTransitiveDependencies0;
  static final $allTransitiveDependencies4 = gameCommandControllerProvider;
  static final $allTransitiveDependencies5 =
      GameCommandControllerProvider.$allTransitiveDependencies3;
  static final $allTransitiveDependencies6 =
      GameCommandControllerProvider.$allTransitiveDependencies4;

  @override
  String debugGetCreateSourceHash() => _$gamePlayerControlControllerHash();

  @$internal
  @override
  GamePlayerControlController create() => GamePlayerControlController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlayerControlState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlayerControlState>(value),
    );
  }
}

String _$gamePlayerControlControllerHash() =>
    r'5a70490169481fc61ee5969f48cb6009ab303192';

abstract class _$GamePlayerControlController
    extends $Notifier<PlayerControlState> {
  PlayerControlState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<PlayerControlState, PlayerControlState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<PlayerControlState, PlayerControlState>,
              PlayerControlState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
