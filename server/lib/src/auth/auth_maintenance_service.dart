import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;
import 'package:serverpod_auth_idp_server/core.dart' as auth_idp;

import '../generated/protocol.dart';
import '../scheduling/background_task_support.dart';
import 'auth_rate_limit_constants.dart';

export 'auth_rate_limit_constants.dart' show aonwAuthRateLimitDomain;

/// How often the server removes authentication records that are no longer
/// useful.
const authMaintenanceInterval = Duration(hours: 6);

/// Maximum number of rows selected and deleted by one database operation.
const authMaintenanceBatchSize = 500;

/// Caps work per table and invocation so maintenance cannot monopolize a
/// server process after a long period of downtime.
const authMaintenanceMaxBatchesPerTable = 10;

/// Extra grace period after a JWT refresh token has expired.
const expiredRefreshTokenRetention = Duration(days: 7);

/// Grace period after a Steam authentication request has expired.
const expiredSteamAuthRequestRetention = Duration(days: 7);

/// Retention for rate-limit attempts. The longest live policy is one hour, so
/// seven days leaves a conservative operational buffer.
const expiredAuthRateLimitAttemptRetention = Duration(days: 7);

enum AuthMaintenanceTarget {
  refreshTokens,
  steamAuthRequests,
  rateLimitAttempts,
}

typedef AuthMaintenanceErrorKind = BackgroundTaskErrorKind;

final class AuthMaintenanceFailure {
  const AuthMaintenanceFailure({
    required this.target,
    required this.kind,
    required this.deletedBeforeFailure,
    required this.stackTrace,
  });

  final AuthMaintenanceTarget target;
  final BackgroundTaskErrorKind kind;
  final int deletedBeforeFailure;
  final StackTrace stackTrace;
}

final class AuthMaintenanceResult {
  const AuthMaintenanceResult({
    required this.deletedRefreshTokens,
    required this.deletedSteamAuthRequests,
    required this.deletedRateLimitAttempts,
    required this.failures,
    required this.backlogTargets,
  });

  final int deletedRefreshTokens;
  final int deletedSteamAuthRequests;
  final int deletedRateLimitAttempts;
  final List<AuthMaintenanceFailure> failures;
  final Set<AuthMaintenanceTarget> backlogTargets;

  int get totalDeleted =>
      deletedRefreshTokens +
      deletedSteamAuthRequests +
      deletedRateLimitAttempts;

  bool get backlogRemaining => backlogTargets.isNotEmpty;
}

abstract interface class AuthMaintenanceStore {
  Future<int> deleteExpiredRefreshTokens({
    required DateTime cutoff,
    required int limit,
  });

  Future<int> deleteExpiredSteamAuthRequests({
    required DateTime cutoff,
    required int limit,
  });

  Future<int> deleteExpiredRateLimitAttempts({
    required DateTime cutoff,
    required int limit,
  });
}

/// Removes old authentication records in small, bounded batches.
final class AuthMaintenanceService {
  const AuthMaintenanceService({
    this.batchSize = authMaintenanceBatchSize,
    this.maxBatchesPerTable = authMaintenanceMaxBatchesPerTable,
  }) : assert(batchSize > 0),
       assert(maxBatchesPerTable > 0);

  final int batchSize;
  final int maxBatchesPerTable;

  Future<AuthMaintenanceResult> run({
    required AuthMaintenanceStore store,
    required DateTime now,
    required Duration refreshTokenLifetime,
  }) async {
    if (refreshTokenLifetime.isNegative) {
      throw ArgumentError.value(
        refreshTokenLifetime,
        'refreshTokenLifetime',
        'must not be negative',
      );
    }

    final nowUtc = now.toUtc();
    final refreshTokens = await _deleteInBatches(
      (limit) => store.deleteExpiredRefreshTokens(
        cutoff: nowUtc
            .subtract(refreshTokenLifetime)
            .subtract(expiredRefreshTokenRetention),
        limit: limit,
      ),
    );
    final steamAuthRequests = await _deleteInBatches(
      (limit) => store.deleteExpiredSteamAuthRequests(
        cutoff: nowUtc.subtract(expiredSteamAuthRequestRetention),
        limit: limit,
      ),
    );
    final rateLimitAttempts = await _deleteInBatches(
      (limit) => store.deleteExpiredRateLimitAttempts(
        cutoff: nowUtc.subtract(expiredAuthRateLimitAttemptRetention),
        limit: limit,
      ),
    );
    final outcomes = <AuthMaintenanceTarget, _BatchDeletionResult>{
      AuthMaintenanceTarget.refreshTokens: refreshTokens,
      AuthMaintenanceTarget.steamAuthRequests: steamAuthRequests,
      AuthMaintenanceTarget.rateLimitAttempts: rateLimitAttempts,
    };
    final failures = <AuthMaintenanceFailure>[
      for (final MapEntry(key: target, value: outcome) in outcomes.entries)
        if (outcome.failureKind case final kind?)
          AuthMaintenanceFailure(
            target: target,
            kind: kind,
            deletedBeforeFailure: outcome.deleted,
            stackTrace: outcome.stackTrace!,
          ),
    ];
    final backlogTargets = <AuthMaintenanceTarget>{
      for (final MapEntry(key: target, value: outcome) in outcomes.entries)
        if (outcome.backlogRemaining) target,
    };

    return AuthMaintenanceResult(
      deletedRefreshTokens: refreshTokens.deleted,
      deletedSteamAuthRequests: steamAuthRequests.deleted,
      deletedRateLimitAttempts: rateLimitAttempts.deleted,
      failures: List.unmodifiable(failures),
      backlogTargets: Set.unmodifiable(backlogTargets),
    );
  }

