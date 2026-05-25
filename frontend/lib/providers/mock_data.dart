enum JobState { running, paused, passed, failed, cancelled, queued, retrying }

class WorkflowSummary {
  final String id;
  final String name;
  final int version;
  final int? draft;
  final String updated;

  const WorkflowSummary({
    required this.id,
    required this.name,
    required this.version,
    this.draft,
    required this.updated,
  });
}

class JobSummary {
  final String id;
  final String? workflow;
  final int? workflowVersion;
  final JobState state;
  final String? input;
  final int elapsedSec;
  final int tokens;
  final double costUsd;

  const JobSummary({
    required this.id,
    this.workflow,
    this.workflowVersion,
    required this.state,
    this.input,
    this.elapsedSec = 0,
    this.tokens = 0,
    this.costUsd = 0,
  });
}

final mockWorkflow = WorkflowSummary(
  id: 'wf_pr_reviewer',
  name: 'pr-reviewer',
  version: 14,
  draft: 15,
  updated: '2 min ago by jen.b',
);

final mockJob = JobSummary(
  id: 'job_r8f2a91c',
  workflow: 'pr-reviewer',
  workflowVersion: 14,
  state: JobState.running,
  input: 'PR #1428',
  elapsedSec: 247,
  tokens: 184233,
  costUsd: 0.42,
);

const historyCount = 13;
