import 'dart:async';

import 'package:aonw/game/presentation/input/gamepad/gamepad_input.dart';
import 'package:aonw/shared/widgets/game_ui/game_ui_focus_ring.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

typedef MenuGamepadActionBuilder =
    Widget Function(BuildContext context, bool focused);

class MenuGamepadInputBinding extends StatefulWidget {
  const MenuGamepadInputBinding({
    required this.child,
    this.input,
    this.onCancel,
    super.key,
  });

  final ValueListenable<GamepadInputSnapshot>? input;
  final VoidCallback? onCancel;
  final Widget child;

  @override
  State<MenuGamepadInputBinding> createState() =>
      _MenuGamepadInputBindingState();
}

class _MenuGamepadInputBindingState extends State<MenuGamepadInputBinding> {
  final FocusScopeNode _scopeNode = FocusScopeNode(
    debugLabel: 'menu gamepad scope',
  );
  final ValueNotifier<bool> _gamepadFocusActive = ValueNotifier(false);
  GamepadInputAdapter? _adapter;

  ValueListenable<GamepadInputSnapshot> get _input {
    final input = widget.input;
    if (input != null) return input;
    return (_adapter ??= GamepadInputAdapter()..start()).snapshot;
  }

  @override
  void didUpdateWidget(MenuGamepadInputBinding oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.input != widget.input && widget.input != null) {
      _adapter?.dispose();
      _adapter = null;
    }
  }

  @override
  void dispose() {
    _adapter?.dispose();
    _gamepadFocusActive.dispose();
    _scopeNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _MenuGamepadFocusMode(
      notifier: _gamepadFocusActive,
      child: MouseRegion(
        onHover: (_) => _setGamepadFocusActive(false),
        child: Listener(
          onPointerDown: (_) => _setGamepadFocusActive(false),
          child: FocusTraversalGroup(
            child: FocusScope(
              node: _scopeNode,
              child: GamepadPanelInputListener(
                input: _input,
                onNavigate: _handleNavigate,
                onConfirm: _handleConfirm,
                onCancel: _handleCancel,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleNavigate(GamepadMapDirection direction) {
    _setGamepadFocusActive(true);
    final focused = _focusedNode();
    if (focused == null) {
      _focusBoundary(
        last:
            direction == GamepadMapDirection.up ||
            direction == GamepadMapDirection.left,
      );
      return;
    }
    if (_handleAdjust(direction, focused)) return;

    final policy = _policyFor(focused);
    final forward =
        direction == GamepadMapDirection.down ||
        direction == GamepadMapDirection.right;
    final moved = forward ? policy.next(focused) : policy.previous(focused);
    if (!moved) {
      _focusBoundary(last: !forward);
    }
    _scrollFocusedIntoView();
  }

  void _handleConfirm() {
    _setGamepadFocusActive(true);
    final focused = _focusedNode() ?? _focusBoundary();
    final focusContext = focused?.context;
    if (focusContext == null) return;
    Actions.maybeInvoke(focusContext, const ActivateIntent());
  }

  void _handleCancel() {
    unawaited(_handleCancelAsync());
  }

  Future<void> _handleCancelAsync() async {
    final route = ModalRoute.of(context);
    if (route?.isCurrent == false && await Navigator.of(context).maybePop()) {
      return;
    }
    widget.onCancel?.call();
  }

  bool _handleAdjust(GamepadMapDirection direction, FocusNode focused) {
    final delta = switch (direction) {
      GamepadMapDirection.left => -1,
      GamepadMapDirection.right => 1,
      _ => 0,
    };
    if (delta == 0) return false;
    final focusContext = focused.context;
    if (focusContext == null) return false;
    return Actions.maybeInvoke(focusContext, MenuGamepadAdjustIntent(delta)) !=
        null;
  }

  FocusNode? _focusedNode() {
    final primary = FocusManager.instance.primaryFocus;
    if (primary?.context == null) return null;
    if (_isInsideScope(primary!)) return primary;
    if (ModalRoute.of(context)?.isCurrent == false) return primary;
    return null;
  }

  bool _isInsideScope(FocusNode node) {
    return node == _scopeNode || node.ancestors.contains(_scopeNode);
  }

  FocusNode? _focusBoundary({bool last = false}) {
    final moved = last ? _scopeNode.previousFocus() : _scopeNode.nextFocus();
    if (!moved) return null;
    _scrollFocusedIntoView();
    return FocusManager.instance.primaryFocus;
  }

  FocusTraversalPolicy _policyFor(FocusNode focused) {
    final focusContext = focused.context;
    if (focusContext == null) return FocusTraversalGroup.of(context);
    return FocusTraversalGroup.of(focusContext);
  }

  void _scrollFocusedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focusContext = FocusManager.instance.primaryFocus?.context;
      if (focusContext == null || !focusContext.mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          focusContext,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
  }

  void _setGamepadFocusActive(bool value) {
    if (_gamepadFocusActive.value == value) return;
    _gamepadFocusActive.value = value;
  }
}

class MenuGamepadAction extends StatefulWidget {
  const MenuGamepadAction({
    required this.builder,
    this.onActivate,
    this.enabled = true,
    this.borderRadius,
    super.key,
  });

  final MenuGamepadActionBuilder builder;
  final VoidCallback? onActivate;
  final bool enabled;
  final BorderRadiusGeometry? borderRadius;

  @override
  State<MenuGamepadAction> createState() => _MenuGamepadActionState();
}

class _MenuGamepadActionState extends State<MenuGamepadAction> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final gamepadFocusActive = _MenuGamepadFocusMode.activeOf(context);
    final visibleFocus = _focused && gamepadFocusActive;
    return FocusableActionDetector(
      enabled: widget.enabled && widget.onActivate != null,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onActivate?.call();
            return null;
          },
        ),
      },
      onFocusChange: (focused) {
        if (_focused == focused) return;
        setState(() => _focused = focused);
        if (focused && _MenuGamepadFocusMode.activeWithoutListening(context)) {
          _scrollIntoView();
        }
      },
      child: GameUiFocusRing(
        focused: visibleFocus,
        borderRadius: widget.borderRadius,
        child: widget.builder(context, visibleFocus),
      ),
    );
  }

  void _scrollIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
        ),
      );
    });
  }
}

class MenuGamepadAdjustIntent extends Intent {
  const MenuGamepadAdjustIntent(this.delta);

  final int delta;
}

class _MenuGamepadFocusMode extends InheritedNotifier<ValueNotifier<bool>> {
  const _MenuGamepadFocusMode({
    required ValueNotifier<bool> super.notifier,
    required super.child,
  });

  static bool activeOf(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<_MenuGamepadFocusMode>()
            ?.notifier
            ?.value ??
        false;
  }

  static bool activeWithoutListening(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<_MenuGamepadFocusMode>();
    final widget = element?.widget;
    return widget is _MenuGamepadFocusMode
        ? widget.notifier?.value ?? false
        : false;
  }
}
