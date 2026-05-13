use anyhow::Result;
use std::path::Path;
use std::process::Command;

use super::{IdeAdapter, JobContext};

pub struct ShellAdapter;

impl IdeAdapter for ShellAdapter {
    fn name(&self) -> &str {
        "shell"
    }

    fn detect(&self) -> bool {
        std::env::var("SHELL").is_ok()
    }

    fn open_workspace(&self, path: &Path, _ctx: &JobContext) -> Result<()> {
        let shell = std::env::var("SHELL").unwrap_or_else(|_| "/bin/sh".into());
        Command::new(shell)
            .current_dir(path)
            .spawn()?;
        Ok(())
    }

    fn is_attached(&self, _job_id: &str) -> bool {
        false
    }

    fn detach(&self, _job_id: &str) -> Result<()> {
        Ok(())
    }
}
