use std::{
    env,
    error::Error,
    fs::{self, File},
    io::{self, Cursor},
    os::unix::fs::MetadataExt,
    path::Path,
};
use stone::*;

fn main() -> Result<(), Box<dyn Error>> {
    let args: Vec<_> = env::args().collect();
    if args.len() != 4 {
        return Err(
            "usage: horizon-stone-pack ROOT VERSION OUTPUT.stone (ROOT contains usr/)".into(),
        );
    }
    let root = Path::new(&args[1]);
    let mut files = Vec::new();
    collect(&root.join("usr"), root, &mut files)?;
    if files.is_empty() {
        return Err("empty package".into());
    }
    let mut meta = Vec::new();
    for (tag, value) in [
        (StonePayloadMetaTag::Name, "horizon-offline"),
        (StonePayloadMetaTag::Version, &args[2]),
        (StonePayloadMetaTag::Architecture, "x86_64"),
        (StonePayloadMetaTag::Summary, "Horizon Offline launcher"),
        (
            StonePayloadMetaTag::Description,
            "Horizon launcher using a local Minecraft 26.3 installation; no game assets included.",
        ),
        (
            StonePayloadMetaTag::Homepage,
            "https://github.com/Guilherme4Colamarco/horizon",
        ),
        (StonePayloadMetaTag::SourceID, "horizon-offline"),
        (StonePayloadMetaTag::License, "LGPL-3.0-or-later"),
    ] {
        meta.push(StonePayloadMetaRecord {
            tag,
            primitive: StonePayloadMetaPrimitive::String(value.into()),
        });
    }
    for tag in [
        StonePayloadMetaTag::Release,
        StonePayloadMetaTag::BuildRelease,
    ] {
        meta.push(StonePayloadMetaRecord {
            tag,
            primitive: StonePayloadMetaPrimitive::Uint64(1),
        });
    }
    // AppImage extraction avoids FUSE. Drivers and the session remain system-owned.
    for soname in [
        "libc.so.6(x86_64)",
        "libvulkan.so.1(x86_64)",
        "libasound.so.2(x86_64)",
        "libudev.so.1(x86_64)",
        "libdbus-1.so.3(x86_64)",
    ] {
        meta.push(StonePayloadMetaRecord {
            tag: StonePayloadMetaTag::Depends,
            primitive: StonePayloadMetaPrimitive::Dependency(
                StonePayloadMetaDependency::SharedLibrary,
                soname.into(),
            ),
        });
    }
    let output = File::create(&args[3])?;
    let mut writer = StoneWriter::new(output, StoneHeaderV1FileType::Binary)?;
    writer.add_payload(meta.as_slice())?;
    let size: u64 = files.iter().map(|(_, data, _)| data.len() as u64).sum();
    let mut writer = writer.with_content(Cursor::new(Vec::new()), Some(size), 1)?;
    let mut layouts = Vec::new();
    let mut seen = std::collections::HashSet::new();
    for (target, data, mode) in files {
        let mut hash = StoneDigestWriterHasher::new();
        hash.update(&data);
        let digest = hash.digest128();
        if seen.insert(digest) {
            writer.add_content(&mut data.as_slice())?;
        }
        layouts.push(StonePayloadLayoutRecord {
            uid: 0,
            gid: 0,
            mode,
            tag: 0,
            file: StonePayloadLayoutFile::Regular(digest, target.into()),
        });
    }
    writer.add_payload(layouts.as_slice())?;
    writer.finalize()?;
    // Decode every payload, verify content checksum, and verify file index hashes.
    let mut reader = read(File::open(&args[3])?)?;
    let payloads = reader.payloads()?.collect::<Result<Vec<_>, _>>()?;
    let metadata = payloads
        .iter()
        .find_map(StoneDecodedPayload::meta)
        .ok_or("missing metadata")?;
    if metadata.body != meta {
        return Err("metadata round-trip mismatch".into());
    }
    let decoded_layouts = payloads
        .iter()
        .find_map(StoneDecodedPayload::layout)
        .ok_or("missing layout")?;
    if decoded_layouts.body != layouts {
        return Err("layout round-trip mismatch".into());
    }
    let index = payloads
        .iter()
        .find_map(StoneDecodedPayload::index)
        .ok_or("missing index")?;
    let content = payloads
        .iter()
        .find_map(StoneDecodedPayload::content)
        .ok_or("missing content")?;
    let mut bytes = Vec::new();
    reader.unpack_content(content, &mut bytes)?;
    for entry in &index.body {
        let mut hash = StoneDigestWriterHasher::new();
        hash.update(
            bytes
                .get(entry.start as usize..entry.end as usize)
                .ok_or("invalid content range")?,
        );
        if hash.digest128() != entry.digest {
            return Err("content digest mismatch".into());
        }
    }
    println!(
        "Validated {} files in {} using the official Stone reader",
        layouts.len(),
        args[3]
    );
    Ok(())
}

fn collect(dir: &Path, root: &Path, files: &mut Vec<(String, Vec<u8>, u32)>) -> io::Result<()> {
    let mut entries = fs::read_dir(dir)?.collect::<Result<Vec<_>, _>>()?;
    entries.sort_by_key(|e| e.path());
    for entry in entries {
        let path = entry.path();
        let meta = fs::symlink_metadata(&path)?;
        if meta.is_dir() {
            collect(&path, root, files)?;
        } else if meta.is_file() {
            let target = path
                .strip_prefix(root.join("usr"))
                .map_err(io::Error::other)?
                .to_str()
                .ok_or_else(|| io::Error::other("non UTF-8 path"))?
                .to_owned();
            files.push((target, fs::read(&path)?, meta.mode()));
        } else {
            return Err(io::Error::other("only regular files supported"));
        }
    }
    Ok(())
}
