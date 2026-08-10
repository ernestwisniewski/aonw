import 'package:aonw/l10n/generated/app_localizations.dart';
import 'package:aonw/menu/manual_models.dart';
import 'package:aonw/shared/theme/game_ui_theme.dart';
import 'package:flutter/material.dart';

abstract final class ManualControlCatalog {
  static List<ManualLoopItem> commandLoop(AppLocalizations l10n) => [
    ManualLoopItem(
      icon: Icons.ads_click,
      title: l10n.manualCommandLoopSelectTitle,
      body: l10n.manualCommandLoopSelectBody,
    ),
    ManualLoopItem(
      icon: Icons.visibility_outlined,
      title: l10n.manualCommandLoopPreviewTitle,
      body: l10n.manualCommandLoopPreviewBody,
    ),
    ManualLoopItem(
      icon: Icons.check_circle_outline,
      title: l10n.manualCommandLoopConfirmTitle,
      body: l10n.manualCommandLoopConfirmBody,
    ),
    ManualLoopItem(
      icon: Icons.play_arrow,
      title: l10n.manualCommandLoopAdvanceTitle,
      body: l10n.manualCommandLoopAdvanceBody,
    ),
  ];

  static List<ManualControlGroup> desktop(AppLocalizations l10n) => [
    _desktopMap(l10n),
    _desktopOrders(l10n),
    _desktopPanels(l10n),
    _desktopTurn(l10n),
  ];

  static List<ManualControlGroup> mobile(AppLocalizations l10n) => [
    _mobileMap(l10n),
    _mobileOrders(l10n),
    _mobilePanels(l10n),
    _mobileTurn(l10n),
  ];

  static List<ManualControlGroup> gamepad(AppLocalizations l10n) => [
    _gamepadMap(l10n),
    _gamepadOrders(l10n),
    _gamepadPanels(l10n),
    _gamepadTurn(l10n),
  ];

