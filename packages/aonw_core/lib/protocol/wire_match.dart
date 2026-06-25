import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';
import 'package:aonw_core/protocol/wire_player.dart';

class WireMatch {
  final int v;
  final String id;
  final String ownerUserId;
  final String name;
  final String mapName;
  final List<WirePlayer> players;
  final int maxPlayers;
  final int minPlayers;
  final bool quickplay;
  final int turn;
  final String state;
  final DateTime createdAt;
  final DateTime? autoStartAt;
  final String? inviteCode;

  const WireMatch({
    this.v = kProtocolVersion,
    required this.id,
    required this.ownerUserId,
    required this.name,
    required this.mapName,
    required this.players,
    int? maxPlayers,
    int? minPlayers,
    this.quickplay = false,
    required this.turn,
    required this.state,
    required this.createdAt,
    this.autoStartAt,
    this.inviteCode,
  }) : maxPlayers = maxPlayers ?? players.length,
       minPlayers = minPlayers ?? maxPlayers ?? players.length;

  factory WireMatch.fromJson(Map<String, dynamic> json) {
    final rawPlayers = WireJson.requiredList(
      json['players'],
      'WireMatch.players',
    );
    return WireMatch(
      v: WireJson.readVersion(json, 'WireMatch'),
      id: WireJson.requiredString(json, 'WireMatch', 'id'),
      ownerUserId: WireJson.requiredString(json, 'WireMatch', 'ownerUserId'),
      name: WireJson.requiredString(json, 'WireMatch', 'name'),
      mapName: WireJson.requiredString(json, 'WireMatch', 'mapName'),
      players: rawPlayers
          .map(
            (player) => WirePlayer.fromJson(
              WireJson.requiredMap(player, 'WireMatch.players[]'),
            ),
          )
          .toList(),
      maxPlayers:
          WireJson.optionalInt(json, 'WireMatch', 'maxPlayers') ??
          rawPlayers.length,
      minPlayers:
          WireJson.optionalInt(json, 'WireMatch', 'minPlayers') ??
          WireJson.optionalInt(json, 'WireMatch', 'maxPlayers') ??
          rawPlayers.length,
      quickplay: WireJson.optionalBool(json, 'WireMatch', 'quickplay') ?? false,
      turn: WireJson.requiredInt(json, 'WireMatch', 'turn'),
      state: WireJson.requiredString(json, 'WireMatch', 'state'),
      createdAt: WireJson.requiredDateTimeUtc(json, 'WireMatch', 'createdAt'),
      autoStartAt: _optionalDateTimeUtc(json, 'autoStartAt'),
      inviteCode: WireJson.optionalString(json, 'WireMatch', 'inviteCode'),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'id': id,
    'ownerUserId': ownerUserId,
    'name': name,
    'mapName': mapName,
    'players': players.map((player) => player.toJson()).toList(),
    'maxPlayers': maxPlayers,
    'minPlayers': minPlayers,
    'quickplay': quickplay,
    'turn': turn,
    'state': state,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (autoStartAt != null)
      'autoStartAt': autoStartAt!.toUtc().toIso8601String(),
    if (inviteCode != null) 'inviteCode': inviteCode,
  };

  WireMatch copyWith({
    int? v,
    String? id,
    String? ownerUserId,
    String? name,
    String? mapName,
    List<WirePlayer>? players,
    int? maxPlayers,
    int? minPlayers,
    bool? quickplay,
    int? turn,
    String? state,
    DateTime? createdAt,
    Object? autoStartAt = _undefined,
    Object? inviteCode = _undefined,
  }) {
    return WireMatch(
      v: v ?? this.v,
      id: id ?? this.id,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      name: name ?? this.name,
      mapName: mapName ?? this.mapName,
      players: players ?? this.players,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      minPlayers: minPlayers ?? this.minPlayers,
      quickplay: quickplay ?? this.quickplay,
      turn: turn ?? this.turn,
      state: state ?? this.state,
      createdAt: createdAt ?? this.createdAt,
      autoStartAt: identical(autoStartAt, _undefined)
          ? this.autoStartAt
          : autoStartAt as DateTime?,
      inviteCode: identical(inviteCode, _undefined)
          ? this.inviteCode
          : inviteCode as String?,
    );
  }

  static DateTime? _optionalDateTimeUtc(
    Map<String, dynamic> json,
    String field,
  ) {
    final value = WireJson.optionalString(json, 'WireMatch', field);
    if (value == null) return null;
    return DateTime.parse(value).toUtc();
  }
}

const Object _undefined = Object();
