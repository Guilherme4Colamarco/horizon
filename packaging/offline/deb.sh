#!/usr/bin/env bash
set -euo pipefail
binary=$(realpath "$1"); version=$2; out=$(mkdir -p "$3" && realpath "$3")
[[ "$version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Expected numeric X.Y.Z version' >&2; exit 1; }
here=$(cd "$(dirname "$0")" && pwd)
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
install -Dm755 "$binary" "$work/usr/bin/horizon-offline"
install -Dm644 "$here/../../LICENSE" "$work/usr/share/licenses/horizon-offline/LICENSE"
install -Dm644 "$here/../../THIRD_PARTY_NOTICES.md" "$work/usr/share/licenses/horizon-offline/THIRD_PARTY_NOTICES.md"
install -Dm644 "$here/horizon-offline.desktop" "$work/usr/share/applications/horizon-offline.desktop"
mkdir -p "$work/DEBIAN"
cat > "$work/DEBIAN/control" <<CONTROL
Package: horizon-offline
Version: $version
Architecture: amd64
Maintainer: Guilherme4Colamarco <88679520+Guilherme4Colamarco@users.noreply.github.com>
Homepage: https://github.com/Guilherme4Colamarco/horizon
Section: games
Priority: optional
Depends: libc6 (>= 2.35), libgcc-s1, libstdc++6, libx11-6, libx11-xcb1, libxcb1, libxkbcommon0, libxkbcommon-x11-0, libwayland-client0, libfontconfig1, libfreetype6, libasound2, libdbus-1-3, libvulkan1, libudev1, zlib1g
Description: Horizon launcher with support for a local Minecraft installation
 Uses the player's own Minecraft Java 26.3 files without requiring a second login.
CONTROL
dpkg-deb --root-owner-group --build "$work" "$out/horizon-offline-${version}-amd64.deb"
dpkg-deb --info "$out/horizon-offline-${version}-amd64.deb"
