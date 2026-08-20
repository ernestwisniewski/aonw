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
    r'7697cad63f7fce92c1804461ab125e7f5c88681d';

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
    extends $NotifierProvider<EditorMapNotifier, MapDraft?> {
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
  Override overrideWithValue(MapDraft? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapDraft?>(value),
    );
  }
}

String _$editorMapNotifierHash() => r'04bb55d9e8efa85846d637b41145a1fbcf8a702f';

abstract class _$EditorMapNotifier extends $Notifier<MapDraft?> {
  MapDraft? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<MapDraft?, MapDraft?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<MapDraft?, MapDraft?>,
              MapDraft?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