  static ManualControlGroup _desktopMap(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.map_outlined,
      title: l10n.manualMapCameraGroup,
      color: GameUiTheme.info,
      items: [
        ManualControlItem(
          icon: Icons.mouse_outlined,
          action: l10n.manualDesktopLeftClickAction,
          body: l10n.manualDesktopLeftClickBody,
        ),
        ManualControlItem(
          icon: Icons.open_with,
          action: l10n.manualDesktopDragAction,
          body: l10n.manualDesktopDragBody,
        ),
        ManualControlItem(
          icon: Icons.zoom_in,
          action: l10n.manualDesktopZoomAction,
          body: l10n.manualDesktopZoomBody,
        ),
        ManualControlItem(
          icon: Icons.info_outline,
          action: l10n.manualDesktopHoverAction,
          body: l10n.manualDesktopHoverBody,
        ),
      ],
    );
  }

  static ManualControlGroup _desktopOrders(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.gps_fixed,
      title: l10n.manualOrdersGroup,
      color: GameUiTheme.success,
      items: [
        ManualControlItem(
          icon: Icons.widgets_outlined,
          action: l10n.manualDesktopActionChipsAction,
          body: l10n.manualDesktopActionChipsBody,
        ),
        ManualControlItem(
          icon: Icons.check_circle_outline,
          action: l10n.manualDesktopSecondClickAction,
          body: l10n.manualDesktopSecondClickBody,
        ),
        ManualControlItem(
          icon: Icons.touch_app,
          action: l10n.manualDesktopHoldAction,
          body: l10n.manualDesktopHoldBody,
        ),
      ],
    );
  }

  static ManualControlGroup _desktopPanels(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.menu_open,
      title: l10n.manualPanelsGroup,
      color: GameUiTheme.goldLight,
      items: [
        ManualControlItem(
          icon: Icons.view_sidebar_outlined,
          action: l10n.manualDesktopRailAction,
          body: l10n.manualDesktopRailBody,
        ),
        ManualControlItem(
          icon: Icons.query_stats,
          action: l10n.manualDesktopTopPillsAction,
          body: l10n.manualDesktopTopPillsBody,
        ),
        ManualControlItem(
          icon: Icons.close,
          action: l10n.manualDesktopCloseAction,
          body: l10n.manualDesktopCloseBody,
        ),
        ManualControlItem(
          icon: Icons.help_outline,
          action: l10n.manualDesktopHelpAction,
          body: l10n.manualDesktopHelpBody,
        ),
      ],
    );
  }

  static ManualControlGroup _desktopTurn(AppLocalizations l10n) {
    return _turnGroup(
      l10n,
      items: [
        ManualControlItem(
          icon: Icons.play_arrow,
          action: l10n.manualDesktopTurnAction,
          body: l10n.manualDesktopTurnBody,
        ),
      ],
    );
  }

  static ManualControlGroup _mobileMap(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.map_outlined,
      title: l10n.manualMapCameraGroup,
      color: GameUiTheme.info,
      items: [
        ManualControlItem(
          icon: Icons.touch_app_outlined,
          action: l10n.manualMobileTapAction,
          body: l10n.manualMobileTapBody,
        ),
        ManualControlItem(
          icon: Icons.open_with,
          action: l10n.manualMobileDragAction,
          body: l10n.manualMobileDragBody,
        ),
        ManualControlItem(
          icon: Icons.zoom_in,
          action: l10n.manualMobilePinchAction,
          body: l10n.manualMobilePinchBody,
        ),
        ManualControlItem(
          icon: Icons.check_circle_outline,
          action: l10n.manualMobileSecondTapAction,
          body: l10n.manualMobileSecondTapBody,
        ),
      ],
    );
  }

  static ManualControlGroup _mobileOrders(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.gps_fixed,
      title: l10n.manualOrdersGroup,
      color: GameUiTheme.success,
      items: [
        ManualControlItem(
          icon: Icons.widgets_outlined,
          action: l10n.manualMobileActionChipsAction,
          body: l10n.manualMobileActionChipsBody,
        ),
        ManualControlItem(
          icon: Icons.touch_app,
          action: l10n.manualMobileHoldAction,
          body: l10n.manualMobileHoldBody,
        ),
        ManualControlItem(
          icon: Icons.swipe,
          action: l10n.manualMobileScrollAction,
          body: l10n.manualMobileScrollBody,
        ),
      ],
    );
  }

  static ManualControlGroup _mobilePanels(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.menu_open,
      title: l10n.manualPanelsGroup,
      color: GameUiTheme.goldLight,
      items: [
        ManualControlItem(
          icon: Icons.view_sidebar_outlined,
          action: l10n.manualMobileRailAction,
          body: l10n.manualMobileRailBody,
        ),
        ManualControlItem(
          icon: Icons.help_outline,
          action: l10n.manualMobileHelpAction,
          body: l10n.manualMobileHelpBody,
        ),
      ],
    );
  }

  static ManualControlGroup _mobileTurn(AppLocalizations l10n) {
    return _turnGroup(
      l10n,
      items: [
        ManualControlItem(
          icon: Icons.play_arrow,
          action: l10n.manualMobileTurnAction,
          body: l10n.manualMobileTurnBody,
        ),
      ],
    );
  }

  static ManualControlGroup _gamepadMap(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.map_outlined,
      title: l10n.manualMapCameraGroup,
      color: GameUiTheme.info,
      items: [
        ManualControlItem(
          icon: Icons.control_camera,
          action: l10n.manualGamepadCursorAction,
          body: l10n.manualGamepadCursorBody,
        ),
        ManualControlItem(
          icon: Icons.open_with,
          action: l10n.manualGamepadPanAction,
          body: l10n.manualGamepadPanBody,
        ),
        ManualControlItem(
          icon: Icons.zoom_in,
          action: l10n.manualGamepadZoomAction,
          body: l10n.manualGamepadZoomBody,
        ),
      ],
    );
  }

  static ManualControlGroup _gamepadOrders(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.gps_fixed,
      title: l10n.manualOrdersGroup,
      color: GameUiTheme.success,
      items: [
        ManualControlItem(
          icon: Icons.check_circle_outline,
          action: l10n.manualGamepadConfirmAction,
          body: l10n.manualGamepadConfirmBody,
        ),
        ManualControlItem(
          icon: Icons.cancel_outlined,
          action: l10n.manualGamepadCancelAction,
          body: l10n.manualGamepadCancelBody,
        ),
        ManualControlItem(
          icon: Icons.alt_route,
          action: l10n.manualGamepadModeAction,
          body: l10n.manualGamepadModeBody,
        ),
        ManualControlItem(
          icon: Icons.info_outline,
          action: l10n.manualGamepadInspectAction,
          body: l10n.manualGamepadInspectBody,
        ),
      ],
    );
  }

  static ManualControlGroup _gamepadPanels(AppLocalizations l10n) {
    return ManualControlGroup(
      icon: Icons.menu_open,
      title: l10n.manualPanelsGroup,
      color: GameUiTheme.goldLight,
      items: [
        ManualControlItem(
          icon: Icons.center_focus_strong,
          action: l10n.manualGamepadHudFocusAction,
          body: l10n.manualGamepadHudFocusBody,
        ),
        ManualControlItem(
          icon: Icons.tune,
          action: l10n.manualGamepadSettingsAction,
          body: l10n.manualGamepadSettingsBody,
        ),
      ],
    );
  }

  static ManualControlGroup _gamepadTurn(AppLocalizations l10n) {
    return _turnGroup(
      l10n,
      items: [
        ManualControlItem(
          icon: Icons.skip_next,
          action: l10n.manualGamepadNextAction,
          body: l10n.manualGamepadNextBody,
        ),
        ManualControlItem(
          icon: Icons.first_page,
          action: l10n.manualGamepadFocusAction,
          body: l10n.manualGamepadFocusBody,
        ),
        ManualControlItem(
          icon: Icons.play_arrow,
          action: l10n.manualGamepadTurnAction,
          body: l10n.manualGamepadTurnBody,
        ),
      ],
    );
  }

  static ManualControlGroup _turnGroup(
    AppLocalizations l10n, {
    required List<ManualControlItem> items,
  }) {
    return ManualControlGroup(
      icon: Icons.flag_outlined,
      title: l10n.manualTurnFlowGroup,
      color: GameUiTheme.warning,
      items: items,
    );
  }
}
