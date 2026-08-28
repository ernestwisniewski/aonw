import 'dart:convert';
import 'dart:io';

import 'package:aonw_flutter/features/local_game/application/local_game_catalog.dart';
import 'package:aonw_flutter/features/local_game/application/local_game_session_port.dart';
import 'package:aonw_flutter/features/map/infrastructure/rust_game_session_gateway.dart';
import 'package:aonw_flutter/features/save_game/application/game_save_session_port.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'rejects invalid native saves without replacing the retained session',
    () async {
      final gateway = RustGameSessionGateway(assets: _FileAssetBundle());
      addTearDown(gateway.close);
      final assets = LocalGameCatalog.entries.first.assets;
      final initial = await gateway.startLocalMatch(_setup());
      final save = await gateway.exportSaveDocument();
      final mismatch = jsonDecode(save) as Map<String, dynamic>;
      mismatch['mapHash'] = 'f' * 64;

      for (final rejected in [
        save.substring(0, save.length ~/ 2),
        jsonEncode(mismatch),
      ]) {
        await expectLater(
          gateway.openSaveDocument(assets: assets, document: rejected),
          throwsA(isA<GameSaveSessionException>()),
        );
        expect(await gateway.exportSaveDocument(), save);
      }

      final restored = await gateway.openSaveDocument(
        assets: assets,
        document: save,
      );
      expect(restored.player.stamp.revision, initial.player.stamp.revision);
      expect(
        restored.player.stamp.stateDigest,
        initial.player.stamp.stateDigest,
      );
      expect(restored.player.stamp.mapHash, initial.player.stamp.mapHash);
      expect(
        restored.player.stamp.rulesetHash,
        initial.player.stamp.rulesetHash,
      );
      expect(await gateway.exportSaveDocument(), save);
    },
  );
}

LocalMatchSetupView _setup() => LocalMatchSetupView(
  assets: LocalGameCatalog.entries.first.assets,
  participants: [
    LocalParticipantSetupView(
      id: 'player-1',
      name: 'Player',
      colorValue: 0xff3d5a80,
      country: LocalPlayerCountryView.poland,
      control: LocalPlayerControlView.human,
    ),
    LocalParticipantSetupView(
      id: 'player-2',
      name: 'AI',
      colorValue: 0xffee6c4d,
      country: LocalPlayerCountryView.japan,
      control: LocalPlayerControlView.ai,
      ai: const LocalAiProfileView(seed: 42),
    ),
  ],
  fogEnabled: false,
);

final class _FileAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final bytes = await File(key).readAsBytes();
    return ByteData.sublistView(Uint8List.fromList(bytes));
  }
}
