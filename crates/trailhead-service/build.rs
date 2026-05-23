use std::path::Path;

fn main() {
    println!("cargo:rerun-if-changed=Cargo.toml");
    println!("cargo:rerun-if-changed=ui/dist/");

    let frontend_build = Path::new("../../frontend/build/web");
    let embed_dir = Path::new("ui/dist");

    if frontend_build.is_dir() {
        let _ = std::fs::remove_dir_all(embed_dir);
        let result = std::fs::create_dir_all(embed_dir)
            .and_then(|()| copy_dir_recursive(frontend_build, embed_dir));
        match result {
            Ok(()) => eprintln!("cargo:warning=embedded frontend from {}", frontend_build.display()),
            Err(e) => eprintln!("cargo:warning=frontend copy failed: {e}"),
        }
    } else {
        eprintln!("cargo:warning=frontend build not found at {}, skip embedding", frontend_build.display());
    }
}

fn copy_dir_recursive(src: &Path, dst: &Path) -> std::io::Result<()> {
    for entry in std::fs::read_dir(src)? {
        let entry = entry?;
        let file_type = entry.file_type()?;
        let src_path = entry.path();
        let dst_path = dst.join(entry.file_name());
        if file_type.is_dir() {
            std::fs::create_dir_all(&dst_path)?;
            copy_dir_recursive(&src_path, &dst_path)?;
        } else {
            std::fs::copy(&src_path, &dst_path)?;
        }
    }
    Ok(())
}
