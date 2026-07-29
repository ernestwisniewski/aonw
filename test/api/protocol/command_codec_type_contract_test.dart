import 'package:aonw/api/protocol/codecs.dart';
import 'package:aonw_core/game/domain/command.dart';
import 'package:aonw_core/game/domain/event.dart';
import 'package:aonw_core/protocol.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('CommandCodec exposes DomainCommand-only player wire types', () {
    const codec = CommandCodec();
    final _DomainCommandEncoder encoder = codec.toWire;
    final _DomainCommandDecoder decoder = codec.fromWire;

    expect(encoder, isA<_DomainCommandEncoder>());
    expect(encoder, isNot(isA<_GameCommandEncoder>()));
    expect(decoder, isA<_DomainCommandDecoder>());
  });

  test('EventCodec exposes DomainCommand-only embedded command types', () {
    const codec = EventCodec();
    final _DomainEventEncoder encoder = codec.toWire;
    final _DomainEventCommandDecoder decoder = codec.commandFromWire;

    expect(encoder, isA<_DomainEventEncoder>());
    expect(encoder, isNot(isA<_GameEventEncoder>()));
    expect(decoder, isA<_DomainEventCommandDecoder>());
  });
}

typedef _DomainCommandEncoder =
    WireCommand Function({
      required String matchId,
      required int tick,
      int? turn,
      required String actorPlayerId,
      required DomainCommand command,
    });

typedef _GameCommandEncoder =
    WireCommand Function({
      required String matchId,
      required int tick,
      int? turn,
      required String actorPlayerId,
      required GameCommand command,
    });

typedef _DomainCommandDecoder = DomainCommand Function(WireCommand wire);

typedef _DomainEventEncoder =
    WireEvent Function({
      required String matchId,
      required int offset,
      required DateTime timestamp,
      required List<GameEvent> events,
      String? actorPlayerId,
      int? tick,
      int? turn,
      DomainCommand? command,
      Iterable<WireMovementExecution> movementExecutions,
    });

typedef _GameEventEncoder =
    WireEvent Function({
      required String matchId,
      required int offset,
      required DateTime timestamp,
      required List<GameEvent> events,
      String? actorPlayerId,
      int? tick,
      int? turn,
      GameCommand? command,
      Iterable<WireMovementExecution> movementExecutions,
    });

typedef _DomainEventCommandDecoder = DomainCommand? Function(WireEvent wire);
