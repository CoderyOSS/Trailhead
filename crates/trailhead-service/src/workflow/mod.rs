pub mod parser;
pub mod resolver;
pub mod router;

pub use parser::{CommitPolicy, Stage, Workflow};

use anyhow::{anyhow, Result};
use resolver::{TemplateVars, StageOutput, resolve_prompt, resolve_input};
use router::evaluate_routes;
use std::collections::HashMap;

#[derive(Debug, Clone, serde::Serialize)]
pub struct CommitInfo {
    pub sha: String,
    pub short_hash: String,
    pub message: String,
}

#[derive(Debug, Clone, serde::Serialize)]
pub struct StageResult {
    pub stage_name: String,
    pub response: serde_json::Value,
    pub commits: Vec<CommitInfo>,
    pub changed_files: Vec<String>,
}

#[derive(Debug, Clone)]
pub struct Engine {
    pub workflow: Workflow,
    pub current_stage: String,
    pub stage_history: Vec<StageResult>,
    pub stage_outputs: HashMap<String, StageOutput>,
}

#[derive(Debug, Clone, PartialEq)]
pub enum AdvanceResult {
    Advance,
    PauseForHuman,
    Finished,
}

impl Engine {
    pub fn new(workflow: Workflow, start_stage: Option<String>) -> Result<Self> {
        let start = start_stage
            .unwrap_or_else(|| workflow.stages.keys().next().cloned().unwrap_or_default());
        if !workflow.stages.contains_key(&start) {
            return Err(anyhow!("unknown stage: {}", start));
        }
        Ok(Self {
            workflow,
            current_stage: start,
            stage_history: Vec::new(),
            stage_outputs: HashMap::new(),
        })
    }

    pub fn current_stage_def(&self) -> Option<&Stage> {
        self.workflow.stages.get(&self.current_stage)
    }

    pub fn resolve_stage_prompt(
        &self,
        user_input: &str,
        project: &resolver::ProjectVars,
        env: &HashMap<String, String>,
    ) -> Result<String> {
        let stage = self.current_stage_def().ok_or_else(|| anyhow!("no current stage"))?;
        let prev = self.stage_history.last().map(|s| s.stage_name.clone());
        let input = resolve_input(user_input, prev.as_deref(), &self.stage_outputs);
        let vars = TemplateVars {
            input,
            project: project.clone(),
            stages: self.stage_outputs.clone(),
            env: env.clone(),
        };
        resolve_prompt(&stage.prompt, &vars)
    }

    pub fn process_response(&mut self, response: serde_json::Value) -> Result<AdvanceResult> {
        self.process_response_with_commits(response, vec![])
    }

    pub fn process_response_with_commits(
        &mut self,
        response: serde_json::Value,
        commits: Vec<CommitInfo>,
    ) -> Result<AdvanceResult> {
        let stage = self.current_stage_def().ok_or_else(|| anyhow!("no current stage"))?;
        let routes = stage.routes.clone();
        self.stage_outputs.insert(
            self.current_stage.clone(),
            StageOutput {
                output: serde_json::to_string_pretty(&response)?,
                commits: commits.clone(),
                changed_files: Vec::new(),
            },
        );
        self.stage_history.push(StageResult {
            stage_name: self.current_stage.clone(),
            response: response.clone(),
            commits,
            changed_files: Vec::new(),
        });
        let routes = match routes {
            Some(r) => r,
            None => return Ok(AdvanceResult::Finished),
        };
        match evaluate_routes(&routes, &response)? {
            Some(next) if next == "pause_for_human" => Ok(AdvanceResult::PauseForHuman),
            Some(next) => {
                self.current_stage = next;
                Ok(AdvanceResult::Advance)
            }
            None => Ok(AdvanceResult::Finished),
        }
    }
}
