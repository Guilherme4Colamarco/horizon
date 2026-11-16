#!/usr/bin/env bash
# Build a real Stone archive using the AerynOS project's pinned writer/reader.
# Usage: stone.sh RELEASE_APPIMAGE VERSION OUTDIR
set -euo pipefail
here=$(cd "$(dirname "$0")" && pwd)
repo=$(cd "$here/../.." && pwd)
image=$(realpath "$1")
version=$2
out=$(mkdir -p "$3" && cd "$3" && pwd)
[[ "$version" =~ ^[0-9][0-9A-Za-z._+-]*$ ]] || { echo 'Invalid package version' >&2; exit 1; }
[[ "$(od -An -tx1 -j8 -N3 "$image" | tr -d ' \n')" == 414902 ]] || { echo 'Expected type-2 AppImage' >&2; exit 1; }
root=$(mktemp -d)
trap 'rm -rf "$root"' EXIT
install -Dm755 "$image" "$root/usr/lib/horizon-offline/horizon-offline.AppImage"
install -Dm644 "$repo/LICENSE" "$root/usr/share/licenses/horizon-offline/LICENSE"
install -Dm644 "$repo/THIRD_PARTY_NOTICES.md" "$root/usr/share/licenses/horizon-offline/THIRD_PARTY_NOTICES.md"
install -Dm644 "$repo/packaging/icons/hicolor/256x256/apps/horizon.png" "$root/usr/share/icons/hicolor/256x256/apps/horizon-offline.png"
mkdir -p "$root/usr/bin" "$root/usr/share/applications"
cat > "$root/usr/bin/horizon-offline" <<'EOF'
#!/bin/sh
# moss owns this installation; the package manager handles launcher updates.
export HORIZON_LAUNCHER_NO_SELF_UPDATE=1
exec /usr/lib/horizon-offline/horizon-offline.AppImage --appimage-extract-and-run "$@"
EOF
chmod 755 "$root/usr/bin/horizon-offline"
cat > "$root/usr/share/applications/horizon-offline.desktop" <<'EOF'
[Desktop Entry]
Type=Application
Name=Horizon Offline
Comment=Play Horizon using your local Minecraft installation
Exec=horizon-offline
Icon=horizon-offline
Categories=Game;
Terminal=false
EOF
cargo run --release --locked --manifest-path "$here/stone-pack/Cargo.toml" -- \
  "$root" "$version" "$out/horizon-offline-$version-1-1-x86_64.stone"
