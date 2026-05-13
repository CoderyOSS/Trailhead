use anyhow::{anyhow, Result};

pub fn can_transition(from: &str, to: &str) -> bool {
    match from {
        "queued" => matches!(to, "scheduled" | "cancelled"),
        "scheduled" => matches!(to, "provisioning" | "failed_retryable" | "cancelled"),
        "provisioning" => matches!(to, "running" | "failed_retryable" | "cancelled"),
        "running" => matches!(
            to,
            "checkpointing"
                | "paused"
                | "paused_for_human"
                | "completed"
                | "failed_retryable"
                | "cancelled"
        ),
        "checkpointing" => matches!(to, "running" | "failed_retryable" | "cancelled"),
        "paused" => matches!(to, "resuming" | "cancelled"),
        "paused_for_human" => matches!(to, "resuming" | "cancelled"),
        "resuming" => matches!(to, "running" | "failed_retryable" | "cancelled"),
        "failed_retryable" => matches!(to, "scheduled" | "failed_final" | "cancelled"),
        _ => false,
    }
}

pub fn transition(from: &str, to: &str) -> Result<()> {
    if can_transition(from, to) {
        Ok(())
    } else {
        Err(anyhow!("invalid transition: {} -> {}", from, to))
    }
}

pub fn is_terminal(status: &str) -> bool {
    matches!(status, "completed" | "failed_final" | "cancelled")
}
