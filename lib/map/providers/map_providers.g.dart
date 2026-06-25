// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'map_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(mapRepository)
final mapRepositoryProvider = MapRepositoryProvider._();

final class MapRepositoryProvider
    extends $FunctionalProvider<MapRepository, MapRepository, MapRepository>
    with $Provider<MapRepository> {
  MapRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mapRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mapRepositoryHash();

  @$internal
  @override
  $ProviderElement<MapRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  MapRepository create(Ref ref) {
    return mapRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MapRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MapRepository>(value),
    );
  }
}

String _$mapRepositoryHash() => r'88e5ac5dbaf914d0cad7b37abd88932ff1f8521c';

@ProviderFor(availableMaps)
final availableMapsProvider = AvailableMapsProvider._();

final class AvailableMapsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<MapSelection>>,
          List<MapSelection>,
          FutureOr<List<MapSelection>>
        >
    with
        $FutureModifier<List<MapSelection>>,
        $FutureProvider<List<MapSelection>> {
  AvailableMapsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'availableMapsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$availableMapsHash();

  @$internal
  @override
  $FutureProviderElement<List<MapSelection>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<MapSelection>> create(Ref ref) {
    return availableMaps(ref);
  }
}

String _$availableMapsHash() => r'96c2f5dc46e97e901332a91b935658535831db67';

@ProviderFor(activeMap)
final activeMapProvider = ActiveMapFamily._();

final class ActiveMapProvider
    extends $FunctionalProvider<AsyncValue<MapData>, MapData, FutureOr<MapData>>
    with $FutureModifier<MapData>, $FutureProvider<MapData> {
  ActiveMapProvider._({
    required ActiveMapFamily super.from,
    required MapSelection super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'activeMapProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$activeMapHash();

  @override
  String toString() {
    return r'activeMapProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MapData> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<MapData> create(Ref ref) {
    final argument = this.argument as MapSelection;
    return activeMap(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ActiveMapProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$activeMapHash() => r'8f7f7dc6f7e271a58b6def3cedf6cdad3bc91031';

final class ActiveMapFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MapData>, MapSelection> {
  ActiveMapFamily._()
    : super(
        retry: _doNotRetry,
        name: r'activeMapProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ActiveMapProvider call(MapSelection selection) =>
      ActiveMapProvider._(argument: selection, from: this);

  @override
  String toString() => r'activeMapProvider';
}

@ProviderFor(mapImagePath)
final mapImagePathProvider = MapImagePathFamily._();

final class MapImagePathProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, FutureOr<String?>>
    with $FutureModifier<String?>, $FutureProvider<String?> {
  MapImagePathProvider._({
    required MapImagePathFamily super.from,
    required MapSelection super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'mapImagePathProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapImagePathHash();

  @override
  String toString() {
    return r'mapImagePathProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String?> create(Ref ref) {
    final argument = this.argument as MapSelection;
    return mapImagePath(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MapImagePathProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapImagePathHash() => r'3404e2d13d877313c8fae15e54edb31fbdd2b14d';

final class MapImagePathFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<String?>, MapSelection> {
  MapImagePathFamily._()
    : super(
        retry: _doNotRetry,
        name: r'mapImagePathProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MapImagePathProvider call(MapSelection selection) =>
      MapImagePathProvider._(argument: selection, from: this);

  @override
  String toString() => r'mapImagePathProvider';
}
