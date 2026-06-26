import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:aonw/game/domain/city.dart';
import 'package:aonw/game/domain/reducer/game_state/game_state_transition.dart';
import 'package:aonw/game/presentation/engine/rendering_layers/city/city_marker_layer.dart';
import 'package:aonw/map/domain/map_config.dart';
import 'package:aonw/map/rendering/hex_geometry.dart';
import 'package:aonw/map/rendering/hex_grid.dart';
import 'package:aonw/map/rendering/layer_attachment.dart';
import 'package:aonw/map/rendering/map_alpha.dart';
import 'package:aonw/map/rendering/map_priority.dart';
import 'package:aonw/shared/theme/hud_paint.dart';
import 'package:aonw/shared/theme/hud_palette.dart';
import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/animation.dart';

class ParticleEffectsLayer extends Component with LayerAttachment {
  final math.Random _random;
  final Set<ParticleSystemComponent> _bursts = {};

  ParticleEffectsLayer({math.Random? random})
    : _random = random ?? math.Random();

  ParticleSystemComponent spawnBurst({
    required Component parent,
    required SpawnParticleBurstEffect effect,
  }) {
    ensureAttachedTo(parent);
    final owner = attachedOwner;
    _pruneDetachedBursts();
    final component = ParticleSystemComponent(
      position: _worldPositionFor(effect.col, effect.row),
      priority: _priorityFor(effect.col, effect.row),
      particle: _particleFor(effect),
    );
    _bursts.add(component);
    unawaited(Future<void>.value(owner.add(component)));
    return component;
  }

