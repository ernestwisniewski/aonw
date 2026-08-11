// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hex_display_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(HexDisplayNotifier)
final hexDisplayProvider = HexDisplayNotifierProvider._();

final class HexDisplayNotifierProvider
    extends $NotifierProvider<HexDisplayNotifier, HexDisplaySettings> {
  HexDisplayNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'hexDisplayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$hexDisplayNotifierHash();

  @$internal
  @override
  HexDisplayNotifier create() => HexDisplayNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HexDisplaySettings value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HexDisplaySettings>(value),
    );
  }
}

String _$hexDisplayNotifierHash() =>
    r'5ea02c0df222a64aee683586aa1d0190ed199413';

abstract class _$HexDisplayNotifier extends $Notifier<HexDisplaySettings> {
  HexDisplaySettings build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<HexDisplaySettings, HexDisplaySettings>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<HexDisplaySettings, HexDisplaySettings>,
              HexDisplaySettings,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
