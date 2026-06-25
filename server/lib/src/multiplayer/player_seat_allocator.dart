import 'package:aonw_core/game/domain/player.dart';
import 'package:aonw_core/protocol.dart';

class PlayerSeatAllocator {
  const PlayerSeatAllocator();

  WirePlayer createHumanPlayer({
    required String userIdentifier,
    required int index,
    required List<WirePlayer> existingPlayers,
    String? displayName,
    String? requestedCountryId,
    bool ready = false,
  }) {
    final country = _countryForSeat(
      requestedCountryId: requestedCountryId,
      existingPlayers: existingPlayers,
      index: index,
    );
    return WirePlayer(
      id: 'player-${index + 1}-$userIdentifier',
      userId: userIdentifier,
      name: displayName?.trim().isNotEmpty == true
          ? displayName!.trim()
          : 'Player ${index + 1}',
      colorValue: _playerColors[index % _playerColors.length],
      country: country,
      kind: WirePlayerKind.human,
      connectionState: WirePlayerConnectionState.connected,
      ready: ready,
    );
  }

  PlayerCountry _countryForSeat({
    required String? requestedCountryId,
    required List<WirePlayer> existingPlayers,
    required int index,
  }) {
    final taken = existingPlayers.map((player) => player.country).toSet();
    final requested = countryFromId(requestedCountryId);
    if (requested != null) {
      if (taken.contains(requested)) {
        throw const PlayerSeatAllocationFailure(
          code: 'country_unavailable',
          message: 'Selected civilization is already taken.',
        );
      }
      return requested;
    }
    for (var offset = 0; offset < PlayerCountry.values.length; offset++) {
      final candidate =
          PlayerCountry.values[(index + offset) % PlayerCountry.values.length];
      if (!taken.contains(candidate)) return candidate;
    }
    throw const PlayerSeatAllocationFailure(
      code: 'country_unavailable',
      message: 'No civilization is available.',
    );
  }

  PlayerCountry? countryFromId(String? countryId) {
    final normalized = countryId?.trim();
    if (normalized == null || normalized.isEmpty) return null;
    for (final country in PlayerCountry.values) {
      if (country.name == normalized) return country;
    }
    throw const PlayerSeatAllocationFailure(
      code: 'country_unavailable',
      message: 'Selected civilization is unavailable.',
    );
  }
}

final class PlayerSeatAllocationFailure implements Exception {
  const PlayerSeatAllocationFailure({
    required this.code,
    required this.message,
  });

  final String code;
  final String message;

  @override
  String toString() => 'PlayerSeatAllocationFailure($code, $message)';
}

const _playerColors = [
  0xFFE53935,
  0xFF1E88E5,
  0xFF43A047,
  0xFFFDD835,
  0xFF8E24AA,
  0xFF00ACC1,
];
