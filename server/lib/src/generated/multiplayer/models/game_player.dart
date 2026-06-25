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
import '../../multiplayer/models/game_match.dart' as _i2;
import 'package:aonw_server/src/generated/protocol.dart' as _i3;

abstract class GamePlayer
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GamePlayer._({
    this.id,
    required this.matchId,
    this.match,
    required this.publicPlayerId,
    required this.userIdentifier,
    required this.displayName,
    required this.colorValue,
    required this.countryId,
    required this.kind,
    required this.connectionState,
    required this.ready,
    required this.seatOrder,
  });

  factory GamePlayer({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String publicPlayerId,
    required String userIdentifier,
    required String displayName,
    required int colorValue,
    required String countryId,
    required String kind,
    required String connectionState,
    required bool ready,
    required int seatOrder,
  }) = _GamePlayerImpl;

  factory GamePlayer.fromJson(Map<String, dynamic> jsonSerialization) {
    return GamePlayer(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      publicPlayerId: jsonSerialization['publicPlayerId'] as String,
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      displayName: jsonSerialization['displayName'] as String,
      colorValue: jsonSerialization['colorValue'] as int,
      countryId: jsonSerialization['countryId'] as String,
      kind: jsonSerialization['kind'] as String,
      connectionState: jsonSerialization['connectionState'] as String,
      ready: _i1.BoolJsonExtension.fromJson(jsonSerialization['ready']),
      seatOrder: jsonSerialization['seatOrder'] as int,
    );
  }

  static final t = GamePlayerTable();

  static const db = GamePlayerRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String publicPlayerId;

  String userIdentifier;

  String displayName;

  int colorValue;

  String countryId;

  String kind;

  String connectionState;

  bool ready;

  int seatOrder;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GamePlayer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GamePlayer copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? publicPlayerId,
    String? userIdentifier,
    String? displayName,
    int? colorValue,
    String? countryId,
    String? kind,
    String? connectionState,
    bool? ready,
    int? seatOrder,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GamePlayer',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'publicPlayerId': publicPlayerId,
      'userIdentifier': userIdentifier,
      'displayName': displayName,
      'colorValue': colorValue,
      'countryId': countryId,
      'kind': kind,
      'connectionState': connectionState,
      'ready': ready,
      'seatOrder': seatOrder,
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GamePlayer',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'publicPlayerId': publicPlayerId,
      'userIdentifier': userIdentifier,
      'displayName': displayName,
      'colorValue': colorValue,
      'countryId': countryId,
      'kind': kind,
      'connectionState': connectionState,
      'ready': ready,
      'seatOrder': seatOrder,
    };
  }

  static GamePlayerInclude include({_i2.GameMatchInclude? match}) {
    return GamePlayerInclude._(match: match);
  }

  static GamePlayerIncludeList includeList({
    _i1.WhereExpressionBuilder<GamePlayerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GamePlayerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GamePlayerTable>? orderByList,
    GamePlayerInclude? include,
  }) {
    return GamePlayerIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GamePlayer.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GamePlayer.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GamePlayerImpl extends GamePlayer {
  _GamePlayerImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String publicPlayerId,
    required String userIdentifier,
    required String displayName,
    required int colorValue,
    required String countryId,
    required String kind,
    required String connectionState,
    required bool ready,
    required int seatOrder,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         publicPlayerId: publicPlayerId,
         userIdentifier: userIdentifier,
         displayName: displayName,
         colorValue: colorValue,
         countryId: countryId,
         kind: kind,
         connectionState: connectionState,
         ready: ready,
         seatOrder: seatOrder,
       );

  /// Returns a shallow copy of this [GamePlayer]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GamePlayer copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? publicPlayerId,
    String? userIdentifier,
    String? displayName,
    int? colorValue,
    String? countryId,
    String? kind,
    String? connectionState,
    bool? ready,
    int? seatOrder,
  }) {
    return GamePlayer(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      publicPlayerId: publicPlayerId ?? this.publicPlayerId,
      userIdentifier: userIdentifier ?? this.userIdentifier,
      displayName: displayName ?? this.displayName,
      colorValue: colorValue ?? this.colorValue,
      countryId: countryId ?? this.countryId,
      kind: kind ?? this.kind,
      connectionState: connectionState ?? this.connectionState,
      ready: ready ?? this.ready,
      seatOrder: seatOrder ?? this.seatOrder,
    );
  }
}

class GamePlayerUpdateTable extends _i1.UpdateTable<GamePlayerTable> {
  GamePlayerUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) =>
      _i1.ColumnValue(table.matchId, value);

  _i1.ColumnValue<String, String> publicPlayerId(String value) =>
      _i1.ColumnValue(table.publicPlayerId, value);

  _i1.ColumnValue<String, String> userIdentifier(String value) =>
      _i1.ColumnValue(table.userIdentifier, value);

  _i1.ColumnValue<String, String> displayName(String value) =>
      _i1.ColumnValue(table.displayName, value);

  _i1.ColumnValue<int, int> colorValue(int value) =>
      _i1.ColumnValue(table.colorValue, value);

  _i1.ColumnValue<String, String> countryId(String value) =>
      _i1.ColumnValue(table.countryId, value);

  _i1.ColumnValue<String, String> kind(String value) =>
      _i1.ColumnValue(table.kind, value);

  _i1.ColumnValue<String, String> connectionState(String value) =>
      _i1.ColumnValue(table.connectionState, value);

  _i1.ColumnValue<bool, bool> ready(bool value) =>
      _i1.ColumnValue(table.ready, value);

  _i1.ColumnValue<int, int> seatOrder(int value) =>
      _i1.ColumnValue(table.seatOrder, value);
}

