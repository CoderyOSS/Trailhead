use anyhow::Result;
use std::path::Path;
use std::process::Command;

use super::{IdeAdapter, JobContext};

pub struct CursorAdapter;

impl IdeAdapter for CursorAdapter {
    fn name(&self) -> &str {
        "cursor"
    }

    fn detect(&self) -> bool {
        which_exists("cursor")
    }

    fn open_workspace(&self, path: &Path, _ctx: &JobContext) -> Result<()> {
        Command::new("cursor").arg(path).spawn()?;
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
