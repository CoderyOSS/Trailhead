#[derive(Debug, Clone)]
pub enum PermissionPolicy {
    AutoApprove,
    AutoApproveExcept(Vec<String>),
    Deny,
}

#[derive(Debug, Clone, PartialEq)]
pub enum PermissionAction {
    Approve,
    Reject { message: String },
}

pub fn decide(permission: &str, _patterns: &[String], policy: &PermissionPolicy) -> PermissionAction {
    match policy {
        PermissionPolicy::AutoApprove => PermissionAction::Approve,
        PermissionPolicy::AutoApproveExcept(blocked) => {
            if blocked.iter().any(|b| b == permission) {
                PermissionAction::Reject {
                    message: format!("permission '{}' requires operator approval", permission),
                }
            } else {
                PermissionAction::Approve
            }
        }
        PermissionPolicy::Deny => PermissionAction::Reject {
            message: format!("permission '{}' denied by policy", permission),
        },
    }
}
