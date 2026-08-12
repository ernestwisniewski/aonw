import 'package:aonw/game/presentation/formatters/game_display_names.dart';
import 'package:aonw/game/presentation/widgets/theme/game_icon.dart';
import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal.dart';
import 'package:aonw/shared/widgets/game_ui/game_modal_scaffold.dart';
import 'package:aonw_core/game/domain/resource.dart';
import 'package:aonw_core/game/domain/unit.dart';
import 'package:flutter/material.dart';

Future<int?> showCityProductionResourceOptionModal({
  required BuildContext context,
  required UnitStrategicResourceAvailability availability,
}) {
  final l10n = AppLocalizations.of(context);
  final available = availability.onHand.credit(availability.refundable);
  return showGameModal<int>(
    context: context,
    size: GameModalSize.compact,
    builder: (dialogContext) => GameModalScaffold(
      size: GameModalSize.compact,
      header: GameModalHeader(
        title: l10n.cityProductionResourceOptionTitle,
        onClose: () => Navigator.of(dialogContext).pop(),
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (index, option) in availability.options.indexed)
            _StrategicResourceOptionTile(
              selected: index == availability.selectedOptionIndex,
              enabled: available.covers(option),
              title: _bundleLabel(l10n, option),
              subtitle: option.amounts.entries
                  .map(
                    (entry) => l10n.cityProductionStrategicAvailable(
                      available.amountFor(entry.key),
                      entry.value,
                      GameDisplayNames.resource(l10n, entry.key),
                    ),
                  )
                  .join(' · '),
              onTap: () => Navigator.of(dialogContext).pop(index),
            ),
        ],
      ),
      actions: [
        GameModalAction(
          label: l10n.cancelAction,
          variant: EpicButtonVariant.text,
          onPressed: () => Navigator.of(dialogContext).pop(),
        ),
      ],
    ),
  );
}

Future<bool> showCityProductionChangeConfirmationModal({
  required BuildContext context,
  required StrategicResourceStockpile stockpile,
  required StrategicResourceBundle currentAllocation,
  required StrategicResourceBundle nextAllocation,
}) async {
  final l10n = AppLocalizations.of(context);
  final freeAfter = stockpile.credit(currentAllocation).debit(nextAllocation);
  final result = await showGameModal<bool>(
    context: context,
    size: GameModalSize.compact,
    builder: (dialogContext) => GameModalScaffold(
      size: GameModalSize.compact,
      header: GameModalHeader(
        title: l10n.cityProductionChangeTitle,
        onClose: () => Navigator.of(dialogContext).pop(false),
      ),
      content: _ProductionAllocationDelta(
        currentAllocation: currentAllocation,
        nextAllocation: nextAllocation,
        freeAfter: freeAfter,
      ),
      actions: [
        GameModalAction(
          label: l10n.cancelAction,
          variant: EpicButtonVariant.text,
          onPressed: () => Navigator.of(dialogContext).pop(false),
        ),
        GameModalAction(
          label: l10n.cityProductionChangeAction,
          variant: EpicButtonVariant.primary,
          onPressed: () => Navigator.of(dialogContext).pop(true),
        ),
      ],
    ),
  );
  return result ?? false;
}

class _StrategicResourceOptionTile extends StatelessWidget {
  const _StrategicResourceOptionTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    enabled: enabled,
    leading: GameIcon(
      selected ? GameIcons.checkCircle : GameIcons.resources,
      size: 22,
      color: selected
          ? Theme.of(context).colorScheme.primary
          : Theme.of(context).colorScheme.onSurfaceVariant,
    ),
    title: Text(title),
    subtitle: Text(subtitle),
    onTap: enabled ? onTap : null,
  );
}

class _ProductionAllocationDelta extends StatelessWidget {
  const _ProductionAllocationDelta({
    required this.currentAllocation,
    required this.nextAllocation,
    required this.freeAfter,
  });

  final StrategicResourceBundle currentAllocation;
  final StrategicResourceBundle nextAllocation;
  final StrategicResourceStockpile freeAfter;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.cityProductionChangeWarning),
        if (!currentAllocation.isEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.cityProductionChangeRelease(
              _bundleLabel(l10n, currentAllocation),
            ),
          ),
        ],
        if (!nextAllocation.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.cityProductionChangeAllocate(
              _bundleLabel(l10n, nextAllocation),
            ),
          ),
        ],
        if (!currentAllocation.isEmpty || !nextAllocation.isEmpty) ...[
          const SizedBox(height: 6),
          Text(
            l10n.cityProductionChangeFreeAfter(
              ResourceCatalog.stockpiledResources
                  .map(
                    (resource) =>
                        '${freeAfter.amountFor(resource)} ${GameDisplayNames.resource(l10n, resource)}',
                  )
                  .join(' · '),
            ),
          ),
        ],
      ],
    );
  }
}

String _bundleLabel(AppLocalizations l10n, StrategicResourceBundle bundle) =>
    bundle.amounts.entries
        .map(
          (entry) =>
              '${entry.value} ${GameDisplayNames.resource(l10n, entry.key)}',
        )
        .join(' + ');
