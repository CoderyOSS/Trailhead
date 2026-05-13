use agent_runner::agent::{self, AgentConfig, FinishReason, TokenUsage};
use agent_runner::provider::anthropic::AnthropicProvider;
use agent_runner::session::Session;
use agent_runner::tools::{self, ToolContext};
use anyhow::{anyhow, Result};
use std::env;
use std::path::PathBuf;
use std::process;

fn get_arg<'a>(args: &'a [String], flag: &str) -> Option<&'a str> {
    args.iter()
        .position(|a| a == flag)
        .and_then(|i| args.get(i + 1).map(|s| s.as_str()))
}

fn parse_args() -> Vec<String> {
    env::args().skip(1).collect()
}

fn print_usage() {
    eprintln!("agent-runner - AI agent that executes tasks using LLM tools

USAGE:
    agent-runner <SUBCOMMAND>

SUBCOMMANDS:
    run      Run a new agent session
    resume   Resume an existing agent session

RUN OPTIONS:
    --workspace <PATH>        Working directory (required)
    --prompt <TEXT>           User prompt (required)
    --tools <LIST>            Comma-separated tool names (default: all)
    --max-tokens <N>          Max tokens per LLM response (default: 4096)
    --max-tool-calls <N>      Max tool calls before stopping (default: 50)
    --system-prompt <TEXT>    System prompt (optional)

RESUME OPTIONS:
    --workspace <PATH>        Working directory with existing session (required)
    --prompt <TEXT>           Follow-up prompt (required)
    --max-tokens <N>          Max tokens per LLM response (default: 4096)
    --max-tool-calls <N>      Max tool calls before stopping (default: 50)");
}

fn create_provider() -> Result<Box<dyn agent_runner::provider::LlmProvider>> {
    let provider_name = env::var("LLM_PROVIDER").unwrap_or_else(|_| "anthropic".to_string());
    let api_key = env::var("LLM_API_KEY").map_err(|_| anyhow!("LLM_API_KEY environment variable is required"))?;
    let model = env::var("LLM_MODEL").unwrap_or_else(|_| "claude-sonnet-4-20250514".to_string());

    match provider_name.as_str() {
        "anthropic" => Ok(Box::new(AnthropicProvider::new(api_key, model))),
        "openai" => {
            let _base_url = env::var("OPENAI_BASE_URL").ok();
            Err(anyhow!("OpenAI provider not yet implemented"))
        }
        other => Err(anyhow!("unknown LLM_PROVIDER: {other}")),
    }
}

fn validate_tools(registry: &tools::ToolRegistry, tool_names: &[String]) -> Result<()> {
    for name in tool_names {
        if !registry.has(name) {
            return Err(anyhow!("invalid tool: {name}"));
        }
    }
    Ok(())
}

async fn run_command() -> Result<()> {
    let args = parse_args();

    if args.is_empty() {
        return Err(anyhow!("missing subcommand. Use 'run' or 'resume'"));
    }

    if args[0] == "--help" || args[0] == "-h" {
        print_usage();
        process::exit(0);
    }

    if args[0] == "run" {
        let workspace = get_arg(&args, "--workspace")
            .ok_or_else(|| anyhow!("missing required argument: --workspace"))?;
        let prompt = get_arg(&args, "--prompt")
            .ok_or_else(|| anyhow!("missing required argument: --prompt"))?;

        let max_tokens: u32 = get_arg(&args, "--max-tokens")
            .map(|s| s.parse())
            .transpose()?
            .unwrap_or(4096);
        let max_tool_calls: u32 = get_arg(&args, "--max-tool-calls")
            .map(|s| s.parse())
            .transpose()?
            .unwrap_or(50);
        let system_prompt = get_arg(&args, "--system-prompt").map(String::from);

        let registry = tools::default_tools();
        let allowed_tools = get_arg(&args, "--tools")
            .map(|s| s.split(',').map(|t| t.trim().to_string()).collect::<Vec<_>>())
            .unwrap_or_else(|| {
                vec![
                    "bash".into(),
                    "read".into(),
                    "write".into(),
                    "edit".into(),
                    "glob".into(),
                    "grep".into(),
                ]
            });

        validate_tools(&registry, &allowed_tools)?;

        let ws = PathBuf::from(workspace);
        std::fs::create_dir_all(&ws)?;

        let provider = create_provider()?;
        let config = AgentConfig {
            max_tool_calls,
            system_prompt,
            user_prompt: prompt.to_string(),
            allowed_tools,
            max_tokens,
        };
        let tool_ctx = ToolContext {
            workspace: ws.clone(),
            timeout: 120,
        };

        let output = agent::run_agent_loop(provider.as_ref(), &registry, config, tool_ctx).await?;

        let _session = Session::new(output.messages.clone(), output.usage);

        if let Some(last) = output.messages.last() {
            if let Some(content) = &last.content {
                println!("{content}");
            }
        }

        Ok(())
    } else if args[0] == "resume" {
        let workspace = get_arg(&args, "--workspace")
            .ok_or_else(|| anyhow!("missing required argument: --workspace"))?;
        let prompt = get_arg(&args, "--prompt")
            .ok_or_else(|| anyhow!("missing required argument: --prompt"))?;

        let max_tokens: u32 = get_arg(&args, "--max-tokens")
            .map(|s| s.parse())
            .transpose()?
            .unwrap_or(4096);
        let max_tool_calls: u32 = get_arg(&args, "--max-tool-calls")
            .map(|s| s.parse())
            .transpose()?
            .unwrap_or(50);

        let ws = PathBuf::from(workspace);
        let mut session = Session::load(&ws).map_err(|e| {
            if e.to_string().contains("not found") {
                anyhow!("session file not found. Run 'agent-runner run' first.")
            } else {
                e
            }
        })?;

        let registry = tools::default_tools();
        let allowed_tools = vec![
            "bash".into(),
            "read".into(),
            "write".into(),
            "edit".into(),
            "glob".into(),
            "grep".into(),
        ];

        let provider = create_provider()?;
        let config = AgentConfig {
            max_tool_calls,
            system_prompt: None,
            user_prompt: prompt.to_string(),
            allowed_tools,
            max_tokens,
        };
        let tool_ctx = ToolContext {
            workspace: ws.clone(),
            timeout: 120,
        };

        let mut messages = session.messages.clone();
        messages.push(agent::Message::user(&config.user_prompt));

        let tool_defs = registry.tool_defs(&config.allowed_tools)?;
        let request_config = agent_runner::provider::RequestConfig {
            max_tokens: config.max_tokens,
            tools: tool_defs,
        };

        let mut tool_calls_made = 0u32;
        let mut total_usage = TokenUsage::zero();
        let mut _finish_reason = FinishReason::Stop;

        loop {
            let response = provider.send(&messages, &request_config).await?;
            total_usage = total_usage + response.usage.clone();

            let assistant_msg = response.message.clone();
            _finish_reason = response.finish_reason;
            messages.push(assistant_msg.clone());

            match response.finish_reason {
                FinishReason::ToolUse => {
                    if tool_calls_made >= config.max_tool_calls {
                        _finish_reason = FinishReason::MaxTokens;
                        break;
                    }
                    let tool_calls = assistant_msg.tool_calls.as_deref().unwrap_or(&[]);
                    for tc in tool_calls {
                        tool_calls_made += 1;
                        let result = registry
                            .execute(&tc.name, &tc.arguments, &tool_ctx)
                            .await
                            .unwrap_or_else(|e| format!("error: {e}"));
                        messages.push(agent::Message::tool_result(&tc.id, result));
                    }
                }
                FinishReason::Stop | FinishReason::MaxTokens => break,
            }
        }

        session.messages = messages;
        session.token_usage = session.token_usage.clone() + total_usage;
        session.save(&ws)?;

        if let Some(last) = session.messages.last() {
            if let Some(content) = &last.content {
                println!("{content}");
            }
        }

        Ok(())
    } else {
        Err(anyhow!("error: unknown subcommand '{}'. Use 'run' or 'resume'.", args[0]))
    }
}

fn main() {
    let rt = tokio::runtime::Runtime::new().expect("failed to create tokio runtime");
    if let Err(e) = rt.block_on(run_command()) {
        eprintln!("{e}");
        process::exit(1);
    }
}
