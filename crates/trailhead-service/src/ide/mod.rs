pub mod cursor;
pub mod opencode;
pub mod shell;
pub mod ssh;
pub mod vscode;

use anyhow::Result;
use std::path::Path;
use std::path::PathBuf;

pub struct JobContext {
    pub job_id: String,
    pub current_step: String,
    pub last_agent_output: String,
    pub changed_files: Vec<String>,
    pub workspace_path: PathBuf,
}

pub trait IdeAdapter: Send + Sync {
    fn name(&self) -> &str;
    fn detect(&self) -> bool;
    fn open_workspace(&self, path: &Path, ctx: &JobContext) -> Result<()>;
    fn is_attached(&self, job_id: &str) -> bool;
    fn detach(&self, job_id: &str) -> Result<()>;
}

pub fn auto_detect() -> Option<Box<dyn IdeAdapter>> {
    let adapters: Vec<Box<dyn IdeAdapter>> = vec![
        Box::new(opencode::OpenCodeAdapter),
        Box::new(cursor::CursorAdapter),
        Box::new(vscode::VsCodeAdapter),
        Box::new(shell::ShellAdapter),
    ];
    adapters.into_iter().find(|a| a.detect())
}

pub fn get_adapter(name: &str) -> Option<Box<dyn IdeAdapter>> {
    match name {
        "opencode" => Some(Box::new(opencode::OpenCodeAdapter)),
        "cursor" => Some(Box::new(cursor::CursorAdapter)),
        "vscode" => Some(Box::new(vscode::VsCodeAdapter)),
        "shell" => Some(Box::new(shell::ShellAdapter)),
        "ssh" => Some(Box::new(ssh::SshAdapter)),
        _ => None,
    }
}
