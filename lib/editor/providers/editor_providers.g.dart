// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'editor_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(EditorStateNotifier)
final editorStateProvider = EditorStateNotifierProvider._();

final class EditorStateNotifierProvider
    extends $NotifierProvider<EditorStateNotifier, EditorState> {
  EditorStateNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorStateNotifierHash();

  @$internal
  @override
  EditorStateNotifier create() => EditorStateNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EditorState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EditorState>(value),
    );
  }
}

String _$editorStateNotifierHash() =>
    r'e90bbe64b41c2714dd6f0dbed23a8dc7d02a9ed8';

abstract class _$EditorStateNotifier extends $Notifier<EditorState> {
  EditorState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EditorState, EditorState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EditorState, EditorState>,
              EditorState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(EditorMapNotifier)
final editorMapProvider = EditorMapNotifierProvider._();

final class EditorMapNotifierProvider
    extends $NotifierProvider<EditorMapNotifier, MapData?> {
  EditorMapNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'editorMapProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$editorMapNotifierHash();

  @$internal
  @override
  EditorMapNotifier create() => EditorMapNotifier();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapData? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapData?>(value),
    );
  }
}

String _$editorMapNotifierHash() => r'b2f9004f51083c98cff2ed11bb593af6a38af787';

abstract class _$EditorMapNotifier extends $Notifier<MapData?> {
  MapData? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapData?, MapData?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapData?, MapData?>,
              MapData?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
