import 'package:aonw_server_client/aonw_server_client.dart';
import 'package:test/test.dart';

void main() {
  test('generated client protocol round-trips create match requests', () {
    final request = CreateMatchRequest(
      name: 'CI smoke',
      mapName: 'myranth',
      maxPlayers: 4,
      minPlayers: 2,
      private: false,
      countryId: 'netherlands',
    );

    final roundTrip = Protocol().deserialize<CreateMatchRequest>(
      request.toJson(),
    );

    expect(roundTrip.name, 'CI smoke');
    expect(roundTrip.mapName, 'myranth');
    expect(roundTrip.maxPlayers, 4);
    expect(roundTrip.minPlayers, 2);
    expect(roundTrip.private, isFalse);
    expect(roundTrip.countryId, 'netherlands');
  });
}
