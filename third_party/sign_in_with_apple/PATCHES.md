# sign_in_with_apple local patch

This directory vendors `sign_in_with_apple` 7.0.1 because
`serverpod_auth_idp_flutter` 3.4.10 constrains the package to 7.x.

Local change:
- Add the Swift 6.2 `ASAuthorizationError.Code` cases already present
  upstream in `sign_in_with_apple` 8.1.0, while keeping the 7.x Dart API
  required by Serverpod.

Remove this override once Serverpod accepts `sign_in_with_apple` 8.x.