  void clear() {
    for (final burst in _bursts) {
      burst.removeFromParent();
    }
    _bursts.clear();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  void _pruneDetachedBursts() {
    _bursts.removeWhere((burst) => burst.parent == null && !burst.isMounted);
  }

  Particle _particleFor(SpawnParticleBurstEffect effect) {
    return switch (effect.kind) {
      ParticleBurstKind.cityFounded => _cityFoundedBurst(
        Color(effect.colorValue),
      ),
      ParticleBurstKind.hexClaimed => _hexClaimedBurst(
        Color(effect.colorValue),
      ),
      ParticleBurstKind.technologyResearched => _technologyBurst(),
      ParticleBurstKind.unitProduced => _unitProducedBurst(
        Color(effect.colorValue),
      ),
      ParticleBurstKind.unitKilled => _unitKilledBurst(),
      ParticleBurstKind.cityAttacked => _cityAttackedBurst(
        Color(effect.colorValue),
      ),
    };
  }

  Particle _cityFoundedBurst(Color color) {
    const lifespan = 1.35;
    return Particle.generate(
      count: 36,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * math.pi * 2;
        final speed = 55 + _random.nextDouble() * 85;
        final radius = 2.2 + _random.nextDouble() * 2.6;
        return AcceleratedParticle(
          lifespan: lifespan,
          speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 35),
          acceleration: Vector2(0, 95),
          child: _fadingCircle(color, radius: radius, lifespan: lifespan),
        );
      },
    );
  }

  Particle _hexClaimedBurst(Color color) {
    const lifespan = 0.95;
    return Particle.generate(
      count: 24,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * math.pi * 2;
        final distance = 16 + _random.nextDouble() * 28;
        final target = Vector2(
          math.cos(angle) * distance,
          math.sin(angle) * 12,
        );
        return MovingParticle(
          lifespan: lifespan,
          to: target,
          curve: Curves.easeOutCubic,
          child: _fadingCircle(color, radius: 2.1, lifespan: lifespan),
        );
      },
    );
  }

  Particle _technologyBurst() {
    const lifespan = 1.45;
    return Particle.generate(
      count: 32,
      lifespan: lifespan,
      generator: (_) {
        final driftX = -28 + _random.nextDouble() * 56;
        final startY = -46 - _random.nextDouble() * 28;
        final speedY = 35 + _random.nextDouble() * 55;
        return AcceleratedParticle(
          lifespan: lifespan,
          position: Vector2(driftX, startY),
          speed: Vector2(-12 + _random.nextDouble() * 24, speedY),
          acceleration: Vector2(0, 38),
          child: _fadingCircle(
            HudPalette.gold,
            radius: 1.8 + _random.nextDouble() * 2.0,
            lifespan: lifespan,
          ),
        );
      },
    );
  }

  Particle _unitProducedBurst(Color color) {
    const lifespan = 0.7;
    return Particle.generate(
      count: 18,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * math.pi * 2;
        final distance = 10 + _random.nextDouble() * 20;
        return MovingParticle(
          lifespan: lifespan,
          to: Vector2(math.cos(angle) * distance, math.sin(angle) * distance),
          curve: Curves.easeOutBack,
          child: _fadingCircle(
            Color.lerp(color, HudPalette.textBright, 0.35)!,
            radius: 1.6 + _random.nextDouble() * 1.4,
            lifespan: lifespan,
          ),
        );
      },
    );
  }

  Particle _unitKilledBurst() {
    const lifespan = 0.85;
    return Particle.generate(
      count: 28,
      lifespan: lifespan,
      generator: (_) {
        final angle = _random.nextDouble() * math.pi * 2;
        final speed = 35 + _random.nextDouble() * 70;
        final shade = 45 + _random.nextInt(55);
        return AcceleratedParticle(
          lifespan: lifespan,
          speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 10),
          acceleration: Vector2(0, -18),
          child: _fadingCircle(
            Color.fromARGB(MapAlpha.full, shade, shade, shade),
            radius: 2.0 + _random.nextDouble() * 2.2,
            lifespan: lifespan,
          ),
        );
      },
    );
  }

  Particle _cityAttackedBurst(Color color) {
    const lifespan = 1.05;
    return Particle.generate(
      count: 34,
      lifespan: lifespan,
      generator: (_) {
        final angle = -math.pi * 0.9 + _random.nextDouble() * math.pi * 0.8;
        final speed = 24 + _random.nextDouble() * 82;
        final radius = 2.0 + _random.nextDouble() * 2.4;
        final ember = Color.lerp(color, HudPalette.warning, 0.28)!;
        return AcceleratedParticle(
          lifespan: lifespan,
          position: Vector2(
            -12 + _random.nextDouble() * 24,
            -8 + _random.nextDouble() * 10,
          ),
          speed: Vector2(math.cos(angle) * speed, math.sin(angle) * speed - 24),
          acceleration: Vector2(0, 72),
          child: _fadingCircle(ember, radius: radius, lifespan: lifespan),
        );
      },
    );
  }

  Particle _fadingCircle(
    Color color, {
    required double radius,
    required double lifespan,
  }) {
    return ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final opacity = (1 - particle.progress).clamp(0.0, 1.0);
        final paint = HudPaint.fill(
          color,
          alpha: (opacity * MapAlpha.solid).round(),
        )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.2);
        canvas.drawCircle(Offset.zero, radius * (1 + particle.progress), paint);
      },
    );
  }

  Vector2 _worldPositionFor(int col, int row) {
    final tileCenter = HexGeometry.tilePosition(
      col: col,
      row: row,
      hexRadius: MapConfig.defaultConfig.hexRadius,
    );
    return Vector2(tileCenter.x, tileCenter.y * HexGrid.perspectiveY - 10);
  }

  int _priorityFor(int col, int row) {
    return MapPriority.perTile(MapPriority.particles, col: col, row: row);
  }
}

class CityProductionParticleLayer extends Component with LayerAttachment {
  final Map<String, CityProductionHintEmitter> _emitters = {};
  bool _reduceMotion;
  bool _visible;

  CityProductionParticleLayer({bool reduceMotion = false, bool visible = true})
    : _reduceMotion = reduceMotion,
      _visible = visible;

  bool get reduceMotion => _reduceMotion;

  bool get visible => _visible;

