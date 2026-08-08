#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 BUNDLE_DIR" >&2
  exit 64
fi

bundle_dir=$(realpath "$1")
if [[ ! -x "$bundle_dir/aonw" || ! -x "$bundle_dir/aonw-bin" ]]; then
  echo "Bundle must contain executable aonw and aonw-bin files." >&2
  exit 66
fi
if [[ -e "$bundle_dir/lib/libdartjni.so" ]]; then
  echo "The Linux bundle contains the unused Android JVM bridge." >&2
  exit 1
fi

export LD_LIBRARY_PATH="$bundle_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GST_PLUGIN_PATH_1_0="$bundle_dir/lib/gstreamer-1.0"
export GST_PLUGIN_SYSTEM_PATH_1_0="$bundle_dir/lib/gstreamer-1.0"
export GST_PLUGIN_SCANNER_1_0="$bundle_dir/libexec/gstreamer-1.0/gst-plugin-scanner"
export GSETTINGS_SCHEMA_DIR="$bundle_dir/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$bundle_dir/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

failed=0
while IFS= read -r binary; do
  if ldd "$binary" | grep -F 'not found'; then
    echo "Unresolved runtime dependency in $binary" >&2
    failed=1
  fi
done < <(
  find "$bundle_dir" -type f \
    \( -name 'aonw-bin' -o -name '*.so' -o -name '*.so.*' \
       -o -name 'gst-plugin-scanner' \) -print
)
(( failed == 0 )) || exit 1

if ldd "$bundle_dir/aonw-bin" | grep -Eiq 'webkit2gtk|javascriptcoregtk'; then
  echo "The release executable still links the unused embedded WebKit backend." >&2
  exit 1
fi

required_audio_plugins=(
  libgstaudiofx.so
  libgstautodetect.so
  libgstcoreelements.so
  libgstmpg123.so
  libgstplayback.so
  libgstpulseaudio.so
  libgsttypefindfunctions.so
  libgstwavparse.so
)
for plugin in "${required_audio_plugins[@]}"; do
  test -f "$bundle_dir/lib/gstreamer-1.0/$plugin" || {
    echo "Missing required audio plugin: $plugin" >&2
    exit 1
  }
done

test -s "$bundle_dir/STEAM_RUNTIME_MANIFEST.txt"
test -s "$bundle_dir/share/glib-2.0/schemas/gschemas.compiled"
echo "Steam Runtime 4 bundle dependency closure is valid."
