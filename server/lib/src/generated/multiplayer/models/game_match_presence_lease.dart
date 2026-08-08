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

abstract class GameMatchPresenceLease
    implements _i1.TableRow<int?>, _i1.ProtocolSerialization {
  GameMatchPresenceLease._({
    this.id,
    required this.matchId,
    this.match,
    required this.userIdentifier,
    required this.connectionGeneration,
    required this.expiresAt,
    required this.updatedAt,
  });

  factory GameMatchPresenceLease({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime expiresAt,
    required DateTime updatedAt,
  }) = _GameMatchPresenceLeaseImpl;

  factory GameMatchPresenceLease.fromJson(
    Map<String, dynamic> jsonSerialization,
  ) {
    return GameMatchPresenceLease(
      id: jsonSerialization['id'] as int?,
      matchId: jsonSerialization['matchId'] as int,
      match: jsonSerialization['match'] == null
          ? null
          : _i3.Protocol().deserialize<_i2.GameMatch>(
              jsonSerialization['match'],
            ),
      userIdentifier: jsonSerialization['userIdentifier'] as String,
      connectionGeneration: jsonSerialization['connectionGeneration'] as String,
      expiresAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['expiresAt'],
      ),
      updatedAt: _i1.DateTimeJsonExtension.fromJson(
        jsonSerialization['updatedAt'],
      ),
    );
  }

  static final t = GameMatchPresenceLeaseTable();

  static const db = GameMatchPresenceLeaseRepository._();

  @override
  int? id;

  int matchId;

  _i2.GameMatch? match;

  String userIdentifier;

  String connectionGeneration;

  DateTime expiresAt;

  DateTime updatedAt;

  @override
  _i1.Table<int?> get table => t;

  /// Returns a shallow copy of this [GameMatchPresenceLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  GameMatchPresenceLease copyWith({
    int? id,
    int? matchId,
    _i2.GameMatch? match,
    String? userIdentifier,
    String? connectionGeneration,
    DateTime? expiresAt,
    DateTime? updatedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'GameMatchPresenceLease',
      if (id != null) 'id': id,
      'matchId': matchId,
      if (match != null) 'match': match?.toJson(),
      'userIdentifier': userIdentifier,
      'connectionGeneration': connectionGeneration,
      'expiresAt': expiresAt.toJson(),
      'updatedAt': updatedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {};
  }

  static GameMatchPresenceLeaseInclude include({_i2.GameMatchInclude? match}) {
    return GameMatchPresenceLeaseInclude._(match: match);
  }

  static GameMatchPresenceLeaseIncludeList includeList({
    _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchPresenceLeaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchPresenceLeaseTable>? orderByList,
    GameMatchPresenceLeaseInclude? include,
  }) {
    return GameMatchPresenceLeaseIncludeList._(
      where: where,
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatchPresenceLease.t),
      orderDescending: orderDescending,
      orderByList: orderByList?.call(GameMatchPresenceLease.t),
      include: include,
    );
  }

  @override
  String toString() {
    return _i1.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _GameMatchPresenceLeaseImpl extends GameMatchPresenceLease {
  _GameMatchPresenceLeaseImpl({
    int? id,
    required int matchId,
    _i2.GameMatch? match,
    required String userIdentifier,
    required String connectionGeneration,
    required DateTime expiresAt,
    required DateTime updatedAt,
  }) : super._(
         id: id,
         matchId: matchId,
         match: match,
         userIdentifier: userIdentifier,
         connectionGeneration: connectionGeneration,
         expiresAt: expiresAt,
         updatedAt: updatedAt,
       );

  /// Returns a shallow copy of this [GameMatchPresenceLease]
  /// with some or all fields replaced by the given arguments.
  @_i1.useResult
  @override
  GameMatchPresenceLease copyWith({
    Object? id = _Undefined,
    int? matchId,
    Object? match = _Undefined,
    String? userIdentifier,
    String? connectionGeneration,
    DateTime? expiresAt,
    DateTime? updatedAt,
  }) {
    return GameMatchPresenceLease(
      id: id is int? ? id : this.id,
      matchId: matchId ?? this.matchId,
      match: match is _i2.GameMatch? ? match : this.match?.copyWith(),
      userIdentifier: userIdentifier ?? this.userIdentifier,
      connectionGeneration: connectionGeneration ?? this.connectionGeneration,
      expiresAt: expiresAt ?? this.expiresAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class GameMatchPresenceLeaseUpdateTable
    extends _i1.UpdateTable<GameMatchPresenceLeaseTable> {
  GameMatchPresenceLeaseUpdateTable(super.table);

  _i1.ColumnValue<int, int> matchId(int value) => _i1.ColumnValue(
    table.matchId,
    value,
  );

  _i1.ColumnValue<String, String> userIdentifier(String value) =>
      _i1.ColumnValue(
        table.userIdentifier,
        value,
      );

  _i1.ColumnValue<String, String> connectionGeneration(String value) =>
      _i1.ColumnValue(
        table.connectionGeneration,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> expiresAt(DateTime value) =>
      _i1.ColumnValue(
        table.expiresAt,
        value,
      );

  _i1.ColumnValue<DateTime, DateTime> updatedAt(DateTime value) =>
      _i1.ColumnValue(
        table.updatedAt,
        value,
      );
}

class GameMatchPresenceLeaseTable extends _i1.Table<int?> {
  GameMatchPresenceLeaseTable({super.tableRelation})
    : super(tableName: 'aonw_match_presence_lease') {
    updateTable = GameMatchPresenceLeaseUpdateTable(this);
    matchId = _i1.ColumnInt(
      'matchId',
      this,
    );
    userIdentifier = _i1.ColumnString(
      'userIdentifier',
      this,
    );
    connectionGeneration = _i1.ColumnString(
      'connectionGeneration',
      this,
    );
    expiresAt = _i1.ColumnDateTime(
      'expiresAt',
      this,
    );
    updatedAt = _i1.ColumnDateTime(
      'updatedAt',
      this,
    );
  }

  late final GameMatchPresenceLeaseUpdateTable updateTable;

  late final _i1.ColumnInt matchId;

  _i2.GameMatchTable? _match;

  late final _i1.ColumnString userIdentifier;

  late final _i1.ColumnString connectionGeneration;

  late final _i1.ColumnDateTime expiresAt;

  late final _i1.ColumnDateTime updatedAt;

  _i2.GameMatchTable get match {
    if (_match != null) return _match!;
    _match = _i1.createRelationTable(
      relationFieldName: 'match',
      field: GameMatchPresenceLease.t.matchId,
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
    userIdentifier,
    connectionGeneration,
    expiresAt,
    updatedAt,
  ];

  @override
  _i1.Table? getRelationTable(String relationField) {
    if (relationField == 'match') {
      return match;
    }
    return null;
  }
}

class GameMatchPresenceLeaseInclude extends _i1.IncludeObject {
  GameMatchPresenceLeaseInclude._({_i2.GameMatchInclude? match}) {
    _match = match;
  }

  _i2.GameMatchInclude? _match;

  @override
  Map<String, _i1.Include?> get includes => {'match': _match};

  @override
  _i1.Table<int?> get table => GameMatchPresenceLease.t;
}

class GameMatchPresenceLeaseIncludeList extends _i1.IncludeList {
  GameMatchPresenceLeaseIncludeList._({
    _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable>? where,
    super.limit,
    super.offset,
    super.orderBy,
    super.orderDescending,
    super.orderByList,
    super.include,
  }) {
    super.where = where?.call(GameMatchPresenceLease.t);
  }

  @override
  Map<String, _i1.Include?> get includes => include?.includes ?? {};

  @override
  _i1.Table<int?> get table => GameMatchPresenceLease.t;
}

class GameMatchPresenceLeaseRepository {
  const GameMatchPresenceLeaseRepository._();

  final attachRow = const GameMatchPresenceLeaseAttachRowRepository._();

  /// Returns a list of [GameMatchPresenceLease]s matching the given query parameters.
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
  Future<List<GameMatchPresenceLease>> find(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable>? where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchPresenceLeaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchPresenceLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchPresenceLeaseInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.find<GameMatchPresenceLease>(
      where: where?.call(GameMatchPresenceLease.t),
      orderBy: orderBy?.call(GameMatchPresenceLease.t),
      orderByList: orderByList?.call(GameMatchPresenceLease.t),
      orderDescending: orderDescending,
      limit: limit,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Returns the first matching [GameMatchPresenceLease] matching the given query parameters.
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
  Future<GameMatchPresenceLease?> findFirstRow(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable>? where,
    int? offset,
    _i1.OrderByBuilder<GameMatchPresenceLeaseTable>? orderBy,
    bool orderDescending = false,
    _i1.OrderByListBuilder<GameMatchPresenceLeaseTable>? orderByList,
    _i1.Transaction? transaction,
    GameMatchPresenceLeaseInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findFirstRow<GameMatchPresenceLease>(
      where: where?.call(GameMatchPresenceLease.t),
      orderBy: orderBy?.call(GameMatchPresenceLease.t),
      orderByList: orderByList?.call(GameMatchPresenceLease.t),
      orderDescending: orderDescending,
      offset: offset,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Finds a single [GameMatchPresenceLease] by its [id] or null if no such row exists.
  Future<GameMatchPresenceLease?> findById(
    _i1.DatabaseSession session,
    int id, {
    _i1.Transaction? transaction,
    GameMatchPresenceLeaseInclude? include,
    _i1.LockMode? lockMode,
    _i1.LockBehavior? lockBehavior,
  }) async {
    return session.db.findById<GameMatchPresenceLease>(
      id,
      transaction: transaction,
      include: include,
      lockMode: lockMode,
      lockBehavior: lockBehavior,
    );
  }

  /// Inserts all [GameMatchPresenceLease]s in the list and returns the inserted rows.
  ///
  /// The returned [GameMatchPresenceLease]s will have their `id` fields set.
  ///
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// insert, none of the rows will be inserted.
  ///
  /// If [ignoreConflicts] is set to `true`, rows that conflict with existing
  /// rows are silently skipped, and only the successfully inserted rows are
  /// returned.
  Future<List<GameMatchPresenceLease>> insert(
    _i1.DatabaseSession session,
    List<GameMatchPresenceLease> rows, {
    _i1.Transaction? transaction,
    bool ignoreConflicts = false,
  }) async {
    return session.db.insert<GameMatchPresenceLease>(
      rows,
      transaction: transaction,
      ignoreConflicts: ignoreConflicts,
    );
  }

  /// Inserts a single [GameMatchPresenceLease] and returns the inserted row.
  ///
  /// The returned [GameMatchPresenceLease] will have its `id` field set.
  Future<GameMatchPresenceLease> insertRow(
    _i1.DatabaseSession session,
    GameMatchPresenceLease row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.insertRow<GameMatchPresenceLease>(
      row,
      transaction: transaction,
    );
  }

  /// Updates all [GameMatchPresenceLease]s in the list and returns the updated rows. If
  /// [columns] is provided, only those columns will be updated. Defaults to
  /// all columns.
  /// This is an atomic operation, meaning that if one of the rows fails to
  /// update, none of the rows will be updated.
  Future<List<GameMatchPresenceLease>> update(
    _i1.DatabaseSession session,
    List<GameMatchPresenceLease> rows, {
    _i1.ColumnSelections<GameMatchPresenceLeaseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.update<GameMatchPresenceLease>(
      rows,
      columns: columns?.call(GameMatchPresenceLease.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatchPresenceLease]. The row needs to have its id set.
  /// Optionally, a list of [columns] can be provided to only update those
  /// columns. Defaults to all columns.
  Future<GameMatchPresenceLease> updateRow(
    _i1.DatabaseSession session,
    GameMatchPresenceLease row, {
    _i1.ColumnSelections<GameMatchPresenceLeaseTable>? columns,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateRow<GameMatchPresenceLease>(
      row,
      columns: columns?.call(GameMatchPresenceLease.t),
      transaction: transaction,
    );
  }

  /// Updates a single [GameMatchPresenceLease] by its [id] with the specified [columnValues].
  /// Returns the updated row or null if no row with the given id exists.
  Future<GameMatchPresenceLease?> updateById(
    _i1.DatabaseSession session,
    int id, {
    required _i1.ColumnValueListBuilder<GameMatchPresenceLeaseUpdateTable>
    columnValues,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateById<GameMatchPresenceLease>(
      id,
      columnValues: columnValues(GameMatchPresenceLease.t.updateTable),
      transaction: transaction,
    );
  }

  /// Updates all [GameMatchPresenceLease]s matching the [where] expression with the specified [columnValues].
  /// Returns the list of updated rows.
  Future<List<GameMatchPresenceLease>> updateWhere(
    _i1.DatabaseSession session, {
    required _i1.ColumnValueListBuilder<GameMatchPresenceLeaseUpdateTable>
    columnValues,
    required _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable> where,
    int? limit,
    int? offset,
    _i1.OrderByBuilder<GameMatchPresenceLeaseTable>? orderBy,
    _i1.OrderByListBuilder<GameMatchPresenceLeaseTable>? orderByList,
    bool orderDescending = false,
    _i1.Transaction? transaction,
  }) async {
    return session.db.updateWhere<GameMatchPresenceLease>(
      columnValues: columnValues(GameMatchPresenceLease.t.updateTable),
      where: where(GameMatchPresenceLease.t),
      limit: limit,
      offset: offset,
      orderBy: orderBy?.call(GameMatchPresenceLease.t),
      orderByList: orderByList?.call(GameMatchPresenceLease.t),
      orderDescending: orderDescending,
      transaction: transaction,
    );
  }

  /// Deletes all [GameMatchPresenceLease]s in the list and returns the deleted rows.
  /// This is an atomic operation, meaning that if one of the rows fail to
  /// be deleted, none of the rows will be deleted.
  Future<List<GameMatchPresenceLease>> delete(
    _i1.DatabaseSession session,
    List<GameMatchPresenceLease> rows, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.delete<GameMatchPresenceLease>(
      rows,
      transaction: transaction,
    );
  }

  /// Deletes a single [GameMatchPresenceLease].
  Future<GameMatchPresenceLease> deleteRow(
    _i1.DatabaseSession session,
    GameMatchPresenceLease row, {
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteRow<GameMatchPresenceLease>(
      row,
      transaction: transaction,
    );
  }

  /// Deletes all rows matching the [where] expression.
  Future<List<GameMatchPresenceLease>> deleteWhere(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable> where,
    _i1.Transaction? transaction,
  }) async {
    return session.db.deleteWhere<GameMatchPresenceLease>(
      where: where(GameMatchPresenceLease.t),
      transaction: transaction,
    );
  }

  /// Counts the number of rows matching the [where] expression. If omitted,
  /// will return the count of all rows in the table.
  Future<int> count(
    _i1.DatabaseSession session, {
    _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable>? where,
    int? limit,
    _i1.Transaction? transaction,
  }) async {
    return session.db.count<GameMatchPresenceLease>(
      where: where?.call(GameMatchPresenceLease.t),
      limit: limit,
      transaction: transaction,
    );
  }

  /// Acquires row-level locks on [GameMatchPresenceLease] rows matching the [where] expression.
  Future<void> lockRows(
    _i1.DatabaseSession session, {
    required _i1.WhereExpressionBuilder<GameMatchPresenceLeaseTable> where,
    required _i1.LockMode lockMode,
    required _i1.Transaction transaction,
    _i1.LockBehavior lockBehavior = _i1.LockBehavior.wait,
  }) async {
    return session.db.lockRows<GameMatchPresenceLease>(
      where: where(GameMatchPresenceLease.t),
      lockMode: lockMode,
      lockBehavior: lockBehavior,
      transaction: transaction,
    );
  }
}

class GameMatchPresenceLeaseAttachRowRepository {
  const GameMatchPresenceLeaseAttachRowRepository._();

  /// Creates a relation between the given [GameMatchPresenceLease] and [GameMatch]
  /// by setting the [GameMatchPresenceLease]'s foreign key `matchId` to refer to the [GameMatch].
  Future<void> match(
    _i1.DatabaseSession session,
    GameMatchPresenceLease gameMatchPresenceLease,
    _i2.GameMatch match, {
    _i1.Transaction? transaction,
  }) async {
    if (gameMatchPresenceLease.id == null) {
      throw ArgumentError.notNull('gameMatchPresenceLease.id');
    }
    if (match.id == null) {
      throw ArgumentError.notNull('match.id');
    }

    var $gameMatchPresenceLease = gameMatchPresenceLease.copyWith(
      matchId: match.id,
    );
    await session.db.updateRow<GameMatchPresenceLease>(
      $gameMatchPresenceLease,
      columns: [GameMatchPresenceLease.t.matchId],
      transaction: transaction,
    );
  }
}
