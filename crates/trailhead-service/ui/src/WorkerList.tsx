import type { Worker } from "./types";

export function WorkerList({ workers }: { workers: Worker[] }) {
  return (
    <table>
      <thead>
        <tr>
          <th>ID</th>
          <th>Job</th>
          <th>Status</th>
          <th>Last Heartbeat</th>
          <th>Created</th>
        </tr>
      </thead>
      <tbody>
        {workers.map((w) => (
          <tr key={w.id}>
            <td>{w.id.slice(0, 8)}</td>
            <td>{w.job_id ? w.job_id.slice(0, 8) : "-"}</td>
            <td>{w.status}</td>
            <td>{w.heartbeat_at ? new Date(w.heartbeat_at).toLocaleString() : "-"}</td>
            <td>{new Date(w.created_at).toLocaleString()}</td>
          </tr>
        ))}
      </tbody>
    </table>
  );
}
