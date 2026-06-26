// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(gameClock)
final gameClockProvider = GameClockProvider._();

final class GameClockProvider extends $FunctionalProvider<Clock, Clock, Clock>
    with $Provider<Clock> {
  GameClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameClockProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameClockHash();

  @$internal
  @override
  $ProviderElement<Clock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Clock create(Ref ref) {
    return gameClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Clock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Clock>(value),
    );
  }
}

String _$gameClockHash() => r'1c7559ec3c17c7f0128d0d8824a8fcfa7a82c2b9';

@ProviderFor(saveIdGenerator)
final saveIdGeneratorProvider = SaveIdGeneratorProvider._();

final class SaveIdGeneratorProvider
    extends $FunctionalProvider<IdGenerator, IdGenerator, IdGenerator>
    with $Provider<IdGenerator> {
  SaveIdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'saveIdGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$saveIdGeneratorHash();

  @$internal
  @override
  $ProviderElement<IdGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  IdGenerator create(Ref ref) {
    return saveIdGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(IdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<IdGenerator>(value),
    );
  }
}

String _$saveIdGeneratorHash() => r'1c343990c699700dc62c20476972dc83b4c1bca6';

@ProviderFor(gameLogger)
final gameLoggerProvider = GameLoggerProvider._();

final class GameLoggerProvider
    extends $FunctionalProvider<GameLogger, GameLogger, GameLogger>
    with $Provider<GameLogger> {
  GameLoggerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameLoggerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameLoggerHash();

  @$internal
  @override
  $ProviderElement<GameLogger> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameLogger create(Ref ref) {
    return gameLogger(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameLogger value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameLogger>(value),
    );
  }
}

String _$gameLoggerHash() => r'acfa29920cbd79ab747e4db1bb685f982f9a2549';

@ProviderFor(gameRepository)
final gameRepositoryProvider = GameRepositoryProvider._();

final class GameRepositoryProvider
    extends $FunctionalProvider<GameRepository, GameRepository, GameRepository>
    with $Provider<GameRepository> {
  GameRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameRepositoryHash();

  @$internal
  @override
  $ProviderElement<GameRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameRepository create(Ref ref) {
    return gameRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameRepository>(value),
    );
  }
}

String _$gameRepositoryHash() => r'ee10887bbc735e721f6d06a84016a9cfd6dc31c9';

@ProviderFor(eventLog)
final eventLogProvider = EventLogProvider._();

final class EventLogProvider
    extends $FunctionalProvider<EventLog, EventLog, EventLog>
    with $Provider<EventLog> {
  EventLogProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'eventLogProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$eventLogHash();

  @$internal
  @override
  $ProviderElement<EventLog> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  EventLog create(Ref ref) {
    return eventLog(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EventLog value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EventLog>(value),
    );
  }
}

String _$eventLogHash() => r'dfc81ed19cdde8643553038f23de5a7f2507d603';

@ProviderFor(snapshotStore)
final snapshotStoreProvider = SnapshotStoreProvider._();

final class SnapshotStoreProvider
    extends $FunctionalProvider<SnapshotStore, SnapshotStore, SnapshotStore>
    with $Provider<SnapshotStore> {
  SnapshotStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'snapshotStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$snapshotStoreHash();

  @$internal
  @override
  $ProviderElement<SnapshotStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SnapshotStore create(Ref ref) {
    return snapshotStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SnapshotStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SnapshotStore>(value),
    );
  }
}

String _$snapshotStoreHash() => r'cef957e12d7cbea7c9deb2dfef1375e709cfa9d3';

@ProviderFor(replayStore)
final replayStoreProvider = ReplayStoreProvider._();

final class ReplayStoreProvider
    extends $FunctionalProvider<ReplayStore, ReplayStore, ReplayStore>
    with $Provider<ReplayStore> {
  ReplayStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'replayStoreProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$replayStoreHash();

  @$internal
  @override
  $ProviderElement<ReplayStore> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ReplayStore create(Ref ref) {
    return replayStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ReplayStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ReplayStore>(value),
    );
  }
}

String _$replayStoreHash() => r'b5b585cf85fc3507c7d622e0eaf13b86133fc5af';

@ProviderFor(apiConfig)
final apiConfigProvider = ApiConfigProvider._();

final class ApiConfigProvider
    extends $FunctionalProvider<ApiConfig, ApiConfig, ApiConfig>
    with $Provider<ApiConfig> {
  ApiConfigProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'apiConfigProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$apiConfigHash();

  @$internal
  @override
  $ProviderElement<ApiConfig> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ApiConfig create(Ref ref) {
    return apiConfig(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ApiConfig value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ApiConfig>(value),
    );
  }
}

