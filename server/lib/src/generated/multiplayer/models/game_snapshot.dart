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
import 'package:aonw_core/protocol.dart' as _i3;
import 'package:aonw_server/src/generated/protocol.dart' as _i4;

abstract class GameSnapshot
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameSnapshot._({
    this.id,
    required this.matchId,
    this.match,
    required this.offset,
    required this.snapshot,
    required this.createdAt,
  });

  factory GameSnapshot({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required _i3.WireSnapshot snapshot,
    required DateTime createdAt,
  }) = _GameSnapshotImpl;

  factory GameSnapshot.fromJson(Map<String, dynamic> jsonSerialization) {
    return GameSnapshot(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i4.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      offset: jsonSerialization['offset'] as int,
      snapshot: _i3.WireSnapshot.fromJson(jsonSerialization['snapshot']),
      createdAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['createdAt'],
      ),
    );
  }

  static final t = GameSnapshotTable();

  static const db = GameSnapshotRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  int offset;

  _i3.WireSnapshot snapshot;

  DateTime createdAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameSnapshot copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    int? offset,
    _i3.WireSnapshot? snapshot,
    DateTime? createdAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'offset': offset,
      'snapshot': snapshot.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'GameSnapshot',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJsonForProtocol(),
      'offset': offset,
      'snapshot':
          // ignore: unnecessary_type_check
          snapshot is _i1.ProtocolSerialization
          ? (snapshot as _i1.ProtocolSerialization).toJsonForProtocol()
          : snapshot.toJson(),
      'createdAt': createdAt.toJson(),
    };
  }

  static GameSnapshotInclude include({_i2.GameMatchInclude? match}) {
    return GameSnapshotInclude._(match: match);
  }

  static GameSnapshotIncludeList includeList({
    _i1.WhereExpressionBuilder<GameSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameSnapshotTable>? orderByList,
    GameSnapshotInclude? include,
  }) {
    return GameSnapshotIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameSnapshot.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameSnapshot.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameSnapshotImpl extends GameSnapshot {
  _GameSnapshotImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required int offset,
    required _i3.WireSnapshot snapshot,
    required DateTime createdAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         offset: offset,
         snapshot: snapshot,
         createdAt: createdAt,
       );

  /// Returns a shallow copy of this [GameSnapshot]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameSnapshot copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    int? offset,
    _i3.WireSnapshot? snapshot,
    DateTime? createdAt,
  }) {
    return GameSnapshot(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      offset: offset ?? this.offset,
      snapshot: snapshot ?? this.snapshot.copyWith(),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class GameSnapshotUpdateTable extends _i1.UpdateTable<GameSnapshotTable> {
  GameSnapshotUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) =>
      _i1.ColumnValue(table.matchId, value);

  _i1.ColumnValue<int, int> offset(int value) =>
      _i1.ColumnValue(table.offset, value);

  _i1.ColumnValue<_i3.WireSnapshot, _i3.WireSnapshot> snapshot(
    _i3.WireSnapshot value,
  ) => _i1.ColumnValue(table.snapshot, value);

  _i1.ColumnValue<DateTime, DateTime> createdAt(DateTime value) =>
      _i1.ColumnValue(table.createdAt, value);
}

class GameSnapshotTable extends _i1.Table<int?> {
  GameSnapshotTable({super.tableRelation}) : super(tableName: 'aonw_snapshot') {
    updateTable = GameSnapshotUpdateTable(this);
    matchId = _i1.ColumnInt('matchId', this);
    offset = _i1.ColumnInt('offset', this);
    snapshot = _i1.ColumnSerializable<_i3.WireSnapshot>('snapshot', this);
    createdAt = _i1.ColumnDateTime('createdAt', this);
  }

  late final GameSnapshotUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnInt offset;

  late final _i1.ColumnSerializable<_i3.WireSnapshot> snapshot;

  late final _i1.ColumnDateTime createdAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameSnapshot.t.matchId,
      foreignField: _i2.GameMatch.t.id,
      tableRelation: tableRelation,
      createTable: (foreignTableRelation) =>
          _i2.GameMatchTable(tableRelation: foreignTableRelation),
    );
    return _match!;
  }

  @override
  List<_i1.Column> get columns => [id, matchId, offset, snapshot, createdAt];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GameSnapshotInclude extends _i1.IncludeObject {
  GameSnapshotInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameSnapshot.t;
}

