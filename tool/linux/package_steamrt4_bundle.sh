#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 RELEASE_DIR OUTPUT_DIR PLATFORM_SONAMES" >&2
  exit 64
fi

release_dir=$(realpath "$1")
output_dir=$(realpath -m "$2")
platform_sonames=$(realpath "$3")

if [[ ! -x "$release_dir/aonw" ]]; then
  echo "Expected an executable at $release_dir/aonw" >&2
  exit 66
fi
if [[ ! -s "$platform_sonames" ]]; then
  echo "Steam Runtime platform SONAME inventory is empty: $platform_sonames" >&2
  exit 66
fi
case "$output_dir" in
  /|.|"$release_dir")
    echo "Refusing unsafe output directory: $output_dir" >&2
    exit 64
    ;;
esac

for command in cp dpkg-query find glib-compile-schemas ldd realpath; do
  command -v "$command" >/dev/null || {
    echo "Required packaging command is unavailable: $command" >&2
    exit 69
  }
done

rm -rf "$output_dir"
mkdir -p "$output_dir"
cp -a "$release_dir/." "$output_dir/"
mv "$output_dir/aonw" "$output_dir/aonw-bin"
# jni_flutter contributes an Android JVM bridge to the generic native-assets
# bundle even though the Linux manifest has no JNI asset. Keeping it would add
# an impossible libjvm.so dependency to an otherwise closed desktop bundle.
rm -f "$output_dir/lib/libdartjni.so"
mkdir -p \
  "$output_dir/lib/gstreamer-1.0" \
  "$output_dir/libexec/gstreamer-1.0" \
  "$output_dir/licenses" \
  "$output_dir/share/glib-2.0/schemas"

declare -A queued=()
declare -a queue=()
declare -A bundled_packages=()

enqueue() {
  local path=$1
  path=$(readlink -f "$path")
  if [[ -z ${queued[$path]+set} ]]; then
    queued[$path]=1
    queue+=("$path")
  fi
}

record_package() {
  local path=$1
  local owner
  owner=$(dpkg-query -S "$(readlink -f "$path")" 2>/dev/null | head -n 1 | cut -d: -f1 || true)
  if [[ -n "$owner" ]]; then
    bundled_packages[$owner]=1
  fi
}

record_tree_package() {
  local root=$1
  local representative
  if [[ -f "$root/index.theme" ]]; then
    representative="$root/index.theme"
  else
    representative=$(find "$root" -type f -print -quit)
  fi
  if [[ -n "$representative" ]]; then
    record_package "$representative"
  fi
}

platform_provides() {
  grep -Fqx "$1" "$platform_sonames"
}

capture_dependency() {
  local soname=$1
  local source=$2
  local destination="$output_dir/lib/$soname"

  if platform_provides "$soname"; then
    return
  fi
  if [[ ! -e "$source" ]]; then
    echo "Cannot resolve required library $soname ($source)" >&2
    exit 1
  fi
  if [[ ! -e "$destination" ]]; then
    cp -L --preserve=mode,timestamps "$source" "$destination"
    chmod u+w "$destination"
    record_package "$source"
  fi
  enqueue "$source"
}

capture_elf_dependencies() {
  local binary=$1
  local line soname source
  while IFS='|' read -r soname source; do
    [[ -n "$soname" && -n "$source" ]] || continue
    capture_dependency "$soname" "$source"
  done < <(
    LD_LIBRARY_PATH="$output_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      ldd "$binary" | awk '
        $2 == "=>" && $3 ~ /^\// { print $1 "|" $3 }
        $1 ~ /^\// { name=$1; sub(/^.*\//, "", name); print name "|" $1 }
      '
  )

  if LD_LIBRARY_PATH="$output_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      ldd "$binary" | grep -Fq 'not found'; then
    echo "Unresolved dependency while packaging $binary" >&2
    LD_LIBRARY_PATH="$output_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}" \
      ldd "$binary" >&2
    exit 1
  fi
}

