import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/manual_control_catalog.dart';
import 'package:aonw/menu/manual_widgets.dart';
import 'package:flutter/material.dart';

class ManualContent extends StatelessWidget {
  const ManualContent({
    required this.l10n,
    required this.mobileFirst,
    super.key,
  });

  final AppLocalizations l10n;
  final bool mobileFirst;

  @override
  Widget build(BuildContext context) {
    final sections = mobileFirst
        ? [
            _mobileControls(),
            _commandLoop(),
            _gamepadControls(),
            _desktopControls(),
          ]
        : [
            _commandLoop(),
            _mobileControls(),
            _gamepadControls(),
            _desktopControls(),
          ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(height: 22),
          ...sections[i],
        ],
      ],
    );
  }

  List<Widget> _commandLoop() => [
    ManualSectionLead(
      key: const Key('manual.commandLoopSection'),
      icon: Icons.keyboard_double_arrow_right,
      title: l10n.manualCommandLoopTitle,
    ),
    const SizedBox(height: 10),
    ManualLoopGrid(items: ManualControlCatalog.commandLoop(l10n)),
  ];

  List<Widget> _mobileControls() => [
    ManualSectionLead(
      key: const Key('manual.mobileSection'),
      icon: Icons.touch_app_outlined,
      title: l10n.manualMobileTitle,
      subtitle: l10n.manualMobileSubtitle,
    ),
    const SizedBox(height: 10),
    ManualControlGrid(groups: ManualControlCatalog.mobile(l10n)),
  ];

  List<Widget> _gamepadControls() => [
    ManualSectionLead(
      key: const Key('manual.gamepadSection'),
      icon: Icons.sports_esports_outlined,
      title: l10n.manualGamepadTitle,
      subtitle: l10n.manualGamepadSubtitle,
    ),
    const SizedBox(height: 10),
    ManualControlGrid(groups: ManualControlCatalog.gamepad(l10n)),
  ];

  List<Widget> _desktopControls() => [
    ManualSectionLead(
      key: const Key('manual.desktopSection'),
      icon: Icons.mouse_outlined,
      title: l10n.manualDesktopTitle,
      subtitle: l10n.manualDesktopSubtitle,
    ),
    const SizedBox(height: 10),
    ManualControlGrid(groups: ManualControlCatalog.desktop(l10n)),
  ];
}
