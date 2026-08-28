import 'package:flutter/material.dart';

import '../../../design_system/aonw_tokens.dart';
import '../../../design_system/widgets/aonw_progress_indicator.dart';
import '../../../l10n/l10n.dart';
import '../application/action_deck_state.dart';
import '../read_model/unit_action_view.dart';
import 'unit_action_failure_messages.dart';

final class UnitActionDeck extends StatelessWidget {
  const UnitActionDeck({
    required this.state,
    required this.onAction,
    this.enabled = true,
    super.key,
  });

  final ActionDeckViewState state;
  final ValueChanged<UnitActionKindView> onAction;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.aonwL10n;
    final acceptsInput = enabled && !state.commandPending;
    return FocusTraversalGroup(
      policy: OrderedTraversalPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AonwSpacing.sm),
          Text(
            l10n.unitActionLabel('title'),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: AonwSpacing.xs),
          Wrap(
            spacing: AonwSpacing.xs,
            runSpacing: AonwSpacing.xs,
            children: _actionButtons(l10n, acceptsInput, onAction),
          ),
          if (state.commandPending) ...[
            const SizedBox(height: AonwSpacing.sm),
            AonwProgressIndicator(
              semanticLabel: l10n.unitActionLabel('executing'),
              compact: true,
            ),
          ],
          if (state.failure case final failure?) ...[
            const SizedBox(height: AonwSpacing.sm),
            Text(
              unitActionFailureMessage(l10n, failure),
              key: const ValueKey('unit-action-error'),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ],
        ],
      ),
    );
  }
}

List<Widget> _actionButtons(
  AonwLocalizations l10n,
  bool enabled,
  ValueChanged<UnitActionKindView> onAction,
) => [
  _ActionButton(
    order: 1,
    action: UnitActionKindView.fortify,
    label: l10n.unitActionLabel('fortify'),
    icon: Icons.shield_outlined,
    enabled: enabled,
    onAction: onAction,
  ),
  _ActionButton(
    order: 2,
    action: UnitActionKindView.skip,
    label: l10n.unitActionLabel('skip'),
    icon: Icons.skip_next,
    enabled: enabled,
    onAction: onAction,
  ),
  _ActionButton(
    order: 3,
    action: UnitActionKindView.cancel,
    label: l10n.unitActionLabel('cancel'),
    icon: Icons.cancel_outlined,
    enabled: enabled,
    onAction: onAction,
  ),
];

final class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.order,
    required this.action,
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onAction,
  });

  final double order;
  final UnitActionKindView action;
  final String label;
  final IconData icon;
  final bool enabled;
  final ValueChanged<UnitActionKindView> onAction;

  @override
  Widget build(BuildContext context) => FocusTraversalOrder(
    order: NumericFocusOrder(order),
    child: OutlinedButton.icon(
      key: ValueKey(('unit-action', action.name)),
      onPressed: enabled ? () => onAction(action) : null,
      icon: Icon(icon),
      label: Text(label),
    ),
  );
}
