#!/usr/bin/env bash
# Ad-hoc signed app and DMG; notarization requires a separate Developer ID setup.
set -euo pipefail
binary=$1 version=$2 out=$3 arch=$4
here=$(cd "$(dirname "$0")/.." && pwd)
mkdir -p "$out"
out=$(cd "$out" && pwd)
app="$out/Horizon Offline.app"
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
cp "$binary" "$app/Contents/MacOS/horizon-launcher"
chmod 755 "$app/Contents/MacOS/horizon-launcher"
cp "$here/icons/horizon.icns" "$app/Contents/Resources/horizon.icns"
sed -e "s/@VERSION@/$version/g" -e 's/<string>Horizon<\//<string>Horizon Offline<\//g' -e 's/dev.horizon.launcher/io.github.Guilherme4Colamarco.horizon-offline/' "$here/macos/Info.plist" > "$app/Contents/Info.plist"
plutil -lint "$app/Contents/Info.plist"
codesign --force --sign - "$app"
codesign --verify --strict "$app"
(cd "$out" && ditto -c -k --norsrc --noextattr --noqtn --keepParent 'Horizon Offline.app' "horizon-offline-macos-$arch.zip")
stage=$(mktemp -d)
trap 'rm -rf "$stage"' EXIT
cp -R "$app" "$stage/"
ln -s /Applications "$stage/Applications"
hdiutil create -volname 'Horizon Offline' -srcfolder "$stage" -ov -format UDZO "$out/horizon-offline-macos-$arch.dmg"
hdiutil verify "$out/horizon-offline-macos-$arch.dmg"
rm -rf "$app"
