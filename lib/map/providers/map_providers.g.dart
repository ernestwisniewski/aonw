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
    extends
        $FunctionalProvider<AsyncValue<WorldMap>, WorldMap, FutureOr<WorldMap>>
    with $FutureModifier<WorldMap>, $FutureProvider<WorldMap> {
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
  $FutureProviderElement<WorldMap> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WorldMap> create(Ref ref) {
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

String _$activeMapHash() => r'69d2563ee82766b228ea547442645ccfb17680d1';

final class ActiveMapFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<WorldMap>, MapSelection> {
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

@ProviderFor(mapImageSource)
final mapImageSourceProvider = MapImageSourceFamily._();

final class MapImageSourceProvider
    extends
        $FunctionalProvider<
          AsyncValue<MapImageSource?>,
          MapImageSource?,
          FutureOr<MapImageSource?>
        >
    with $FutureModifier<MapImageSource?>, $FutureProvider<MapImageSource?> {
  MapImageSourceProvider._({
    required MapImageSourceFamily super.from,
    required MapSelection super.argument,
  }) : super(
         retry: _doNotRetry,
         name: r'mapImageSourceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$mapImageSourceHash();

  @override
  String toString() {
    return r'mapImageSourceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<MapImageSource?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<MapImageSource?> create(Ref ref) {
    final argument = this.argument as MapSelection;
    return mapImageSource(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is MapImageSourceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$mapImageSourceHash() => r'ab8de82c61d748f0f6f14f713fad9f03d730188e';

final class MapImageSourceFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<MapImageSource?>, MapSelection> {
  MapImageSourceFamily._()
    : super(
        retry: _doNotRetry,
        name: r'mapImageSourceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  MapImageSourceProvider call(MapSelection selection) =>
      MapImageSourceProvider._(argument: selection, from: this);

  @override
  String toString() => r'mapImageSourceProvider';
}