for binary in "$output_dir/aonw-bin" "$output_dir"/lib/*.so; do
  [[ -f "$binary" ]] && enqueue "$binary"
done

gstreamer_packages=(
  libgstreamer1.0-0
  gstreamer1.0-plugins-base
  gstreamer1.0-plugins-good
)
for package in "${gstreamer_packages[@]}"; do
  dpkg-query -W "$package" >/dev/null 2>&1 || {
    echo "Required GStreamer runtime package is not installed: $package" >&2
    exit 69
  }
  while IFS= read -r plugin; do
    [[ -f "$plugin" ]] || continue
    cp -L --preserve=mode,timestamps \
      "$plugin" "$output_dir/lib/gstreamer-1.0/$(basename "$plugin")"
    record_package "$plugin"
    enqueue "$plugin"
  done < <(dpkg-query -L "$package" | grep -E '/gstreamer-1\.0/[^/]+\.so$')
done

plugin_scanner=$(
  dpkg-query -L libgstreamer1.0-0 | \
    grep -E '/gstreamer1\.0/gstreamer-1\.0/gst-plugin-scanner$' | \
    head -n 1
)
if [[ ! -x "$plugin_scanner" ]]; then
  echo "GStreamer plugin scanner was not found." >&2
  exit 69
fi
cp --preserve=mode,timestamps \
  "$plugin_scanner" "$output_dir/libexec/gstreamer-1.0/gst-plugin-scanner"
record_package "$plugin_scanner"
enqueue "$plugin_scanner"

index=0
while (( index < ${#queue[@]} )); do
  capture_elf_dependencies "${queue[$index]}"
  ((index += 1))
done

if [[ -d /usr/share/themes/Adwaita ]]; then
  mkdir -p "$output_dir/share/themes"
  cp -a /usr/share/themes/Adwaita "$output_dir/share/themes/"
  record_tree_package /usr/share/themes/Adwaita
fi
for icon_theme in Adwaita hicolor; do
  if [[ -d "/usr/share/icons/$icon_theme" ]]; then
    mkdir -p "$output_dir/share/icons"
    cp -a "/usr/share/icons/$icon_theme" "$output_dir/share/icons/"
    record_tree_package "/usr/share/icons/$icon_theme"
  fi
done
while IFS= read -r -d '' schema; do
  cp -a "$schema" "$output_dir/share/glib-2.0/schemas/"
  record_package "$schema"
done < <(
  find /usr/share/glib-2.0/schemas -maxdepth 1 -type f \
    \( -name '*.xml' -o -name '*.override' \) -print0
)
glib-compile-schemas "$output_dir/share/glib-2.0/schemas"

cat >"$output_dir/aonw" <<'LAUNCHER'
#!/bin/sh
set -eu

app_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
export LD_LIBRARY_PATH="$app_dir/lib${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export GST_PLUGIN_PATH_1_0="$app_dir/lib/gstreamer-1.0"
export GST_PLUGIN_SYSTEM_PATH_1_0="$app_dir/lib/gstreamer-1.0"
export GST_PLUGIN_SCANNER_1_0="$app_dir/libexec/gstreamer-1.0/gst-plugin-scanner"
export GSETTINGS_SCHEMA_DIR="$app_dir/share/glib-2.0/schemas"
export XDG_DATA_DIRS="$app_dir/share:${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"

exec "$app_dir/aonw-bin" "$@"
LAUNCHER
chmod 0755 "$output_dir/aonw"

runtime_manifest="$output_dir/STEAM_RUNTIME_MANIFEST.txt"
{
  echo "sdk_image=${STEAMRT_SDK_IMAGE:-unknown}"
  echo "platform_image=${STEAMRT_PLATFORM_IMAGE:-unknown}"
  echo "bundled_packages:"
  for package in "${!bundled_packages[@]}"; do
    version=$(dpkg-query -W -f='${Version}' "$package")
    echo "  $package=$version"
  done | sort
} >"$runtime_manifest"

for package in "${!bundled_packages[@]}"; do
  package_without_arch=${package%%:*}
  copyright="/usr/share/doc/$package_without_arch/copyright"
  if [[ -f "$copyright" ]]; then
    cp -L "$copyright" "$output_dir/licenses/$package_without_arch.copyright"
  fi
done

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
  if [[ ! -f "$output_dir/lib/gstreamer-1.0/$plugin" ]]; then
    echo "Required GStreamer plugin was not bundled: $plugin" >&2
    exit 1
  fi
done

echo "Steam Runtime 4 bundle created at $output_dir"
