// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameSessionNotifier)
final gameSessionProvider = GameSessionNotifierFamily._();

final class GameSessionNotifierProvider
    extends $AsyncNotifierProvider<GameSessionNotifier, GameSession> {
  GameSessionNotifierProvider._({
    required GameSessionNotifierFamily super.from,
    required (MapSelection, String) super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'gameSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameSessionNotifierHash();

  @override
  String toString() {
    return r'gameSessionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  GameSessionNotifier create() => GameSessionNotifier();

  @override
  bool operator ==(Object other) {
    return other is GameSessionNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameSessionNotifierHash() =>
    r'ed5324c55facb6d74412799b6dd22838c71718db';

final class GameSessionNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          GameSessionNotifier,
          AsyncValue<GameSession>,
          GameSession,
          FutureOr<GameSession>,
          (MapSelection, String)
        > {
  GameSessionNotifierFamily._()
    : super(
        retry: _doNotRetry,
        name: r'gameSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GameSessionNotifierProvider call(MapSelection selection, String saveId) =>
      GameSessionNotifierProvider._(argument: (selection, saveId), from: this);

  @override
  String toString() => r'gameSessionProvider';
}

abstract class _$GameSessionNotifier extends $AsyncNotifier<GameSession> {
  late final _$args = ref.$arg as (MapSelection, String);
  MapSelection get selection => _$args.$1;
  String get saveId => _$args.$2;

  FutureOr<GameSession> build(MapSelection selection, String saveId);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<GameSession>, GameSession>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<GameSession>, GameSession>,
              AsyncValue<GameSession>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}

@ProviderFor(gameSessionFactory)
final gameSessionFactoryProvider = GameSessionFactoryProvider._();

final class GameSessionFactoryProvider
    extends
        $FunctionalProvider<
          GameSessionFactory,
          GameSessionFactory,
          GameSessionFactory
        >
    with $Provider<GameSessionFactory> {
  GameSessionFactoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameSessionFactoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameSessionFactoryHash();

  @$internal
  @override
  $ProviderElement<GameSessionFactory> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  GameSessionFactory create(Ref ref) {
    return gameSessionFactory(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSessionFactory value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSessionFactory>(value),
    );
  }
}

String _$gameSessionFactoryHash() =>
    r'3be87fb1dbf6aa22eb2f79cca65ad8c086d21eb2';

@ProviderFor(gameSavesIndex)
final gameSavesIndexProvider = GameSavesIndexProvider._();

final class GameSavesIndexProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<GameSaveIndex>>,
          List<GameSaveIndex>,
          FutureOr<List<GameSaveIndex>>
        >
    with
        $FutureModifier<List<GameSaveIndex>>,
        $FutureProvider<List<GameSaveIndex>> {
  GameSavesIndexProvider._()
    : super(
        from: null,
        argument: null,
        retry: _doNotRetry,
        name: r'gameSavesIndexProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameSavesIndexHash();

  @$internal
  @override
  $FutureProviderElement<List<GameSaveIndex>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<GameSaveIndex>> create(Ref ref) {
    return gameSavesIndex(ref);
  }
}

String _$gameSavesIndexHash() => r'5c02704e77d20c7924f12384616f4d1754f6d943';

/// Holds the currently active [GameSession] inside a game screen scope.
///
/// Defaults to null outside a running game.
///
/// `dependencies: const []` marks this as a *scoped* provider: overrides via
/// `ProviderScope(overrides: [...])` only propagate to descendants when both
/// the scoped provider and every consumer that reads it declare `dependencies`.
/// See https://riverpod.dev/docs/concepts/scopes

@ProviderFor(activeGameSession)
final activeGameSessionProvider = ActiveGameSessionProvider._();

/// Holds the currently active [GameSession] inside a game screen scope.
///
/// Defaults to null outside a running game.
///
/// `dependencies: const []` marks this as a *scoped* provider: overrides via
/// `ProviderScope(overrides: [...])` only propagate to descendants when both
/// the scoped provider and every consumer that reads it declare `dependencies`.
/// See https://riverpod.dev/docs/concepts/scopes

final class ActiveGameSessionProvider
    extends $FunctionalProvider<GameSession?, GameSession?, GameSession?>
    with $Provider<GameSession?> {
  /// Holds the currently active [GameSession] inside a game screen scope.
  ///
  /// Defaults to null outside a running game.
  ///
  /// `dependencies: const []` marks this as a *scoped* provider: overrides via
  /// `ProviderScope(overrides: [...])` only propagate to descendants when both
  /// the scoped provider and every consumer that reads it declare `dependencies`.
  /// See https://riverpod.dev/docs/concepts/scopes
  ActiveGameSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGameSessionProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$activeGameSessionHash();

  @$internal
  @override
  $ProviderElement<GameSession?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameSession? create(Ref ref) {
    return activeGameSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameSession?>(value),
    );
  }
}

String _$activeGameSessionHash() => r'a6c9f15c6d0aef1a03628beeaba12efe35068bea';

/// Loads the saved camera state for a save slot.
///
/// Empty save ids do not have persisted camera metadata. Repository errors are
/// surfaced by [gameSaveSnapshotProvider] as AsyncError.

@ProviderFor(savedCamera)
final savedCameraProvider = SavedCameraFamily._();

/// Loads the saved camera state for a save slot.
///
/// Empty save ids do not have persisted camera metadata. Repository errors are
/// surfaced by [gameSaveSnapshotProvider] as AsyncError.

final class SavedCameraProvider
    extends
        $FunctionalProvider<
          AsyncValue<CameraState?>,
          CameraState?,
          FutureOr<CameraState?>
        >
    with $FutureModifier<CameraState?>, $FutureProvider<CameraState?> {
  /// Loads the saved camera state for a save slot.
  ///
  /// Empty save ids do not have persisted camera metadata. Repository errors are
  /// surfaced by [gameSaveSnapshotProvider] as AsyncError.
  SavedCameraProvider._({
    required SavedCameraFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'savedCameraProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$savedCameraHash();

  @override
  String toString() {
    return r'savedCameraProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CameraState?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CameraState?> create(Ref ref) {
    final argument = this.argument as String;
    return savedCamera(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is SavedCameraProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$savedCameraHash() => r'c5a82861adfcfb12d8c2814d0869259be7dad826';

/// Loads the saved camera state for a save slot.
///
/// Empty save ids do not have persisted camera metadata. Repository errors are
/// surfaced by [gameSaveSnapshotProvider] as AsyncError.

final class SavedCameraFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CameraState?>, String> {
  SavedCameraFamily._()
    : super(
        retry: null,
        name: r'savedCameraProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the saved camera state for a save slot.
  ///
  /// Empty save ids do not have persisted camera metadata. Repository errors are
  /// surfaced by [gameSaveSnapshotProvider] as AsyncError.

  SavedCameraProvider call(String saveId) =>
      SavedCameraProvider._(argument: saveId, from: this);

  @override
  String toString() => r'savedCameraProvider';
}

@ProviderFor(gameSaveSnapshot)
final gameSaveSnapshotProvider = GameSaveSnapshotFamily._();

final class GameSaveSnapshotProvider
    extends
        $FunctionalProvider<
          AsyncValue<SaveSnapshot?>,
          SaveSnapshot?,
          FutureOr<SaveSnapshot?>
        >
    with $FutureModifier<SaveSnapshot?>, $FutureProvider<SaveSnapshot?> {
  GameSaveSnapshotProvider._({
    required GameSaveSnapshotFamily super.from,
    required String super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'gameSaveSnapshotProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameSaveSnapshotHash();

  @override
  String toString() {
    return r'gameSaveSnapshotProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<SaveSnapshot?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SaveSnapshot?> create(Ref ref) {
    final argument = this.argument as String;
    return gameSaveSnapshot(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GameSaveSnapshotProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameSaveSnapshotHash() => r'6dac830148451806a53c549bc62fd471773319db';

final class GameSaveSnapshotFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<SaveSnapshot?>, String> {
  GameSaveSnapshotFamily._()
    : super(
        retry: _doNotRetry,
        name: r'gameSaveSnapshotProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  GameSaveSnapshotProvider call(String saveId) =>
      GameSaveSnapshotProvider._(argument: saveId, from: this);

  @override
  String toString() => r'gameSaveSnapshotProvider';
}

/// Loads the full game save for a save slot.
///
/// Empty save ids return null. Repository errors stay visible as AsyncError.

@ProviderFor(gameSave)
final gameSaveProvider = GameSaveFamily._();

/// Loads the full game save for a save slot.
///
/// Empty save ids return null. Repository errors stay visible as AsyncError.

final class GameSaveProvider
    extends
        $FunctionalProvider<
          AsyncValue<GameSave?>,
          GameSave?,
          FutureOr<GameSave?>
        >
    with $FutureModifier<GameSave?>, $FutureProvider<GameSave?> {
  /// Loads the full game save for a save slot.
  ///
  /// Empty save ids return null. Repository errors stay visible as AsyncError.
  GameSaveProvider._({
    required GameSaveFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'gameSaveProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$gameSaveHash();

  @override
  String toString() {
    return r'gameSaveProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<GameSave?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<GameSave?> create(Ref ref) {
    final argument = this.argument as String;
    return gameSave(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is GameSaveProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$gameSaveHash() => r'c16b688eb4717a496d99610f78b3d1d3e4e09cc5';

/// Loads the full game save for a save slot.
///
/// Empty save ids return null. Repository errors stay visible as AsyncError.

final class GameSaveFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<GameSave?>, String> {
  GameSaveFamily._()
    : super(
        retry: null,
        name: r'gameSaveProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Loads the full game save for a save slot.
  ///
  /// Empty save ids return null. Repository errors stay visible as AsyncError.

  GameSaveProvider call(String saveId) =>
      GameSaveProvider._(argument: saveId, from: this);

  @override
  String toString() => r'gameSaveProvider';
}
