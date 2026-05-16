use serde::Deserialize;

#[derive(Debug, Clone, Deserialize)]
pub struct PermissionAskedEvent {
    pub id: String,
    #[serde(rename = "sessionID")]
    pub session_id: String,
    pub permission: String,
    pub patterns: Vec<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SessionStatusEvent {
    #[serde(rename = "sessionID")]
    pub session_id: String,
    pub status: SessionStatusValue,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SessionStatusValue {
    #[serde(rename = "type")]
    pub status_type: String,
}

#[derive(Debug, Clone, Deserialize)]
pub struct MessagePartEvent {
    pub part: MessagePart,
}

#[derive(Debug, Clone, Deserialize)]
pub struct MessagePart {
    #[serde(rename = "type")]
    pub part_type: String,
    pub tool: Option<String>,
    pub state: Option<MessagePartState>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct MessagePartState {
    pub status: Option<String>,
}

#[derive(Debug, Clone, Deserialize)]
pub struct SessionErrorEvent {
    #[serde(rename = "sessionID")]
    pub session_id: String,
    pub error: String,
}

#[derive(Debug, Clone)]
pub enum WorkerEvent {
    PermissionAsked(PermissionAskedEvent),
    SessionStatus(SessionStatusEvent),
    MessagePartUpdated(MessagePartEvent),
    SessionError(SessionErrorEvent),
    Unknown(String),
}

#[derive(Deserialize)]
struct RawEvent {
    #[serde(rename = "type")]
    event_type: String,
    properties: serde_json::Value,
}

pub fn parse_sse_line(line: &str) -> Option<WorkerEvent> {
    let data_prefix = "data: ";
    let trimmed = line.trim();
    if !trimmed.starts_with(data_prefix) {
        return None;
    }
    let json_str = &trimmed[data_prefix.len()..];
    let raw: RawEvent = serde_json::from_str(json_str).ok()?;
    match raw.event_type.as_str() {
        "permission.asked" => {
            let evt: PermissionAskedEvent = serde_json::from_value(raw.properties).ok()?;
            Some(WorkerEvent::PermissionAsked(evt))
        }
        "session.status" => {
            let evt: SessionStatusEvent = serde_json::from_value(raw.properties).ok()?;
            Some(WorkerEvent::SessionStatus(evt))
        }
        "message.part.updated" => {
            let evt: MessagePartEvent = serde_json::from_value(raw.properties).ok()?;
            Some(WorkerEvent::MessagePartUpdated(evt))
        }
        "session.error" => {
            let evt: SessionErrorEvent = serde_json::from_value(raw.properties).ok()?;
            Some(WorkerEvent::SessionError(evt))
        }
        other => Some(WorkerEvent::Unknown(other.to_string())),
    }
}
