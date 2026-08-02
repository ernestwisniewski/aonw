// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'game_state_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameStateNotifier)
final gameStateProvider = GameStateNotifierFamily._();

final class GameStateNotifierProvider
    extends $AsyncNotifierProvider<GameStateNotifier, GameClientState> {
  GameStateNotifierProvider._({
    required GameStateNotifierFamily super.from,
    required String super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'gameStateProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  static final $allTransitiveDependencies0 = activeGameSessionProvider;
  static final $allTransitiveDependencies1 = networkSessionProvider;
  static final $allTransitiveDependencies2 = activeRendererViewModelProvider;
  static final $allTransitiveDependencies3 =
      ActiveRendererViewModelProvider.$allTransitiveDependencies0;

  @override
  String debugGetCreateSourceHash() => _$gameStateNotifierHash();

  @override
  String toString() {
    return r'gameStateProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  GameStateNotifier create() => GameStateNotifier();

  @override
  bool operator ==(Object other) {
    return other is GameStateNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameStateNotifierHash() => r'67cec75b7e4447b04554e805eeddc80131010f6f';

final class GameStateNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GameStateNotifier,
          AsyncValue<GameClientState>,
          GameClientState,
          FutureOr<GameClientState>,
          String
        > {
  GameStateNotifierFamily._()
    : super(
        retry: _doNotRetry,
        name: r'gameStateProvider',
        dependencies: <ProviderOrFamily>[
          activeGameSessionProvider,
          networkSessionProvider,
          activeRendererViewModelProvider,
        ],
        $allTransitiveDependencies: <ProviderOrFamily>{
          GameStateNotifierProvider.$allTransitiveDependencies0,
          GameStateNotifierProvider.$allTransitiveDependencies1,
          GameStateNotifierProvider.$allTransitiveDependencies2,
          GameStateNotifierProvider.$allTransitiveDependencies3,
        },
        isAutoDispose: true,
      );

  GameStateNotifierProvider call(String saveId) =>
      GameStateNotifierProvider._(argument: saveId, from: this);

  @override
  String toString() => r'gameStateProvider';
}

abstract class _$GameStateNotifier extends $AsyncNotifier<GameClientState> {
  late final _$args = ref.$arg as String;
  String get saveId => _$args;

  FutureOr<GameClientState> build(String saveId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameClientState>, GameClientState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameClientState>, GameClientState>,
              AsyncValue<GameClientState>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
