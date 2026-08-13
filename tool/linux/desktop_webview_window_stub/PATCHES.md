# AoNW desktop webview compatibility shim

`serverpod_auth_idp_flutter` depends transitively on `flutter_web_auth_2`,
which in turn registers `desktop_webview_window` on Linux. That native plugin
links WebKitGTK into the main executable even though AoNW's desktop sign-in
flow uses `url_launcher` and server-side polling.

This package preserves the small public API needed to compile the transitive
dependency, reports that an embedded webview is unavailable, and deliberately
declares no native plugin. Remove the override when the upstream dependency can
be configured to use an external browser without registering WebKitGTK.
