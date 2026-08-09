import 'package:aonw/game/presentation/screens/new_game/new_game_flow.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_review_card.dart';
import 'package:aonw/game/presentation/screens/new_game/new_game_setup_options.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/l10n/l10n.dart';
import 'package:aonw/menu/menu_route_shell.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_screen_header.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/map_validation.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/map/domain/map_selection.dart';
import 'package:flutter/material.dart';

Widget buildNewGameReviewStep({
  Key? key,
  required NewGameFlow flow,
  required MapSelection? map,
  required PlayerCountry playerCountry,
  required SinglePlayerGameLengthPreset gameLengthPreset,
  required AiDifficulty aiDifficulty,
  required bool mapPickedManually,
  required int singlePlayerPlayerCount,
  required MapValidationResult? mapValidation,
  required bool mapValidationLoading,
  required Object? mapValidationError,
}) {
  return _ReviewStep(
    key: key,
    flow: flow,
    map: map,
    playerCountry: playerCountry,
    gameLengthPreset: gameLengthPreset,
    aiDifficulty: aiDifficulty,
    mapPickedManually: mapPickedManually,
    singlePlayerPlayerCount: singlePlayerPlayerCount,
    mapValidation: mapValidation,
    mapValidationLoading: mapValidationLoading,
    mapValidationError: mapValidationError,
  );
}

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.flow,
    required this.map,
    required this.playerCountry,
    required this.gameLengthPreset,
    required this.aiDifficulty,
    required this.mapPickedManually,
    required this.singlePlayerPlayerCount,
    required this.mapValidation,
    required this.mapValidationLoading,
    required this.mapValidationError,
    super.key,
  });

  final NewGameFlow flow;
  final MapSelection? map;
  final PlayerCountry playerCountry;
  final SinglePlayerGameLengthPreset gameLengthPreset;
  final AiDifficulty aiDifficulty;
  final bool mapPickedManually;
  final int singlePlayerPlayerCount;
  final MapValidationResult? mapValidation;
  final bool mapValidationLoading;
  final Object? mapValidationError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final map = this.map;
    return MenuRouteSection(
      icon: Icons.flag_outlined,
      title: l10n.newGameReviewTitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (map == null)
            GameUiEmptyState(
              icon: Icons.map_outlined,
              title: l10n.noMapsTitle,
              message: l10n.newGameReviewMissingMap,
            )
          else
            buildNewGameReviewCard(
              flow: flow,
              map: map,
              playerCountry: playerCountry,
              gameLengthPreset: gameLengthPreset,
              aiDifficulty: aiDifficulty,
              mapPickedManually: mapPickedManually,
              singlePlayerPlayerCount: singlePlayerPlayerCount,
            ),
          if (flow == NewGameFlow.singlePlayer) ...[
            const SizedBox(height: 12),
            _NewGameMapValidationNotice(
              result: mapValidation,
              loading: mapValidationLoading,
              loadError: mapValidationError,
            ),
          ],
        ],
      ),
    );
  }
}

class _NewGameMapValidationNotice extends StatelessWidget {
  const _NewGameMapValidationNotice({
    required this.result,
    required this.loading,
    required this.loadError,
  });

  final MapValidationResult? result;
  final bool loading;
  final Object? loadError;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final result = this.result;
    final issues = result == null
        ? const <MapValidationIssue>[]
        : [...result.errors, ...result.warnings];
    if (!loading && loadError == null && issues.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasErrors = loadError != null || result?.errors.isNotEmpty == true;
    final color = hasErrors ? GameUiTheme.danger : GameUiTheme.gold;
    final title = hasErrors
        ? l10n.mapValidationErrorTitle
        : loading
        ? l10n.mapValidationLoadingTitle
        : l10n.mapValidationWarningTitle;
    final messages = loadError != null
        ? [l10n.mapValidationLoadError('$loadError')]
        : loading
        ? [l10n.mapValidationLoadingMessage]
        : [for (final issue in issues.take(3)) _issueText(l10n, issue)];

    return DecoratedBox(
      key: const Key('newGame.mapValidationNotice'),
      decoration: BoxDecoration(
        color: color.withAlpha(24),
        borderRadius: GameUiTheme.borderRadius,
        border: Border.all(color: color.withAlpha(105)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 9, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasErrors ? Icons.error_outline : Icons.warning_amber_outlined,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GameUiTheme.bodyStrong.copyWith(color: color),
                  ),
                  const SizedBox(height: 4),
                  for (var i = 0; i < messages.length; i++) ...[
                    Text(
                      messages[i],
                      style: GameUiTheme.cardMeta.copyWith(
                        color: GameUiTheme.textSecondary,
                        height: 1.2,
                      ),
                    ),
                    if (i < messages.length - 1) const SizedBox(height: 3),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _issueText(AppLocalizations l10n, MapValidationIssue issue) {
    return switch (issue.code) {
      'short_game_slow_first_contact' =>
        l10n.mapValidationIssueSlowFirstContact,
      'short_game_large_map' => l10n.mapValidationIssueLargeMap,
      'invalid_player_count' => l10n.mapValidationIssueInvalidPlayerCount,
      'map_has_no_tiles' => l10n.mapValidationIssueNoTiles,
      'low_passable_tile_ratio' => l10n.mapValidationIssueLowPassableTileRatio,
      'low_food_resource_density' =>
        l10n.mapValidationIssueLowFoodResourceDensity,
      'low_strategic_resource_density' =>
        l10n.mapValidationIssueLowStrategicResourceDensity,
      'low_luxury_resource_density' =>
        l10n.mapValidationIssueLowLuxuryResourceDensity,
      'start_site_not_foundable' =>
        l10n.mapValidationIssueStartSiteNotFoundable,
      'start_site_low_land_ring' => l10n.mapValidationIssueStartSiteLowLandRing,
      'start_site_low_food' => l10n.mapValidationIssueStartSiteLowFood,
      'start_site_low_city_control' =>
        l10n.mapValidationIssueStartSiteLowCityControl,
      'start_sites_too_close' => l10n.mapValidationIssueStartSitesTooClose,
      _ => issue.message,
    };
  }
}
