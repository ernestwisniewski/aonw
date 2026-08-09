import 'dart:async';

import 'package:aonw/game/presentation/providers/game/game_state_provider.dart';
import 'package:aonw/game/presentation/providers/multiplayer/multiplayer_connection_status_provider.dart';
import 'package:aonw/game/presentation/providers/session/repository_providers.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/shared/widgets/game_ui/game_toast.dart';
import 'package:aonw_core/application.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Owns the presentation transition out of an authoritatively abandoned game.
final class GameAbandonedMatchBoundary extends ConsumerStatefulWidget {
  const GameAbandonedMatchBoundary({
    required this.selection,
    required this.saveId,
    required this.child,
    super.key,
  });

  final MapSelection selection;
  final String saveId;
  final Widget child;

  @override
  ConsumerState<GameAbandonedMatchBoundary> createState() =>
      _GameAbandonedMatchBoundaryState();
}

final class _GameAbandonedMatchBoundaryState
    extends ConsumerState<GameAbandonedMatchBoundary> {
  bool _handlingAbandonment = false;

  @override
  Widget build(BuildContext context) {
    final sessionMatchId = ref.watch(
      networkSessionProvider.select((session) => session?.matchId),
    );
    if (widget.saveId.isNotEmpty && sessionMatchId == widget.saveId) {
      final matchState = ref.watch(
        multiplayerMatchProvider.select(
          (matches) => matches[widget.saveId]?.state,
        ),
      );
      if (matchState != null &&
          const MatchLifecycleWireAdapter().decodeObservedState(matchState)
              is AbandonedObservedMatchLifecycleState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) unawaited(_leaveAbandonedMatch());
        });
      }
    }
    return widget.child;
  }

  Future<void> _leaveAbandonedMatch() async {
    if (_handlingAbandonment) return;
    _handlingAbandonment = true;
    final saveId = widget.saveId;
    final session = ref.read(networkSessionProvider);
    await ref.read(gameStateProvider(saveId).notifier).closeLiveEvents();
    if (session?.matchId == saveId) {
      await ref
          .read(networkSessionStateProvider.notifier)
          .clearMatch(
            expectedUserId: session!.userId,
            changedAt: ref.read(gameClockProvider).nowUtc(),
          );
    }
    if (!mounted) return;
    ref.read(multiplayerMatchProvider.notifier).clear(saveId);
    GameToast.show(
      context,
      message: context.l10n.multiplayerMatchUnavailable,
      tone: GameToastTone.error,
    );
    context.go(_multiplayerLobbyLocation());
  }

  String _multiplayerLobbyLocation() {
    return Uri(
      path: '/lobby',
      queryParameters: {
        'name': widget.selection.name,
        'source': widget.selection.source.name,
        'mode': 'multiplayer',
      },
    ).toString();
  }
}
