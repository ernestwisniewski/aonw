part of 'main_menu_screen.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key, this.onExit, this.gamepadInputListenable});

  final Future<void> Function()? onExit;
  final ValueListenable<GamepadInputSnapshot>? gamepadInputListenable;

  @override
  Widget build(BuildContext context) {
    return MenuGamepadInputBinding(
      input: gamepadInputListenable,
      child: Scaffold(
        backgroundColor: GameUiTheme.bg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            const _MenuBackground(),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 700;
                  final panelWidth = compact
                      ? constraints.maxWidth
                      : constraints.maxWidth.clamp(340.0, 390.0).toDouble();
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: panelWidth,
                      child: _MenuPanel(
                        showBottomLinks: compact,
                        onExit: onExit,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Positioned(
              top: 12,
              right: 16,
              child: SafeArea(child: _VersionTag()),
            ),
            const Positioned(
              right: 18,
              bottom: 18,
              child: SafeArea(child: _RightInfoColumn()),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuBackground extends StatelessWidget {
  const _MenuBackground();

  @override
  Widget build(BuildContext context) {
    return MenuAnimatedBackground(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  GameUiTheme.bg,
                  Color(0xA80A0E14),
                  Color(0x1F0A0E14),
                  Color(0x000A0E14),
                ],
                stops: [0, 0.28, 0.48, 1],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(color: GameUiTheme.bg.withAlpha(34)),
          ),
        ],
      ),
    );
  }
}

class _MenuPanel extends ConsumerStatefulWidget {
  final bool showBottomLinks;
  final Future<void> Function()? onExit;

  const _MenuPanel({required this.showBottomLinks, this.onExit});

  @override
  ConsumerState<_MenuPanel> createState() => _MenuPanelState();
}
