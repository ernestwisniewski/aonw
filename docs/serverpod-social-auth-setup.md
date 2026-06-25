# Serverpod Social Auth Setup

This project uses Serverpod Auth Core for user sessions and Serverpod Auth IDP
for Google and Apple sign-in. Steam sign-in uses Steam OpenID and issues the
same Serverpod Auth tokens as the other providers.

Official references:

- Serverpod auth setup: https://docs.serverpod.dev/concepts/authentication/setup
- Google provider setup: https://docs.serverpod.dev/concepts/authentication/providers/google/setup
- Apple provider setup: https://docs.serverpod.dev/concepts/authentication/providers/apple/setup
- Working with users: https://docs.serverpod.dev/concepts/authentication/working-with-users
- Steam OpenID: https://steamcommunity.com/dev
- Serverpod custom routes: https://docs.serverpod.dev/concepts/webserver/routing

Before a release, confirm the Google Cloud Console, Apple Developer, and Steam
provider settings match the env names, callback paths, platform bundle IDs, and
client IDs documented here. Those provider-console settings live outside the
repo and can drift independently from source code.

## Serverpod

All secrets live in the environment (there is no `passwords.yaml`). Set them in
`.env` (see `.env.example`); Compose injects them and
`server/docker-entrypoint.sh` decodes the base64-encoded multi-line values.

1. Keep the existing JWT and email secrets (`SERVERPOD_PASSWORD_*`).
2. Set the downloaded Google Web OAuth client JSON, base64-encoded, in
   `AONW_GOOGLE_CLIENT_SECRET_B64` (for example `base64 -w0 client.json`).
3. Set the Apple fields:
   - `SERVERPOD_PASSWORD_appleServiceIdentifier`
   - `SERVERPOD_PASSWORD_appleBundleIdentifier`
   - `SERVERPOD_PASSWORD_appleRedirectUri`
   - `SERVERPOD_PASSWORD_appleTeamId`
   - `SERVERPOD_PASSWORD_appleKeyId`
   - `AONW_APPLE_KEY_B64` — the sign-in private key PEM, base64-encoded
   - `SERVERPOD_PASSWORD_appleAndroidPackageIdentifier` for Android
   - `SERVERPOD_PASSWORD_appleWebRedirectUri` for Flutter Web
4. Apply the new Serverpod migration before using social sign-in in a shared
   environment.

The server only enables Google and Apple providers when their required password
values are present, so local email/password development can still run without
OAuth secrets.

Steam does not require a server secret for identity-only OpenID sign-in, but the
callback route must be reachable from the browser:

```text
https://your-api-domain/auth/steam/callback
```

## Google

1. Create or select a Google Cloud project.
2. Enable Google Auth Platform and Google People API.
3. Configure the consent screen.
4. Add scopes:
   - `https://www.googleapis.com/auth/userinfo.email`
   - `https://www.googleapis.com/auth/userinfo.profile`
5. Create a Web OAuth client and paste the downloaded JSON into
   `googleClientSecret`. This Web client is the server-side OAuth client.
6. Create platform OAuth clients as needed:
   - Android: package name `aonw.net.game` and SHA-1 certificate fingerprint.
   - iOS: bundle ID `aonw.net.game`.
   - macOS: create an iOS OAuth client for bundle ID `aonw.net.game`.
   - Web: authorized JavaScript origins.

   Current Google OAuth client IDs:
   - Web/server: `421226196002-m0f4ncq3o59uc0vvpj0lniuq99os9bbg.apps.googleusercontent.com`
   - Android: `421226196002-jf8m41ra0hiukmlg4u0aum9ne8u49n05.apps.googleusercontent.com`
     - Package name: `aonw.net.game`
     - Production SHA-1: `D7:B6:69:3A:97:2A:9B:66:C8:49:A7:72:41:37:1B:05:ED:6D:26:86`
   - iOS/macOS: `421226196002-kts2aank920f811rvbggu8n4f4sqdn4a.apps.googleusercontent.com`

7. For Flutter builds, pass Google IDs when the platform needs them. The
   `GOOGLE_SERVER_CLIENT_ID` should be the Web OAuth client ID.

```sh
flutter run \
  --dart-define=GOOGLE_CLIENT_ID=your-client-id.apps.googleusercontent.com \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=your-web-client-id.apps.googleusercontent.com
```

For Android, do not pass the Android OAuth client as `GOOGLE_CLIENT_ID`.
Android uses the registered package name and SHA-1 fingerprint, while
`GOOGLE_SERVER_CLIENT_ID` remains the Web OAuth client ID:

