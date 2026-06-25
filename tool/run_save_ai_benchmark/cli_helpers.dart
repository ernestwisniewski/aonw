part of '../run_save_ai_benchmark.dart';

class _Finding {
  const _Finding({required this.severity, required this.message});

  final String severity;
  final String message;

  Map<String, Object?> toJson() => {'severity': severity, 'message': message};
}

void _writeFindings(StringBuffer buffer, List<_Finding> findings) {
  if (findings.isEmpty) return;
  buffer.writeln('Findings:');
  for (final finding in findings) {
    buffer.writeln('- [${finding.severity}] ${finding.message}');
  }
  buffer.writeln();
}

class _ProfileSelection {
  const _ProfileSelection.auto() : name = 'auto', profile = null;
  _ProfileSelection.fixed(MctsRuntimeProfile this.profile)
    : name = profile.name;

  final String name;
  final MctsRuntimeProfile? profile;

  MctsRuntimeProfile resolve(GameView view) {
    final selected = profile;
    if (selected != null) return selected;
    return view.turn >= AiRuntimeThrottler.adaptiveLateGameTurnThreshold ||
            view.ownUnits.length + view.visibleEnemyUnits.length >=
                AiRuntimeThrottler.adaptiveLateGameUnitThreshold ||
            view.ownCities.length + view.rememberedEnemyCities.length >=
                AiRuntimeThrottler.adaptiveLateGameCityThreshold
        ? MctsRuntimeProfile.batterySaver
        : MctsRuntimeProfile.interactive;
  }
}

class _Options {
  const _Options({
    required this.savePath,
    required this.savesRoot,
    required this.mapPath,
    required this.minTurn,
    required this.profiles,
    required this.repeats,
    required this.multiTurnCycles,
    required this.jsonOut,
    required this.markdownOut,
    required this.includeDeadline,
    required this.strategyOverride,
    required this.failOnFinding,
  });

  final String? savePath;
  final String? savesRoot;
  final String? mapPath;
  final int minTurn;
  final List<_ProfileSelection> profiles;
  final int repeats;
  final int multiTurnCycles;
  final String? jsonOut;
  final String? markdownOut;
  final bool includeDeadline;
  final AiStrategyId? strategyOverride;
  final bool failOnFinding;

  factory _Options.fromArgs(List<String> args) {
    final repeats = int.parse(_readOption(args, '--repeats') ?? '1');
    if (repeats <= 0) {
      throw const _UsageException('--repeats must be positive.');
    }
    final multiTurnCycles = int.parse(
      _readOption(args, '--multi-turns') ?? '0',
    );
    if (multiTurnCycles < 0) {
      throw const _UsageException('--multi-turns must be zero or positive.');
    }
    return _Options(
      savePath: _readOption(args, '--save'),
      savesRoot: _readOption(args, '--saves-root'),
      mapPath: _readOption(args, '--map'),
      minTurn: int.parse(_readOption(args, '--min-turn') ?? '$_defaultMinTurn'),
      profiles: _profilesFromArgs(_readOption(args, '--profiles') ?? 'auto'),
      repeats: repeats,
      multiTurnCycles: multiTurnCycles,
      jsonOut: _readOption(args, '--json-out'),
      markdownOut: _readOption(args, '--markdown-out'),
      includeDeadline: _hasFlag(args, '--include-deadline'),
      strategyOverride: _readOption(args, '--strategy') == null
          ? null
          : _enumByName(
              _readOption(args, '--strategy')!,
              AiStrategyId.values,
              'strategy',
            ),
      failOnFinding: _hasFlag(args, '--fail-on-finding'),
    );
  }
}

