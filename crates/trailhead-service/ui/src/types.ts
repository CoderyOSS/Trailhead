export interface Job {
  id: string;
  project_id: string;
  description: string;
  status: string;
  worker_id: string | null;
  current_stage: string | null;
  workflow_name: string | null;
  attempt: number;
  max_attempts: number;
  created_at: string;
  updated_at: string;
  started_at: string | null;
  finished_at: string | null;
  result: string | null;
  error: string | null;
}

export interface Worker {
  id: string;
  job_id: string | null;
  status: string;
  heartbeat_at: string | null;
  created_at: string;
}

export interface Project {
  id: string;
  repo_url: string;
  branch: string;
  created_at: string;
}
