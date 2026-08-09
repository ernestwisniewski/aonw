import 'package:aonw/app/app_release_info.dart';
import 'package:aonw/game/application/ports/network_session.dart';
import 'package:aonw/game/application/services/multiplayer_save_origin.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/game/presentation/providers/session/session_providers.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _appUpdateCheckTimeout = Duration(seconds: 3);

@immutable
class MultiplayerUpdateNotice {
  const MultiplayerUpdateNotice();
}

enum MultiplayerAccessState { pending, allowed, updateRequired, unavailable }

typedef MultiplayerSaveAccessDecision = ({
  MultiplayerAccessState state,
  bool networkBacked,
});

typedef MultiplayerVersionStatusLoader =
    Future<String> Function({
      required String platform,
      required int buildNumber,
      required int multiplayerVersion,
    });

final multiplayerUpdateCheckEnabledProvider = Provider<bool>(
  (_) => _appUpdateCheckEnabled,
);

final multiplayerVersionStatusLoaderProvider =
    Provider<MultiplayerVersionStatusLoader>((ref) {
      final client = ref.watch(networkSessionClientProvider);
      return ({
        required String platform,
        required int buildNumber,
        required int multiplayerVersion,
      }) => client.versionStatus(
        platform: platform,
        buildNumber: buildNumber,
        multiplayerVersion: multiplayerVersion,
      );
    });

final multiplayerUpdateNoticeProvider =
    FutureProvider<MultiplayerUpdateNotice?>((ref) async {
      if (!ref.watch(multiplayerUpdateCheckEnabledProvider)) return null;

      final releaseInfo = await ref.watch(appReleaseInfoProvider.future);
      final status = await ref
          .watch(multiplayerVersionStatusLoaderProvider)(
            platform: resolveAppReleasePlatform(),
            buildNumber: releaseInfo.buildNumberValue,
            multiplayerVersion: kCurrentMultiplayerVersion,
          )
          .timeout(_appUpdateCheckTimeout);
      return multiplayerUpdateNoticeForStatus(status);
    });

/// Central client-side decision for entering multiplayer flows.
///
/// Release builds wait for the compatibility check and stay closed when the
/// server reports that this build needs an update. Server endpoint guards stay
/// authoritative for stale clients and direct requests.
final multiplayerAccessStateProvider = Provider<MultiplayerAccessState>((ref) {
  if (!ref.watch(multiplayerUpdateCheckEnabledProvider)) {
    return MultiplayerAccessState.allowed;
  }
  return switch (ref.watch(multiplayerUpdateNoticeProvider)) {
    AsyncData(:final value) =>
      value == null
          ? MultiplayerAccessState.allowed
          : MultiplayerAccessState.updateRequired,
    AsyncLoading() => MultiplayerAccessState.pending,
    AsyncError() => MultiplayerAccessState.unavailable,
  };
});

final multiplayerAccessAllowedProvider = Provider<bool>((ref) {
  return ref.watch(multiplayerAccessStateProvider) ==
      MultiplayerAccessState.allowed;
});

typedef MultiplayerCompatibilityRetry = void Function();

final multiplayerCompatibilityRetryProvider =
    Provider<MultiplayerCompatibilityRetry>((ref) {
      return () => ref.invalidate(multiplayerUpdateNoticeProvider);
    });

/// Resolves durable multiplayer identity from the full save. The active match
/// id short-circuits before any repository read, which keeps online deep links
/// fail-closed even while their cached snapshot is unavailable.
final networkBackedSaveProvider = FutureProvider.family<bool, String>((
  ref,
  saveId,
) async {
  if (saveId.isEmpty) return false;
  final networkSession = ref.watch(networkSessionProvider);
  if (networkSession?.matchId == saveId) return true;
  final save = await ref.watch(gameSaveProvider(saveId).future);
  if (save == null) return false;
  return isNetworkBackedGameSave(save: save, networkSession: networkSession);
});

final multiplayerSaveCompatibilityRetryProvider =
    Provider.family<MultiplayerCompatibilityRetry, String>((ref, saveId) {
      return () {
        ref.read(multiplayerCompatibilityRetryProvider)();
        ref.invalidate(networkBackedSaveProvider(saveId));
      };
    });

final multiplayerSaveAccessDecisionProvider =
    FutureProvider.family<MultiplayerSaveAccessDecision, String>((
      ref,
      saveId,
    ) async {
      final multiplayerAccess = ref.watch(multiplayerAccessStateProvider);
      final networkBacked = await ref.watch(
        networkBackedSaveProvider(saveId).future,
      );
      if (!networkBacked) {
        return (state: MultiplayerAccessState.allowed, networkBacked: false);
      }

      // Read after the asynchronous origin lookup so a session that changed
      // while the save was loading cannot authorize a stale network route.
      final session = ref.read(networkSessionProvider);
      return (
        state: canUseNetworkMatchTransport(session: session, saveId: saveId)
            ? multiplayerAccess
            : MultiplayerAccessState.unavailable,
        networkBacked: true,
      );
    });

final multiplayerSaveAccessStateProvider =
    FutureProvider.family<MultiplayerAccessState, String>((ref, saveId) async {
      final decision = await ref.watch(
        multiplayerSaveAccessDecisionProvider(saveId).future,
      );
      return decision.state;
    });

MultiplayerAccessState multiplayerSaveAccessOrFailClosed(
  AsyncValue<MultiplayerAccessState> access,
) {
  return switch (access) {
    AsyncData(:final value) => value,
    AsyncLoading() => MultiplayerAccessState.pending,
    AsyncError() => MultiplayerAccessState.unavailable,
  };
}

MultiplayerAccessState multiplayerSaveRouteAccessOrFailClosed(
  AsyncValue<MultiplayerSaveAccessDecision> decision,
) {
  if (decision.isLoading && !decision.hasError && decision.hasValue) {
    final previous = decision.requireValue;
    if (!previous.networkBacked) return previous.state;
  }
  return switch (decision) {
    AsyncData(:final value) => value.state,
    AsyncLoading() => MultiplayerAccessState.pending,
    AsyncError() => MultiplayerAccessState.unavailable,
  };
}

bool networkBackedSaveOrFalse(AsyncValue<bool> origin) {
  return switch (origin) {
    AsyncData(:final value) => value,
    AsyncLoading() || AsyncError() => false,
  };
}

MultiplayerUpdateNotice? multiplayerUpdateNoticeForStatus(String status) {
  return switch (status) {
    'soon' => const MultiplayerUpdateNotice(),
    'current' => null,
    _ => throw StateError('Unsupported multiplayer status: $status'),
  };
}

bool get _appUpdateCheckEnabled {
  const hasOverride = bool.hasEnvironment('AONW_ENABLE_UPDATE_CHECK');
  const override = bool.fromEnvironment('AONW_ENABLE_UPDATE_CHECK');
  return hasOverride ? override : kReleaseMode;
}
