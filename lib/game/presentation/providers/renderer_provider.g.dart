// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'renderer_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the current Flame renderer instance inside a game screen scope.
///
/// `dependencies: const []` marks this as a *scoped* provider so that
/// `ProviderScope(overrides: [...])` actually propagates the renderer to
/// descendants. Consumers must declare this in their own `dependencies`.

@ProviderFor(activeGameRenderer)
final activeGameRendererProvider = ActiveGameRendererProvider._();

/// Holds the current Flame renderer instance inside a game screen scope.
///
/// `dependencies: const []` marks this as a *scoped* provider so that
/// `ProviderScope(overrides: [...])` actually propagates the renderer to
/// descendants. Consumers must declare this in their own `dependencies`.

final class ActiveGameRendererProvider
    extends $FunctionalProvider<GameRenderer?, GameRenderer?, GameRenderer?>
    with $Provider<GameRenderer?> {
  /// Holds the current Flame renderer instance inside a game screen scope.
  ///
  /// `dependencies: const []` marks this as a *scoped* provider so that
  /// `ProviderScope(overrides: [...])` actually propagates the renderer to
  /// descendants. Consumers must declare this in their own `dependencies`.
  ActiveGameRendererProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeGameRendererProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[],
        $allTransitiveDependencies: <ProviderOrFamily>[],
      );

  @override
  String debugGetCreateSourceHash() => _$activeGameRendererHash();

  @$internal
  @override
  $ProviderElement<GameRenderer?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GameRenderer? create(Ref ref) {
    return activeGameRenderer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GameRenderer? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GameRenderer?>(value),
    );
  }
}

String _$activeGameRendererHash() =>
    r'a3662208d538124af84894adc143ed9f8c2cf9a9';

/// Renderer-facing view model used by Riverpod controllers.
///
/// Provider/controller code should depend on this port instead of the concrete
/// Flame [GameRenderer]. The concrete renderer remains a host-widget concern.

@ProviderFor(activeRendererViewModel)
final activeRendererViewModelProvider = ActiveRendererViewModelProvider._();

/// Renderer-facing view model used by Riverpod controllers.
///
/// Provider/controller code should depend on this port instead of the concrete
/// Flame [GameRenderer]. The concrete renderer remains a host-widget concern.

final class ActiveRendererViewModelProvider
    extends
        $FunctionalProvider<
          RendererViewModel?,
          RendererViewModel?,
          RendererViewModel?
        >
    with $Provider<RendererViewModel?> {
  /// Renderer-facing view model used by Riverpod controllers.
  ///
  /// Provider/controller code should depend on this port instead of the concrete
  /// Flame [GameRenderer]. The concrete renderer remains a host-widget concern.
  ActiveRendererViewModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'activeRendererViewModelProvider',
        isAutoDispose: true,
        dependencies: <ProviderOrFamily>[activeGameRendererProvider],
        $allTransitiveDependencies: <ProviderOrFamily>[
          ActiveRendererViewModelProvider.$allTransitiveDependencies0,
        ],
      );

  static final $allTransitiveDependencies0 = activeGameRendererProvider;

  @override
  String debugGetCreateSourceHash() => _$activeRendererViewModelHash();

  @$internal
  @override
  $ProviderElement<RendererViewModel?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  RendererViewModel? create(Ref ref) {
    return activeRendererViewModel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(RendererViewModel? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<RendererViewModel?>(value),
    );
  }
}

String _$activeRendererViewModelHash() =>
    r'af0df0d2e8a695579db2db42e4e36af266de9d70';
