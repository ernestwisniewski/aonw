import 'package:aonw_rust_client/aonw_rust_client.dart';
import 'package:flutter/services.dart';

import '../application/map_repository.dart';
import '../read_model/map_scene.dart';
import 'map_reference_bundle_loader.dart';
import 'map_view_mapper.dart';

typedef RustSessionFactory = Future<AonwRustSession?> Function();

final class RustMapRepository implements MapRepository {
  RustMapRepository({
    required AssetBundle assets,
    RustSessionFactory sessionFactory = createAonwRustSession,
    MapViewMapper mapper = const MapViewMapper(),
  }) : _assets = assets,
       _sessionFactory = sessionFactory,
       _mapper = mapper,
       _bundleLoader = MapReferenceBundleLoader(assets);

  final AssetBundle _assets;
  final RustSessionFactory _sessionFactory;
  final MapViewMapper _mapper;
  final MapReferenceBundleLoader _bundleLoader;

  @override
  Future<MapScene> load(MapAssetPaths assets) async {
    final session = await _sessionFactory();
    if (session == null) {
      throw const MapLoadException(
        code: 'rust_adapter_unavailable',
        message: 'The Rust map adapter is unavailable on this platform.',
      );
    }
    try {
      final document = await _assets.loadString(assets.document);
      final response = await session.send(
        AonwClientRequest.inspectMap(mapDocument: document),
      );
      if (!response.isSuccess) {
        final error = response.error!;
        throw MapLoadException(
          code: error.code,
          message: 'The map could not be opened.',
          diagnosticCause: error,
          diagnosticStackTrace: StackTrace.current,
        );
      }
      final wire = response.require<AonwMapInspectedResponse>().map;
      final map = _mapper.fromWire(wire);
      final reference = await _bundleLoader.load(
        manifestAsset: assets.bundleManifest,
        map: map,
      );
      return MapScene(map: map, reference: reference);
    } on MapLoadException {
      rethrow;
    } on FormatException catch (error, stackTrace) {
      throw MapLoadException(
        code: 'invalid_map_protocol',
        message: 'The map data is incompatible with this client.',
        diagnosticCause: error,
        diagnosticStackTrace: stackTrace,
      );
    } finally {
      await session.close();
    }
  }
}
