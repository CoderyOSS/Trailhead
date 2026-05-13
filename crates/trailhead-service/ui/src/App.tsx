import { useState, useEffect } from "react";
import type { Job, Worker } from "./types";
import { JobList } from "./JobList";
import { WorkerList } from "./WorkerList";

type Tab = "jobs" | "workers";

export default function App() {
  const [tab, setTab] = useState<Tab>("jobs");
  const [jobs, setJobs] = useState<Job[]>([]);
  const [workers, setWorkers] = useState<Worker[]>([]);

  useEffect(() => {
    fetch("/api/v1/jobs")
      .then((r) => r.json())
      .then((data: unknown) => {
        if (Array.isArray(data)) setJobs(data);
      })
      .catch(() => {});
  }, []);

  useEffect(() => {
    fetch("/api/v1/workers")
      .then((r) => r.json())
      .then((data: unknown) => {
        if (Array.isArray(data)) setWorkers(data);
      })
      .catch(() => {});
  }, []);

  return (
    <div>
      <h1>Trailhead</h1>
      <nav>
        <button onClick={() => setTab("jobs")}>Jobs ({jobs.length})</button>
        <button onClick={() => setTab("workers")}>Workers ({workers.length})</button>
      </nav>
      {tab === "jobs" ? <JobList jobs={jobs} /> : <WorkerList workers={workers} />}
    </div>
  );
}
