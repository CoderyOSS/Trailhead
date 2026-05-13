pub mod types {
    use serde::{Deserialize, Serialize};
    use uuid::Uuid;

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct JobId(pub String);

    impl JobId {
        pub fn new() -> Self {
            Self(Uuid::new_v4().to_string())
        }
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct WorkerId(pub String);

    impl WorkerId {
        pub fn new() -> Self {
            Self(Uuid::new_v4().to_string())
        }
    }

    #[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
    #[serde(rename_all = "snake_case")]
    pub enum JobStatus {
        Queued,
        Scheduled,
        Provisioning,
        Running,
        Checkpointing,
        Paused,
        PausedForHuman,
        Resuming,
        FailedRetryable,
        FailedFinal,
        Completed,
        Cancelled,
    }

    #[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
    #[serde(rename_all = "snake_case")]
    pub enum WorkerStatus {
        Creating,
        Running,
        Idle,
        Stopping,
        Stopped,
        Failed(String),
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct TokenUsage {
        pub input_tokens: u64,
        pub output_tokens: u64,
    }

    impl TokenUsage {
        pub fn zero() -> Self {
            Self {
                input_tokens: 0,
                output_tokens: 0,
            }
        }
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct HeartbeatPayload {
        pub status: String,
        pub current_stage: String,
        pub token_usage: TokenUsage,
        pub files_changed: u64,
        pub tool_calls_made: u64,
        pub message: String,
    }

    #[derive(Debug, Clone, Serialize, Deserialize)]
    pub struct CheckpointPayload {
        pub stage: String,
        pub response: serde_json::Value,
        pub session_path: String,
        pub git_sha: String,
        pub token_usage: TokenUsage,
        pub files_changed: Vec<String>,
        pub next_stage: String,
    }
}