  set visible(bool value) {
    if (_visible == value) return;
    _visible = value;
    if (!_visible) {
      clear();
    }
  }

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    for (final emitter in _emitters.values) {
      emitter.reduceMotion = value;
    }
  }

  void sync({
    required Component parent,
    required Iterable<GameCity> cities,
    required int Function(String playerId) colorForPlayer,
  }) {
    if (!_visible) {
      clear();
      return;
    }

    ensureAttachedTo(parent);
    final owner = attachedOwner;
    final producingCities = [
      for (final city in cities)
        if (city.productionQueue != null) city,
    ];
    final producingCityIds = producingCities.map((city) => city.id).toSet();
    for (final entry in _emitters.entries.toList()) {
      if (producingCityIds.contains(entry.key)) continue;
      entry.value.removeFromParent();
      _emitters.remove(entry.key);
    }

    for (final city in producingCities) {
      final position = CityMarkerLayer.worldPositionFor(
        city.center.col,
        city.center.row,
      );
      final colorValue = colorForPlayer(city.ownerPlayerId);
      final emitter = _emitters[city.id];
      final priority = _productionPriorityFor(city.center.col, city.center.row);
      if (emitter == null) {
        final created = CityProductionHintEmitter(
          position: position,
          priority: priority,
          colorValue: colorValue,
          reduceMotion: _reduceMotion,
        );
        _emitters[city.id] = created;
        unawaited(Future<void>.value(owner.add(created)));
      } else {
        emitter
          ..position = position
          ..priority = priority
          ..colorValue = colorValue
          ..reduceMotion = _reduceMotion;
      }
    }
  }

  int _productionPriorityFor(int col, int row) {
    return MapPriority.perTile(
      MapPriority.productionParticles,
      col: col,
      row: row,
    );
  }

  void clear() {
    for (final emitter in _emitters.values) {
      emitter.removeFromParent();
    }
    _emitters.clear();
  }

  @override
  void onRemove() {
    clear();
    super.onRemove();
  }

  int get emitterCountForTesting => _emitters.length;

  bool hasEmitterForTesting(String cityId) => _emitters.containsKey(cityId);

  bool emitterReduceMotionForTesting(String cityId) =>
      _emitters[cityId]?.reduceMotion ?? false;

  int emitterSpawnCountForTesting(String cityId) =>
      _emitters[cityId]?.spawnCountForTesting ?? 0;
}

class CityProductionHintEmitter extends PositionComponent {
  int colorValue;
  bool _reduceMotion;
  double _elapsed = 0;
  int _spawnCount = 0;

  static const double emissionPeriod = 2.0;
  static const double lifespan = 1.1;
  static final Vector2 _spawnOffset = Vector2(0, -30);

  CityProductionHintEmitter({
    required Vector2 position,
    required int priority,
    required this.colorValue,
    bool reduceMotion = false,
  }) : _reduceMotion = reduceMotion,
       super(position: position, priority: priority);

  bool get reduceMotion => _reduceMotion;

  set reduceMotion(bool value) {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    _elapsed = 0;
    if (_reduceMotion) {
      removeWhere((component) => component is ParticleSystemComponent);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_reduceMotion) return;
    _elapsed += dt;
    while (_elapsed >= emissionPeriod) {
      _elapsed -= emissionPeriod;
      _spawnHintParticle();
    }
  }

  void _spawnHintParticle() {
    _spawnCount++;
    final component = ParticleSystemComponent(
      position: _spawnOffset.clone(),
      particle: _productionHintParticle(Color(colorValue)),
    );
    unawaited(Future<void>.value(add(component)));
  }

  Particle _productionHintParticle(Color color) {
    const gold = HudPalette.gold;
    final accent = Color.lerp(color, gold, 0.7) ?? gold;
    return MovingParticle(
      lifespan: lifespan,
      to: Vector2(0, -14),
      curve: Curves.easeOutCubic,
      child: _productionHintCircle(accent),
    );
  }

  Particle _productionHintCircle(Color color) {
    return ComputedParticle(
      lifespan: lifespan,
      renderer: (canvas, particle) {
        final opacity = (1 - particle.progress).clamp(0.0, 1.0);
        final radius = 1.7 + particle.progress * 1.4;
        final paint = HudPaint.fill(
          color,
          alpha: (opacity * MapAlpha.solid).round(),
        )..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.1);
        canvas.drawCircle(Offset.zero, radius, paint);
      },
    );
  }

  int get spawnCountForTesting => _spawnCount;
}
