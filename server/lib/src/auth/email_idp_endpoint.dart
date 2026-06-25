import 'package:serverpod/serverpod.dart';
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as auth_core;

import '../generated/protocol.dart';

/// Email/password account endpoint backed by Serverpod Auth Core.
class EmailIdpEndpoint extends Endpoint {
  static const _authMethod = 'email';
  static const _hashSaltLength = 16;

  @unauthenticatedClientCall
  Future<auth_core.AuthSuccess> login(
    Session session, {
    required String email,
    required String password,
  }) async {
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.email.equals(_normalizeEmail(email)),
    );
    if (account == null ||
        account.passwordHash.isEmpty ||
        !await _hashUtil().validateHashFromString(
          secret: password,
          hashString: account.passwordHash,
        )) {
      throw _authError('invalid_credentials', 'Invalid email or password.');
    }

    return auth_core.AuthServices.instance.tokenManager.issueToken(
      session,
      authUserId: account.authUserId,
      method: _authMethod,
    );
  }

  @unauthenticatedClientCall
  Future<auth_core.AuthSuccess> createAccount(
    Session session, {
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      throw _authError('invalid_email', 'Email address is invalid.');
    }
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    _validateDisplayName(normalizedDisplayName);
    final displayNameKey = _displayNameKey(normalizedDisplayName);
    if (password.length < 8) {
      throw _authError(
        'weak_password',
        'Password must be at least 8 characters long.',
      );
    }

    final passwordHash = await _hashUtil().createHashFromString(
      secret: password,
    );
    return session.db.transaction((transaction) async {
      final existing = await AonwAccount.db.findFirstRow(
        session,
        where: (table) => table.email.equals(normalized),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (existing != null) {
        throw _authError('account_exists', 'Account already exists.');
      }
      final existingDisplayName = await AonwAccount.db.findFirstRow(
        session,
        where: (table) => table.displayNameKey.equals(displayNameKey),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (existingDisplayName != null) {
        throw _authError(
          'display_name_taken',
          'This nickname is already taken.',
        );
      }

      final authUser = await auth_core.AuthServices.instance.authUsers.create(
        session,
        transaction: transaction,
      );
      await auth_core.AuthServices.instance.userProfiles.createUserProfile(
        session,
        authUser.id,
        auth_core.UserProfileData(
          userName: normalizedDisplayName,
          fullName: normalizedDisplayName,
          email: normalized,
        ),
        transaction: transaction,
      );
      await AonwAccount.db.insertRow(
        session,
        AonwAccount(
          authUserId: authUser.id,
          email: normalized,
          displayName: normalizedDisplayName,
          displayNameKey: displayNameKey,
          passwordHash: passwordHash,
          createdAt: DateTime.now().toUtc(),
        ),
        transaction: transaction,
      );
      return auth_core.AuthServices.instance.tokenManager.issueToken(
        session,
        authUserId: authUser.id,
        method: _authMethod,
        transaction: transaction,
      );
    });
  }

  Future<String> displayName(Session session) async {
    final account = await _requireAccount(session);
    return account.displayName;
  }

  Future<String> updateDisplayName(
    Session session, {
    required String displayName,
  }) async {
    final user = _requireUser(session);
    final normalizedDisplayName = _normalizeDisplayName(displayName);
    _validateDisplayName(normalizedDisplayName);
    final displayNameKey = _displayNameKey(normalizedDisplayName);
    return session.db.transaction((transaction) async {
      final account = await _requireAccountForUser(
        session,
        user,
        transaction: transaction,
        lock: true,
      );
      final existing = await AonwAccount.db.findFirstRow(
        session,
        where: (table) => table.displayNameKey.equals(displayNameKey),
        transaction: transaction,
        lockMode: LockMode.forUpdate,
        lockBehavior: LockBehavior.wait,
      );
      if (existing != null && existing.authUserId != account.authUserId) {
        throw _authError(
          'display_name_taken',
          'This nickname is already taken.',
        );
      }
      final updated = await AonwAccount.db.updateRow(
        session,
        account.copyWith(
          displayName: normalizedDisplayName,
          displayNameKey: displayNameKey,
        ),
        transaction: transaction,
      );
      await _syncUserProfileDisplayName(
        session,
        account: updated,
        transaction: transaction,
      );
      return updated.displayName;
    });
  }

  Future<bool> hasAccount(Session session) async {
    final user = session.authenticated;
    if (user == null) return false;
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(_authUserId(user)),
    );
    return account != null;
  }

  Future<AonwAccount> _requireAccount(Session session) async {
    final user = _requireUser(session);
    return _requireAccountForUser(session, user);
  }

  Future<AonwAccount> _requireAccountForUser(
    Session session,
    AuthenticationInfo user, {
    Transaction? transaction,
    bool lock = false,
  }) async {
    final account = await AonwAccount.db.findFirstRow(
      session,
      where: (table) => table.authUserId.equals(user.authUserId),
      transaction: transaction,
      lockMode: lock ? LockMode.forUpdate : null,
      lockBehavior: lock ? LockBehavior.wait : null,
    );
    if (account == null) {
      throw _authError('account_not_found', 'Account not found.');
    }
    return account;
  }

  AuthenticationInfo _requireUser(Session session) {
    final user = session.authenticated;
    if (user == null) {
      throw _authError('auth_required', 'Authentication is required.');
    }
    return user;
  }

  auth_core.Argon2HashUtil _hashUtil() {
    const key = 'emailSecretHashPepper';
    final hashPepper = Serverpod.instance.getPassword(key);
    if (hashPepper == null) {
      throw auth_core.PasswordNotFoundException(key);
    }
    return auth_core.Argon2HashUtil(
      hashPepper: hashPepper,
      hashSaltLength: _hashSaltLength,
    );
  }

  Future<void> _syncUserProfileDisplayName(
    Session session, {
    required AonwAccount account,
    required Transaction transaction,
  }) async {
    final userProfiles = auth_core.AuthServices.instance.userProfiles;
    final profile = await userProfiles.maybeFindUserProfileByUserId(
      session,
      account.authUserId,
      transaction: transaction,
    );
    if (profile == null) {
      await userProfiles.createUserProfile(
        session,
        account.authUserId,
        auth_core.UserProfileData(
          userName: account.displayName,
          fullName: account.displayName,
          email: account.email,
        ),
        transaction: transaction,
      );
      return;
    }

    await userProfiles.changeUserName(
      session,
      account.authUserId,
      account.displayName,
      transaction: transaction,
    );
  }

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  UuidValue _authUserId(AuthenticationInfo user) {
    return UuidValue.withValidation(user.userIdentifier);
  }

  String _normalizeDisplayName(String displayName) {
    return displayName.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  String _displayNameKey(String displayName) {
    return _normalizeDisplayName(displayName).toLowerCase();
  }

  void _validateDisplayName(String displayName) {
    if (displayName.length < 3 || displayName.length > 24) {
      throw _authError(
        'invalid_display_name',
        'Nickname must be 3-24 characters long.',
      );
    }
    final valid = RegExp(
      r'^[\p{L}\p{N} _-]+$',
      unicode: true,
    ).hasMatch(displayName);
    if (!valid) {
      throw _authError(
        'invalid_display_name',
        'Nickname can contain letters, numbers, spaces, underscores, or hyphens.',
      );
    }
  }

  AccountAuthException _authError(String code, String message) {
    return AccountAuthException(code: code, message: message);
  }
}
