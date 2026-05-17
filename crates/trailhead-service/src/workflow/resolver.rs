use anyhow::Result;
use minijinja::{Environment, context};
use serde::Serialize;
use std::collections::HashMap;

#[derive(Debug, Clone, Serialize)]
pub struct TemplateVars {
    pub input: String,
    pub project: ProjectVars,
    pub stages: HashMap<String, StageOutput>,
    pub env: HashMap<String, String>,
}

#[derive(Debug, Clone, Serialize)]
pub struct ProjectVars {
    pub name: String,
    pub repo: String,
    pub branch: String,
}

#[derive(Debug, Clone, Serialize)]
pub struct StageOutput {
    pub output: String,
    pub commits: Vec<crate::workflow::CommitInfo>,
    pub changed_files: Vec<String>,
}

pub fn resolve_prompt(template: &str, vars: &TemplateVars) -> Result<String> {
    let mut env = Environment::new();
    env.add_template("prompt", template)?;
    let tmpl = env.get_template("prompt")?;
    Ok(tmpl.render(context! { input => &vars.input, project => &vars.project, stages => &vars.stages, env => &vars.env })?)
}

pub fn resolve_input(
    user_input: &str,
    previous_stage_name: Option<&str>,
    stage_outputs: &HashMap<String, StageOutput>,
) -> String {
    match previous_stage_name {
        Some(id) => stage_outputs
            .get(id)
            .map(|s| s.output.clone())
            .unwrap_or_default(),
        None => user_input.to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn resolve_input_var() {
        let vars = TemplateVars {
            input: "fix the bug".into(),
            project: ProjectVars {
                name: "myproject".into(),
                repo: "https://github.com/x/y".into(),
                branch: "main".into(),
            },
            stages: HashMap::new(),
            env: HashMap::new(),
        };
        let result = resolve_prompt("Task: {{input}}", &vars).unwrap();
        assert_eq!(result, "Task: fix the bug");
    }

    #[test]
    fn resolve_stages_var() {
        let mut stages = HashMap::new();
        stages.insert(
            "plan".into(),
            StageOutput {
                output: "do thing".into(),
                commits: vec![],
                changed_files: vec![],
            },
        );
        let vars = TemplateVars {
            input: "original".into(),
            project: ProjectVars {
                name: "p".into(),
                repo: "r".into(),
                branch: "main".into(),
            },
            stages,
            env: HashMap::new(),
        };
        let result = resolve_prompt("Plan: {{stages.plan.output}}", &vars).unwrap();
        assert_eq!(result, "Plan: do thing");
    }

    #[test]
    fn resolve_input_from_previous_stage() {
        let mut stages = HashMap::new();
        stages.insert(
            "plan".into(),
            StageOutput {
                output: "{\"plan\": \"do it\"}".into(),
                commits: vec![],
                changed_files: vec![],
            },
        );
        let result = resolve_input("original", Some("plan"), &stages);
        assert_eq!(result, "{\"plan\": \"do it\"}");
    }

    #[test]
    fn resolve_input_first_stage() {
        let result = resolve_input("fix this", None, &HashMap::new());
        assert_eq!(result, "fix this");
    }
}
