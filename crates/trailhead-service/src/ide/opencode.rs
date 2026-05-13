use anyhow::Result;
use std::path::Path;
use std::process::Command;

use super::{IdeAdapter, JobContext};

pub struct OpenCodeAdapter;

impl IdeAdapter for OpenCodeAdapter {
    fn name(&self) -> &str {
        "opencode"
    }

    fn detect(&self) -> bool {
        which_exists("opencode")
    }

    fn open_workspace(&self, path: &Path, _ctx: &JobContext) -> Result<()> {
        Command::new("opencode").arg(path).spawn()?;
        Ok(())
    }

    fn is_attached(&self, _job_id: &str) -> bool {
        false
    }

    fn detach(&self, _job_id: &str) -> Result<()> {
        Ok(())
    }
}

fn which_exists(cmd: &str) -> bool {
    Command::new("which")
        .arg(cmd)
        .output()
        .map(|o| o.status.success())
        .unwrap_or(false)
}
