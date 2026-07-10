part of 'matchmaking_service.dart';

const _inviteCodeAllocationAttempts = 16;

extension MatchmakingServiceCreation on MatchmakingService {
  Future<WireMatch> createMatch({
    required MultiplayerMatchStore store,
    required String userIdentifier,
    String? displayName,
    required CreateMatchRequest request,
  }) async {
    final validatedRequest = _requestValidator.validate(request);
    if (!validatedRequest.private) {
      return store.transaction((txStore) {
        return _createMatch(
          store: txStore,
          userIdentifier: userIdentifier,
          displayName: displayName,
          request: validatedRequest,
        );
      });
    }

    for (var attempt = 0; attempt < _inviteCodeAllocationAttempts; attempt++) {
      final inviteCode = _inviteCodeGenerator.generate();
      if (!SecureInviteCodeGenerator.isValid(inviteCode)) {
        throw StateError('Invite code generator returned an invalid code.');
      }
      try {
        return await store.transaction((txStore) async {
          final existing = await txStore.findPrivateState(inviteCode);
          if (existing != null) throw const InviteCodeConflictException();
          return _createMatch(
            store: txStore,
            userIdentifier: userIdentifier,
            displayName: displayName,
            request: validatedRequest,
            inviteCode: inviteCode,
          );
        });
      } on InviteCodeConflictException {
        continue;
      }
    }

    throw multiplayerException(
      'invite_code_unavailable',
      'Could not allocate a private match invite code.',
    );
  }
}
