import 'package:freezed_annotation/freezed_annotation.dart';

part 'network_connection.freezed.dart';

enum NetworkConnectionStatus { connected, connecting, reconnecting, offline }

@freezed
abstract class NetworkConnectionState with _$NetworkConnectionState {
  const NetworkConnectionState._();

  const factory NetworkConnectionState({
    required NetworkConnectionStatus status,
    String? lastError,
    DateTime? changedAt,
  }) = _NetworkConnectionState;

  static const offline = NetworkConnectionState(
    status: NetworkConnectionStatus.offline,
  );

  bool get isConnected => status == NetworkConnectionStatus.connected;
}
