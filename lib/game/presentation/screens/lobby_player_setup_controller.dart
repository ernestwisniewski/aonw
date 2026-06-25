import 'package:aonw/game/presentation/screens/new_game_flow.dart';
import 'package:aonw_core/ai.dart';
import 'package:aonw_core/game/domain/player.dart';
import 'package:flutter/material.dart';

typedef LobbyPlayerNameResolver =
    String Function(int zeroBasedIndex, PlayerCountry country);

final class LobbyPlayerSetupController {
  LobbyPlayerSetupController({
    required this.flow,
    required PlayerCountry primaryCountry,
    int? maximumPlayers,
  }) {
    _maximumPlayers = maximumPlayers ?? defaultMaximumPlayers;
    final initialPlayerCount = flow == NewGameFlow.singlePlayer
        ? NewGameFlowX.singlePlayerPlayerCount
              .clamp(minimumPlayers, _maximumPlayers)
              .toInt()
        : minimumPlayers;
    for (var index = 0; index < initialPlayerCount; index++) {
      _nameControllers.add(TextEditingController());
      _kinds.add(_defaultKindFor(index));
      _countries.add(index == 0 ? primaryCountry : _defaultCountryFor(index));
    }
  }

  static const minimumPlayers = 2;
  static const defaultMaximumPlayers = 4;

  final NewGameFlow flow;
  final List<TextEditingController> _nameControllers = [];
  final List<PlayerCountry> _countries = [];
  final List<PlayerKind> _kinds = [];
  late int _maximumPlayers;

  int get playerCount => _nameControllers.length;

  int get maximumPlayers => _maximumPlayers;

  bool get canEditPlayerKinds => !flow.locksAiOpponent;

  bool get canAddPlayers => flow != NewGameFlow.singlePlayer;

  bool get canStartLocalGame =>
      flow.startsLocally &&
      playerCount >= minimumPlayers &&
      playerCount <= maximumPlayers &&
      _nameControllers.first.text.trim().isNotEmpty;

  TextEditingController nameControllerAt(int index) => _nameControllers[index];

  PlayerCountry countryAt(int index) => _countries[index];

  PlayerKind kindAt(int index) => _kinds[index];

  void applyLocalizedDefaults(LobbyPlayerNameResolver nameFor) {
    for (var index = 0; index < playerCount; index++) {
      _nameControllers[index].text = defaultNameFor(index, nameFor);
    }
  }

  String defaultNameFor(int zeroBasedIndex, LobbyPlayerNameResolver nameFor) {
    return nameFor(zeroBasedIndex, _countries[zeroBasedIndex]);
  }

  bool addPlayer(LobbyPlayerNameResolver nameFor) {
    if (!canAddPlayers || playerCount >= maximumPlayers) return false;
    final index = playerCount;
    final country = _defaultCountryFor(index);
    _nameControllers.add(TextEditingController(text: nameFor(index, country)));
    _countries.add(country);
    _kinds.add(_defaultKindFor(index));
    return true;
  }

  bool updateMaximumPlayers(int maximumPlayers) {
    final nextMaximum = maximumPlayers < minimumPlayers
        ? minimumPlayers
        : maximumPlayers;
    if (_maximumPlayers == nextMaximum) return false;
    _maximumPlayers = nextMaximum;
    while (playerCount > _maximumPlayers) {
      _nameControllers.removeLast().dispose();
      _countries.removeLast();
      _kinds.removeLast();
    }
    return true;
  }

  bool removePlayer(int index) {
    if (!canAddPlayers || index == 0 || playerCount <= minimumPlayers) {
      return false;
    }
    _nameControllers.removeAt(index).dispose();
    _countries.removeAt(index);
    _kinds.removeAt(index);
    return true;
  }

  bool setKind(int index, PlayerKind kind) {
    if (!canEditPlayerKinds || index == 0 || _kinds[index] == kind) {
      return false;
    }
    _kinds[index] = kind;
    return true;
  }

  bool setCountry(
    int index,
    PlayerCountry country,
    LobbyPlayerNameResolver nameFor,
  ) {
    if (_countries[index] == country ||
        isCountryTakenByOtherPlayer(index, country)) {
      return false;
    }
    _countries[index] = country;
    if (flow == NewGameFlow.singlePlayer) {
      _nameControllers[index].text = nameFor(index, country);
    }
    return true;
  }

  bool isCountryTakenByOtherPlayer(int index, PlayerCountry country) {
    for (var otherIndex = 0; otherIndex < _countries.length; otherIndex++) {
      if (otherIndex != index && _countries[otherIndex] == country) {
        return true;
      }
    }
    return false;
  }

  List<PlayerCountry> countryOptionsFor(int index) {
    return [
      for (final country in PlayerCountry.values)
        if (country == _countries[index] ||
            !isCountryTakenByOtherPlayer(index, country))
          country,
    ];
  }

  List<Player> buildPlayers(LobbyPlayerNameResolver nameFor) {
    return List<Player>.generate(playerCount, (index) {
      final base = Player.forIndex(index);
      final name = _nameControllers[index].text.trim();
      return Player(
        id: base.id,
        name: name.isEmpty ? defaultNameFor(index, nameFor) : name,
        colorValue: base.colorValue,
        country: _countries[index],
        kind: _kinds[index],
        ai: _aiPlayerFor(index),
      );
    });
  }

  void dispose() {
    for (final controller in _nameControllers) {
      controller.dispose();
    }
  }

  PlayerCountry _defaultCountryFor(int zeroBasedIndex) {
    return PlayerCountry.values[zeroBasedIndex % PlayerCountry.values.length];
  }

  PlayerKind _defaultKindFor(int zeroBasedIndex) {
    if (zeroBasedIndex == 0) return PlayerKind.human;
    return flow.locksAiOpponent ? PlayerKind.ai : PlayerKind.human;
  }

  AiPlayer? _aiPlayerFor(int index) {
    if (_kinds[index] != PlayerKind.ai) return null;
    return AiPlayer(
      strategyId: AiStrategyId.mcts,
      difficulty: AiDifficulty.normal,
      persona: AiPersona.balanced,
      seed: 1000 + index,
    );
  }
}
