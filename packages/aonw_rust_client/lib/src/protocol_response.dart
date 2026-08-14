import 'package:aonw_rust_client/src/protocol_execution.dart';
import 'package:aonw_rust_client/src/protocol_json.dart';
import 'package:aonw_rust_client/src/protocol_query.dart';
import 'package:aonw_rust_client/src/protocol_values.dart';

sealed class AonwClientResponseBody {
  const AonwClientResponseBody();

  factory AonwClientResponseBody.fromJson(Object? source) {
    final value = readObject(source, 'success response');
    return switch (value['type']) {
      'capabilities' => AonwCapabilitiesResponse.fromJson(value),
      'sessionOpened' => AonwSessionOpenedResponse.fromJson(value),
      'sessionClosed' => AonwSessionClosedResponse.fromJson(value),
      'snapshot' => AonwSnapshotResponse.fromJson(value),
      'query' => AonwQueryResponse.fromJson(value),
      'command' => AonwCommandResponse.fromJson(value),
      'saveExported' => AonwSaveExportedResponse.fromJson(value),
      'saveOpened' => AonwSaveOpenedResponse.fromJson(value),
      'replayExported' => AonwReplayExportedResponse.fromJson(value),
      'replayVerified' => AonwReplayVerifiedResponse.fromJson(value),
      final Object? type => throw FormatException(
        'Unknown AoNW client response $type.',
      ),
    };
  }
}

final class AonwCapabilitiesResponse extends AonwClientResponseBody {
  const AonwCapabilitiesResponse({
    required this.behaviorVersion,
    required this.features,
  });

  factory AonwCapabilitiesResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'behaviorVersion',
      'features',
    }, 'capabilities response');
    return AonwCapabilitiesResponse(
      behaviorVersion: readUnsigned(
        value['behaviorVersion'],
        'behavior version',
      ),
      features: readList(
        value['features'],
        'client features',
        (item, _) => AonwClientFeature.fromJson(item),
      ),
    );
  }

  final int behaviorVersion;
  final List<AonwClientFeature> features;
}

final class AonwSessionOpenedResponse extends AonwClientResponseBody {
  const AonwSessionOpenedResponse(this.stamp);

  factory AonwSessionOpenedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'stamp'}, 'session opened response');
    return AonwSessionOpenedResponse(AonwSessionStamp.fromJson(value['stamp']));
  }

  final AonwSessionStamp stamp;
}

final class AonwSessionClosedResponse extends AonwClientResponseBody {
  const AonwSessionClosedResponse();

  factory AonwSessionClosedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type'}, 'session closed response');
    return const AonwSessionClosedResponse();
  }
}

final class AonwSnapshotResponse extends AonwClientResponseBody {
  const AonwSnapshotResponse(this.snapshot);

  factory AonwSnapshotResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'snapshot'}, 'snapshot response');
    return AonwSnapshotResponse(
      AonwPlayerViewSnapshot.fromJson(value['snapshot']),
    );
  }

  final AonwPlayerViewSnapshot snapshot;
}

final class AonwQueryResponse extends AonwClientResponseBody {
  const AonwQueryResponse(this.result);

  factory AonwQueryResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'result'}, 'query response');
    return AonwQueryResponse(AonwQueryResult.fromJson(value['result']));
  }

  final AonwQueryResult result;
}

final class AonwCommandResponse extends AonwClientResponseBody {
  const AonwCommandResponse(this.result);

  factory AonwCommandResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'result'}, 'command response');
    return AonwCommandResponse(AonwCommandResult.fromJson(value['result']));
  }

  final AonwCommandResult result;
}

final class AonwSaveExportedResponse extends AonwClientResponseBody {
  const AonwSaveExportedResponse(this.document);

  factory AonwSaveExportedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'document'}, 'save exported response');
    return AonwSaveExportedResponse(
      readString(value['document'], 'save document'),
    );
  }

  final String document;
}

final class AonwSaveOpenedResponse extends AonwClientResponseBody {
  const AonwSaveOpenedResponse(this.stamp);

  factory AonwSaveOpenedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'stamp'}, 'save opened response');
    return AonwSaveOpenedResponse(AonwSessionStamp.fromJson(value['stamp']));
  }

  final AonwSessionStamp stamp;
}

final class AonwReplayExportedResponse extends AonwClientResponseBody {
  const AonwReplayExportedResponse(this.document);

  factory AonwReplayExportedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {'type', 'document'}, 'replay exported response');
    return AonwReplayExportedResponse(
      readString(value['document'], 'replay document'),
    );
  }

  final String document;
}

final class AonwReplayVerifiedResponse extends AonwClientResponseBody {
  const AonwReplayVerifiedResponse(this.verification);

  factory AonwReplayVerifiedResponse.fromJson(Map<String, Object?> value) {
    requireKeys(value, const {
      'type',
      'verification',
    }, 'replay verified response');
    return AonwReplayVerifiedResponse(
      AonwReplayVerification.fromJson(value['verification']),
    );
  }

  final AonwReplayVerification verification;
}

final class AonwReplayVerification {
  const AonwReplayVerification({
    required this.entryCount,
    required this.finalEventOffset,
    required this.finalStamp,
  });

  factory AonwReplayVerification.fromJson(Object? source) {
    final value = readObject(source, 'replay verification');
    requireKeys(value, const {
      'entryCount',
      'finalEventOffset',
      'finalStamp',
    }, 'replay verification');
    return AonwReplayVerification(
      entryCount: readUnsigned(value['entryCount'], 'verified entry count'),
      finalEventOffset: readUnsigned(
        value['finalEventOffset'],
        'final event offset',
      ),
      finalStamp: AonwSessionStamp.fromJson(value['finalStamp']),
    );
  }

  final int entryCount;
  final int finalEventOffset;
  final AonwSessionStamp finalStamp;
}
