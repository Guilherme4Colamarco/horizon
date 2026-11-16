#!/bin/sh
# Build a native x86_64 glibc XBPS package; no musl compatibility is implied.
set -eu
binary=$(realpath "$1"); version=$2; out=$(mkdir -p "$3" && realpath "$3")
printf '%s\n' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' || { echo 'Expected numeric X.Y.Z version' >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
if ! command -v xbps-create >/dev/null; then
  exec docker run --rm -v "$binary:/input/horizon-offline:ro" -v "$out:/out" -v "$here:/scripts:ro" -v "$here/../../LICENSE:/LICENSE:ro" -v "$here/../../THIRD_PARTY_NOTICES.md:/THIRD_PARTY_NOTICES.md:ro" ghcr.io/void-linux/void-glibc-full:20260901r1 sh /scripts/void.sh /input/horizon-offline "$version" /out
fi
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
install -Dm755 "$binary" "$work/usr/bin/horizon-offline"
install -Dm644 "$here/../../LICENSE" "$work/usr/share/licenses/horizon-offline/LICENSE"
install -Dm644 "$here/../../THIRD_PARTY_NOTICES.md" "$work/usr/share/licenses/horizon-offline/THIRD_PARTY_NOTICES.md"
install -Dm644 "$here/horizon-offline.desktop" "$work/usr/share/applications/horizon-offline.desktop"
cd "$out"
xbps-create -A x86_64 -n "horizon-offline-${version}_1" -s 'Horizon launcher using a local Minecraft installation' -l LGPL-3.0-or-later -H https://github.com/Guilherme4Colamarco/horizon -D 'glibc libgcc libstdc++ libX11 libxcb libxkbcommon libxkbcommon-x11 wayland fontconfig freetype alsa-lib dbus-libs Vulkan-Loader eudev-libudev zlib' "$work"
xbps-rindex -a "horizon-offline-${version}_1.x86_64.xbps"
xbps-query -R --repository="$out" -p pkgver horizon-offline
