enum NetworkConnectionStatus { connected, connecting, reconnecting, offline }

class NetworkConnectionState {
  final NetworkConnectionStatus status;
  final String? lastError;
  final DateTime? changedAt;

  const NetworkConnectionState({
    required this.status,
    this.lastError,
    this.changedAt,
  });

  static const offline = NetworkConnectionState(
    status: NetworkConnectionStatus.offline,
  );

  bool get isConnected => status == NetworkConnectionStatus.connected;

  NetworkConnectionState copyWith({
    NetworkConnectionStatus? status,
    String? lastError,
    DateTime? changedAt,
  }) {
    return NetworkConnectionState(
      status: status ?? this.status,
      lastError: lastError ?? this.lastError,
      changedAt: changedAt ?? this.changedAt,
    );
  }
}