class GamePlayerTable extends _i1.Table<int?> {
  GamePlayerTable({super.tableRelation}) : super(tableName: 'aonw_player') {
    updateTable = GamePlayerUpdateTable(this);
    matchId = _i1.ColumnInt('matchId', this);
    publicPlayerId = _i1.ColumnString('publicPlayerId', this);
    userIdentifier = _i1.ColumnString('userIdentifier', this);
    displayName = _i1.ColumnString('displayName', this);
    colorValue = _i1.ColumnInt('colorValue', this);
    countryId = _i1.ColumnString('countryId', this);
    kind = _i1.ColumnString('kind', this);
    connectionState = _i1.ColumnString('connectionState', this);
    ready = _i1.ColumnBool('ready', this);
    seatOrder = _i1.ColumnInt('seatOrder', this);
  }

  late final GamePlayerUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnString publicPlayerId;

  late final _i1.ColumnString userIdentifier;

  late final _i1.ColumnString displayName;

  late final _i1.ColumnInt colorValue;

  late final _i1.ColumnString countryId;

  late final _i1.ColumnString kind;

  late final _i1.ColumnString connectionState;

  late final _i1.ColumnBool ready;

  late final _i1.ColumnInt seatOrder;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GamePlayer.t.matchId,
      foreignField: _i2.GameMatch.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameMatchTable(tableRelation: foreignTableRelation),
    );
    return _match!;
  }

  @override
  List<_i1.Column> get columns => [
    id,
    matchId,
    publicPlayerId,
    userIdentifier,
    displayName,
    colorValue,
    countryId,
    kind,
    connectionState,
    ready,
    seatOrder,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GamePlayerInclude extends _i1.IncludeObject {
  GamePlayerInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GamePlayer.t;
}

class GamePlayerIncludeList extends _i1.IncludeList {
  GamePlayerIncludeList._({
    _i1.WhereExpressionBuilder<GamePlayerTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GamePlayer.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GamePlayer.t;
}

class GamePlayerRepository {
  const GamePlayerRepository._();

  final attachRow = const GamePlayerAttachRowRepository._();

  /// Returns a list of [GamePlayer]s matching the given query parameters.
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
  Future<List<GamePlayer>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GamePlayerTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GamePlayerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GamePlayerTable>? orderByList,
    _i1.Transaction? transaction,
    GamePlayerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GamePlayer>(
      where: where?.call(GamePlayer.t),
      orderBy: orderBy?.call(GamePlayer.t),
      orderByList: orderByList?.call(GamePlayer.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GamePlayer] matching the given query parameters.
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
  Future<GamePlayer?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GamePlayerTable>? where,
    int? offset,
    _i1.OrderByBuilder<GamePlayerTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GamePlayerTable>? orderByList,
    _i1.Transaction? transaction,
    GamePlayerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GamePlayer>(
      where: where?.call(GamePlayer.t),
      orderBy: orderBy?.call(GamePlayer.t),
      orderByList: orderByList?.call(GamePlayer.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GamePlayer] by its [id] or null if no such row exists.
  Future<GamePlayer?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GamePlayerInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GamePlayer>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GamePlayer]s in the list and returns the inserted rows.
  ///
  /// The returned [GamePlayer]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GamePlayer>> insert(
    _i1.DatabaseSession session,
    List<GamePlayer> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GamePlayer>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GamePlayer] and returns the inserted row.
  ///
  /// The returned [GamePlayer] will have its `id` field set.
  Future<GamePlayer> insertRow(
    _i1.DatabaseSession session,
    GamePlayer row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GamePlayer>(row, transaction: transaction);
  }

  /// Updates all [GamePlayer]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GamePlayer>> update(
    _i1.DatabaseSession session,
    List<GamePlayer> rows, {
    _i1.ColumnSelections<GamePlayerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GamePlayer>(
      rows,
      columns: columns?.call(GamePlayer.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GamePlayer]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GamePlayer> updateRow(
    _i1.DatabaseSession session,
    GamePlayer row, {
    _i1.ColumnSelections<GamePlayerTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GamePlayer>(
      row,
      columns: columns?.call(GamePlayer.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GamePlayer] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GamePlayer?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GamePlayerUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GamePlayer>(
      id,
      columnValues: columnValues(GamePlayer.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GamePlayer]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GamePlayer>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GamePlayerUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GamePlayerTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GamePlayerTable>? orderBy,
    _i1.OrderByListBuilder<GamePlayerTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GamePlayer>(
      columnValues: columnValues(GamePlayer.t.updateTable),
      where: where(GamePlayer.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GamePlayer.t),
      orderByList: orderByList?.call(GamePlayer.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GamePlayer]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GamePlayer>> delete(
    _i1.DatabaseSession session,
    List<GamePlayer> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GamePlayer>(rows, transaction: transaction);
  }

  /// Deletes a single [GamePlayer].
  Future<GamePlayer> deleteRow(
    _i1.DatabaseSession session,
    GamePlayer row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GamePlayer>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GamePlayer>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GamePlayerTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GamePlayer>(
      where: where(GamePlayer.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GamePlayerTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GamePlayer>(
      where: where?.call(GamePlayer.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GamePlayer] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GamePlayerTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GamePlayer>(
      where: where(GamePlayer.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GamePlayerAttachRowRepository {
  const GamePlayerAttachRowRepository._();

  /// Creates a relation between the given [GamePlayer] and [GameMatch]
  /// by setting the [GamePlayer]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GamePlayer gamePlayer,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gamePlayer.id == null) {
      throw ArgumentError.notNull('gamePlayer.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gamePlayer = gamePlayer.copyWith(matchId: match.id);
    await session.db.updateRow<GamePlayer>(
      $gamePlayer,
      columns: [GamePlayer.t.matchId],
      transaction: transaction,
    );
  }
}
