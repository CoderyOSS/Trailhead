use anyhow::Result;
use std::path::Path;

use super::{IdeAdapter, JobContext};

pub struct SshAdapter;

impl IdeAdapter for SshAdapter {
    fn name(&self) -> &str {
        "ssh"
    }

    fn detect(&self) -> bool {
        true
    }

    fn open_workspace(&self, _path: &Path, _ctx: &JobContext) -> Result<()> {
        Ok(())
    }

    fn is_attached(&self, _job_id: &str) -> bool {
        false
    }

    fn detach(&self, _job_id: &str) -> Result<()> {
        Ok(())
    }
}
