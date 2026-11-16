# AerynOS package

`stone.sh RELEASE_APPIMAGE VERSION OUTDIR` produces a genuine `.stone` using
the official AerynOS `stone` Rust library, pinned by commit and Cargo.lock.
It packages the release AppImage in `/usr/lib/horizon-offline` with a desktop
entry and `/usr/bin/horizon-offline` wrapper. The wrapper extracts without
requiring FUSE and disables launcher self-update: moss owns this installation.
The AppImage retains its Linux host requirements, including compatible glibc
and Vulkan graphics drivers. No Minecraft resources are included.

The writer immediately reads every payload and checks the content checksum and
file digests with the official reader. This validates the archive format, not
installation or gameplay on AerynOS; those require a separate clean-system test.

Build requirements: Rust 1.94 or later, C compiler (zstd), network access to
Cargo dependencies, and a release x86_64 AppImage built by the release workflow.
This is a third-party package, not an AerynOS repository submission.

Format/tool sources:
- https://github.com/aerynOS/os-tools/tree/d9c7d289c0a9bd65a78fe8c532526cc21afbaaf4/crates/stone
- https://github.com/aerynOS/os-tools/blob/d9c7d289c0a9bd65a78fe8c532526cc21afbaaf4/boulder/src/package/emit.rs
