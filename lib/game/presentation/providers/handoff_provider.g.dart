// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'handoff_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(GameHandoffNotifier)
final gameHandoffProvider = GameHandoffNotifierProvider._();

final class GameHandoffNotifierProvider
    extends $NotifierProvider<GameHandoffNotifier, HandoffData?> {
  GameHandoffNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gameHandoffProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gameHandoffNotifierHash();

  @$internal
  @override
  GameHandoffNotifier create() => GameHandoffNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HandoffData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HandoffData?>(value),
    );
  }
}

String _$gameHandoffNotifierHash() =>
    r'6b331d4640367dfdc21ad96a3a285db506b782ea';

abstract class _$GameHandoffNotifier extends $Notifier<HandoffData?> {
  HandoffData? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HandoffData?, HandoffData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HandoffData?, HandoffData?>,
              HandoffData?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
