// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'multiplayer_connection_status_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(MultiplayerConnectionStatusNotifier)
final multiplayerConnectionStatusProvider =
    MultiplayerConnectionStatusNotifierProvider._();

final class MultiplayerConnectionStatusNotifierProvider
    extends
        $NotifierProvider<
          MultiplayerConnectionStatusNotifier,
          MultiplayerConnectionStatusSnapshot?
        > {
  MultiplayerConnectionStatusNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiplayerConnectionStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() =>
      _$multiplayerConnectionStatusNotifierHash();

  @$internal
  @override
  MultiplayerConnectionStatusNotifier create() =>
      MultiplayerConnectionStatusNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MultiplayerConnectionStatusSnapshot? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride:
          $SyncValueProvider<MultiplayerConnectionStatusSnapshot?>(value),
    );
  }
}

String _$multiplayerConnectionStatusNotifierHash() =>
    r'17f8ff7be327b8b78f6a531109d564dca7e3e95c';

abstract class _$MultiplayerConnectionStatusNotifier
    extends $Notifier<MultiplayerConnectionStatusSnapshot?> {
  MultiplayerConnectionStatusSnapshot? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              MultiplayerConnectionStatusSnapshot?,
              MultiplayerConnectionStatusSnapshot?
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                MultiplayerConnectionStatusSnapshot?,
                MultiplayerConnectionStatusSnapshot?
              >,
              MultiplayerConnectionStatusSnapshot?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MultiplayerMatchNotifier)
final multiplayerMatchProvider = MultiplayerMatchNotifierProvider._();

final class MultiplayerMatchNotifierProvider
    extends
        $NotifierProvider<MultiplayerMatchNotifier, Map<String, WireMatch>> {
  MultiplayerMatchNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'multiplayerMatchProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$multiplayerMatchNotifierHash();

  @$internal
  @override
  MultiplayerMatchNotifier create() => MultiplayerMatchNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, WireMatch> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, WireMatch>>(value),
    );
  }
}

String _$multiplayerMatchNotifierHash() =>
    r'452a9978c24bcca9d188d3d3135a727a3b839c20';

abstract class _$MultiplayerMatchNotifier
    extends $Notifier<Map<String, WireMatch>> {
  Map<String, WireMatch> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<Map<String, WireMatch>, Map<String, WireMatch>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<Map<String, WireMatch>, Map<String, WireMatch>>,
              Map<String, WireMatch>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
