/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: unnecessary_null_comparison

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod/serverpod.dart' as _i1;
import '../../multiplayer/models/game_player.dart' as _i2;
import '../../multiplayer/models/game_snapshot.dart' as _i3;
import '../../multiplayer/models/game_event.dart' as _i4;
import 'package:aonw_server/src/generated/protocol.dart' as _i5;

abstract class GameMatch
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameMatch._({
    this.id,
    required this.publicId,
    required this.ownerUserIdentifier,
    required this.name,
    required this.mapName,
    required this.state,
    required this.turn,
    required this.maxPlayers,
    required this.minPlayers,
    required this.private,
    required this.quickplay,
    required this.createdAt,
    this.startedAt,
    this.autoStartAt,
    this.inviteCode,
    this.players,
    this.snapshots,
    this.events,
  });

  factory GameMatch({
    int? id,
    required String publicId,
    required String ownerUserIdentifier,
    required String name,
    required String mapName,
    required String state,
    required int turn,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    required bool quickplay,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  }) = _GameMatchImpl;

  factory GameMatch.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameMatch(
      id: jsonSerialization['id'] as int?,
      publicId: jsonSerialization['publicId'] as String,
      ownerUserIdentifier: jsonSerialization['ownerUserIdentifier'] as String,
      name: jsonSerialization['name'] as String,
      mapName: jsonSerialization['mapName'] as String,
      state: jsonSerialization['state'] as String,
      turn: jsonSerialization['turn'] as int,
      maxPlayers: jsonSerialization['maxPlayers'] as int,
      minPlayers: jsonSerialization['minPlayers'] as int,
      private: _i1.BoolJsonExtension.fromJson(jsonSerialization['private']),
      quickplay: _i1.BoolJsonExtension.fromJson(jsonSerialization['quickplay']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
      startedAt: jsonSerialization['startedAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(jsonSerialization['startedAt']),
      autoStartAt: jsonSerialization['autoStartAt'] == null
          ? null
          : _i1.DateTimeJsonExtension.fromJson(
              jsonSerialization['autoStartAt'],
            ),
      inviteCode: jsonSerialization['inviteCode'] as String?,
      players: jsonSerialization['players'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i2.GamePlayer>>(
              jsonSerialization['players'],
            ),
      snapshots: jsonSerialization['snapshots'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i3.GameSnapshot>>(
              jsonSerialization['snapshots'],
            ),
      events: jsonSerialization['events'] == null
          ? null
          : _i5.Protocol().deserialize<List<_i4.GameEvent>>(
              jsonSerialization['events'],
            ),
    );
  }

  static final t = GameMatchTable();

  static const db = GameMatchRepository._();

  @override
  int? id;

  String publicId;

  String ownerUserIdentifier;

  String name;

  String mapName;

  String state;

  int turn;

  int maxPlayers;

  int minPlayers;

  bool private;

  bool quickplay;

  DateTime createdAt;

  DateTime? startedAt;

  DateTime? autoStartAt;

  String? inviteCode;

  List<_i2.GamePlayer>? players;

  List<_i3.GameSnapshot>? snapshots;

  List<_i4.GameEvent>? events;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatch copyWith({
    int? id,
    String? publicId,
    String? ownerUserIdentifier,
    String? name,
    String? mapName,
    String? state,
    int? turn,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    bool? quickplay,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'ownerUserIdentifier': ownerUserIdentifier,
      'name': name,
      'mapName': mapName,
      'state': state,
      'turn': turn,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'private': private,
      'quickplay': quickplay,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (autoStartAt != null) 'autoStartAt': autoStartAt?.toJson(),
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (players != null)
        'players': players?.toJson(valueToJson: (v) => v.toJson()),
      if (snapshots != null)
        'snapshots': snapshots?.toJson(valueToJson: (v) => v.toJson()),
      if (events != null)
        'events': events?.toJson(valueToJson: (v) => v.toJson()),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameMatch',
      if (id != null) 'id': id,
      'publicId': publicId,
      'ownerUserIdentifier': ownerUserIdentifier,
      'name': name,
      'mapName': mapName,
      'state': state,
      'turn': turn,
      'maxPlayers': maxPlayers,
      'minPlayers': minPlayers,
      'private': private,
      'quickplay': quickplay,
      'createdAt': createdAt.toJson(),
      if (startedAt != null) 'startedAt': startedAt?.toJson(),
      if (autoStartAt != null) 'autoStartAt': autoStartAt?.toJson(),
      if (inviteCode != null) 'inviteCode': inviteCode,
      if (players != null)
        'players': players?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
      if (snapshots != null)
        'snapshots': snapshots?.toJson(
          valueToJson: (v) => v.toJsonForProtocol(),
        ),
      if (events != null)
        'events': events?.toJson(valueToJson: (v) => v.toJsonForProtocol()),
    };
  }

  static GameMatchInclude include({
    _i2.GamePlayerIncludeList? players,
    _i3.GameSnapshotIncludeList? snapshots,
    _i4.GameEventIncludeList? events,
  }) {
    return GameMatchInclude._(
      players: players,
      snapshots: snapshots,
      events: events,
    );
  }

  static GameMatchIncludeList includeList({
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    GameMatchInclude? include,
  }) {
    return GameMatchIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatch.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameMatch.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchImpl extends GameMatch {
  _GameMatchImpl({
    int? id,
    required String publicId,
    required String ownerUserIdentifier,
    required String name,
    required String mapName,
    required String state,
    required int turn,
    required int maxPlayers,
    required int minPlayers,
    required bool private,
    required bool quickplay,
    required DateTime createdAt,
    DateTime? startedAt,
    DateTime? autoStartAt,
    String? inviteCode,
    List<_i2.GamePlayer>? players,
    List<_i3.GameSnapshot>? snapshots,
    List<_i4.GameEvent>? events,
  }) : super._(
         id: id,
         publicId: publicId,
         ownerUserIdentifier: ownerUserIdentifier,
         name: name,
         mapName: mapName,
         state: state,
         turn: turn,
         maxPlayers: maxPlayers,
         minPlayers: minPlayers,
         private: private,
         quickplay: quickplay,
         createdAt: createdAt,
         startedAt: startedAt,
         autoStartAt: autoStartAt,
         inviteCode: inviteCode,
         players: players,
         snapshots: snapshots,
         events: events,
       );

  /// Returns a shallow copy of this [GameMatch]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatch copyWith({
    Object? id = _Undefined,
    String? publicId,
    String? ownerUserIdentifier,
    String? name,
    String? mapName,
    String? state,
    int? turn,
    int? maxPlayers,
    int? minPlayers,
    bool? private,
    bool? quickplay,
    DateTime? createdAt,
    Object? startedAt = _Undefined,
    Object? autoStartAt = _Undefined,
    Object? inviteCode = _Undefined,
    Object? players = _Undefined,
    Object? snapshots = _Undefined,
    Object? events = _Undefined,
  }) {
    return GameMatch(
      id: id is int? ? id : this.id,
      publicId: publicId ?? this.publicId,
      ownerUserIdentifier: ownerUserIdentifier ?? this.ownerUserIdentifier,
      name: name ?? this.name,
      mapName: mapName ?? this.mapName,
      state: state ?? this.state,
      turn: turn ?? this.turn,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      private: private ?? this.private,
      quickplay: quickplay ?? this.quickplay,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt is DateTime? ? startedAt : this.startedAt,
      autoStartAt: autoStartAt is DateTime? ? autoStartAt : this.autoStartAt,
      inviteCode: inviteCode is String? ? inviteCode : this.inviteCode,
      players: players is List<_i2.GamePlayer>?
          ? players
          : this.players?.map((e0) => e0.copyWith()).toList(),
      snapshots: snapshots is List<_i3.GameSnapshot>?
          ? snapshots
          : this.snapshots?.map((e0) => e0.copyWith()).toList(),
      events: events is List<_i4.GameEvent>?
          ? events
          : this.events?.map((e0) => e0.copyWith()).toList(),
    );
  }
}

class GameMatchUpdateTable extends _i1.UpdateTable<GameMatchTable> {
  GameMatchUpdateTable(super.table);

  _i1.ColumnValue<String, String> publicId(String value) =>
      _i1.ColumnValue(table.publicId, value);

  _i1.ColumnValue<String, String> ownerUserIdentifier(String value) =>
      _i1.ColumnValue(table.ownerUserIdentifier, value);

  _i1.ColumnValue<String, String> name(String value) =>
      _i1.ColumnValue(table.name, value);

  _i1.ColumnValue<String, String> mapName(String value) =>
      _i1.ColumnValue(table.mapName, value);

  _i1.ColumnValue<String, String> state(String value) =>
      _i1.ColumnValue(table.state, value);

  _i1.ColumnValue<int, int> turn(int value) =>
      _i1.ColumnValue(table.turn, value);

  _i1.ColumnValue<int, int> maxPlayers(int value) =>
      _i1.ColumnValue(table.maxPlayers, value);

  _i1.ColumnValue<int, int> minPlayers(int value) =>
      _i1.ColumnValue(table.minPlayers, value);

  _i1.ColumnValue<bool, bool> private(bool value) =>
      _i1.ColumnValue(table.private, value);

  _i1.ColumnValue<bool, bool> quickplay(bool value) =>
      _i1.ColumnValue(table.quickplay, value);

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(table.createdAt, value);

  _i1.ColumnValue<DateTime, DateTime> startedAt(DateTime? value) =>
      _i1.ColumnValue(table.startedAt, value);

  _i1.ColumnValue<DateTime, DateTime> autoStartAt(DateTime? value) =>
      _i1.ColumnValue(table.autoStartAt, value);

  _i1.ColumnValue<String, String> inviteCode(String? value) =>
      _i1.ColumnValue(table.inviteCode, value);
}

class GameMatchTable extends _i1.Table<int?> {
  GameMatchTable({super.tableRelation}) : super(tableName: 'aonw_match') {
    updateTable = GameMatchUpdateTable(this);
    publicId = _i1.ColumnString('publicId', this);
    ownerUserIdentifier = _i1.ColumnString('ownerUserIdentifier', this);
    name = _i1.ColumnString('name', this);
    mapName = _i1.ColumnString('mapName', this);
    state = _i1.ColumnString('state', this);
    turn = _i1.ColumnInt('turn', this);
    maxPlayers = _i1.ColumnInt('maxPlayers', this);
    minPlayers = _i1.ColumnInt('minPlayers', this);
    private = _i1.ColumnBool('private', this);
    quickplay = _i1.ColumnBool('quickplay', this);
    createdAt = _i1.ColumnDateTime('createdAt', this);
    startedAt = _i1.ColumnDateTime('startedAt', this);
    autoStartAt = _i1.ColumnDateTime('autoStartAt', this);
    inviteCode = _i1.ColumnString('inviteCode', this);
  }

  late final GameMatchUpdateTable updateTable;

  late final _i1.ColumnString publicId;

  late final _i1.ColumnString ownerUserIdentifier;

  late final _i1.ColumnString name;

  late final _i1.ColumnString mapName;

  late final _i1.ColumnString state;

  late final _i1.ColumnInt turn;

  late final _i1.ColumnInt maxPlayers;

  late final _i1.ColumnInt minPlayers;

  late final _i1.ColumnBool private;

  late final _i1.ColumnBool quickplay;

  late final _i1.ColumnDateTime createdAt;

  late final _i1.ColumnDateTime startedAt;

  late final _i1.ColumnDateTime autoStartAt;

  late final _i1.ColumnString inviteCode;

  _i2.GamePlayerTable? ___players;

  _i1.ManyRelation<_i2.GamePlayerTable>? _players;

  _i3.GameSnapshotTable? ___snapshots;

  _i1.ManyRelation<_i3.GameSnapshotTable>? _snapshots;

  _i4.GameEventTable? ___events;

  _i1.ManyRelation<_i4.GameEventTable>? _events;

  _i2.GamePlayerTable get __players {
    if (___players != null) return ___players!;
    ___players = _i1.createRelationTable(
      relationFieldName: '__players',
      field: GameMatch.t.id,
      foreignField: _i2.GamePlayer.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GamePlayerTable(tableRelation: foreignTableRelation),
    );
    return ___players!;
  }

  _i3.GameSnapshotTable get __snapshots {
    if (___snapshots != null) return ___snapshots!;
    ___snapshots = _i1.createRelationTable(
      relationFieldName: '__snapshots',
      field: GameMatch.t.id,
      foreignField: _i3.GameSnapshot.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameSnapshotTable(tableRelation: foreignTableRelation),
    );
    return ___snapshots!;
  }

  _i4.GameEventTable get __events {
    if (___events != null) return ___events!;
    ___events = _i1.createRelationTable(
      relationFieldName: '__events',
      field: GameMatch.t.id,
      foreignField: _i4.GameEvent.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.GameEventTable(tableRelation: foreignTableRelation),
    );
    return ___events!;
  }

  _i1.ManyRelation<_i2.GamePlayerTable> get players {
    if (_players != null) return _players!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'players',
      field: GameMatch.t.id,
      foreignField: _i2.GamePlayer.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GamePlayerTable(tableRelation: foreignTableRelation),
    );
    _players = _i1.ManyRelation<_i2.GamePlayerTable>(
      tableWithRelations: relationTable,
      table: _i2.GamePlayerTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _players!;
  }

  _i1.ManyRelation<_i3.GameSnapshotTable> get snapshots {
    if (_snapshots != null) return _snapshots!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'snapshots',
      field: GameMatch.t.id,
      foreignField: _i3.GameSnapshot.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i3.GameSnapshotTable(tableRelation: foreignTableRelation),
    );
    _snapshots = _i1.ManyRelation<_i3.GameSnapshotTable>(
      tableWithRelations: relationTable,
      table: _i3.GameSnapshotTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _snapshots!;
  }

  _i1.ManyRelation<_i4.GameEventTable> get events {
    if (_events != null) return _events!;
    var relationTable = _i1.createRelationTable(
      relationFieldName: 'events',
      field: GameMatch.t.id,
      foreignField: _i4.GameEvent.t.matchId,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i4.GameEventTable(tableRelation: foreignTableRelation),
    );
    _events = _i1.ManyRelation<_i4.GameEventTable>(
      tableWithRelations: relationTable,
      table: _i4.GameEventTable(
        tableRelation: relationTable.tableRelation!.lastRelation,
      ),
    );
    return _events!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    publicId,
    ownerUserIdentifier,
    name,
    mapName,
    state,
    turn,
    maxPlayers,
    minPlayers,
    private,
    quickplay,
    createdAt,
    startedAt,
    autoStartAt,
    inviteCode,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'players') {
      return __players;
    }
    if (relationField == 'snapshots') {
      return __snapshots;
    }
    if (relationField == 'events') {
      return __events;
    }
    return null;
  }
}

class GameMatchInclude extends _i1.IncludeObject {
  GameMatchInclude._({
    _i2.GamePlayerIncludeList? players,
    _i3.GameSnapshotIncludeList? snapshots,
    _i4.GameEventIncludeList? events,
  }) {
    _players = players;
    _snapshots = snapshots;
    _events = events;
  }

  _i2.GamePlayerIncludeList? _players;

  _i3.GameSnapshotIncludeList? _snapshots;

  _i4.GameEventIncludeList? _events;

  @override
  Map<String, _i1.Include?> get includes => {
    'players': _players,
    'snapshots': _snapshots,
    'events': _events,
  };

  @override
  _i1.Table<int?> get table => GameMatch.t;
}

class GameMatchIncludeList extends _i1.IncludeList {
  GameMatchIncludeList._({
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameMatch.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameMatch.t;
}

class GameMatchRepository {
  const GameMatchRepository._();

  final attach = const GameMatchAttachRepository._();

  final attachRow = const GameMatchAttachRowRepository._();

  final detach = const GameMatchDetachRepository._();

  final detachRow = const GameMatchDetachRowRepository._();

  /// Returns a list of [GameMatch]s matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order of the items use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// The maximum number of items can be set by [limit]. If no limit is set,
  /// all items matching the query will be returned.
  ///
  /// [offset] defines how many items to skip, after which [limit] (or all)
  /// items are read from the database.
  ///
  /// ```dart
  /// var persons = await Persons.db.find(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.firstName,
  ///   limit: 100,
  /// );
  /// ```
  Future<List<GameMatch>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameMatch>(
      where: where?.call(GameMatch.t),
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameMatch] matching the given query parameters.
  ///
  /// Use [where] to specify which items to include in the return value.
  /// If none is specified, all items will be returned.
  ///
  /// To specify the order use [orderBy] or [orderByList]
  /// when sorting by multiple columns.
  ///
  /// [offset] defines how many items to skip, after which the next one will be picked.
  ///
  /// ```dart
  /// var youngestPerson = await Persons.db.findFirstRow(
  ///   session,
  ///   where: (t) => t.lastName.equals('Jones'),
  ///   orderBy: (t) => t.age,
  /// );
  /// ```
  Future<GameMatch?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameMatch>(
      where: where?.call(GameMatch.t),
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameMatch] by its [id] or null if no such row exists.
  Future<GameMatch?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameMatchInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameMatch>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameMatch]s in the list and returns the inserted rows.
  ///
  /// The returned [GameMatch]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameMatch>> insert(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameMatch>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameMatch] and returns the inserted row.
  ///
  /// The returned [GameMatch] will have its `id` field set.
  Future<GameMatch> insertRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameMatch>(row, transaction: transaction);
  }

  /// Updates all [GameMatch]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameMatch>> update(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.ColumnSelections<GameMatchTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameMatch>(
      rows,
      columns: columns?.call(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatch]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameMatch> updateRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.ColumnSelections<GameMatchTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameMatch>(
      row,
      columns: columns?.call(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatch] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameMatch?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameMatchUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameMatch>(
      id,
      columnValues: columnValues(GameMatch.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameMatch]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameMatch>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameMatchUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchTable>? orderBy,
    _i1.OrderByListBuilder<GameMatchTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameMatch>(
      columnValues: columnValues(GameMatch.t.updateTable),
      where: where(GameMatch.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatch.t),
      orderByList: orderByList?.call(GameMatch.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameMatch]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameMatch>> delete(
    _i1.DatabaseSession session,
    List<GameMatch> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameMatch>(rows, transaction: transaction);
  }

  /// Deletes a single [GameMatch].
  Future<GameMatch> deleteRow(
    _i1.DatabaseSession session,
    GameMatch row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameMatch>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameMatch>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameMatch>(
      where: where(GameMatch.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameMatch>(
      where: where?.call(GameMatch.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameMatch] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameMatch>(
      where: where(GameMatch.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameMatchAttachRepository {
  const GameMatchAttachRepository._();

  /// Creates a relation between this [GameMatch] and the given [GamePlayer]s
  /// by setting each [GamePlayer]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> players(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i2.GamePlayer> gamePlayer, {
    _i1.Transaction? transaction,
  }) async {
    if (gamePlayer.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gamePlayer.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gamePlayer = gamePlayer
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i2.GamePlayer>(
      $gamePlayer,
      columns: [_i2.GamePlayer.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameSnapshot]s
  /// by setting each [GameSnapshot]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> snapshots(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i3.GameSnapshot> gameSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameSnapshot.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameSnapshot.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameSnapshot = gameSnapshot
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i3.GameSnapshot>(
      $gameSnapshot,
      columns: [_i3.GameSnapshot.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameEvent]s
  /// by setting each [GameEvent]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> events(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    List<_i4.GameEvent> gameEvent, {
    _i1.Transaction? transaction,
  }) async {
    if (gameEvent.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameEvent.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameEvent = gameEvent
        .map((e) => e.copyWith(matchId: gameMatch.id))
        .toList();
    await session.db.update<_i4.GameEvent>(
      $gameEvent,
      columns: [_i4.GameEvent.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchAttachRowRepository {
  const GameMatchAttachRowRepository._();

  /// Creates a relation between this [GameMatch] and the given [GamePlayer]
  /// by setting the [GamePlayer]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> players(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i2.GamePlayer gamePlayer, {
    _i1.Transaction? transaction,
  }) async {
    if (gamePlayer.id == null) {
      throw ArgumentError.notNull('gamePlayer.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gamePlayer = gamePlayer.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i2.GamePlayer>(
      $gamePlayer,
      columns: [_i2.GamePlayer.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameSnapshot]
  /// by setting the [GameSnapshot]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> snapshots(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i3.GameSnapshot gameSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameSnapshot.id == null) {
      throw ArgumentError.notNull('gameSnapshot.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameSnapshot = gameSnapshot.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i3.GameSnapshot>(
      $gameSnapshot,
      columns: [_i3.GameSnapshot.t.matchId],
      transaction: transaction,
    );
  }

  /// Creates a relation between this [GameMatch] and the given [GameEvent]
  /// by setting the [GameEvent]'s foreign key `matchId` to refer to this [GameMatch].
  Future<void> events(
    _i1.DatabaseSession session,
    GameMatch gameMatch,
    _i4.GameEvent gameEvent, {
    _i1.Transaction? transaction,
  }) async {
    if (gameEvent.id == null) {
      throw ArgumentError.notNull('gameEvent.id');
    }
    if (gameMatch.id == null) {
      throw ArgumentError.notNull('gameMatch.id');
    }

    var $gameEvent = gameEvent.copyWith(matchId: gameMatch.id);
    await session.db.updateRow<_i4.GameEvent>(
      $gameEvent,
      columns: [_i4.GameEvent.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchDetachRepository {
  const GameMatchDetachRepository._();

  /// Detaches the relation between this [GameMatch] and the given [GamePlayer]
  /// by setting the [GamePlayer]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> players(
    _i1.DatabaseSession session,
    List<_i2.GamePlayer> gamePlayer, {
    _i1.Transaction? transaction,
  }) async {
    if (gamePlayer.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gamePlayer.id');
    }

    var $gamePlayer = gamePlayer.map((e) => e.copyWith(matchId: null)).toList();
    await session.db.update<_i2.GamePlayer>(
      $gamePlayer,
      columns: [_i2.GamePlayer.t.matchId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [GameMatch] and the given [GameSnapshot]
  /// by setting the [GameSnapshot]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> snapshots(
    _i1.DatabaseSession session,
    List<_i3.GameSnapshot> gameSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameSnapshot.any((e) => e.id == null)) {
      throw ArgumentError.notNull('gameSnapshot.id');
    }

    var $gameSnapshot = gameSnapshot
        .map((e) => e.copyWith(matchId: null))
        .toList();
    await session.db.update<_i3.GameSnapshot>(
      $gameSnapshot,
      columns: [_i3.GameSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}

class GameMatchDetachRowRepository {
  const GameMatchDetachRowRepository._();

  /// Detaches the relation between this [GameMatch] and the given [GamePlayer]
  /// by setting the [GamePlayer]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> players(
    _i1.DatabaseSession session,
    _i2.GamePlayer gamePlayer, {
    _i1.Transaction? transaction,
  }) async {
    if (gamePlayer.id == null) {
      throw ArgumentError.notNull('gamePlayer.id');
    }

    var $gamePlayer = gamePlayer.copyWith(matchId: null);
    await session.db.updateRow<_i2.GamePlayer>(
      $gamePlayer,
      columns: [_i2.GamePlayer.t.matchId],
      transaction: transaction,
    );
  }

  /// Detaches the relation between this [GameMatch] and the given [GameSnapshot]
  /// by setting the [GameSnapshot]'s foreign key `matchId` to `null`.
  ///
  /// This removes the association between the two models without deleting
  /// the related record.
  Future<void> snapshots(
    _i1.DatabaseSession session,
    _i3.GameSnapshot gameSnapshot, {
    _i1.Transaction? transaction,
  }) async {
    if (gameSnapshot.id == null) {
      throw ArgumentError.notNull('gameSnapshot.id');
    }

    var $gameSnapshot = gameSnapshot.copyWith(matchId: null);
    await session.db.updateRow<_i3.GameSnapshot>(
      $gameSnapshot,
      columns: [_i3.GameSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}
