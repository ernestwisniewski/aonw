import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WorldMap composition roots', () {
    test('local session owns WorldMap', () {
      expect(
        _fieldType(
          'lib/game/application/services/game_session.dart',
          'GameSession',
          'mapData',
        ),
        'WorldMap',
      );
    });

    test('AI simulation configuration owns WorldMap', () {
      expect(
        _fieldType(
          'packages/aonw_core/lib/ai/simulation/'
              'economy_simulation_models.dart',
          'EconomySimulationConfig',
          'mapData',
        ),
        'WorldMap?',
      );
    });

    test('server catalog loads WorldMap directly', () {
      const path = 'server/lib/src/multiplayer/multiplayer_map_catalog.dart';
      final unit = _unit(path);
      final catalog = unit.declarations
          .whereType<ClassDeclaration>()
          .singleWhere(
            (declaration) =>
                declaration.namePart.typeName.lexeme == 'MultiplayerMapCatalog',
          );
      final load = catalog.body.members
          .whereType<MethodDeclaration>()
          .singleWhere((method) => method.name.lexeme == 'loadAssetMap');

      expect(load.returnType?.toSource(), 'Future<WorldMap>');
      expect(
        File(
          'server/lib/src/multiplayer/server_map_cache.dart',
        ).readAsStringSync(),
        isNot(contains('indexedReadView')),
      );
    });

    test('map codec constructs and serializes only WorldMap', () {
      const path = 'packages/aonw_core/lib/map/persistence/map_data_codec.dart';
      final source = File(path).readAsStringSync();
      expect(source, contains('static WorldMap fromJson('));
      expect(source, contains('static String toJson(WorldMap worldMap)'));
      expect(source, isNot(matches(RegExp(r'\b(MapData|TileData)\b'))));
    });
  });
}

String? _fieldType(String path, String className, String fieldName) {
  final declaration = _unit(path).declarations
      .whereType<ClassDeclaration>()
      .singleWhere(
        (candidate) => candidate.namePart.typeName.lexeme == className,
      );
  for (final field in declaration.body.members.whereType<FieldDeclaration>()) {
    if (field.fields.variables.any(
      (variable) => variable.name.lexeme == fieldName,
    )) {
      return field.fields.type?.toSource();
    }
  }
  return null;
}

CompilationUnit _unit(String path) {
  return parseString(content: File(path).readAsStringSync(), path: path).unit;
}
