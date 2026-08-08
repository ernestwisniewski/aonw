# Linux Steam runtime

## Release contract

The supported Linux target is the x86-64 Steam Linux Runtime 4 (SLR4) selected
for the depot in Steamworks. Both CI images are pinned by digest:

- the SDK image is the build environment;
- the Platform image is the oldest allowed runtime contract.

`.github/workflows/linux-steam-build.yml` captures the Platform SONAME list,
builds in the SDK, and passes both to `tool/linux/package_steamrt4_bundle.sh`.
The packager preserves Flutter's directory structure and adds only dependencies
that the pinned Platform does not provide. It also includes the GStreamer
base/good plugins, scanner, GLib schemas, GTK theme data, license notices, and a
runtime manifest. `aonw` is a small launcher that scopes all library and plugin
paths to the application directory before starting `aonw-bin`.

The unused `libdartjni.so` generic native asset is removed. It is an Android JVM
bridge, is absent from the Linux native-assets manifest, and would otherwise add
an invalid `libjvm.so` dependency.

Desktop authentication uses the system browser. A Linux compatibility package
therefore keeps `desktop_webview_window` out of the native plugin registrant;
WebKitGTK is not part of the process startup contract.

## Automated acceptance gates

CI validates the exact ZIP uploaded as the build artifact:

1. every executable, shared library, and GStreamer plugin resolves under the
   pinned SLR4 Platform;
2. the executable has no WebKitGTK/JavaScriptCore dependency;
3. required audio plugins and compiled GLib schemas are present;
4. GStreamer decodes one shipped WAV and one shipped MP3 to a fake sink;
5. the app remains alive for 20 seconds under Xvfb with no `/dev/input` mounted.

The last check is a regression test for headless/container launches and systems
where joystick devices are temporarily unavailable. The local
`gamepads_linux` patch treats that state as “zero controllers” instead of
throwing from a detached native thread. Hotplug callbacks are marshalled to the
GTK main context and controller state is synchronized.

## Local build

The preferred entry point is:

```sh
make steam-linux STEAM_LINUX_SOURCE=github
```

For SDK debugging, first capture the contract on the Docker host:

```sh
make steam-runtime-contract
```

Mount the repository and contract into the pinned SDK, install the same packages
as the workflow, set `AONW_STEAMRT4_SDK=1`, and run:

```sh
make steam-linux-local AONW_STEAMRT4_SDK=1
```

`steam-linux-local` deliberately rejects a generic Linux host. Distribution
correctness depends on the pinned SDK/Platform pair, not on the developer
machine's Ubuntu version.

## Steamworks and physical Steam Deck acceptance

Select Steam Linux Runtime 4 for the Linux launch option/depot. Before promoting
a build, test the default stable SteamOS image in both Gaming Mode and Desktop
Mode:

- cold launch and menu navigation;
- Steam Deck built-in controls reported as Steam Virtual Gamepad;
- one external USB/Bluetooth controller, including hotplug after startup;
- menu click and music playback through speakers, headphones, and after an
  output-device change;
- suspend/resume, then controller input and audio again;
- desktop OAuth login and persisted session after restart.

Automated checks establish loader, decoder, and no-device behavior. They cannot
prove physical speaker routing, Steam Input configuration, Bluetooth firmware,
or the Steamworks controller template. Record the tested SteamOS client/build,
game build number, Steam Input template, and controller connection type with
the release result.

## Failure triage

- Startup loader errors: inspect `ldd` using
  `tool/linux/verify_steamrt4_bundle.sh`; do not add host-wide packages to the
  Steam Deck as a workaround.
- No audio: run with `GST_DEBUG=2`, confirm the bundled plugin paths printed by
  the launcher environment, and distinguish decode failure from output-device
  routing.
- No controller: compare `/dev/input/js*`, Steam Input template/mode, and the
  native log. Absence of `/dev/input` is supported and must not terminate the
  process.
- OAuth failure: inspect the external browser callback/polling flow; WebKitGTK
  is intentionally not loaded by the Linux executable.
