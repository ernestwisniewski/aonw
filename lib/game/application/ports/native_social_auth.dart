/// Opaque bridge for native Serverpod social-auth widgets.
///
/// Presentation passes [clientHandle] back to the installed auth widget, but
/// neither application nor presentation depends on the generated client type.
abstract interface class NativeSocialAuthSession {
  Object get clientHandle;

  Object? get authSuccess;

  Future<void> initializeGoogle({String? clientId, String? serverClientId});

  Future<void> initializeApple({
    String? serviceIdentifier,
    String? redirectUri,
  });

  void close();
}

typedef NativeSocialAuthSessionFactory = NativeSocialAuthSession Function();
