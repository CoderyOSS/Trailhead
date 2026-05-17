use anyhow::{Context, Result, bail};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Default)]
#[serde(rename_all = "snake_case")]
pub enum CommitPolicy {
    #[default]
    Prohibited,
    Allowed,
    Required,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Workflow {
    pub name: String,
    #[serde(default)]
    pub description: String,
    pub branch: String,
    pub stages: HashMap<String, Stage>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Stage {
    #[serde(default)]
    pub skill: Option<String>,
    #[serde(default)]
    pub prompt: String,
    pub model: Option<String>,
    pub response_schema: Option<serde_json::Value>,
    #[serde(default)]
    pub tools: Vec<String>,
    pub max_tokens: Option<u32>,
    pub timeout_secs: Option<u64>,
    #[serde(default)]
    pub checkpoint: bool,
    #[serde(default)]
    pub commits: CommitPolicy,
    pub routes: Option<Vec<Route>>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Route {
    pub when: String,
    pub next: String,
}

pub fn parse_workflow(yaml_str: &str) -> Result<Workflow> {
    let wf: Workflow = serde_yaml::from_str(yaml_str).context("parse workflow YAML")?;
    if wf.stages.is_empty() {
        bail!("workflow needs at least one stage");
    }
    if wf.branch.is_empty() {
        bail!("workflow requires a branch");
    }
    for (name, stage) in &wf.stages {
        if let Some(ref routes) = stage.routes {
            for route in routes {
                if !route.next.is_empty() && !wf.stages.contains_key(&route.next) {
                    bail!("stage '{}' routes to unknown stage '{}'", name, route.next);
                }
            }
        }
    }
    Ok(wf)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parse_simple_workflow() {
        let yaml = r#"
name: test
branch: main
stages:
  plan:
    skill: plan
    prompt: "Plan: {{input}}"
    routes:
      - when: 'response.ok'
        next: done
  done:
    skill: pause
    routes: null
"#;
        let wf = parse_workflow(yaml).unwrap();
        assert_eq!(wf.name, "test");
        assert_eq!(wf.branch, "main");
        assert_eq!(wf.stages.len(), 2);
        assert!(wf.stages["plan"].routes.is_some());
    }

    #[test]
    fn reject_empty_stages() {
        let yaml = "name: bad\nbranch: main\nstages: {}\n";
        assert!(parse_workflow(yaml).is_err());
    }

    #[test]
    fn reject_missing_branch() {
        let yaml = r#"
name: bad
stages:
  start:
    skill: plan
"#;
        assert!(parse_workflow(yaml).is_err());
    }

    #[test]
    fn reject_unknown_route_target() {
        let yaml = r#"
name: bad
branch: main
stages:
  start:
    skill: plan
    routes:
      - when: "true"
        next: nonexistent
"#;
        assert!(parse_workflow(yaml).is_err());
    }

    #[test]
    fn default_commit_policy_is_prohibited() {
        let yaml = r#"
name: test
branch: main
stages:
  start:
    skill: plan
"#;
        let wf = parse_workflow(yaml).unwrap();
        assert_eq!(wf.stages["start"].commits, CommitPolicy::Prohibited);
    }

    #[test]
    fn explicit_commit_policy() {
        let yaml = r#"
name: test
branch: main
stages:
  start:
    skill: plan
    commits: required
"#;
        let wf = parse_workflow(yaml).unwrap();
        assert_eq!(wf.stages["start"].commits, CommitPolicy::Required);
    }
}
