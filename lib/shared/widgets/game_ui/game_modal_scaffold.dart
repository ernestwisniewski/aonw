import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:aonw/shared/widgets/game_ui/epic_button.dart';
import 'package:aonw/shared/widgets/game_ui/epic_card_surface.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_epic_header.dart';
import 'package:aonw/shared/widgets/game_ui/gold_divider.dart';
import 'package:flutter/material.dart';

enum GameModalSize { compact, regular, wide, adaptive }

enum GameModalShape { dialog, bottomSheet }

class GameModalHeader {
  const GameModalHeader({
    required this.title,
    this.subtitle,
    this.icon,
    this.onClose,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onClose;
}

class GameModalAction {
  const GameModalAction({
    required this.label,
    required this.onPressed,
    this.variant = EpicButtonVariant.outlined,
    this.key,
    this.icon,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final EpicButtonVariant variant;
  final Key? key;
  final IconData? icon;
  final EdgeInsetsGeometry? padding;
}

class GameModalScaffold extends StatelessWidget {
  const GameModalScaffold({
    required this.content,
    this.header,
    this.actions = const [],
    this.size = GameModalSize.adaptive,
    this.shape = GameModalShape.dialog,
    this.contentPadding = const EdgeInsets.all(16),
    this.scrollable = true,
    this.showCornerDiamonds = true,
    this.centerInAvailableSpace = true,
    this.surfaceKey,
    super.key,
  });

  final GameModalHeader? header;
  final Widget content;
  final List<GameModalAction> actions;
  final GameModalSize size;
  final GameModalShape shape;
  final EdgeInsetsGeometry contentPadding;
  final bool scrollable;
  final bool showCornerDiamonds;
  final bool centerInAvailableSpace;
  final Key? surfaceKey;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final resolvedSize = _resolvedSize(screenSize);
    final maxWidth = _maxWidth(resolvedSize, screenSize.width);
    final maxHeight =
        screenSize.height *
        switch (shape) {
          GameModalShape.dialog => 0.86,
          GameModalShape.bottomSheet => 0.9,
        };

    final modalFrame = Padding(
      padding: centerInAvailableSpace ? _outerPadding(shape) : EdgeInsets.zero,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth, maxHeight: maxHeight),
        child: EpicCardSurface(
          surfaceKey: surfaceKey,
          header: header == null ? null : _GameModalHeaderView(header!),
          onClose: header?.onClose,
          padding: EdgeInsets.zero,
          showCornerDiamonds:
              showCornerDiamonds && shape == GameModalShape.dialog,
          content: _GameModalBody(
            content: content,
            actions: actions,
            padding: contentPadding,
            scrollable: scrollable,
          ),
        ),
      ),
    );

    if (!centerInAvailableSpace) {
      if (shape == GameModalShape.bottomSheet) {
        return Align(alignment: Alignment.bottomCenter, child: modalFrame);
      }
      return modalFrame;
    }

    return Align(
      alignment: shape == GameModalShape.bottomSheet
          ? Alignment.bottomCenter
          : Alignment.center,
      child: modalFrame,
    );
  }

  GameModalSize _resolvedSize(Size screenSize) {
    if (size != GameModalSize.adaptive) return size;
    if (screenSize.width < 640) {
      return GameModalSize.compact;
    }
    return GameModalSize.regular;
  }

  double _maxWidth(GameModalSize size, double screenWidth) {
    return switch (size) {
      GameModalSize.compact => screenWidth,
      GameModalSize.regular => 680,
      GameModalSize.wide => 980,
      GameModalSize.adaptive => 680,
    };
  }

  EdgeInsets _outerPadding(GameModalShape shape) {
    return switch (shape) {
      GameModalShape.dialog => const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 20,
      ),
      GameModalShape.bottomSheet => const EdgeInsets.fromLTRB(10, 0, 10, 10),
    };
  }
}

class _GameModalHeaderView extends StatelessWidget {
  const _GameModalHeaderView(this.header);

  final GameModalHeader header;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GameUiEpicHeader(
                label: header.title,
                alignment: Alignment.centerLeft,
                compact: false,
                leading: header.icon == null
                    ? null
                    : Icon(header.icon, size: 18, color: GameUiTheme.goldLight),
              ),
              if (header.subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  header.subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GameUiTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _GameModalBody extends StatelessWidget {
  const _GameModalBody({
    required this.content,
    required this.actions,
    required this.padding,
    required this.scrollable,
  });

  final Widget content;
  final List<GameModalAction> actions;
  final EdgeInsetsGeometry padding;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final paddedContent = Padding(padding: padding, child: content);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: scrollable
              ? SingleChildScrollView(child: paddedContent)
              : paddedContent,
        ),
        if (actions.isNotEmpty) ...[
          const GoldDivider(),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
            child: Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final action in actions) _GameModalActionButton(action),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GameModalActionButton extends StatelessWidget {
  const _GameModalActionButton(this.action);

  final GameModalAction action;

  @override
  Widget build(BuildContext context) {
    return switch (action.variant) {
      EpicButtonVariant.primary => EpicButton.primary(
        key: action.key,
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        padding: action.padding,
      ),
      EpicButtonVariant.outlined => EpicButton.outlined(
        key: action.key,
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        padding: action.padding,
      ),
      EpicButtonVariant.text => EpicButton.text(
        key: action.key,
        onPressed: action.onPressed,
        label: action.label,
        icon: action.icon,
        padding: action.padding,
      ),
    };
  }
}
