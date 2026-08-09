part of '../realtime_match_hub_test.dart';

final class _TurnMovementFixture {
  const _TurnMovementFixture({
    required this.hub,
    required this.store,
    required this.match,
    required this.owner,
    required this.unitBPlayer,
    required this.observer,
  });

  final RealtimeMatchHub hub;
  final TestMatchStore store;
  final WireMatch match;
  final WirePlayer owner;
  final WirePlayer unitBPlayer;
  final WirePlayer observer;
}

final class _TurnMovementClients {
  _TurnMovementClients._({
    required this.ownerInput,
    required this.secondOwnerInput,
    required this.observerInput,
    required this.ownerStream,
    required this.secondOwnerStream,
    required this.observerStream,
  });

  static Future<_TurnMovementClients> connect(
    _TurnMovementFixture fixture,
  ) async {
    final ownerInput = StreamController<MultiplayerClientMessage>();
    final secondOwnerInput = StreamController<MultiplayerClientMessage>();
    final observerInput = StreamController<MultiplayerClientMessage>();
    final ownerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: fixture.owner.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: ownerInput.stream,
        )
        .asBroadcastStream();
    final secondOwnerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: fixture.owner.userId,
          matchId: fixture.match.id,
          afterOffset: 0,
          input: secondOwnerInput.stream,
        )
        .asBroadcastStream();
    final observerStream = fixture.hub
        .connect(
          store: fixture.store,
          userIdentifier: 'turn-movement-observer',
          matchId: fixture.match.id,
          afterOffset: 0,
          input: observerInput.stream,
        )
        .asBroadcastStream();
    await Future.wait([
      ownerStream.first,
      secondOwnerStream.first,
      observerStream.first,
    ]);
    return _TurnMovementClients._(
      ownerInput: ownerInput,
      secondOwnerInput: secondOwnerInput,
      observerInput: observerInput,
      ownerStream: ownerStream,
      secondOwnerStream: secondOwnerStream,
      observerStream: observerStream,
    ).._recordMessages();
  }

  final StreamController<MultiplayerClientMessage> ownerInput;
  final StreamController<MultiplayerClientMessage> secondOwnerInput;
  final StreamController<MultiplayerClientMessage> observerInput;
  final Stream<MultiplayerServerMessage> ownerStream;
  final Stream<MultiplayerServerMessage> secondOwnerStream;
  final Stream<MultiplayerServerMessage> observerStream;
  final List<MultiplayerServerMessage> ownerAcks = [];
  final List<MultiplayerServerMessage> ownerEvents = [];
  final List<MultiplayerServerMessage> secondOwnerAcks = [];
  final List<MultiplayerServerMessage> secondOwnerEvents = [];
  final List<MultiplayerServerMessage> observerAcks = [];
  final List<MultiplayerServerMessage> observerEvents = [];
  final List<StreamSubscription<MultiplayerServerMessage>> _subscriptions = [];

  void _recordMessages() {
    _subscriptions
      ..add(
        ownerStream
            .where((message) => message.ack != null)
            .listen(ownerAcks.add),
      )
      ..add(
        ownerStream
            .where((message) => message.event != null)
            .listen(ownerEvents.add),
      )
      ..add(
        secondOwnerStream
            .where((message) => message.ack != null)
            .listen(secondOwnerAcks.add),
      )
      ..add(
        secondOwnerStream
            .where((message) => message.event != null)
            .listen(secondOwnerEvents.add),
      )
      ..add(
        observerStream
            .where((message) => message.ack != null)
            .listen(observerAcks.add),
      )
      ..add(
        observerStream
            .where((message) => message.event != null)
            .listen(observerEvents.add),
      );
  }

  Future<MultiplayerServerMessage> sendOwner(MultiplayerClientMessage message) {
    final acknowledgement = ownerStream.firstWhere(
      (serverMessage) => serverMessage.ack != null,
    );
    ownerInput.add(message);
    return acknowledgement;
  }

  Future<void> close() async {
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await ownerInput.close();
    await secondOwnerInput.close();
    await observerInput.close();
  }
}
