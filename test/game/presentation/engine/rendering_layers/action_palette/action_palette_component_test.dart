import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_component.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/action_palette/action_palette_option.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/animation_frame_adjustments.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/assets/board_asset_cap.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_cache.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/improvements/field_improvement_sprite_catalog.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw_core/game/domain/city.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const farm = ActionPaletteOption(
    id: 'farm',
    iconAtlasRow: 0,
    iconAtlasColumn: 0,
    label: 'Farm',
    yieldChips: [
      ActionPaletteYieldChip(kind: ActionPaletteYieldKind.food, value: 2),
    ],
    turns: 4,
    state: ActionPaletteOptionState.recommended,
    ctaLabel: 'ZBUDUJ',
  );

  ActionPaletteComponent buildComponent({
    List<ActionPaletteOption> options = const [farm],
    String? previewedOptionId,
    void Function(String id)? onPreview,
    void Function(String id)? onConfirm,
    void Function()? onCancel,
  }) {
    return ActionPaletteComponent(
      options: options,
      previewedOptionId: previewedOptionId,
      onPreview: onPreview ?? (_) {},
      onConfirm: onConfirm ?? (_) {},
      onCancel: onCancel ?? () {},
    );
  }

  group('ActionPaletteComponent collapsed bar', () {
    test('renders at action palette priority so it draws above map layers', () {
      final component = buildComponent();

      expect(component.priority, MapPriority.actionPalette);
    });

    test('uses Anchor.center so its position represents the bar center', () {
      final component = buildComponent();

      expect(component.anchor, Anchor.center);
    });

    test('exposes option rects matching option length and order', () {
      final component = buildComponent(
        options: const [
          farm,
          ActionPaletteOption(
            id: 'mine',
            iconAtlasRow: 3,
            iconAtlasColumn: 0,
            label: 'Mine',
            yieldChips: [],
            turns: 6,
            state: ActionPaletteOptionState.available,
            ctaLabel: 'ZBUDUJ',
          ),
        ],
      );

      expect(component.optionRectsForTesting.length, 2);
      expect(
        component.optionRectsForTesting.first.left,
        lessThan(component.optionRectsForTesting.last.left),
      );
    });

    test(
      'updateOptions replaces the option set without recreating component',
      () {
        final component = buildComponent()
          ..updateOptions(const [
            farm,
            ActionPaletteOption(
              id: 'mine',
              iconAtlasRow: 3,
              iconAtlasColumn: 0,
              label: 'Mine',
              yieldChips: [],
              turns: 6,
              state: ActionPaletteOptionState.available,
              ctaLabel: 'ZBUDUJ',
            ),
          ]);

        expect(component.optionsForTesting.length, 2);
      },
    );

    test('applies asset editor frame offsets to option sprites', () async {
      const adjustment = AnimationFrameAdjustment(
        offsetX: 9,
        offsetY: -3,
        cropLeft: 4,
        scaleX: 1.15,
      );
      final assetPath = FieldImprovementSpriteCatalog.assetPathFor(
        FieldImprovementType.farm,
      );
      AnimationFrameAdjustmentCatalogCache.replace(
        AnimationFrameAdjustmentCatalog(
          frames: {
            AnimationFrameAdjustmentCatalog.frameKey(
              assetPath: assetPath,
              animationId: FieldImprovementSpriteCatalog.adjustmentIdForVariant(
                type: FieldImprovementType.farm,
                eraColumn: 0,
              ),
              frameIndex: 0,
            ): adjustment,
          },
        ),
      );
      addTearDown(AnimationFrameAdjustmentCatalogCache.clearForTesting);

      final component = buildComponent();
      await component.onLoad();
      final image = await FieldImprovementSpriteCache.load(assetPath);
      final iconRect = component.optionRectsForTesting.single;
      final baseSource = FieldImprovementSpriteCatalog.sourceRectFor(
        imageWidth: image.width,
        imageHeight: image.height,
        type: FieldImprovementType.farm,
        eraColumn: 0,
      );
      final baseDestination = iconRect.deflate(4);
      final expectedDestination = adjustment
          .adjustedDestinationFor(
            baseSource: baseSource,
            baseDestination: baseDestination,
          )
          .shift(
            adjustment.scaledOffset(
              baseSize: BoardAssetCapStyles.improvement.topSize,
              targetSize: baseDestination.size,
            ),
          );

      expect(
        component.spriteSourceForTesting(image: image, option: farm),
        adjustment.croppedSourceFor(baseSource),
      );
      expect(
        component.spriteDestinationForTesting(
          image: image,
          option: farm,
          iconRect: iconRect,
        ),
        expectedDestination,
      );
    });

    test('available option tap calls onPreview', () {
      String? previewed;
      final component = buildComponent(onPreview: (id) => previewed = id)
        ..tapOptionForTesting('farm');

      expect(component.optionsForTesting.single.id, 'farm');
      expect(previewed, 'farm');
    });
  });

  group('ActionPaletteComponent preview', () {
    test('grows in height when an option is previewed', () {
      final component = buildComponent();
      final collapsedHeight = component.size.y;

      expect(
        (component..updatePreviewed('farm')).size.y,
        greaterThan(collapsedHeight),
      );
    });

    test('exposes CTA rect when an available option is previewed', () {
      final component = buildComponent(previewedOptionId: 'farm');

      expect(component.ctaRectForTesting, isNotNull);
    });

    test('CTA tap confirms the previewed option', () {
      String? confirmed;
      final component = buildComponent(
        previewedOptionId: 'farm',
        onConfirm: (id) => confirmed = id,
      )..tapCtaForTesting();

      expect(component.ctaRectForTesting, isNotNull);
      expect(confirmed, 'farm');
    });
  });

  group('ActionPaletteComponent blocked options', () {
    test('blocked tap does not preview but stores tooltip reason', () {
      String? previewed;
      final component = buildComponent(
        options: const [
          ActionPaletteOption(
            id: 'orchard',
            iconAtlasRow: 2,
            iconAtlasColumn: 0,
            label: 'Sad',
            yieldChips: [],
            turns: 5,
            state: ActionPaletteOptionState.blocked,
            ctaLabel: 'ZBUDUJ',
            blockedReason: 'Requires technology: Sadownictwo',
          ),
        ],
        onPreview: (id) => previewed = id,
      )..tapOptionForTesting('orchard');

      expect(previewed, isNull);
      expect(
        component.tooltipMessageForTesting,
        'Requires technology: Sadownictwo',
      );
    });

    test('blocked option cannot expose CTA even if it is marked previewed', () {
      final component = buildComponent(
        options: const [
          ActionPaletteOption(
            id: 'orchard',
            iconAtlasRow: 2,
            iconAtlasColumn: 0,
            label: 'Sad',
            yieldChips: [],
            turns: 5,
            state: ActionPaletteOptionState.blocked,
            ctaLabel: 'ZBUDUJ',
          ),
        ],
        previewedOptionId: 'orchard',
      );

      expect(component.ctaRectForTesting, isNull);
    });
  });

  group('ActionPaletteComponent auto-flip', () {
    test('flips below actor when actor sits in the upper screen band', () {
      final flipped = ActionPaletteComponent.shouldFlipBelow(
        actorScreenTopY: 30,
        actorScreenBottomY: 80,
        screenHeight: 720,
        wasFlippedBelow: false,
      );

      expect(flipped, isTrue);
    });

    test('keeps the previous side within the hysteresis band', () {
      final stayedAbove = ActionPaletteComponent.shouldFlipBelow(
        actorScreenTopY: 200,
        actorScreenBottomY: 250,
        screenHeight: 720,
        wasFlippedBelow: false,
      );

      expect(stayedAbove, isFalse);
    });
  });
}