  Future<_BatchDeletionResult> _deleteInBatches(
    Future<int> Function(int limit) deleteBatch,
  ) async {
    var totalDeleted = 0;
    for (var batch = 0; batch < maxBatchesPerTable; batch += 1) {
      try {
        final deleted = await deleteBatch(batchSize);
        if (deleted < 0 || deleted > batchSize) {
          throw StateError(
            'Auth maintenance store returned an invalid batch size.',
          );
        }
        totalDeleted += deleted;
        if (deleted < batchSize) {
          return _BatchDeletionResult.completed(totalDeleted);
        }
      } catch (error, stackTrace) {
        return _BatchDeletionResult.failed(
          deleted: totalDeleted,
          failureKind: authMaintenanceErrorKind(error),
          stackTrace: stackTrace,
        );
      }
    }
    return _BatchDeletionResult.backlogged(totalDeleted);
  }
}

final class _BatchDeletionResult {
  const _BatchDeletionResult._({
    required this.deleted,
    required this.backlogRemaining,
    this.failureKind,
    this.stackTrace,
  });

  factory _BatchDeletionResult.completed(int deleted) =>
      _BatchDeletionResult._(deleted: deleted, backlogRemaining: false);

  factory _BatchDeletionResult.backlogged(int deleted) =>
      _BatchDeletionResult._(deleted: deleted, backlogRemaining: true);

  factory _BatchDeletionResult.failed({
    required int deleted,
    required AuthMaintenanceErrorKind failureKind,
    required StackTrace stackTrace,
  }) => _BatchDeletionResult._(
    deleted: deleted,
    backlogRemaining: false,
    failureKind: failureKind,
    stackTrace: stackTrace,
  );

  final int deleted;
  final bool backlogRemaining;
  final BackgroundTaskErrorKind? failureKind;
  final StackTrace? stackTrace;
}

BackgroundTaskErrorKind authMaintenanceErrorKind(Object error) =>
    backgroundTaskErrorKind(error);

/// Serverpod-backed maintenance store. Candidate IDs are selected first and
/// the expiry predicate is checked again during deletion. This bounds returned
/// rows and prevents refresh-token rotation racing with maintenance from
/// deleting a newly refreshed token.
final class ServerpodAuthMaintenanceStore implements AuthMaintenanceStore {
  ServerpodAuthMaintenanceStore(this._session);

  final Session _session;

  @override
  Future<int> deleteExpiredRefreshTokens({
    required DateTime cutoff,
    required int limit,
  }) async {
    final candidates = await auth_core.RefreshToken.db.find(
      _session,
      where: (table) => table.lastUpdatedAt < cutoff,
      orderBy: (table) => table.lastUpdatedAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await auth_core.RefreshToken.db.deleteWhere(
      _session,
      where: (table) => table.id.inSet(ids) & (table.lastUpdatedAt < cutoff),
    );
    return deleted.length;
  }

  @override
  Future<int> deleteExpiredSteamAuthRequests({
    required DateTime cutoff,
    required int limit,
  }) async {
    final candidates = await SteamAuthRequest.db.find(
      _session,
      where: (table) => table.expiresAt < cutoff,
      orderBy: (table) => table.expiresAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await SteamAuthRequest.db.deleteWhere(
      _session,
      where: (table) => table.id.inSet(ids) & (table.expiresAt < cutoff),
    );
    return deleted.length;
  }

  @override
  Future<int> deleteExpiredRateLimitAttempts({
    required DateTime cutoff,
    required int limit,
  }) async {
    // Serverpod verifies module-owned table indexes exactly against the module
    // protocol. A downstream (domain, attemptedAt) index would make startup
    // integrity checks fail. Returned/deleted work remains batch-capped, and
    // the coordinator schedules one-minute follow-ups when the cap is reached.
    final candidates = await auth_idp.RateLimitedRequestAttempt.db.find(
      _session,
      where: (table) =>
          table.domain.equals(aonwAuthRateLimitDomain) &
          (table.attemptedAt < cutoff),
      orderBy: (table) => table.attemptedAt,
      limit: limit,
    );
    final ids = _requiredIds(candidates.map((row) => row.id));
    if (ids.isEmpty) return 0;

    final deleted = await auth_idp.RateLimitedRequestAttempt.db.deleteWhere(
      _session,
      where: (table) =>
          table.id.inSet(ids) &
          table.domain.equals(aonwAuthRateLimitDomain) &
          (table.attemptedAt < cutoff),
    );
    return deleted.length;
  }
}

Set<UuidValue> _requiredIds(Iterable<UuidValue?> values) {
  final ids = <UuidValue>{};
  for (final value in values) {
    if (value == null) {
      throw StateError('A persisted auth maintenance candidate has no ID.');
    }
    ids.add(value);
  }
  return ids;
}