class GameSnapshotIncludeList extends _i1.IncludeList {
  GameSnapshotIncludeList._({
    _i1.WhereExpressionBuilder<GameSnapshotTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameSnapshot.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameSnapshot.t;
}

class GameSnapshotRepository {
  const GameSnapshotRepository._();

  final attachRow = const GameSnapshotAttachRowRepository._();

  /// Returns a list of [GameSnapshot]s matching the given query parameters.
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
  Future<List<GameSnapshot>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameSnapshotTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
    GameSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameSnapshot>(
      where: where?.call(GameSnapshot.t),
      orderBy: orderBy?.call(GameSnapshot.t),
      orderByList: orderByList?.call(GameSnapshot.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameSnapshot] matching the given query parameters.
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
  Future<GameSnapshot?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameSnapshotTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameSnapshotTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameSnapshotTable>? orderByList,
    _i1.Transaction? transaction,
    GameSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameSnapshot>(
      where: where?.call(GameSnapshot.t),
      orderBy: orderBy?.call(GameSnapshot.t),
      orderByList: orderByList?.call(GameSnapshot.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameSnapshot] by its [id] or null if no such row exists.
  Future<GameSnapshot?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameSnapshotInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameSnapshot>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameSnapshot]s in the list and returns the inserted rows.
  ///
  /// The returned [GameSnapshot]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameSnapshot>> insert(
    _i1.DatabaseSession session,
    List<GameSnapshot> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameSnapshot>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameSnapshot] and returns the inserted row.
  ///
  /// The returned [GameSnapshot] will have its `id` field set.
  Future<GameSnapshot> insertRow(
    _i1.DatabaseSession session,
    GameSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameSnapshot>(row, transaction: transaction);
  }

  /// Updates all [GameSnapshot]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameSnapshot>> update(
    _i1.DatabaseSession session,
    List<GameSnapshot> rows, {
    _i1.ColumnSelections<GameSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameSnapshot>(
      rows,
      columns: columns?.call(GameSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameSnapshot]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameSnapshot> updateRow(
    _i1.DatabaseSession session,
    GameSnapshot row, {
    _i1.ColumnSelections<GameSnapshotTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameSnapshot>(
      row,
      columns: columns?.call(GameSnapshot.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameSnapshot] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameSnapshot?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameSnapshotUpdateTable> columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameSnapshot>(
      id,
      columnValues: columnValues(GameSnapshot.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameSnapshot]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameSnapshot>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameSnapshotUpdateTable> columnValues,
    required _i1.WhereExpressionBuilder<GameSnapshotTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameSnapshotTable>? orderBy,
    _i1.OrderByListBuilder<GameSnapshotTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameSnapshot>(
      columnValues: columnValues(GameSnapshot.t.updateTable),
      where: where(GameSnapshot.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameSnapshot.t),
      orderByList: orderByList?.call(GameSnapshot.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameSnapshot]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameSnapshot>> delete(
    _i1.DatabaseSession session,
    List<GameSnapshot> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameSnapshot>(rows, transaction: transaction);
  }

  /// Deletes a single [GameSnapshot].
  Future<GameSnapshot> deleteRow(
    _i1.DatabaseSession session,
    GameSnapshot row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameSnapshot>(row, transaction: transaction);
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameSnapshot>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameSnapshotTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameSnapshot>(
      where: where(GameSnapshot.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameSnapshotTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameSnapshot>(
      where: where?.call(GameSnapshot.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameSnapshot] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameSnapshotTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameSnapshot>(
      where: where(GameSnapshot.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameSnapshotAttachRowRepository {
  const GameSnapshotAttachRowRepository._();

  /// Creates a relation between the given [GameSnapshot] and [GameMatch]
  /// by setting the [GameSnapshot]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameSnapshot gameSnapshot,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameSnapshot.id == null) {
      throw ArgumentError.notNull('gameSnapshot.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameSnapshot = gameSnapshot.copyWith(matchId: match.id);
    await session.db.updateRow<GameSnapshot>(
      $gameSnapshot,
      columns: [GameSnapshot.t.matchId],
      transaction: transaction,
    );
  }
}