String _$apiConfigHash() => r'391c9c00229402b6771acc1f615919a1a44fcc19';

@ProviderFor(multiplayerStreamConnector)
final multiplayerStreamConnectorProvider =
    MultiplayerStreamConnectorProvider._();

final class MultiplayerStreamConnectorProvider
    extends
        $FunctionalProvider<
          MultiplayerStreamConnector,
          MultiplayerStreamConnector,
          MultiplayerStreamConnector
        >
    with $Provider<MultiplayerStreamConnector> {
  MultiplayerStreamConnectorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiplayerStreamConnectorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiplayerStreamConnectorHash();

  @$internal
  @override
  $ProviderElement<MultiplayerStreamConnector> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MultiplayerStreamConnector create(Ref ref) {
    return multiplayerStreamConnector(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MultiplayerStreamConnector value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MultiplayerStreamConnector>(value),
    );
  }
}

String _$multiplayerStreamConnectorHash() =>
    r'f5ddac93b95c5f12e4863ee7d5e5b162a55c223d';

@ProviderFor(wireCommandDispatcher)
final wireCommandDispatcherProvider = WireCommandDispatcherProvider._();

final class WireCommandDispatcherProvider
    extends
        $FunctionalProvider<
          WireCommandDispatcher,
          WireCommandDispatcher,
          WireCommandDispatcher
        >
    with $Provider<WireCommandDispatcher> {
  WireCommandDispatcherProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'wireCommandDispatcherProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$wireCommandDispatcherHash();

  @$internal
  @override
  $ProviderElement<WireCommandDispatcher> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WireCommandDispatcher create(Ref ref) {
    return wireCommandDispatcher(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WireCommandDispatcher value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WireCommandDispatcher>(value),
    );
  }
}

String _$wireCommandDispatcherHash() =>
    r'51f311f20c68320e5b3169d46c68e33945452800';

@ProviderFor(networkSessionClient)
final networkSessionClientProvider = NetworkSessionClientProvider._();

final class NetworkSessionClientProvider
    extends
        $FunctionalProvider<
          NetworkSessionClient,
          NetworkSessionClient,
          NetworkSessionClient
        >
    with $Provider<NetworkSessionClient> {
  NetworkSessionClientProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSessionClientProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSessionClientHash();

  @$internal
  @override
  $ProviderElement<NetworkSessionClient> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkSessionClient create(Ref ref) {
    return networkSessionClient(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSessionClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSessionClient>(value),
    );
  }
}

String _$networkSessionClientHash() =>
    r'26d33743964c3b2c94418df64de585d0be4c792e';

@ProviderFor(networkSessionStore)
final networkSessionStoreProvider = NetworkSessionStoreProvider._();

final class NetworkSessionStoreProvider
    extends
        $FunctionalProvider<
          NetworkSessionStore,
          NetworkSessionStore,
          NetworkSessionStore
        >
    with $Provider<NetworkSessionStore> {
  NetworkSessionStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSessionStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSessionStoreHash();

  @$internal
  @override
  $ProviderElement<NetworkSessionStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NetworkSessionStore create(Ref ref) {
    return networkSessionStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSessionStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSessionStore>(value),
    );
  }
}

String _$networkSessionStoreHash() =>
    r'e6cec2edee2a4bc8fd8c7e1b6afe83aeba394fec';

@ProviderFor(NetworkSessionState)
final networkSessionStateProvider = NetworkSessionStateProvider._();

final class NetworkSessionStateProvider
    extends $NotifierProvider<NetworkSessionState, NetworkSession?> {
  NetworkSessionStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSessionStateProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSessionStateHash();

  @$internal
  @override
  NetworkSessionState create() => NetworkSessionState();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSession?>(value),
    );
  }
}

String _$networkSessionStateHash() =>
    r'3421fed17622edeb729c0b8e0c818dae96d36921';

abstract class _$NetworkSessionState extends $Notifier<NetworkSession?> {
  NetworkSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NetworkSession?, NetworkSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NetworkSession?, NetworkSession?>,
              NetworkSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(networkSession)
final networkSessionProvider = NetworkSessionProvider._();

final class NetworkSessionProvider
    extends
        $FunctionalProvider<NetworkSession?, NetworkSession?, NetworkSession?>
    with $Provider<NetworkSession?> {
  NetworkSessionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'networkSessionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$networkSessionHash();

  @$internal
  @override
  $ProviderElement<NetworkSession?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NetworkSession? create(Ref ref) {
    return networkSession(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NetworkSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NetworkSession?>(value),
    );
  }
}

String _$networkSessionHash() => r'd6e393ad6f5cc15fa8c443f8d390d493039b121b';
