import type { Job } from "./types";

const STATUS_COLORS: Record<string, string> = {
  queued: "#6b7280",
  scheduled: "#3b82f6",
  provisioning: "#8b5cf6",
  running: "#22c55e",
  checkpointing: "#f59e0b",
  paused: "#eab308",
  paused_for_human: "#f97316",
  resuming: "#3b82f6",
  failed_retryable: "#ef4444",
  failed_final: "#991b1b",
  completed: "#16a34a",
  cancelled: "#6b7280",
};

function statusColor(status: string): string {
  return STATUS_COLORS[status] || "#6b7280";
}

export function JobList({ jobs }: { jobs: Job[] }) {
  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Description</th>
          <th>Status</th>
          <th>Stage</th>
          <th>Attempt</th>
          <th>Created</th>
        </tr>
      </thead>
      <tbody>
        {jobs.map((job) => (
          <tr key={job.id}>
            <td>{job.id.slice(0, 8)}</td>
            <td>{job.description}</td>
            <td>
              <span style={{ color: statusColor(job.status) }}>{job.status}</span>
            </td>
            <td>{job.current_stage || "-"}</td>
            <td>{job.attempt}/{job.max_attempts}</td>
            <td>{new Date(job.created_at).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
