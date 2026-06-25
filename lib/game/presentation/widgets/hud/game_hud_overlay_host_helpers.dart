part of 'game_hud_overlay_host.dart';

extension _GameHudOverlayHostHelpers on _GameHudOverlayHostState {
  HudOverlayHostActions get _actions {
    return HudOverlayHostActions(
      ref: ref,
      session: widget.session,
      gameSave: widget.gameSave,
      animatingUnitIdsListenable: widget.animatingUnitIdsListenable,
    );
  }

  void _syncModesWithState(GameState? gameState) {
    ref.read(hudPanelControllerProvider.notifier).syncWithGameState(gameState);
  }

  void _closeSelectionDetailAfterBuild() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(openSelectionDetailControllerProvider.notifier).close();
    });
  }

  void _closeSelectionDetail(String? chipId) {
    ref.read(openSelectionDetailControllerProvider.notifier).close();
  }

  void _minimizeModeBanner(String popupId, HudModeBannerSpec spec) {
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          HudMinimizedPopupEntry(
            id: popupId,
            kind: HudMinimizedPopupKind.modeBanner,
            title: spec.title,
            subtitle: spec.instruction,
            payload: {
              for (var i = 0; i < spec.details.length; i++)
                'detail.$i': spec.details[i],
            },
          ),
        );
    if (_restoredModeBannerEntry?.id == popupId) {
      _setRestoredModeBannerEntry(null);
    }
  }

  void _minimizeAutoTurnHint(String popupId) {
    final l10n = AppLocalizations.of(context);
    ref
        .read(hudMinimizedPopupsProvider.notifier)
        .minimize(
          HudMinimizedPopupEntry(
            id: popupId,
            kind: HudMinimizedPopupKind.autoTurnHint,
            title: l10n.autoTurnHintTitle,
            subtitle: l10n.autoTurnHintMinimizedSubtitle,
          ),
        );
    if (_autoTurnHintRestored) _setAutoTurnHintRestored(false);
  }

  void _syncTransientModeHelp(HudOverlayFrame frame) {
    final entry = _modeBannerHelpEntry(frame.resolvedModeBannerSpec);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(hudMinimizedPopupsProvider.notifier)
          .setTransientEntries(
            _transientModeHelpScope(widget.gameSave.id),
            entry == null ? const [] : [entry],
          );
    });
  }

  String _transientModeHelpScope(String saveId) {
    return 'game.$saveId.activeModeHelp';
  }

  HudMinimizedPopupEntry? _modeBannerHelpEntry(HudModeBannerSpec? spec) {
    if (spec == null) return null;
    return HudMinimizedPopupEntry(
      id: HudMinimizedPopupIds.modeBanner(widget.gameSave.id, spec.id),
      kind: HudMinimizedPopupKind.modeBanner,
      title: spec.title,
      subtitle: spec.instruction,
      payload: {
        if (spec.primaryAction != null) 'hasPrimaryAction': 'true',
        for (var i = 0; i < spec.details.length; i++)
          'detail.$i': spec.details[i],
      },
    );
  }

  void _listenForMinimizedPopupRestoreRequests({
    required String? modeBannerPopupId,
    required String autoTurnHintPopupId,
  }) {
    ref.listen<HudMinimizedPopupsState>(hudMinimizedPopupsProvider, (
      previous,
      next,
    ) {
      final request = next.restoreRequest;
      if (request == null ||
          request.sequence == previous?.restoreRequest?.sequence) {
        return;
      }
      final entry = next.entryFor(request.popupId) ?? request.entry;
      if (entry == null || !entry.belongsToSave(widget.gameSave.id)) {
        return;
      }
      if (entry.kind == HudMinimizedPopupKind.autoTurnHint &&
          entry.id == autoTurnHintPopupId) {
        ref
            .read(hudMinimizedPopupsProvider.notifier)
            .removeWhere((candidate) => candidate.id == entry.id);
        _setAutoTurnHintRestored(true);
        return;
      }
      if (entry.kind != HudMinimizedPopupKind.modeBanner) {
        return;
      }
      _setRestoredModeBannerEntry(entry);
      if (entry.id == modeBannerPopupId) {
        ref
            .read(hudMinimizedPopupsProvider.notifier)
            .removeWhere((candidate) => candidate.id == entry.id);
      }
    });
  }

  HudModeBannerSpec? _restoredModeBannerSpec() {
    final entry = _restoredModeBannerEntry;
    if (entry == null ||
        !entry.belongsToSave(widget.gameSave.id) ||
        entry.kind != HudMinimizedPopupKind.modeBanner) {
      return null;
    }
    final specId = _modeBannerSpecIdFromPopupId(entry.id);
    final accent = _modeBannerAccentFor(specId);
    return HudModeBannerSpec(
      id: specId,
      icon: _modeBannerIconFor(specId),
      accent: accent,
      title: entry.title,
      instruction: entry.subtitle,
      details: _modeBannerDetailsFromPayload(entry.payload),
      primaryAction: entry.payload['hasPrimaryAction'] == 'true'
          ? HudModeBannerActionSpec(
              icon: _modeBannerIconFor(specId),
              label: entry.title,
              accent: accent,
            )
          : null,
    );
  }

  String _modeBannerSpecIdFromPopupId(String popupId) {
    const marker = '.modeBanner.';
    final markerIndex = popupId.indexOf(marker);
    if (markerIndex == -1) return popupId;
    return popupId.substring(markerIndex + marker.length);
  }

  GameIconData _modeBannerIconFor(String specId) {
    switch (specId) {
      case 'attackTargeting':
        return GameIcons.attack;
      case 'cityWorkedHexSelection':
      case HudModeBannerSpec.cityExpansionSelectionId:
        return GameIcons.workedHexes;
      case 'workerAction':
      case HudModeBannerSpec.selectedWorkerActionId:
      case HudModeBannerSpec.selectedWorkerMoveToWorkId:
        return GameIcons.production;
      case 'merchantTradeRoute':
        return GameIcons.commerce;
      case 'merchantMoveToCity':
        return GameIcons.city;
      case 'researchSelection':
        return GameIcons.science;
      case 'unitTurnSkip':
        return GameIcons.skipTurn;
      case 'commanderMerge':
        return GameIcons.army;
      case HudModeBannerSpec.moveTargetingId:
        return GameIcons.move;
      case HudModeBannerSpec.selectedScoutExploreId:
        return GameIcons.visibility;
      case HudModeBannerSpec.selectedSettlerCityFoundingId:
      case HudModeBannerSpec.selectedSettlerMoveToCitySiteId:
        return GameIcons.foundCity;
      default:
        return GameIcons.help;
    }
  }

  Color _modeBannerAccentFor(String specId) {
    switch (specId) {
      case 'attackTargeting':
        return GameUiTheme.danger;
      case HudModeBannerSpec.selectedWorkerActionId:
      case HudModeBannerSpec.selectedSettlerCityFoundingId:
        return GameUiTheme.success;
      case HudModeBannerSpec.selectedWorkerMoveToWorkId:
      case HudModeBannerSpec.selectedSettlerMoveToCitySiteId:
        return GameUiTheme.warning;
      case HudModeBannerSpec.selectedScoutExploreId:
        return GameUiTheme.info;
      default:
        return GameUiTheme.gold;
    }
  }

  List<String> _modeBannerDetailsFromPayload(Map<String, String> payload) {
    final details = <String>[];
    for (var i = 0; ; i++) {
      final detail = payload['detail.$i'];
      if (detail == null) break;
      details.add(detail);
    }
    return details;
  }
}
