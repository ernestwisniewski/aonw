part of 'network_command_transport.dart';

class NetworkCommandRejectedException implements Exception {
  final int offset;
  final String? reason;

  const NetworkCommandRejectedException({
    required this.offset,
    required this.reason,
  });

  @override
  String toString() {
    return 'NetworkCommandRejectedException(offset: $offset, reason: $reason)';
  }
}

class NetworkCommandConflictException implements Exception {
  final String code;
  final int? nextTick;

  const NetworkCommandConflictException({required this.code, this.nextTick});

  @override
  String toString() {
    final suffix = nextTick == null ? '' : ', nextTick=$nextTick';
    return 'NetworkCommandConflictException(code: $code$suffix)';
  }
}
