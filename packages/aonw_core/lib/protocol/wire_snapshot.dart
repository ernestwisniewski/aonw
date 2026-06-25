import 'package:aonw_core/protocol/protocol_version.dart';
import 'package:aonw_core/protocol/wire_json.dart';

class WireSnapshot {
  final int v;
  final String matchId;
  final int offset;
  final Map<String, dynamic> save;
  final Map<String, dynamic> state;

  const WireSnapshot({
    this.v = kProtocolVersion,
    required this.matchId,
    required this.offset,
    required this.save,
    required this.state,
  });

  factory WireSnapshot.fromJson(Map<String, dynamic> json) {
    return WireSnapshot(
      v: WireJson.readVersion(json, 'WireSnapshot'),
      matchId: WireJson.requiredString(json, 'WireSnapshot', 'matchId'),
      offset: WireJson.requiredInt(json, 'WireSnapshot', 'offset'),
      save: WireJson.requiredMap(json['save'], 'WireSnapshot.save'),
      state: WireJson.requiredMap(json['state'], 'WireSnapshot.state'),
    );
  }

  Map<String, dynamic> toJson() => {
    'v': v,
    'matchId': matchId,
    'offset': offset,
    'save': Map<String, dynamic>.from(save),
    'state': Map<String, dynamic>.from(state),
  };

  WireSnapshot copyWith({
    int? v,
    String? matchId,
    int? offset,
    Map<String, dynamic>? save,
    Map<String, dynamic>? state,
  }) {
    return WireSnapshot(
      v: v ?? this.v,
      matchId: matchId ?? this.matchId,
      offset: offset ?? this.offset,
      save: save ?? this.save,
      state: state ?? this.state,
    );
  }
}
