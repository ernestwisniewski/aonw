import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum HudMinimizedPopupKind {
  firstTurnCoachmarks,
  modeBanner,
  technologyDiscovery,
  diplomaticMessage,
  diplomaticProposal,
  autoTurnHint,
}

abstract final class HudMinimizedPopupIds {
  static String gamePrefix(String saveId) {
    return 'game.$saveId.';
  }

  static String firstTurnTutorial(String saveId) {
    return '${gamePrefix(saveId)}firstTurnTutorial';
  }

  static String modeBanner(String saveId, String specId) {
    return '${gamePrefix(saveId)}modeBanner.$specId';
  }

  static String technologyDiscovery(String saveId, String discoveryId) {
    return '${gamePrefix(saveId)}technologyDiscovery.$discoveryId';
  }

  static String diplomaticMessage(String saveId, String messageId) {
    return '${gamePrefix(saveId)}diplomaticMessage.$messageId';
  }

  static String diplomaticProposal(String saveId, String proposalId) {
    return '${gamePrefix(saveId)}diplomaticProposal.$proposalId';
  }

  static String autoTurnHint(String saveId) {
    return '${gamePrefix(saveId)}autoTurnHint';
  }
}

class HudMinimizedPopupEntry {
  final String id;
  final HudMinimizedPopupKind kind;
  final String title;
  final String subtitle;
  final Map<String, String> payload;

  const HudMinimizedPopupEntry({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    this.payload = const {},
  });

  bool belongsToSave(String saveId) {
    return id.startsWith(HudMinimizedPopupIds.gamePrefix(saveId));
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'title': title,
      'subtitle': subtitle,
      'payload': payload,
    };
  }

  static HudMinimizedPopupEntry? fromJson(Object? value) {
    if (value is! Map) return null;
    final id = value['id'];
    final kindName = value['kind'];
    final title = value['title'];
    final subtitle = value['subtitle'];
    if (id is! String ||
        kindName is! String ||
        title is! String ||
        subtitle is! String) {
      return null;
    }
    HudMinimizedPopupKind? kind;
    for (final candidate in HudMinimizedPopupKind.values) {
      if (candidate.name == kindName) {
        kind = candidate;
        break;
      }
    }
    if (kind == null) return null;
    final payloadValue = value['payload'];
    final payload = <String, String>{};
    if (payloadValue is Map) {
      for (final entry in payloadValue.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is String && value is String) payload[key] = value;
      }
    }
    return HudMinimizedPopupEntry(
      id: id,
      kind: kind,
      title: title,
      subtitle: subtitle,
      payload: payload,
    );
  }
}

class HudPopupRestoreRequest {
  final String popupId;
  final int sequence;
  final HudMinimizedPopupEntry? entry;

  const HudPopupRestoreRequest({
    required this.popupId,
    required this.sequence,
    this.entry,
  });
}

class HudPopupAttentionRequest {
  final String popupId;
  final int sequence;

  const HudPopupAttentionRequest({
    required this.popupId,
    required this.sequence,
  });
}

class HudMinimizedPopupsState {
  final bool loaded;
  final List<HudMinimizedPopupEntry> entries;
  final Map<String, List<HudMinimizedPopupEntry>> transientEntriesByScope;
  final HudPopupRestoreRequest? restoreRequest;
  final HudPopupAttentionRequest? attentionRequest;

  const HudMinimizedPopupsState({
    this.loaded = false,
    this.entries = const [],
    this.transientEntriesByScope = const {},
    this.restoreRequest,
    this.attentionRequest,
  });

  bool hasEntry(String id) => entries.any((entry) => entry.id == id);