```sh
flutter run -d android \
  --dart-define=GOOGLE_SERVER_CLIENT_ID=421226196002-m0f4ncq3o59uc0vvpj0lniuq99os9bbg.apps.googleusercontent.com
```

8. For Web, keep `web/index.html` in sync with the Web OAuth client:

```html
<meta name="google-signin-client_id" content="your-web-client-id.apps.googleusercontent.com">
```

Add every web origin used by the Flutter app to the Web OAuth client's
Authorized JavaScript origins, for example:

- `http://localhost:7357` for local Flutter Web.
- `https://your-web-domain` for production web builds.

Run local Flutter Web on a stable port:

```sh
flutter run -d chrome --web-hostname localhost --web-port 7357
```

9. For iOS/macOS Google Sign-In, native configuration is also required:
   - Add `GIDClientID` with the platform client ID.
   - Add `GIDServerClientID` with the Web OAuth client ID.
   - Add `CFBundleURLTypes` using the platform `REVERSED_CLIENT_ID`.
   - On macOS, keep `keychain-access-groups` in the app entitlements.

Example macOS `macos/Runner/Info.plist` values after creating the macOS/iOS
OAuth client:

```xml
<key>GIDClientID</key>
<string>your-macos-client-id.apps.googleusercontent.com</string>
<key>GIDServerClientID</key>
<string>your-web-client-id.apps.googleusercontent.com</string>
<key>CFBundleURLTypes</key>
<array>
	<dict>
		<key>CFBundleTypeRole</key>
		<string>Editor</string>
		<key>CFBundleURLSchemes</key>
		<array>
			<string>your-reversed-macos-client-id</string>
		</array>
	</dict>
</array>
```

The current iOS and macOS bundle ID is `aonw.net.game`, and the matching Google
iOS OAuth client is configured in both `ios/Runner/Info.plist` and
`macos/Runner/Info.plist`.

Because macOS Google Sign-In uses Keychain Sharing, the macOS Runner target
must be signed with an Apple Development certificate and a Mac App Development
provisioning profile for `aonw.net.game`. If Xcode cannot generate the profile,
accept the latest Apple Developer Program License Agreement and then let Xcode
update signing once:

```sh
xcodebuild \
  -workspace macos/Runner.xcworkspace \
  -scheme Runner \
  -configuration Debug \
  -allowProvisioningUpdates \
  DEVELOPMENT_TEAM=H64KBQ6T2S \
  CODE_SIGN_STYLE=Automatic \
  build
```

## Apple

1. Use an Apple Developer Program account.
2. Enable Sign in with Apple on the App ID.
3. Create a Services ID for Android/Web flows.
4. Create a Sign in with Apple private key.
5. Set the Apple callback URL to the Serverpod route:

```text
https://your-api-domain/auth/apple/callback
```

6. Put the IDs in `.env` as `SERVERPOD_PASSWORD_apple*` and the private key,
   base64-encoded, in `AONW_APPLE_KEY_B64`.
7. For Android, the `signinwithapple` callback activity is already declared in
   `android/app/src/main/AndroidManifest.xml`.
8. For iOS/macOS, enable the Sign in with Apple capability in Xcode.
9. For Android/Web Flutter builds, pass:

```sh
flutter run \
  --dart-define=APPLE_SERVICE_IDENTIFIER=your.service.id \
  --dart-define=APPLE_REDIRECT_URI=https://your-api-domain/auth/apple/callback
```

Apple requires HTTPS for the web callback. For local testing, use an HTTPS
tunnel or a development domain with TLS.

## Steam

Steam sign-in is intended for desktop builds, including Steam distribution on
macOS, Windows, and Linux.

1. Make sure the Serverpod web server public host points to the public API
   domain used by players.
2. Expose the Steam callback route:

```text
https://your-api-domain/auth/steam/callback
```

3. Run the Serverpod migration that adds:
   - `aonw_steam_account`
   - `aonw_steam_auth_request`
4. No social sign-in secret is required for Steam OpenID.
5. The Flutter desktop app opens Steam in the system browser and polls the
   server for the completed authentication request.

For production AONW, the expected callback is:

```text
https://api.aonw.net/auth/steam/callback
```

Steam OpenID returns a 64-bit Steam ID. If we later need richer Steam profile
data, ownership checks, or Steamworks session tickets inside the Steam runtime,
add the Steam Web API key or Steamworks ticket verification as a separate
authorization step.

## User Data Model

Serverpod `AuthUser` and `UserProfile` are now the base auth identity/profile
records. The game still keeps `AonwAccount` as domain-specific multiplayer
profile data related to `AuthUser`, which matches Serverpod's recommended
pattern for app-specific user data. Steam identities are stored separately in
`SteamAccount` and linked to `AuthUser`.