Future<File> _resolveSaveFile(_Options options) async {
  final explicit = options.savePath;
  if (explicit != null) {
    final file = File(explicit);
    if (await file.exists()) return file;
    throw _UsageException('Save file not found: $explicit');
  }

  final roots = <Directory>[
    if (options.savesRoot != null) Directory(options.savesRoot!),
    ..._defaultSaveRoots(),
  ];
  File? bestFile;
  DateTime? bestSavedAt;
  for (final root in roots) {
    if (!await root.exists()) continue;
    await for (final entity in root.list(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('/snapshot.json')) {
        continue;
      }
      Map<String, dynamic> json;
      try {
        json = jsonDecode(await entity.readAsString()) as Map<String, dynamic>;
      } catch (_) {
        continue;
      }
      final save =
          (json['state'] as Map<String, dynamic>?)?['save']
              as Map<String, dynamic>?;
      if (save == null) continue;
      final turn = save['turn'] as int? ?? 0;
      if (turn < options.minTurn) continue;
      final savedAt = DateTime.tryParse(save['savedAt'] as String? ?? '');
      if (savedAt == null) continue;
      if (bestSavedAt == null || savedAt.isAfter(bestSavedAt)) {
        bestSavedAt = savedAt;
        bestFile = entity;
      }
    }
  }
  if (bestFile == null) {
    throw _UsageException(
      'No snapshot.json save at or above turn ${options.minTurn} was found.',
    );
  }
  return bestFile;
}

List<Directory> _defaultSaveRoots() {
  final home = Platform.environment['HOME'];
  if (home == null || home.trim().isEmpty) return const [];
  return [
    Directory(
      [
        home,
        'Library',
        'Containers',
        'dev.ernest.aonw',
        'Data',
        'Documents',
        'saves',
      ].join(Platform.pathSeparator),
    ),
    Directory(
      [
        home,
        'Library',
        'Application Support',
        'aonw',
        'saves',
      ].join(Platform.pathSeparator),
    ),
    Directory([home, 'Documents', 'saves'].join(Platform.pathSeparator)),
    Directory(
      [home, '.local', 'share', 'aonw', 'saves'].join(Platform.pathSeparator),
    ),
  ];
}

Future<SaveSnapshot> _loadSnapshot(File file) async {
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final state = json['state'] as Map<String, dynamic>?;
  if (state == null) {
    throw _UsageException('Snapshot file has no state object: ${file.path}');
  }
  return SaveSnapshotCodec.fromJson(state);
}

Future<MapData> _loadMap(SaveSnapshot snapshot, String? mapPath) async {
  final file = File(mapPath ?? 'assets/maps/${snapshot.save.mapName}/map.json');
  if (!await file.exists()) {
    throw _UsageException(
      'Map file not found: ${file.path}. Pass --map <path> if this is a saved map.',
    );
  }
  final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
  final tilesJson = json['tiles'] as List<dynamic>;
  return MapData(
    cols: json['cols'] as int,
    rows: json['rows'] as int,
    mapName: json['mapName'] as String?,
    defaultZoom: (json['defaultZoom'] as num?)?.toDouble() ?? 1.0,
    tiles: [
      for (final raw in tilesJson) _tileFromJson(raw as Map<String, dynamic>),
    ],
  );
}

TileData _tileFromJson(Map<String, dynamic> json) {
  return TileData(
    col: json['col'] as int,
    row: json['row'] as int,
    terrains: [
      for (final value in json['terrains'] as List<dynamic>)
        TerrainType.fromString(value as String),
    ],
    resources: [
      for (final value in json['resources'] as List<dynamic>)
        ResourceType.fromString(value as String),
    ],
    height: json['height'] as int,
  );
}

List<_ProfileSelection> _profilesFromArgs(String raw) {
  final values = raw
      .split(',')
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList();
  if (values.isEmpty) {
    throw const _UsageException('--profiles cannot be empty.');
  }
  return [
    for (final value in values)
      if (value == 'auto')
        const _ProfileSelection.auto()
      else
        _ProfileSelection.fixed(
          _enumByName(value, MctsRuntimeProfile.values, 'profile'),
        ),
  ];
}