  HudMinimizedPopupEntry? entryFor(String id) {
    for (final entry in entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  List<HudMinimizedPopupEntry> get transientEntries {
    return [
      for (final scopedEntries in transientEntriesByScope.values)
        ...scopedEntries,
    ];
  }

  List<HudMinimizedPopupEntry> entriesForSave(String saveId) {
    final byId = <String, HudMinimizedPopupEntry>{};
    for (final entry in entries) {
      if (entry.belongsToSave(saveId)) byId[entry.id] = entry;
    }
    for (final entry in transientEntries) {
      if (entry.belongsToSave(saveId)) byId[entry.id] = entry;
    }
    return byId.values.toList(growable: false);
  }

  HudMinimizedPopupsState copyWith({
    bool? loaded,
    List<HudMinimizedPopupEntry>? entries,
    Map<String, List<HudMinimizedPopupEntry>>? transientEntriesByScope,
    HudPopupRestoreRequest? restoreRequest,
    HudPopupAttentionRequest? attentionRequest,
  }) {
    return HudMinimizedPopupsState(
      loaded: loaded ?? this.loaded,
      entries: entries ?? this.entries,
      transientEntriesByScope:
          transientEntriesByScope ?? this.transientEntriesByScope,
      restoreRequest: restoreRequest ?? this.restoreRequest,
      attentionRequest: attentionRequest ?? this.attentionRequest,
    );
  }
}

final hudMinimizedPopupsProvider =
    NotifierProvider<HudMinimizedPopupsController, HudMinimizedPopupsState>(
      HudMinimizedPopupsController.new,
    );

class HudMinimizedPopupsController extends Notifier<HudMinimizedPopupsState> {
  static const preferenceKey = 'hud.minimized_popups.entries.v1';

  var _restoreSequence = 0;
  var _attentionSequence = 0;
  var _localMutationPending = false;

  @override
  HudMinimizedPopupsState build() {
    unawaited(_load());
    return const HudMinimizedPopupsState();
  }

  void minimize(HudMinimizedPopupEntry entry) {
    final entries = [...state.entries];
    final index = entries.indexWhere((candidate) => candidate.id == entry.id);
    if (index == -1) {
      entries.add(entry);
    } else {
      entries[index] = entry;
    }
    _setEntries(
      entries,
      attentionRequest: HudPopupAttentionRequest(
        popupId: entry.id,
        sequence: ++_attentionSequence,
      ),
    );
  }

  void removeWhere(bool Function(HudMinimizedPopupEntry entry) test) {
    final entries = state.entries
        .where((entry) => !test(entry))
        .toList(growable: false);
    if (entries.length == state.entries.length) return;
    _setEntries(entries);
  }

  void setTransientEntries(String scope, List<HudMinimizedPopupEntry> entries) {
    final next = Map<String, List<HudMinimizedPopupEntry>>.from(
      state.transientEntriesByScope,
    );
    final normalized = List<HudMinimizedPopupEntry>.unmodifiable(entries);
    if (normalized.isEmpty) {
      if (!next.containsKey(scope)) return;
      next.remove(scope);
    } else {
      final current = next[scope] ?? const <HudMinimizedPopupEntry>[];
      if (_entriesEqual(current, normalized)) return;
      next[scope] = normalized;
    }
    state = state.copyWith(transientEntriesByScope: Map.unmodifiable(next));
  }

  void requestRestore(String id) {
    if (!state.hasEntry(id)) return;
    _restoreSequence += 1;
    state = state.copyWith(
      restoreRequest: HudPopupRestoreRequest(
        popupId: id,
        sequence: _restoreSequence,
      ),
    );
  }

  void requestRestoreEntry(HudMinimizedPopupEntry entry) {
    _restoreSequence += 1;
    state = state.copyWith(
      restoreRequest: HudPopupRestoreRequest(
        popupId: entry.id,
        sequence: _restoreSequence,
        entry: entry,
      ),
    );
  }

  void _setEntries(
    List<HudMinimizedPopupEntry> entries, {
    HudPopupAttentionRequest? attentionRequest,
  }) {
    _localMutationPending = true;
    state = state.copyWith(
      loaded: true,
      entries: entries,
      attentionRequest: attentionRequest,
    );
    unawaited(_save(entries));
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || _localMutationPending) return;
      state = state.copyWith(
        loaded: true,
        entries: _decodeEntries(prefs.getString(preferenceKey)),
      );
    } on Object {
      if (!ref.mounted || _localMutationPending) return;
      state = state.copyWith(loaded: true);
    }
  }

  Future<void> _save(List<HudMinimizedPopupEntry> entries) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(preferenceKey, _encodeEntries(entries));
      _localMutationPending = false;
    } on Object {
      return;
    }
  }

  static String _encodeEntries(List<HudMinimizedPopupEntry> entries) {
    return jsonEncode([for (final entry in entries) entry.toJson()]);
  }

  static List<HudMinimizedPopupEntry> _decodeEntries(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      return [
        for (final value in decoded) ?HudMinimizedPopupEntry.fromJson(value),
      ];
    } on Object {
      return const [];
    }
  }

  static bool _entriesEqual(
    List<HudMinimizedPopupEntry> left,
    List<HudMinimizedPopupEntry> right,
  ) {
    if (left.length != right.length) return false;
    for (var i = 0; i < left.length; i++) {
      if (left[i].toJson().toString() != right[i].toJson().toString()) {
        return false;
      }
    }
    return true;
  }
}
