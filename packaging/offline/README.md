# Horizon Offline release packages

Run the **Horizon Offline packages** GitHub workflow with numeric SemVer and
`publish=true`. Every platform must succeed before publication. The workflow
uses GitHub-hosted runners, builds the modified launcher from source and emits
checksums with the release.

Formats: Linux x86_64 tar.gz, AppImage, Debian amd64 deb, Void x86_64 glibc XBPS,
AerynOS x86_64 Stone; Windows x64/ARM64 portable EXE, setup EXE and ZIP;
macOS Intel/Apple Silicon ZIP and DMG. macOS apps are ad-hoc signed and not
notarized. Void musl is not supported by these glibc builds.

Launcher self-update is disabled in these distributions to preserve the fork.
Engine builds still come from upstream Horizon. No Minecraft files are bundled.
The local-copy workflow has been tested on Fedora/XFCE/KVM. Distribution package
format validation does not establish gameplay compatibility on every target.

`deb.sh BINARY VERSION OUTDIR` requires dpkg-deb.
`void.sh BINARY VERSION OUTDIR` uses xbps-create/xbps-rindex or a Void OCI container.
For Stone see ../aerynos/README.md.
