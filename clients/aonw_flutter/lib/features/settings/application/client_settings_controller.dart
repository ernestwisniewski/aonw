import 'package:flutter/foundation.dart';

import 'client_settings.dart';
import 'client_settings_store.dart';

final class ClientSettingsController extends ChangeNotifier {
  ClientSettingsController({required ClientSettingsStore store})
    : _store = store;

  factory ClientSettingsController.ephemeral() =>
      ClientSettingsController(store: _EphemeralClientSettingsStore());

  final ClientSettingsStore _store;
  ClientSettings _settings = ClientSettings.defaults;
  Future<void> _writeTail = Future<void>.value();
  int _generation = 0;
  bool _disposed = false;

  ClientSettings get settings => _settings;

  Future<void> load() async {
    final generation = _generation;
    final loaded = await _store.load();
    if (_disposed || generation != _generation || loaded == _settings) return;
    _settings = loaded;
    notifyListeners();
  }

  Future<void> update(ClientSettings settings) async {
    if (_disposed || settings == _settings) return;
    _generation += 1;
    _settings = settings;
    notifyListeners();
    final write = _writeTail.then((_) => _store.save(settings));
    _writeTail = write.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    await write;
  }

  Future<void> reset() => update(ClientSettings.defaults);

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

final class _EphemeralClientSettingsStore implements ClientSettingsStore {
  var _settings = ClientSettings.defaults;

  @override
  Future<ClientSettings> load() async => _settings;

  @override
  Future<void> save(ClientSettings settings) async {
    _settings = settings;
  }
}
