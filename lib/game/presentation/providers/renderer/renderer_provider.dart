import 'package:aonw/game/presentation/engine.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'renderer_provider.g.dart';

/// Holds the current Flame renderer instance inside a game screen scope.
///
/// `dependencies: const []` marks this as a *scoped* provider so that
/// `ProviderScope(overrides: [...])` actually propagates the renderer to
/// descendants. Consumers must declare this in their own `dependencies`.
@Riverpod(dependencies: [])
GameRenderer? activeGameRenderer(Ref ref) => null;

/// Renderer-facing view model used by Riverpod controllers.
///
/// Provider/controller code should depend on this port instead of the concrete
/// Flame [GameRenderer]. The concrete renderer remains a host-widget concern.
@Riverpod(dependencies: [activeGameRenderer])
RendererViewModel? activeRendererViewModel(Ref ref) {
  final renderer = ref.watch(activeGameRendererProvider);
  return renderer == null ? null : GameRendererViewModel(renderer);
}
