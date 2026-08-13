import 'package:aonw/game/domain/game_state.dart';
import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/diplomacy/diplomacy_section.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/theme/border_emphasis.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/theme/surface_elevation.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw_core/domain/world_map.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/diplomacy.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/trade.dart';
import 'package:aonw_core/map/domain/terrain_type.dart';
import 'package:flutter/material.dart';

part 'diplomacy_player_modal_resource_offers.dart';
part 'diplomacy_player_modal_resource_trade_editors.dart';
part 'diplomacy_player_modal_resource_trade_widgets.dart';

const int _resourceTradeGoldPerTurn = 2;
const int _resourceTradeDurationTurns = 8;

enum _ResourceTradeMode { gold, exchange }

class ResourceTradeSection extends StatefulWidget {
  const ResourceTradeSection({
    required this.l10n,
    required this.gameState,
    required this.mapData,
    required this.relation,
    required this.activePlayerId,
    required this.targetPlayerId,
    required this.onCommand,
    this.onResourceTradeCommand,
    super.key,
  });

  final AppLocalizations l10n;
  final GameClientState gameState;
  final WorldMap mapData;
  final DiplomaticRelation relation;
  final String activePlayerId;
  final String targetPlayerId;
  final Future<void> Function(DomainCommand command) onCommand;
  final Future<bool> Function(DomainCommand command)? onResourceTradeCommand;

  @override
  State<ResourceTradeSection> createState() => _ResourceTradeSectionState();
}

class _ResourceTradeSectionState extends State<ResourceTradeSection> {
  _ResourceTradeMode _mode = _ResourceTradeMode.gold;
  ResourceType? _importResource;
  ResourceType? _offeredResource;
  ResourceType? _requestedResource;
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final offers = _resourceTradeOffers(
      gameState: widget.gameState,
      mapData: widget.mapData,
      activePlayerId: widget.activePlayerId,
      targetPlayerId: widget.targetPlayerId,
    );
    final exchanges = _resourceExchangeOffers(
      gameState: widget.gameState,
      mapData: widget.mapData,
      activePlayerId: widget.activePlayerId,
      targetPlayerId: widget.targetPlayerId,
    );
    final blockedByWar = widget.relation.status == DiplomaticRelationStatus.war;
    final mode = _effectiveMode(offers, exchanges);
    return DiplomacySection(
      title: widget.l10n.diplomacyStrategicResourcesTitle,
      child: _ResourceTradeBody(
        l10n: widget.l10n,
        blockedByWar: blockedByWar,
        hasOffers: offers.isNotEmpty || exchanges.isNotEmpty,
        showModePicker: offers.isNotEmpty && exchanges.isNotEmpty,
        mode: mode,
        onModeChanged: (value) => setState(() => _mode = value),
        editor: mode == _ResourceTradeMode.gold
            ? _goldEditor(offers, blockedByWar)
            : _exchangeEditor(exchanges, blockedByWar),
        summary: _ResourceTradeSummary(
          l10n: widget.l10n,
          gameState: widget.gameState,
          activePlayerId: widget.activePlayerId,
          targetPlayerId: widget.targetPlayerId,
        ),
      ),
    );
  }

  _ResourceTradeMode _effectiveMode(
    List<_ResourceTradeOffer> offers,
    List<_ResourceExchangeOffer> exchanges,
  ) {
    if (_mode == _ResourceTradeMode.gold && offers.isNotEmpty) return _mode;
    if (_mode == _ResourceTradeMode.exchange && exchanges.isNotEmpty) {
      return _mode;
    }
    return offers.isNotEmpty
        ? _ResourceTradeMode.gold
        : _ResourceTradeMode.exchange;
  }

  Widget _goldEditor(List<_ResourceTradeOffer> offers, bool blockedByWar) =>
      _GoldResourceTradeEditor(
        l10n: widget.l10n,
        gameState: widget.gameState,
        activePlayerId: widget.activePlayerId,
        targetPlayerId: widget.targetPlayerId,
        offers: offers,
        selectedResource: _importResource,
        enabled: !_submitting && !blockedByWar,
        onSelected: (resource) => setState(() => _importResource = resource),
        onSubmit: _submit,
      );

  Widget _exchangeEditor(
    List<_ResourceExchangeOffer> offers,
    bool blockedByWar,
  ) => _ExchangeResourceTradeEditor(
    l10n: widget.l10n,
    activePlayerId: widget.activePlayerId,
    targetPlayerId: widget.targetPlayerId,
    offers: offers,
    selectedOfferedResource: _offeredResource,
    selectedRequestedResource: _requestedResource,
    enabled: !_submitting && !blockedByWar,
    onOfferedSelected: (resource) => setState(() {
      _offeredResource = resource;
      _requestedResource = null;
    }),
    onRequestedSelected: (resource) =>
        setState(() => _requestedResource = resource),
    onSubmit: _submit,
  );

  Future<void> _submit(DomainCommand command) async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      final request = widget.onResourceTradeCommand;
      var accepted = true;
      if (request == null) {
        await widget.onCommand(command);
      } else {
        accepted = await request(command);
      }
      if (!accepted && mounted) {
        _showMessage(widget.l10n.diplomacyResourceTradeRequestRejected);
      }
    } catch (_) {
      if (mounted) {
        _showMessage(widget.l10n.diplomacyResourceTradeRequestFailed);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
