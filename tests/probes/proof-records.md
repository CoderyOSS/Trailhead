# Trailhead E2E Test Suite

**Date:** 2026-05-15T07:13:59.661Z
**Events:** 561
**Duration:** 3801ms

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:56.198 | Recv | sql:workers | `[]` |
| 2 | 07:13:56.200 | Recv | sql:jobs | `[]` |
| 3 | 07:13:56.201 | Recv | sql:jobs | `[]` |
| 4 | 07:13:57.201 | Recv | sql:jobs | `[]` |
| 5 | 07:13:58.898 | Send | sql.clear | `all tables` |
| 6 | 07:13:58.914 | Send | sql.put | `2 rows` |
| 7 | 07:13:58.938 | Send | sql.clear | `all tables` |
| 8 | 07:13:58.943 | Send | sql.put | `2 rows` |
| 9 | 07:13:59.222 | Send | sql.put | `1 rows` |
| 10 | 07:13:59.222 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239221-bkvqrb","description":"Hello world test"}` |
| 11 | 07:13:59.223 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 12 | 07:13:59.224 | Response | http response | `200 {"job_id":"93e6bf78-c5ed-4aa8-b78c-20d30707f7b4"}` |

<details><summary>1. Recv sql:workers</summary>

```json
[]
```

</details>

<details><summary>2. Recv sql:jobs</summary>

```json
[]
```

</details>

<details><summary>3. Recv sql:jobs</summary>

```json
[]
```

</details>

<details><summary>4. Recv sql:jobs</summary>

```json
[]
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

---

## lists jobs via HTTP matching DB count

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.920 | Send | sql.put | `1 rows` |
| 2 | 07:13:58.920 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238918-vx2eib","description":"Job 1"}` |
| 3 | 07:13:58.922 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:58.925 | Response | http response | `200 {"job_id":"7f7703d4-ed44-4241-98a0-9264b19abf52"}` |
| 5 | 07:13:58.925 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238918-vx2eib","description":"Job 2"}` |
| 6 | 07:13:58.926 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 7 | 07:13:58.927 | Response | http response | `200 {"job_id":"c088f7fd-12de-42cf-88a4-0d9ec47c9cb8"}` |
| 8 | 07:13:58.927 | Send | http.send | `GET /api/v1/jobs` |
| 9 | 07:13:58.928 | Recv | sql:jobs | `[{"id":"7f7703d4-ed44-4241-98a0-9264b19abf52","project_id":"test-1778829238918-vx2eib","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-0...` |
| 10 | 07:13:58.928 | Response | http response | `200 [{"id":"7f7703d4-ed44-4241-98a0-9264b19abf52","project_id":"test-1778829238918-vx2eib","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:jobs</summary>

```json
[
  {
    "id": "7f7703d4-ed44-4241-98a0-9264b19abf52",
    "project_id": "test-1778829238918-vx2eib",
    "description": "Job 1",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.922345311+00:00",
    "updated_at": "2026-05-15T07:13:58.922345311+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "c088f7fd-12de-42cf-88a4-0d9ec47c9cb8",
    "project_id": "test-1778829238918-vx2eib",
    "description": "Job 2",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.925554855+00:00",
    "updated_at": "2026-05-15T07:13:58.925554855+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## list workers via HTTP matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.943 | Send | http.send | `GET /api/v1/workers` |
| 2 | 07:13:58.945 | Recv | sql:workers | `[]` |
| 3 | 07:13:58.946 | Response | http response | `200 []` |

<details><summary>2. Recv sql:workers</summary>

```json
[]
```

</details>

---

## GET /api/v1/jobs returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.954 | Send | sql.put | `1 rows` |
| 2 | 07:13:58.954 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238952-b25cot","description":"Dashboard test job"}` |
| 3 | 07:13:58.955 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:58.957 | Response | http response | `200 {"job_id":"008d28d8-df17-4d91-9868-c3db706b7170"}` |
| 5 | 07:13:58.957 | Send | http.send | `GET /api/v1/jobs` |
| 6 | 07:13:58.957 | Recv | sql:jobs | `[{"id":"008d28d8-df17-4d91-9868-c3db706b7170","project_id":"test-1778829238952-b25cot","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 7 | 07:13:58.958 | Response | http response | `200 [{"id":"008d28d8-df17-4d91-9868-c3db706b7170","project_id":"test-1778829238952-b25cot","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "008d28d8-df17-4d91-9868-c3db706b7170",
    "project_id": "test-1778829238952-b25cot",
    "description": "Dashboard test job",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.954607719+00:00",
    "updated_at": "2026-05-15T07:13:58.954607719+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## GET /api/v1/jobs/{id} returns detail matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.960 | Send | sql.put | `1 rows` |
| 2 | 07:13:58.960 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238959-8t72rd","description":"Detail test"}` |
| 3 | 07:13:58.962 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:58.967 | Response | http response | `200 {"job_id":"d1bb31b3-7668-4661-bd6d-e76b6b82731b"}` |
| 5 | 07:13:58.967 | Send | http.send | `GET /api/v1/jobs/d1bb31b3-7668-4661-bd6d-e76b6b82731b` |
| 6 | 07:13:58.968 | Recv | sql:jobs | `[{"id":"d1bb31b3-7668-4661-bd6d-e76b6b82731b","project_id":"test-1778829238959-8t72rd","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 7 | 07:13:58.968 | Response | http response | `200 {"id":"d1bb31b3-7668-4661-bd6d-e76b6b82731b","project_id":"test-1778829238959-8t72rd","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "d1bb31b3-7668-4661-bd6d-e76b6b82731b",
    "project_id": "test-1778829238959-8t72rd",
    "description": "Detail test",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.960881097+00:00",
    "updated_at": "2026-05-15T07:13:58.960881097+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## GET /api/v1/workers returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.971 | Send | sql.put | `1 rows` |
| 2 | 07:13:58.971 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238969-f6lg2w","description":"Worker list test"}` |
| 3 | 07:13:58.972 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:58.974 | Response | http response | `200 {"job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e"}` |
| 5 | 07:13:58.974 | Send | http.send | `POST /api/v1/workers {"job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test"}` |
| 6 | 07:13:58.975 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:58.979 | Response | http response | `200 {"worker_id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7"}` |
| 8 | 07:13:58.979 | Send | http.send | `POST /api/v1/workers/9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7/register {"job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e"}` |
| 9 | 07:13:58.979 | Recv | sql:workers | `[{"id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7","job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.974519807+00:00","destroyed_at":null}]` |
| 10 | 07:13:58.980 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:58.982 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:58.984 | Response | http response | `200 ` |
| 13 | 07:13:58.984 | Send | http.send | `GET /api/v1/workers` |
| 14 | 07:13:58.985 | Recv | sql:workers | `[{"id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7","job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.974519807+00:00","destroyed_at":null}]` |
| 15 | 07:13:58.985 | Response | http response | `200 [{"id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7","job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.974519807+00:00","destroyed_at":null}]` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7",
    "job_id": "f9cb3437-a06f-4d96-b00d-c469400ad50e",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:58.974519807+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7",
    "job_id": "f9cb3437-a06f-4d96-b00d-c469400ad50e",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:58.974519807+00:00",
    "destroyed_at": null
  }
]
```

</details>

---

## POST /api/v1/jobs/{id}/pause changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:58.987 | Send | sql.put | `1 rows` |
| 2 | 07:13:58.987 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238986-rt7ncg","description":"Pause via dashboard"}` |
| 3 | 07:13:58.988 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:58.990 | Response | http response | `200 {"job_id":"d166c703-4a2f-4c61-ad1c-05a9bd9420d3"}` |
| 5 | 07:13:58.990 | Send | http.send | `POST /api/v1/workers {"job_id":"d166c703-4a2f-4c61-ad1c-05a9bd9420d3","provider":"test"}` |
| 6 | 07:13:58.990 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:58.992 | Response | http response | `200 {"worker_id":"fa915614-6afe-4507-933e-91d195d139ed"}` |
| 8 | 07:13:58.992 | Send | http.send | `POST /api/v1/workers/fa915614-6afe-4507-933e-91d195d139ed/register {"job_id":"d166c703-4a2f-4c61-ad1c-05a9bd9420d3"}` |
| 9 | 07:13:58.992 | Recv | sql:workers | `[{"id":"fa915614-6afe-4507-933e-91d195d139ed","job_id":"d166c703-4a2f-4c61-ad1c-05a9bd9420d3","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.990223396+00:00","destroyed_at":null}]` |
| 10 | 07:13:58.993 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:58.995 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:58.996 | Response | http response | `200 ` |
| 13 | 07:13:58.996 | Send | http.send | `POST /api/v1/jobs/d166c703-4a2f-4c61-ad1c-05a9bd9420d3/pause` |
| 14 | 07:13:58.997 | Recv | sql:jobs | `[{"id":"d166c703-4a2f-4c61-ad1c-05a9bd9420d3","project_id":"test-1778829238986-rt7ncg","description":"Pause via dashboard","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 15 | 07:13:58.997 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 16 | 07:13:58.998 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "fa915614-6afe-4507-933e-91d195d139ed",
    "job_id": "d166c703-4a2f-4c61-ad1c-05a9bd9420d3",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:58.990223396+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
[
  {
    "id": "d166c703-4a2f-4c61-ad1c-05a9bd9420d3",
    "project_id": "test-1778829238986-rt7ncg",
    "description": "Pause via dashboard",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.987994829+00:00",
    "updated_at": "2026-05-15T07:13:58.994947690+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## POST /api/v1/jobs/{id}/cancel changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.000 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.000 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829238999-8tnjvk","description":"Cancel via dashboard"}` |
| 3 | 07:13:59.000 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.001 | Response | http response | `200 {"job_id":"0fc47f07-4136-45de-9143-1dc8583fdd59"}` |
| 5 | 07:13:59.001 | Send | http.send | `POST /api/v1/jobs/0fc47f07-4136-45de-9143-1dc8583fdd59/cancel` |
| 6 | 07:13:59.002 | Recv | sql:jobs | `[{"id":"0fc47f07-4136-45de-9143-1dc8583fdd59","project_id":"test-1778829238999-8tnjvk","description":"Cancel via dashboard","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 7 | 07:13:59.002 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 8 | 07:13:59.003 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "0fc47f07-4136-45de-9143-1dc8583fdd59",
    "project_id": "test-1778829238999-8tnjvk",
    "description": "Cancel via dashboard",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.000450177+00:00",
    "updated_at": "2026-05-15T07:13:59.000450177+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>7. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## new job is queued in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.006 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.006 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239005-rh9bni","description":"State machine test"}` |
| 3 | 07:13:59.006 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.007 | Response | http response | `200 {"job_id":"634cfe06-5a88-4c2c-b9d7-4d403caef029"}` |
| 5 | 07:13:59.608 | Send | sql.put | `1 rows` |
| 6 | 07:13:59.608 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239607-rntih7","description":"Start at first stage"}` |
| 7 | 07:13:59.609 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 8 | 07:13:59.610 | Response | http response | `200 {"job_id":"4a0308ed-2634-4537-af4b-cf64f59df0bd"}` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>7. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

---

## running to paused via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.009 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.009 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239007-7z94lt","description":"Pause test"}` |
| 3 | 07:13:59.010 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.012 | Response | http response | `200 {"job_id":"8e85841e-e6fb-4c7c-9fc8-4ae59c197b25"}` |
| 5 | 07:13:59.012 | Send | http.send | `POST /api/v1/workers {"job_id":"8e85841e-e6fb-4c7c-9fc8-4ae59c197b25","provider":"test"}` |
| 6 | 07:13:59.012 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.013 | Response | http response | `200 {"worker_id":"5d9d2da0-fb53-4352-a5ae-4b93676038c7"}` |
| 8 | 07:13:59.013 | Send | http.send | `POST /api/v1/workers/5d9d2da0-fb53-4352-a5ae-4b93676038c7/register {"job_id":"8e85841e-e6fb-4c7c-9fc8-4ae59c197b25"}` |
| 9 | 07:13:59.014 | Recv | sql:workers | `[{"id":"5d9d2da0-fb53-4352-a5ae-4b93676038c7","job_id":"8e85841e-e6fb-4c7c-9fc8-4ae59c197b25","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.012449969+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.014 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.015 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.016 | Response | http response | `200 ` |
| 13 | 07:13:59.016 | Send | http.send | `POST /api/v1/jobs/8e85841e-e6fb-4c7c-9fc8-4ae59c197b25/pause` |
| 14 | 07:13:59.016 | Recv | sql:jobs | `[{"id":"8e85841e-e6fb-4c7c-9fc8-4ae59c197b25","project_id":"test-1778829239007-7z94lt","description":"Pause test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 15 | 07:13:59.017 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 16 | 07:13:59.018 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "5d9d2da0-fb53-4352-a5ae-4b93676038c7",
    "job_id": "8e85841e-e6fb-4c7c-9fc8-4ae59c197b25",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.012449969+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
[
  {
    "id": "8e85841e-e6fb-4c7c-9fc8-4ae59c197b25",
    "project_id": "test-1778829239007-7z94lt",
    "description": "Pause test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.009186865+00:00",
    "updated_at": "2026-05-15T07:13:59.015448424+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## paused to resuming via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.020 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.020 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239018-tzmy3v","description":"Resume test"}` |
| 3 | 07:13:59.021 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.022 | Response | http response | `200 {"job_id":"df161697-d8ae-42e7-8add-d3d5da4f40c5"}` |
| 5 | 07:13:59.022 | Send | http.send | `POST /api/v1/workers {"job_id":"df161697-d8ae-42e7-8add-d3d5da4f40c5","provider":"test"}` |
| 6 | 07:13:59.022 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.023 | Response | http response | `200 {"worker_id":"a1b77cef-6757-44fa-984a-30c11a928adb"}` |
| 8 | 07:13:59.023 | Send | http.send | `POST /api/v1/workers/a1b77cef-6757-44fa-984a-30c11a928adb/register {"job_id":"df161697-d8ae-42e7-8add-d3d5da4f40c5"}` |
| 9 | 07:13:59.024 | Recv | sql:workers | `[{"id":"a1b77cef-6757-44fa-984a-30c11a928adb","job_id":"df161697-d8ae-42e7-8add-d3d5da4f40c5","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.022474536+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.024 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.026 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.027 | Response | http response | `200 ` |
| 13 | 07:13:59.027 | Send | http.send | `POST /api/v1/jobs/df161697-d8ae-42e7-8add-d3d5da4f40c5/pause` |
| 14 | 07:13:59.027 | Recv | sql:jobs | `[{"id":"df161697-d8ae-42e7-8add-d3d5da4f40c5","project_id":"test-1778829239018-tzmy3v","description":"Resume test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 15 | 07:13:59.028 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 16 | 07:13:59.029 | Response | http response | `200 ` |
| 17 | 07:13:59.029 | Send | http.send | `POST /api/v1/jobs/df161697-d8ae-42e7-8add-d3d5da4f40c5/resume` |
| 18 | 07:13:59.029 | Recv | sql:jobs | `[{"id":"df161697-d8ae-42e7-8add-d3d5da4f40c5","project_id":"test-1778829239018-tzmy3v","description":"Resume test","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 19 | 07:13:59.030 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 20 | 07:13:59.031 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "a1b77cef-6757-44fa-984a-30c11a928adb",
    "job_id": "df161697-d8ae-42e7-8add-d3d5da4f40c5",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.022474536+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
[
  {
    "id": "df161697-d8ae-42e7-8add-d3d5da4f40c5",
    "project_id": "test-1778829239018-tzmy3v",
    "description": "Resume test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.020933495+00:00",
    "updated_at": "2026-05-15T07:13:59.025445841+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>18. Recv sql:jobs</summary>

```json
[
  {
    "id": "df161697-d8ae-42e7-8add-d3d5da4f40c5",
    "project_id": "test-1778829239018-tzmy3v",
    "description": "Resume test",
    "status": "paused",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.020933495+00:00",
    "updated_at": "2026-05-15T07:13:59.028029542+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>19. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## running to completed, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.032 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.032 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239031-7o194a","description":"Complete test"}` |
| 3 | 07:13:59.033 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.034 | Response | http response | `200 {"job_id":"3880c234-c642-4271-871b-27fe25f7d2f9"}` |
| 5 | 07:13:59.034 | Send | http.send | `POST /api/v1/workers {"job_id":"3880c234-c642-4271-871b-27fe25f7d2f9","provider":"test"}` |
| 6 | 07:13:59.035 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.036 | Response | http response | `200 {"worker_id":"deb2f3e7-74bd-4645-9642-4f0d2ce45aac"}` |
| 8 | 07:13:59.036 | Send | http.send | `POST /api/v1/workers/deb2f3e7-74bd-4645-9642-4f0d2ce45aac/register {"job_id":"3880c234-c642-4271-871b-27fe25f7d2f9"}` |
| 9 | 07:13:59.036 | Recv | sql:workers | `[{"id":"deb2f3e7-74bd-4645-9642-4f0d2ce45aac","job_id":"3880c234-c642-4271-871b-27fe25f7d2f9","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.034746337+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.037 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.038 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.040 | Response | http response | `200 ` |
| 13 | 07:13:59.040 | Send | http.send | `POST /api/v1/workers/deb2f3e7-74bd-4645-9642-4f0d2ce45aac/complete {"result":"success"}` |
| 14 | 07:13:59.040 | Recv | sql:workers | `[{"id":"deb2f3e7-74bd-4645-9642-4f0d2ce45aac","job_id":"3880c234-c642-4271-871b-27fe25f7d2f9","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.034746337+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.040 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.044 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.046 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "deb2f3e7-74bd-4645-9642-4f0d2ce45aac",
    "job_id": "3880c234-c642-4271-871b-27fe25f7d2f9",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.034746337+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "deb2f3e7-74bd-4645-9642-4f0d2ce45aac",
    "job_id": "3880c234-c642-4271-871b-27fe25f7d2f9",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.034746337+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## running to failed_retryable, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.047 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.047 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239046-hktt84","description":"Fail test"}` |
| 3 | 07:13:59.048 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.049 | Response | http response | `200 {"job_id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd"}` |
| 5 | 07:13:59.050 | Send | http.send | `POST /api/v1/workers {"job_id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd","provider":"test"}` |
| 6 | 07:13:59.050 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.051 | Response | http response | `200 {"worker_id":"46c6282a-d217-451d-9aa9-6c6763f84091"}` |
| 8 | 07:13:59.051 | Send | http.send | `POST /api/v1/workers/46c6282a-d217-451d-9aa9-6c6763f84091/register {"job_id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd"}` |
| 9 | 07:13:59.052 | Recv | sql:workers | `[{"id":"46c6282a-d217-451d-9aa9-6c6763f84091","job_id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.050121753+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.052 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.054 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.055 | Response | http response | `200 ` |
| 13 | 07:13:59.055 | Send | http.send | `POST /api/v1/workers/46c6282a-d217-451d-9aa9-6c6763f84091/fail {"error":"transient failure"}` |
| 14 | 07:13:59.055 | Recv | sql:workers | `[{"id":"46c6282a-d217-451d-9aa9-6c6763f84091","job_id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.050121753+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.056 | Recv | sql:jobs | `[{"id":"36c98c86-4e4d-42c5-91fa-ead13d4838cd","project_id":"test-1778829239046-hktt84","description":"Fail test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 16 | 07:13:59.056 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5","changes":1}` |
| 17 | 07:13:59.057 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 18 | 07:13:59.059 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "46c6282a-d217-451d-9aa9-6c6763f84091",
    "job_id": "36c98c86-4e4d-42c5-91fa-ead13d4838cd",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.050121753+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "46c6282a-d217-451d-9aa9-6c6763f84091",
    "job_id": "36c98c86-4e4d-42c5-91fa-ead13d4838cd",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.050121753+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
[
  {
    "id": "36c98c86-4e4d-42c5-91fa-ead13d4838cd",
    "project_id": "test-1778829239046-hktt84",
    "description": "Fail test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.048073979+00:00",
    "updated_at": "2026-05-15T07:13:59.054090340+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5",
  "changes": 1
}
```

</details>

<details><summary>17. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## cannot resume completed job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.061 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.061 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239060-4glhmt","description":"Terminal test"}` |
| 3 | 07:13:59.062 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.063 | Response | http response | `200 {"job_id":"3ce46b69-6c38-443f-a937-6a7c5556a25a"}` |
| 5 | 07:13:59.063 | Send | http.send | `POST /api/v1/workers {"job_id":"3ce46b69-6c38-443f-a937-6a7c5556a25a","provider":"test"}` |
| 6 | 07:13:59.063 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.065 | Response | http response | `200 {"worker_id":"e5195439-fc88-4455-8fab-720ab7ccdc87"}` |
| 8 | 07:13:59.065 | Send | http.send | `POST /api/v1/workers/e5195439-fc88-4455-8fab-720ab7ccdc87/register {"job_id":"3ce46b69-6c38-443f-a937-6a7c5556a25a"}` |
| 9 | 07:13:59.065 | Recv | sql:workers | `[{"id":"e5195439-fc88-4455-8fab-720ab7ccdc87","job_id":"3ce46b69-6c38-443f-a937-6a7c5556a25a","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.063445979+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.065 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.067 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.068 | Response | http response | `200 ` |
| 13 | 07:13:59.068 | Send | http.send | `POST /api/v1/workers/e5195439-fc88-4455-8fab-720ab7ccdc87/complete {"result":"done"}` |
| 14 | 07:13:59.069 | Recv | sql:workers | `[{"id":"e5195439-fc88-4455-8fab-720ab7ccdc87","job_id":"3ce46b69-6c38-443f-a937-6a7c5556a25a","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.063445979+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.069 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.070 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.072 | Response | http response | `200 ` |
| 18 | 07:13:59.072 | Send | http.send | `POST /api/v1/jobs/3ce46b69-6c38-443f-a937-6a7c5556a25a/resume` |
| 19 | 07:13:59.072 | Recv | sql:jobs | `[{"id":"3ce46b69-6c38-443f-a937-6a7c5556a25a","project_id":"test-1778829239060-4glhmt","description":"Terminal test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"create...` |
| 20 | 07:13:59.072 | Response | http response | `409 invalid transition: completed -> resuming` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "e5195439-fc88-4455-8fab-720ab7ccdc87",
    "job_id": "3ce46b69-6c38-443f-a937-6a7c5556a25a",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.063445979+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "e5195439-fc88-4455-8fab-720ab7ccdc87",
    "job_id": "3ce46b69-6c38-443f-a937-6a7c5556a25a",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.063445979+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>19. Recv sql:jobs</summary>

```json
[
  {
    "id": "3ce46b69-6c38-443f-a937-6a7c5556a25a",
    "project_id": "test-1778829239060-4glhmt",
    "description": "Terminal test",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "done",
    "error": null,
    "created_at": "2026-05-15T07:13:59.061796825+00:00",
    "updated_at": "2026-05-15T07:13:59.069217732+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.069217732+00:00"
  }
]
```

</details>

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.074 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.075 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239073-mfqtje","description":"Cancel queued"}` |
| 3 | 07:13:59.076 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.078 | Response | http response | `200 {"job_id":"617a4d99-671a-4bcc-9a8f-ac7156d96cff"}` |
| 5 | 07:13:59.078 | Send | http.send | `POST /api/v1/jobs/617a4d99-671a-4bcc-9a8f-ac7156d96cff/cancel` |
| 6 | 07:13:59.078 | Recv | sql:jobs | `[{"id":"617a4d99-671a-4bcc-9a8f-ac7156d96cff","project_id":"test-1778829239073-mfqtje","description":"Cancel queued","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 7 | 07:13:59.079 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 8 | 07:13:59.080 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "617a4d99-671a-4bcc-9a8f-ac7156d96cff",
    "project_id": "test-1778829239073-mfqtje",
    "description": "Cancel queued",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.075127411+00:00",
    "updated_at": "2026-05-15T07:13:59.075127411+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>7. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.082 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.082 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239080-bw08nj","description":"Cancel running"}` |
| 3 | 07:13:59.082 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.084 | Response | http response | `200 {"job_id":"46850b74-f94b-459a-b8cb-215853fbaec3"}` |
| 5 | 07:13:59.084 | Send | http.send | `POST /api/v1/workers {"job_id":"46850b74-f94b-459a-b8cb-215853fbaec3","provider":"test"}` |
| 6 | 07:13:59.084 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.085 | Response | http response | `200 {"worker_id":"df712b3c-881d-4fb3-aa6b-94a99af4ce39"}` |
| 8 | 07:13:59.085 | Send | http.send | `POST /api/v1/workers/df712b3c-881d-4fb3-aa6b-94a99af4ce39/register {"job_id":"46850b74-f94b-459a-b8cb-215853fbaec3"}` |
| 9 | 07:13:59.086 | Recv | sql:workers | `[{"id":"df712b3c-881d-4fb3-aa6b-94a99af4ce39","job_id":"46850b74-f94b-459a-b8cb-215853fbaec3","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.084153374+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.086 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.088 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.089 | Response | http response | `200 ` |
| 13 | 07:13:59.089 | Send | http.send | `POST /api/v1/jobs/46850b74-f94b-459a-b8cb-215853fbaec3/cancel` |
| 14 | 07:13:59.089 | Recv | sql:jobs | `[{"id":"46850b74-f94b-459a-b8cb-215853fbaec3","project_id":"test-1778829239080-bw08nj","description":"Cancel running","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |
| 15 | 07:13:59.090 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 16 | 07:13:59.092 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "df712b3c-881d-4fb3-aa6b-94a99af4ce39",
    "job_id": "46850b74-f94b-459a-b8cb-215853fbaec3",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.084153374+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
[
  {
    "id": "46850b74-f94b-459a-b8cb-215853fbaec3",
    "project_id": "test-1778829239080-bw08nj",
    "description": "Cancel running",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.082451992+00:00",
    "updated_at": "2026-05-15T07:13:59.088039066+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## worker register sets job to running in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.096 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.096 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239094-vgr4cw","description":"E2E test job"}` |
| 3 | 07:13:59.096 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.098 | Response | http response | `200 {"job_id":"21b17fdf-be4f-4681-8f55-16808a2820bc"}` |
| 5 | 07:13:59.098 | Send | http.send | `POST /api/v1/workers {"job_id":"21b17fdf-be4f-4681-8f55-16808a2820bc","provider":"test"}` |
| 6 | 07:13:59.098 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.099 | Response | http response | `200 {"worker_id":"777cfd0d-fe45-4ac3-a83a-b367bb5b1c85"}` |
| 8 | 07:13:59.099 | Send | http.send | `POST /api/v1/workers/777cfd0d-fe45-4ac3-a83a-b367bb5b1c85/register {"job_id":"21b17fdf-be4f-4681-8f55-16808a2820bc"}` |
| 9 | 07:13:59.100 | Recv | sql:workers | `[{"id":"777cfd0d-fe45-4ac3-a83a-b367bb5b1c85","job_id":"21b17fdf-be4f-4681-8f55-16808a2820bc","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.098392649+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.100 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.102 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.103 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "777cfd0d-fe45-4ac3-a83a-b367bb5b1c85",
    "job_id": "21b17fdf-be4f-4681-8f55-16808a2820bc",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.098392649+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## worker heartbeat updates timestamp in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.105 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.105 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239104-nzc9i3","description":"E2E test job"}` |
| 3 | 07:13:59.105 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.106 | Response | http response | `200 {"job_id":"7284a4f5-f297-4c56-aedd-b479b3d29832"}` |
| 5 | 07:13:59.106 | Send | http.send | `POST /api/v1/workers {"job_id":"7284a4f5-f297-4c56-aedd-b479b3d29832","provider":"test"}` |
| 6 | 07:13:59.108 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.109 | Response | http response | `200 {"worker_id":"cc433d54-47f8-4f1c-b560-681ac1ef250c"}` |
| 8 | 07:13:59.109 | Send | http.send | `POST /api/v1/workers/cc433d54-47f8-4f1c-b560-681ac1ef250c/register {"job_id":"7284a4f5-f297-4c56-aedd-b479b3d29832"}` |
| 9 | 07:13:59.109 | Recv | sql:workers | `[{"id":"cc433d54-47f8-4f1c-b560-681ac1ef250c","job_id":"7284a4f5-f297-4c56-aedd-b479b3d29832","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.107720086+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.110 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.111 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.112 | Response | http response | `200 ` |
| 13 | 07:13:59.112 | Send | http.send | `POST /api/v1/workers/cc433d54-47f8-4f1c-b560-681ac1ef250c/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":500,"completion_tokens":200},"files_changed":0,"tool_ca...` |
| 14 | 07:13:59.112 | Recv | sql:workers | `{"sql":"UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2","changes":1}` |
| 15 | 07:13:59.113 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "cc433d54-47f8-4f1c-b560-681ac1ef250c",
    "job_id": "7284a4f5-f297-4c56-aedd-b479b3d29832",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.107720086+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## worker checkpoint writes to jobs and checkpoints tables

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.115 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.115 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239114-33fnaf","description":"E2E test job"}` |
| 3 | 07:13:59.115 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.116 | Response | http response | `200 {"job_id":"0b99774b-e967-4ecb-a454-1c6cda934fae"}` |
| 5 | 07:13:59.116 | Send | http.send | `POST /api/v1/workers {"job_id":"0b99774b-e967-4ecb-a454-1c6cda934fae","provider":"test"}` |
| 6 | 07:13:59.117 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.118 | Response | http response | `200 {"worker_id":"23466024-af9a-47a1-be18-7e67f8cb1fab"}` |
| 8 | 07:13:59.118 | Send | http.send | `POST /api/v1/workers/23466024-af9a-47a1-be18-7e67f8cb1fab/register {"job_id":"0b99774b-e967-4ecb-a454-1c6cda934fae"}` |
| 9 | 07:13:59.119 | Recv | sql:workers | `[{"id":"23466024-af9a-47a1-be18-7e67f8cb1fab","job_id":"0b99774b-e967-4ecb-a454-1c6cda934fae","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.117368697+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.119 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.120 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.121 | Response | http response | `200 ` |
| 13 | 07:13:59.121 | Send | http.send | `POST /api/v1/workers/23466024-af9a-47a1-be18-7e67f8cb1fab/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"def456","token_usage":{"prompt_...` |
| 14 | 07:13:59.121 | Recv | sql:workers | `[{"id":"23466024-af9a-47a1-be18-7e67f8cb1fab","job_id":"0b99774b-e967-4ecb-a454-1c6cda934fae","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.117368697+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.122 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.127 | Recv | sql:jobs | `[{"id":"0b99774b-e967-4ecb-a454-1c6cda934fae","project_id":"test-1778829239114-33fnaf","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 17 | 07:13:59.127 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.129 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "23466024-af9a-47a1-be18-7e67f8cb1fab",
    "job_id": "0b99774b-e967-4ecb-a454-1c6cda934fae",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.117368697+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "23466024-af9a-47a1-be18-7e67f8cb1fab",
    "job_id": "0b99774b-e967-4ecb-a454-1c6cda934fae",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.117368697+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "0b99774b-e967-4ecb-a454-1c6cda934fae",
    "project_id": "test-1778829239114-33fnaf",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.115526032+00:00",
    "updated_at": "2026-05-15T07:13:59.120310407+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## worker complete sets result and destroys worker

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.131 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.131 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239130-540mpq","description":"E2E test job"}` |
| 3 | 07:13:59.131 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.133 | Response | http response | `200 {"job_id":"b0df7217-0f0e-4268-8e18-ba44b472b239"}` |
| 5 | 07:13:59.133 | Send | http.send | `POST /api/v1/workers {"job_id":"b0df7217-0f0e-4268-8e18-ba44b472b239","provider":"test"}` |
| 6 | 07:13:59.134 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.135 | Response | http response | `200 {"worker_id":"dd94e75d-f7e0-4035-b979-0e99b8226617"}` |
| 8 | 07:13:59.135 | Send | http.send | `POST /api/v1/workers/dd94e75d-f7e0-4035-b979-0e99b8226617/register {"job_id":"b0df7217-0f0e-4268-8e18-ba44b472b239"}` |
| 9 | 07:13:59.135 | Recv | sql:workers | `[{"id":"dd94e75d-f7e0-4035-b979-0e99b8226617","job_id":"b0df7217-0f0e-4268-8e18-ba44b472b239","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.134004410+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.136 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.137 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.138 | Response | http response | `200 ` |
| 13 | 07:13:59.138 | Send | http.send | `POST /api/v1/workers/dd94e75d-f7e0-4035-b979-0e99b8226617/complete {"result":"success"}` |
| 14 | 07:13:59.139 | Recv | sql:workers | `[{"id":"dd94e75d-f7e0-4035-b979-0e99b8226617","job_id":"b0df7217-0f0e-4268-8e18-ba44b472b239","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.134004410+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.140 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.141 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.143 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "dd94e75d-f7e0-4035-b979-0e99b8226617",
    "job_id": "b0df7217-0f0e-4268-8e18-ba44b472b239",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.134004410+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "dd94e75d-f7e0-4035-b979-0e99b8226617",
    "job_id": "b0df7217-0f0e-4268-8e18-ba44b472b239",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.134004410+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## worker fail sets error in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.145 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.145 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239143-2prwhk","description":"E2E test job"}` |
| 3 | 07:13:59.145 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.146 | Response | http response | `200 {"job_id":"13137877-d705-4fc6-b4ec-042e49092bea"}` |
| 5 | 07:13:59.146 | Send | http.send | `POST /api/v1/workers {"job_id":"13137877-d705-4fc6-b4ec-042e49092bea","provider":"test"}` |
| 6 | 07:13:59.146 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.147 | Response | http response | `200 {"worker_id":"94591a71-2442-456c-bc95-677a1214c9f7"}` |
| 8 | 07:13:59.147 | Send | http.send | `POST /api/v1/workers/94591a71-2442-456c-bc95-677a1214c9f7/register {"job_id":"13137877-d705-4fc6-b4ec-042e49092bea"}` |
| 9 | 07:13:59.147 | Recv | sql:workers | `[{"id":"94591a71-2442-456c-bc95-677a1214c9f7","job_id":"13137877-d705-4fc6-b4ec-042e49092bea","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.146535071+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.148 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.150 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.151 | Response | http response | `200 ` |
| 13 | 07:13:59.151 | Send | http.send | `POST /api/v1/workers/94591a71-2442-456c-bc95-677a1214c9f7/fail {"error":"build failed"}` |
| 14 | 07:13:59.151 | Recv | sql:workers | `[{"id":"94591a71-2442-456c-bc95-677a1214c9f7","job_id":"13137877-d705-4fc6-b4ec-042e49092bea","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.146535071+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.152 | Recv | sql:jobs | `[{"id":"13137877-d705-4fc6-b4ec-042e49092bea","project_id":"test-1778829239143-2prwhk","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 16 | 07:13:59.152 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5","changes":1}` |
| 17 | 07:13:59.153 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 18 | 07:13:59.155 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "94591a71-2442-456c-bc95-677a1214c9f7",
    "job_id": "13137877-d705-4fc6-b4ec-042e49092bea",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.146535071+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "94591a71-2442-456c-bc95-677a1214c9f7",
    "job_id": "13137877-d705-4fc6-b4ec-042e49092bea",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.146535071+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
[
  {
    "id": "13137877-d705-4fc6-b4ec-042e49092bea",
    "project_id": "test-1778829239143-2prwhk",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.145190877+00:00",
    "updated_at": "2026-05-15T07:13:59.149940560+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET error = ?1, status = ?2, finished_at = ?3, updated_at = ?4 WHERE id = ?5",
  "changes": 1
}
```

</details>

<details><summary>17. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.156 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.156 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239155-a2o1jl","description":"E2E test job"}` |
| 3 | 07:13:59.157 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.158 | Response | http response | `200 {"job_id":"6515ad98-7d8d-4dfb-9704-7d420dfac693"}` |
| 5 | 07:13:59.158 | Send | http.send | `POST /api/v1/workers {"job_id":"6515ad98-7d8d-4dfb-9704-7d420dfac693","provider":"test"}` |
| 6 | 07:13:59.159 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.160 | Response | http response | `200 {"worker_id":"1a622ab6-2e47-4656-9a76-e1ca5808ecaf"}` |
| 8 | 07:13:59.160 | Send | http.send | `POST /api/v1/workers/1a622ab6-2e47-4656-9a76-e1ca5808ecaf/register {"job_id":"6515ad98-7d8d-4dfb-9704-7d420dfac693"}` |
| 9 | 07:13:59.161 | Recv | sql:workers | `[{"id":"1a622ab6-2e47-4656-9a76-e1ca5808ecaf","job_id":"6515ad98-7d8d-4dfb-9704-7d420dfac693","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.158651118+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.161 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.162 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.163 | Response | http response | `200 ` |
| 13 | 07:13:59.163 | Send | http.send | `GET /api/v1/jobs/6515ad98-7d8d-4dfb-9704-7d420dfac693/config` |
| 14 | 07:13:59.164 | Recv | sql:jobs | `[{"id":"6515ad98-7d8d-4dfb-9704-7d420dfac693","project_id":"test-1778829239155-a2o1jl","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 15 | 07:13:59.164 | Response | http response | `200 {"job_id":"6515ad98-7d8d-4dfb-9704-7d420dfac693","stage":"","prompt":"E2E test job","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","api...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "1a622ab6-2e47-4656-9a76-e1ca5808ecaf",
    "job_id": "6515ad98-7d8d-4dfb-9704-7d420dfac693",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.158651118+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
[
  {
    "id": "6515ad98-7d8d-4dfb-9704-7d420dfac693",
    "project_id": "test-1778829239155-a2o1jl",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.157033281+00:00",
    "updated_at": "2026-05-15T07:13:59.162586375+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.166 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.166 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239164-1elq1b","description":"E2E test job"}` |
| 3 | 07:13:59.166 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.167 | Response | http response | `200 {"job_id":"6a752e89-c0ec-4bc2-b588-3cb5bec3f95b"}` |
| 5 | 07:13:59.167 | Send | http.send | `POST /api/v1/workers {"job_id":"6a752e89-c0ec-4bc2-b588-3cb5bec3f95b","provider":"test"}` |
| 6 | 07:13:59.168 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.169 | Response | http response | `200 {"worker_id":"53a85c6c-8d13-4416-99ea-b7f61487d1d7"}` |
| 8 | 07:13:59.169 | Send | http.send | `POST /api/v1/workers/53a85c6c-8d13-4416-99ea-b7f61487d1d7/register {"job_id":"6a752e89-c0ec-4bc2-b588-3cb5bec3f95b"}` |
| 9 | 07:13:59.169 | Recv | sql:workers | `[{"id":"53a85c6c-8d13-4416-99ea-b7f61487d1d7","job_id":"6a752e89-c0ec-4bc2-b588-3cb5bec3f95b","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.167784944+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.170 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.171 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.173 | Response | http response | `200 ` |
| 13 | 07:13:59.173 | Send | http.send | `GET /api/v1/jobs/6a752e89-c0ec-4bc2-b588-3cb5bec3f95b/skill/plan` |
| 14 | 07:13:59.174 | Response | http response | `200 {"content":"You are a senior software engineer tasked with creating an implementation plan.\n\n## Instructions\n\n- Explore the project structure first using glob and grep\n- Identify all files and modules relevant to the task\n- Produce a clear, step-by-step implementation plan\n- Estimate t...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "53a85c6c-8d13-4416-99ea-b7f61487d1d7",
    "job_id": "6a752e89-c0ec-4bc2-b588-3cb5bec3f95b",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.167784944+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

---

## unknown worker returns 404

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.174 | Send | http.send | `POST /api/v1/workers/nonexistent-id/register {"job_id":"fake-job"}` |
| 2 | 07:13:59.174 | Recv | sql:workers | `[]` |
| 3 | 07:13:59.175 | Response | http response | `404 worker not found` |

<details><summary>2. Recv sql:workers</summary>

```json
[]
```

</details>

---

## creates project via SQL seed and reads via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.179 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.179 | Send | http.send | `GET /api/v1/projects` |
| 3 | 07:13:59.179 | Recv | sql:projects | `[{"id":"test-1778829238952-b25cot","repo_url":"https://github.com/test/test-1778829238952-b25cot","branch":"main","created_at":"2026-05-15T07:13:58.952Z","updated_at":"2026-05-15T07:13:58.952Z"},{"id":"test-1778829238959-8t72rd","repo_url":"https://github.com/test/test-1778829238959-8t72rd","bran...` |
| 4 | 07:13:59.180 | Response | http response | `200 [{"id":"test-1778829238952-b25cot","repo_url":"https://github.com/test/test-1778829238952-b25cot","branch":"main","created_at":"2026-05-15T07:13:58.952Z","updated_at":"2026-05-15T07:13:58.952Z"},{"id":"test-1778829238959-8t72rd","repo_url":"https://github.com/test/test-1778829238959-8t72rd","...` |

<details><summary>3. Recv sql:projects</summary>

```json
[
  {
    "id": "test-1778829238952-b25cot",
    "repo_url": "https://github.com/test/test-1778829238952-b25cot",
    "branch": "main",
    "created_at": "2026-05-15T07:13:58.952Z",
    "updated_at": "2026-05-15T07:13:58.952Z"
  },
  {
    "id": "test-1778829238959-8t72rd",
    "repo_url": "https://github.com/test/test-1778829238959-8t72rd",
    "branch": "main",
    "created_at": "2026-05-15T07:13:58.959Z",
    "updated_at": "2026-05-15T07:13:58.959Z"
  },
  {
    "id": "test-1778829238969-f6lg2w",
    "repo_url": "https://github.com/test/test-1778829238969-f6lg2w",
    "branch": "main",
    "created_at": "2026-05-15T07:13:58.969Z",
    "updated_at": "2026-05-15T07:13:58.969Z"
  },
  {
    "id": "test-1778829238986-rt7ncg",
    "repo_url": "https://github.com/test/test-1778829238986-rt7ncg",
    "branch": "main",
    "created_at": "2026-05-15T07:13:58.986Z",
    "updated_at": "2026-05-15T07:13:58.986Z"
  },
  {
    "id": "test-1778829238999-8tnjvk",
    "repo_url": "https://github.com/test/test-1778829238999-8tnjvk",
    "branch": "main",
    "created_at": "2026-05-15T07:13:58.999Z",
    "updated_at": "2026-05-15T07:13:58.999Z"
  },
  {
    "id": "test-1778829239005-rh9bni",
    "repo_url": "https://github.com/test/test-1778829239005-rh9bni",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.005Z",
    "updated_at": "2026-05-15T07:13:59.005Z"
  },
  {
    "id": "test-1778829239007-7z94lt",
    "repo_url": "https://github.com/test/test-1778829239007-7z94lt",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.007Z",
    "updated_at": "2026-05-15T07:13:59.007Z"
  },
  {
    "id": "test-1778829239018-tzmy3v",
    "repo_url": "https://github.com/test/test-1778829239018-tzmy3v",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.018Z",
    "updated_at": "2026-05-15T07:13:59.018Z"
  },
  {
    "id": "test-1778829239031-7o194a",
    "repo_url": "https://github.com/test/test-1778829239031-7o194a",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.031Z",
    "updated_at": "2026-05-15T07:13:59.031Z"
  },
  {
    "id": "test-1778829239046-hktt84",
    "repo_url": "https://github.com/test/test-1778829239046-hktt84",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.046Z",
    "updated_at": "2026-05-15T07:13:59.046Z"
  },
  {
    "id": "test-1778829239060-4glhmt",
    "repo_url": "https://github.com/test/test-1778829239060-4glhmt",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.060Z",
    "updated_at": "2026-05-15T07:13:59.060Z"
  },
  {
    "id": "test-1778829239073-mfqtje",
    "repo_url": "https://github.com/test/test-1778829239073-mfqtje",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.073Z",
    "updated_at": "2026-05-15T07:13:59.073Z"
  },
  {
    "id": "test-1778829239080-bw08nj",
    "repo_url": "https://github.com/test/test-1778829239080-bw08nj",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.080Z",
    "updated_at": "2026-05-15T07:13:59.080Z"
  },
  {
    "id": "test-1778829239094-vgr4cw",
    "repo_url": "https://github.com/test/test-1778829239094-vgr4cw",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.094Z",
    "updated_at": "2026-05-15T07:13:59.094Z"
  },
  {
    "id": "test-1778829239104-nzc9i3",
    "repo_url": "https://github.com/test/test-1778829239104-nzc9i3",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.104Z",
    "updated_at": "2026-05-15T07:13:59.104Z"
  },
  {
    "id": "test-1778829239114-33fnaf",
    "repo_url": "https://github.com/test/test-1778829239114-33fnaf",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.114Z",
    "updated_at": "2026-05-15T07:13:59.114Z"
  },
  {
    "id": "test-1778829239130-540mpq",
    "repo_url": "https://github.com/test/test-1778829239130-540mpq",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.130Z",
    "updated_at": "2026-05-15T07:13:59.130Z"
  },
  {
    "id": "test-1778829239143-2prwhk",
    "repo_url": "https://github.com/test/test-1778829239143-2prwhk",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.143Z",
    "updated_at": "2026-05-15T07:13:59.143Z"
  },
  {
    "id": "test-1778829239155-a2o1jl",
    "repo_url": "https://github.com/test/test-1778829239155-a2o1jl",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.155Z",
    "updated_at": "2026-05-15T07:13:59.155Z"
  },
  {
    "id": "test-1778829239164-1elq1b",
    "repo_url": "https://github.com/test/test-1778829239164-1elq1b",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.164Z",
    "updated_at": "2026-05-15T07:13:59.164Z"
  },
  {
    "id": "test-1778829239177-sxi5n7",
    "repo_url": "https://github.com/test/test-1778829239177-sxi5n7",
    "branch": "main",
    "created_at": "2026-05-15T07:13:59.177Z",
    "updated_at": "2026-05-15T07:13:59.177Z"
  }
]
```

</details>

---

## creates job via HTTP, verifies via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.181 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.181 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239180-16q2vk","description":"DB test job"}` |
| 3 | 07:13:59.182 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.183 | Response | http response | `200 {"job_id":"0d2142f3-9a3d-46d4-97d3-6e7a93938b89"}` |
| 5 | 07:13:59.183 | Send | http.send | `GET /api/v1/jobs/0d2142f3-9a3d-46d4-97d3-6e7a93938b89` |
| 6 | 07:13:59.183 | Recv | sql:jobs | `[{"id":"0d2142f3-9a3d-46d4-97d3-6e7a93938b89","project_id":"test-1778829239180-16q2vk","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 7 | 07:13:59.184 | Response | http response | `200 {"id":"0d2142f3-9a3d-46d4-97d3-6e7a93938b89","project_id":"test-1778829239180-16q2vk","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "0d2142f3-9a3d-46d4-97d3-6e7a93938b89",
    "project_id": "test-1778829239180-16q2vk",
    "description": "DB test job",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.181755063+00:00",
    "updated_at": "2026-05-15T07:13:59.181755063+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## stores checkpoint and verifies via SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.185 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.185 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239184-zawpjc","description":"Checkpoint test"}` |
| 3 | 07:13:59.185 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.187 | Response | http response | `200 {"job_id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4"}` |
| 5 | 07:13:59.187 | Send | http.send | `POST /api/v1/workers {"job_id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4","provider":"test"}` |
| 6 | 07:13:59.187 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.189 | Response | http response | `200 {"worker_id":"3cd263f2-d74a-4eeb-9b76-bb8b1418d387"}` |
| 8 | 07:13:59.189 | Send | http.send | `POST /api/v1/workers/3cd263f2-d74a-4eeb-9b76-bb8b1418d387/register {"job_id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4"}` |
| 9 | 07:13:59.189 | Recv | sql:workers | `[{"id":"3cd263f2-d74a-4eeb-9b76-bb8b1418d387","job_id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.187726626+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.190 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.192 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.193 | Response | http response | `200 ` |
| 13 | 07:13:59.193 | Send | http.send | `POST /api/v1/workers/3cd263f2-d74a-4eeb-9b76-bb8b1418d387/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 14 | 07:13:59.194 | Recv | sql:workers | `[{"id":"3cd263f2-d74a-4eeb-9b76-bb8b1418d387","job_id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.187726626+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.194 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.195 | Recv | sql:jobs | `[{"id":"6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4","project_id":"test-1778829239184-zawpjc","description":"Checkpoint test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |
| 17 | 07:13:59.196 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.197 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "3cd263f2-d74a-4eeb-9b76-bb8b1418d387",
    "job_id": "6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.187726626+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "3cd263f2-d74a-4eeb-9b76-bb8b1418d387",
    "job_id": "6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.187726626+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4",
    "project_id": "test-1778829239184-zawpjc",
    "description": "Checkpoint test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.185728347+00:00",
    "updated_at": "2026-05-15T07:13:59.191713761+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## tracks worker heartbeat in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.199 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.199 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239197-u3cilr","description":"Heartbeat test"}` |
| 3 | 07:13:59.199 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.200 | Response | http response | `200 {"job_id":"879dffb6-f7f3-4d4a-8949-1e33f49e99a3"}` |
| 5 | 07:13:59.200 | Send | http.send | `POST /api/v1/workers {"job_id":"879dffb6-f7f3-4d4a-8949-1e33f49e99a3","provider":"test"}` |
| 6 | 07:13:59.201 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.202 | Response | http response | `200 {"worker_id":"0659cb21-f032-4667-9b7e-6437048b035c"}` |
| 8 | 07:13:59.202 | Send | http.send | `POST /api/v1/workers/0659cb21-f032-4667-9b7e-6437048b035c/register {"job_id":"879dffb6-f7f3-4d4a-8949-1e33f49e99a3"}` |
| 9 | 07:13:59.203 | Recv | sql:workers | `[{"id":"0659cb21-f032-4667-9b7e-6437048b035c","job_id":"879dffb6-f7f3-4d4a-8949-1e33f49e99a3","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.201109079+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.203 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.205 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.206 | Response | http response | `200 ` |
| 13 | 07:13:59.206 | Send | http.send | `POST /api/v1/workers/0659cb21-f032-4667-9b7e-6437048b035c/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 14 | 07:13:59.206 | Recv | sql:workers | `{"sql":"UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2","changes":1}` |
| 15 | 07:13:59.208 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "0659cb21-f032-4667-9b7e-6437048b035c",
    "job_id": "879dffb6-f7f3-4d4a-8949-1e33f49e99a3",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.201109079+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## destroyed workers removed from DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.209 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.209 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239208-xfm1vl","description":"Destroy test"}` |
| 3 | 07:13:59.210 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.211 | Response | http response | `200 {"job_id":"360e9468-68df-4834-8229-a573f1b7c5da"}` |
| 5 | 07:13:59.211 | Send | http.send | `POST /api/v1/workers {"job_id":"360e9468-68df-4834-8229-a573f1b7c5da","provider":"test"}` |
| 6 | 07:13:59.211 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.213 | Response | http response | `200 {"worker_id":"477ecf60-45b4-4dc5-b13b-41d7c11e58c6"}` |
| 8 | 07:13:59.213 | Send | http.send | `POST /api/v1/workers/477ecf60-45b4-4dc5-b13b-41d7c11e58c6/register {"job_id":"360e9468-68df-4834-8229-a573f1b7c5da"}` |
| 9 | 07:13:59.213 | Recv | sql:workers | `[{"id":"477ecf60-45b4-4dc5-b13b-41d7c11e58c6","job_id":"360e9468-68df-4834-8229-a573f1b7c5da","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.211667320+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.214 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.215 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.216 | Response | http response | `200 ` |
| 13 | 07:13:59.216 | Send | http.send | `POST /api/v1/workers/477ecf60-45b4-4dc5-b13b-41d7c11e58c6/complete {"result":"done"}` |
| 14 | 07:13:59.217 | Recv | sql:workers | `[{"id":"477ecf60-45b4-4dc5-b13b-41d7c11e58c6","job_id":"360e9468-68df-4834-8229-a573f1b7c5da","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.211667320+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.217 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.219 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.220 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "477ecf60-45b4-4dc5-b13b-41d7c11e58c6",
    "job_id": "360e9468-68df-4834-8229-a573f1b7c5da",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.211667320+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "477ecf60-45b4-4dc5-b13b-41d7c11e58c6",
    "job_id": "360e9468-68df-4834-8229-a573f1b7c5da",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.211667320+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.225 | Send | http.send | `GET /api/v1/jobs/93e6bf78-c5ed-4aa8-b78c-20d30707f7b4/config` |
| 2 | 07:13:59.225 | Recv | sql:jobs | `[{"id":"93e6bf78-c5ed-4aa8-b78c-20d30707f7b4","project_id":"test-1778829239221-bkvqrb","description":"Hello world test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |
| 3 | 07:13:59.225 | Response | http response | `200 {"job_id":"93e6bf78-c5ed-4aa8-b78c-20d30707f7b4","stage":"","prompt":"Hello world test","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

<details><summary>2. Recv sql:jobs</summary>

```json
[
  {
    "id": "93e6bf78-c5ed-4aa8-b78c-20d30707f7b4",
    "project_id": "test-1778829239221-bkvqrb",
    "description": "Hello world test",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.222969050+00:00",
    "updated_at": "2026-05-15T07:13:59.222969050+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

---

## create project → create job → register worker → complete

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.228 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.228 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239226-adxw10","description":"Full lifecycle test"}` |
| 3 | 07:13:59.228 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.229 | Response | http response | `200 {"job_id":"c545e467-c529-48fb-9d18-15416e32a0a6"}` |
| 5 | 07:13:59.230 | Send | http.send | `POST /api/v1/workers {"job_id":"c545e467-c529-48fb-9d18-15416e32a0a6","provider":"test"}` |
| 6 | 07:13:59.230 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.231 | Response | http response | `200 {"worker_id":"934f5b74-1200-4b6b-a6b9-d41e09f84939"}` |
| 8 | 07:13:59.231 | Send | http.send | `POST /api/v1/workers/934f5b74-1200-4b6b-a6b9-d41e09f84939/register {"job_id":"c545e467-c529-48fb-9d18-15416e32a0a6"}` |
| 9 | 07:13:59.232 | Recv | sql:workers | `[{"id":"934f5b74-1200-4b6b-a6b9-d41e09f84939","job_id":"c545e467-c529-48fb-9d18-15416e32a0a6","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.230105288+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.232 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.233 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.235 | Response | http response | `200 ` |
| 13 | 07:13:59.235 | Send | http.send | `POST /api/v1/workers/934f5b74-1200-4b6b-a6b9-d41e09f84939/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 14 | 07:13:59.235 | Recv | sql:workers | `{"sql":"UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2","changes":1}` |
| 15 | 07:13:59.236 | Response | http response | `200 ` |
| 16 | 07:13:59.236 | Send | http.send | `POST /api/v1/workers/934f5b74-1200-4b6b-a6b9-d41e09f84939/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_us...` |
| 17 | 07:13:59.237 | Recv | sql:workers | `[{"id":"934f5b74-1200-4b6b-a6b9-d41e09f84939","job_id":"c545e467-c529-48fb-9d18-15416e32a0a6","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-15T07:13:59.235461864+00:00","created_at":"2026-05-15T07:13:59.230105288+00:00","de...` |
| 18 | 07:13:59.237 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 19 | 07:13:59.238 | Recv | sql:jobs | `[{"id":"c545e467-c529-48fb-9d18-15416e32a0a6","project_id":"test-1778829239226-adxw10","description":"Full lifecycle test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 20 | 07:13:59.239 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 21 | 07:13:59.240 | Response | http response | `200 ` |
| 22 | 07:13:59.240 | Send | http.send | `POST /api/v1/workers/934f5b74-1200-4b6b-a6b9-d41e09f84939/complete {"result":"Job completed successfully"}` |
| 23 | 07:13:59.241 | Recv | sql:workers | `[{"id":"934f5b74-1200-4b6b-a6b9-d41e09f84939","job_id":"c545e467-c529-48fb-9d18-15416e32a0a6","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-15T07:13:59.235461864+00:00","created_at":"2026-05-15T07:13:59.230105288+00:00","de...` |
| 24 | 07:13:59.242 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 25 | 07:13:59.244 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 26 | 07:13:59.245 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "934f5b74-1200-4b6b-a6b9-d41e09f84939",
    "job_id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.230105288+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET heartbeat_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>17. Recv sql:workers</summary>

```json
[
  {
    "id": "934f5b74-1200-4b6b-a6b9-d41e09f84939",
    "job_id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": "2026-05-15T07:13:59.235461864+00:00",
    "created_at": "2026-05-15T07:13:59.230105288+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>18. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>19. Recv sql:jobs</summary>

```json
[
  {
    "id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "project_id": "test-1778829239226-adxw10",
    "description": "Full lifecycle test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.228465888+00:00",
    "updated_at": "2026-05-15T07:13:59.233678539+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>20. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>23. Recv sql:workers</summary>

```json
[
  {
    "id": "934f5b74-1200-4b6b-a6b9-d41e09f84939",
    "job_id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": "2026-05-15T07:13:59.235461864+00:00",
    "created_at": "2026-05-15T07:13:59.230105288+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>24. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>25. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## lists jobs and workers via HTTP matches DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.246 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 07:13:59.246 | Recv | sql:jobs | `[{"id":"008d28d8-df17-4d91-9868-c3db706b7170","project_id":"test-1778829238952-b25cot","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 3 | 07:13:59.248 | Response | http response | `200 [{"id":"008d28d8-df17-4d91-9868-c3db706b7170","project_id":"test-1778829238952-b25cot","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |
| 4 | 07:13:59.248 | Send | http.send | `GET /api/v1/workers` |
| 5 | 07:13:59.248 | Recv | sql:workers | `[{"id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7","job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.974519807+00:00","destroyed_at":null},{"id":"fa915614...` |
| 6 | 07:13:59.249 | Response | http response | `200 [{"id":"9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7","job_id":"f9cb3437-a06f-4d96-b00d-c469400ad50e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:58.974519807+00:00","destroyed_at":null},{"id":"fa91...` |

<details><summary>2. Recv sql:jobs</summary>

```json
[
  {
    "id": "008d28d8-df17-4d91-9868-c3db706b7170",
    "project_id": "test-1778829238952-b25cot",
    "description": "Dashboard test job",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.954607719+00:00",
    "updated_at": "2026-05-15T07:13:58.954607719+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "d1bb31b3-7668-4661-bd6d-e76b6b82731b",
    "project_id": "test-1778829238959-8t72rd",
    "description": "Detail test",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.960881097+00:00",
    "updated_at": "2026-05-15T07:13:58.960881097+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "f9cb3437-a06f-4d96-b00d-c469400ad50e",
    "project_id": "test-1778829238969-f6lg2w",
    "description": "Worker list test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.971721432+00:00",
    "updated_at": "2026-05-15T07:13:58.982485372+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "d166c703-4a2f-4c61-ad1c-05a9bd9420d3",
    "project_id": "test-1778829238986-rt7ncg",
    "description": "Pause via dashboard",
    "status": "paused",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:58.987994829+00:00",
    "updated_at": "2026-05-15T07:13:58.997315356+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "0fc47f07-4136-45de-9143-1dc8583fdd59",
    "project_id": "test-1778829238999-8tnjvk",
    "description": "Cancel via dashboard",
    "status": "cancelled",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.000450177+00:00",
    "updated_at": "2026-05-15T07:13:59.002147854+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "634cfe06-5a88-4c2c-b9d7-4d403caef029",
    "project_id": "test-1778829239005-rh9bni",
    "description": "State machine test",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.006353528+00:00",
    "updated_at": "2026-05-15T07:13:59.006353528+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "8e85841e-e6fb-4c7c-9fc8-4ae59c197b25",
    "project_id": "test-1778829239007-7z94lt",
    "description": "Pause test",
    "status": "paused",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.009186865+00:00",
    "updated_at": "2026-05-15T07:13:59.017136607+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "df161697-d8ae-42e7-8add-d3d5da4f40c5",
    "project_id": "test-1778829239018-tzmy3v",
    "description": "Resume test",
    "status": "resuming",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.020933495+00:00",
    "updated_at": "2026-05-15T07:13:59.029988873+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "3880c234-c642-4271-871b-27fe25f7d2f9",
    "project_id": "test-1778829239031-7o194a",
    "description": "Complete test",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "success",
    "error": null,
    "created_at": "2026-05-15T07:13:59.033015481+00:00",
    "updated_at": "2026-05-15T07:13:59.040563828+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.040563828+00:00"
  },
  {
    "id": "36c98c86-4e4d-42c5-91fa-ead13d4838cd",
    "project_id": "test-1778829239046-hktt84",
    "description": "Fail test",
    "status": "failed_retryable",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": "transient failure",
    "created_at": "2026-05-15T07:13:59.048073979+00:00",
    "updated_at": "2026-05-15T07:13:59.056302391+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.056302391+00:00"
  },
  {
    "id": "3ce46b69-6c38-443f-a937-6a7c5556a25a",
    "project_id": "test-1778829239060-4glhmt",
    "description": "Terminal test",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "done",
    "error": null,
    "created_at": "2026-05-15T07:13:59.061796825+00:00",
    "updated_at": "2026-05-15T07:13:59.069217732+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.069217732+00:00"
  },
  {
    "id": "617a4d99-671a-4bcc-9a8f-ac7156d96cff",
    "project_id": "test-1778829239073-mfqtje",
    "description": "Cancel queued",
    "status": "cancelled",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.075127411+00:00",
    "updated_at": "2026-05-15T07:13:59.078856046+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "46850b74-f94b-459a-b8cb-215853fbaec3",
    "project_id": "test-1778829239080-bw08nj",
    "description": "Cancel running",
    "status": "cancelled",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.082451992+00:00",
    "updated_at": "2026-05-15T07:13:59.090038207+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "21b17fdf-be4f-4681-8f55-16808a2820bc",
    "project_id": "test-1778829239094-vgr4cw",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.096613359+00:00",
    "updated_at": "2026-05-15T07:13:59.101835624+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "7284a4f5-f297-4c56-aedd-b479b3d29832",
    "project_id": "test-1778829239104-nzc9i3",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.105312910+00:00",
    "updated_at": "2026-05-15T07:13:59.111025103+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "0b99774b-e967-4ecb-a454-1c6cda934fae",
    "project_id": "test-1778829239114-33fnaf",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": "implement",
    "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"}]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.115526032+00:00",
    "updated_at": "2026-05-15T07:13:59.127670541+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "b0df7217-0f0e-4268-8e18-ba44b472b239",
    "project_id": "test-1778829239130-540mpq",
    "description": "E2E test job",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "success",
    "error": null,
    "created_at": "2026-05-15T07:13:59.131611376+00:00",
    "updated_at": "2026-05-15T07:13:59.139902122+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.139902122+00:00"
  },
  {
    "id": "13137877-d705-4fc6-b4ec-042e49092bea",
    "project_id": "test-1778829239143-2prwhk",
    "description": "E2E test job",
    "status": "failed_retryable",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": "build failed",
    "created_at": "2026-05-15T07:13:59.145190877+00:00",
    "updated_at": "2026-05-15T07:13:59.152205110+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.152205110+00:00"
  },
  {
    "id": "6515ad98-7d8d-4dfb-9704-7d420dfac693",
    "project_id": "test-1778829239155-a2o1jl",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.157033281+00:00",
    "updated_at": "2026-05-15T07:13:59.162586375+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "6a752e89-c0ec-4bc2-b588-3cb5bec3f95b",
    "project_id": "test-1778829239164-1elq1b",
    "description": "E2E test job",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.166187037+00:00",
    "updated_at": "2026-05-15T07:13:59.171472086+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "0d2142f3-9a3d-46d4-97d3-6e7a93938b89",
    "project_id": "test-1778829239180-16q2vk",
    "description": "DB test job",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.181755063+00:00",
    "updated_at": "2026-05-15T07:13:59.181755063+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4",
    "project_id": "test-1778829239184-zawpjc",
    "description": "Checkpoint test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": "done",
    "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"}]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.185728347+00:00",
    "updated_at": "2026-05-15T07:13:59.196143752+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "879dffb6-f7f3-4d4a-8949-1e33f49e99a3",
    "project_id": "test-1778829239197-u3cilr",
    "description": "Heartbeat test",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.199274907+00:00",
    "updated_at": "2026-05-15T07:13:59.204725947+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "360e9468-68df-4834-8229-a573f1b7c5da",
    "project_id": "test-1778829239208-xfm1vl",
    "description": "Destroy test",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "done",
    "error": null,
    "created_at": "2026-05-15T07:13:59.209977515+00:00",
    "updated_at": "2026-05-15T07:13:59.217385442+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.217385442+00:00"
  },
  {
    "id": "93e6bf78-c5ed-4aa8-b78c-20d30707f7b4",
    "project_id": "test-1778829239221-bkvqrb",
    "description": "Hello world test",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.222969050+00:00",
    "updated_at": "2026-05-15T07:13:59.222969050+00:00",
    "started_at": null,
    "finished_at": null
  },
  {
    "id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "project_id": "test-1778829239226-adxw10",
    "description": "Full lifecycle test",
    "status": "completed",
    "worker_id": null,
    "branch": null,
    "workflow_name": null,
    "current_stage": "done",
    "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"}]",
    "attempt": 1,
    "max_attempts": 3,
    "result": "Job completed successfully",
    "error": null,
    "created_at": "2026-05-15T07:13:59.228465888+00:00",
    "updated_at": "2026-05-15T07:13:59.242279171+00:00",
    "started_at": null,
    "finished_at": "2026-05-15T07:13:59.242279171+00:00"
  }
]
```

</details>

<details><summary>5. Recv sql:workers</summary>

```json
[
  {
    "id": "9ee86a80-83bf-4fa8-bcf2-d8aea2ddd6f7",
    "job_id": "f9cb3437-a06f-4d96-b00d-c469400ad50e",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:58.974519807+00:00",
    "destroyed_at": null
  },
  {
    "id": "fa915614-6afe-4507-933e-91d195d139ed",
    "job_id": "d166c703-4a2f-4c61-ad1c-05a9bd9420d3",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:58.990223396+00:00",
    "destroyed_at": null
  },
  {
    "id": "5d9d2da0-fb53-4352-a5ae-4b93676038c7",
    "job_id": "8e85841e-e6fb-4c7c-9fc8-4ae59c197b25",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.012449969+00:00",
    "destroyed_at": null
  },
  {
    "id": "a1b77cef-6757-44fa-984a-30c11a928adb",
    "job_id": "df161697-d8ae-42e7-8add-d3d5da4f40c5",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.022474536+00:00",
    "destroyed_at": null
  },
  {
    "id": "deb2f3e7-74bd-4645-9642-4f0d2ce45aac",
    "job_id": "3880c234-c642-4271-871b-27fe25f7d2f9",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.034746337+00:00",
    "destroyed_at": "2026-05-15T07:13:59.042320113+00:00"
  },
  {
    "id": "46c6282a-d217-451d-9aa9-6c6763f84091",
    "job_id": "36c98c86-4e4d-42c5-91fa-ead13d4838cd",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.050121753+00:00",
    "destroyed_at": "2026-05-15T07:13:59.057689720+00:00"
  },
  {
    "id": "e5195439-fc88-4455-8fab-720ab7ccdc87",
    "job_id": "3ce46b69-6c38-443f-a937-6a7c5556a25a",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.063445979+00:00",
    "destroyed_at": "2026-05-15T07:13:59.070667665+00:00"
  },
  {
    "id": "df712b3c-881d-4fb3-aa6b-94a99af4ce39",
    "job_id": "46850b74-f94b-459a-b8cb-215853fbaec3",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.084153374+00:00",
    "destroyed_at": null
  },
  {
    "id": "777cfd0d-fe45-4ac3-a83a-b367bb5b1c85",
    "job_id": "21b17fdf-be4f-4681-8f55-16808a2820bc",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.098392649+00:00",
    "destroyed_at": null
  },
  {
    "id": "cc433d54-47f8-4f1c-b560-681ac1ef250c",
    "job_id": "7284a4f5-f297-4c56-aedd-b479b3d29832",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": "2026-05-15T07:13:59.112451401+00:00",
    "created_at": "2026-05-15T07:13:59.107720086+00:00",
    "destroyed_at": null
  },
  {
    "id": "23466024-af9a-47a1-be18-7e67f8cb1fab",
    "job_id": "0b99774b-e967-4ecb-a454-1c6cda934fae",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.117368697+00:00",
    "destroyed_at": null
  },
  {
    "id": "dd94e75d-f7e0-4035-b979-0e99b8226617",
    "job_id": "b0df7217-0f0e-4268-8e18-ba44b472b239",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.134004410+00:00",
    "destroyed_at": "2026-05-15T07:13:59.141591606+00:00"
  },
  {
    "id": "94591a71-2442-456c-bc95-677a1214c9f7",
    "job_id": "13137877-d705-4fc6-b4ec-042e49092bea",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.146535071+00:00",
    "destroyed_at": "2026-05-15T07:13:59.153697007+00:00"
  },
  {
    "id": "1a622ab6-2e47-4656-9a76-e1ca5808ecaf",
    "job_id": "6515ad98-7d8d-4dfb-9704-7d420dfac693",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.158651118+00:00",
    "destroyed_at": null
  },
  {
    "id": "53a85c6c-8d13-4416-99ea-b7f61487d1d7",
    "job_id": "6a752e89-c0ec-4bc2-b588-3cb5bec3f95b",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.167784944+00:00",
    "destroyed_at": null
  },
  {
    "id": "3cd263f2-d74a-4eeb-9b76-bb8b1418d387",
    "job_id": "6e175aa2-4ee8-4c81-8428-8e5fd04ca7a4",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.187726626+00:00",
    "destroyed_at": null
  },
  {
    "id": "0659cb21-f032-4667-9b7e-6437048b035c",
    "job_id": "879dffb6-f7f3-4d4a-8949-1e33f49e99a3",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": "2026-05-15T07:13:59.206451685+00:00",
    "created_at": "2026-05-15T07:13:59.201109079+00:00",
    "destroyed_at": null
  },
  {
    "id": "477ecf60-45b4-4dc5-b13b-41d7c11e58c6",
    "job_id": "360e9468-68df-4834-8229-a573f1b7c5da",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.211667320+00:00",
    "destroyed_at": "2026-05-15T07:13:59.218912942+00:00"
  },
  {
    "id": "934f5b74-1200-4b6b-a6b9-d41e09f84939",
    "job_id": "c545e467-c529-48fb-9d18-15416e32a0a6",
    "provider": "test",
    "provider_id": null,
    "status": "stopped",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": "2026-05-15T07:13:59.235461864+00:00",
    "created_at": "2026-05-15T07:13:59.230105288+00:00",
    "destroyed_at": "2026-05-15T07:13:59.244160776+00:00"
  }
]
```

</details>

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.249 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 07:13:59.249 | Response | http response | `200 {"name":"test","stages":1,"valid":true}` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.249 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 07:13:59.250 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## routes based on string equality in response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.553 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.553 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239550-bqldl2","description":"Build feature","workflow":"feature"}` |
| 3 | 07:13:59.554 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.555 | Response | http response | `200 {"job_id":"c3f346d1-45cb-45aa-93da-b4c5d399617a"}` |
| 5 | 07:13:59.555 | Send | http.send | `POST /api/v1/workers {"job_id":"c3f346d1-45cb-45aa-93da-b4c5d399617a","provider":"test"}` |
| 6 | 07:13:59.556 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.557 | Response | http response | `200 {"worker_id":"e30de998-76b4-410a-85fc-bf074a765ebe"}` |
| 8 | 07:13:59.558 | Send | http.send | `POST /api/v1/workers/e30de998-76b4-410a-85fc-bf074a765ebe/register {"job_id":"c3f346d1-45cb-45aa-93da-b4c5d399617a"}` |
| 9 | 07:13:59.558 | Recv | sql:workers | `[{"id":"e30de998-76b4-410a-85fc-bf074a765ebe","job_id":"c3f346d1-45cb-45aa-93da-b4c5d399617a","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.555929459+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.559 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.561 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.563 | Response | http response | `200 ` |
| 13 | 07:13:59.563 | Send | http.send | `POST /api/v1/workers/e30de998-76b4-410a-85fc-bf074a765ebe/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 14 | 07:13:59.564 | Recv | sql:workers | `[{"id":"e30de998-76b4-410a-85fc-bf074a765ebe","job_id":"c3f346d1-45cb-45aa-93da-b4c5d399617a","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.555929459+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.565 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.566 | Recv | sql:jobs | `[{"id":"c3f346d1-45cb-45aa-93da-b4c5d399617a","project_id":"test-1778829239550-bqldl2","description":"Build feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 17 | 07:13:59.567 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.569 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "e30de998-76b4-410a-85fc-bf074a765ebe",
    "job_id": "c3f346d1-45cb-45aa-93da-b4c5d399617a",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.555929459+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "e30de998-76b4-410a-85fc-bf074a765ebe",
    "job_id": "c3f346d1-45cb-45aa-93da-b4c5d399617a",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.555929459+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "c3f346d1-45cb-45aa-93da-b4c5d399617a",
    "project_id": "test-1778829239550-bqldl2",
    "description": "Build feature",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.553580331+00:00",
    "updated_at": "2026-05-15T07:13:59.561233176+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## routes to plan_detail on complex response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.571 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.571 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239570-kuizm6","description":"Complex feature","workflow":"feature"}` |
| 3 | 07:13:59.573 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.575 | Response | http response | `200 {"job_id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6"}` |
| 5 | 07:13:59.575 | Send | http.send | `POST /api/v1/workers {"job_id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6","provider":"test"}` |
| 6 | 07:13:59.575 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.576 | Response | http response | `200 {"worker_id":"a4fe24df-555d-4e69-b4be-aa959e9c0ad8"}` |
| 8 | 07:13:59.576 | Send | http.send | `POST /api/v1/workers/a4fe24df-555d-4e69-b4be-aa959e9c0ad8/register {"job_id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6"}` |
| 9 | 07:13:59.577 | Recv | sql:workers | `[{"id":"a4fe24df-555d-4e69-b4be-aa959e9c0ad8","job_id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.575303716+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.577 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.578 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.580 | Response | http response | `200 ` |
| 13 | 07:13:59.580 | Send | http.send | `POST /api/v1/workers/a4fe24df-555d-4e69-b4be-aa959e9c0ad8/checkpoint {"stage":"plan","response":{"complexity":"complex"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt...` |
| 14 | 07:13:59.580 | Recv | sql:workers | `[{"id":"a4fe24df-555d-4e69-b4be-aa959e9c0ad8","job_id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.575303716+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.581 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.582 | Recv | sql:jobs | `[{"id":"4ec75896-ae43-4870-a47a-fcb1ba5f11b6","project_id":"test-1778829239570-kuizm6","description":"Complex feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cre...` |
| 17 | 07:13:59.582 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.584 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "a4fe24df-555d-4e69-b4be-aa959e9c0ad8",
    "job_id": "4ec75896-ae43-4870-a47a-fcb1ba5f11b6",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.575303716+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "a4fe24df-555d-4e69-b4be-aa959e9c0ad8",
    "job_id": "4ec75896-ae43-4870-a47a-fcb1ba5f11b6",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.575303716+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "4ec75896-ae43-4870-a47a-fcb1ba5f11b6",
    "project_id": "test-1778829239570-kuizm6",
    "description": "Complex feature",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.572124508+00:00",
    "updated_at": "2026-05-15T07:13:59.578689305+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## completes workflow when routes is null

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.586 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.586 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239584-l9gys7","description":"Simple task","workflow":"simple"}` |
| 3 | 07:13:59.586 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.587 | Response | http response | `200 {"job_id":"b8af5b2d-5a35-4018-ab10-9cbd84c47507"}` |
| 5 | 07:13:59.587 | Send | http.send | `POST /api/v1/workers {"job_id":"b8af5b2d-5a35-4018-ab10-9cbd84c47507","provider":"test"}` |
| 6 | 07:13:59.589 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.591 | Response | http response | `200 {"worker_id":"6e00082c-dcb3-4ee0-9757-6939a2f7e28f"}` |
| 8 | 07:13:59.591 | Send | http.send | `POST /api/v1/workers/6e00082c-dcb3-4ee0-9757-6939a2f7e28f/register {"job_id":"b8af5b2d-5a35-4018-ab10-9cbd84c47507"}` |
| 9 | 07:13:59.591 | Recv | sql:workers | `[{"id":"6e00082c-dcb3-4ee0-9757-6939a2f7e28f","job_id":"b8af5b2d-5a35-4018-ab10-9cbd84c47507","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.588026557+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.591 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.594 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.595 | Response | http response | `200 ` |
| 13 | 07:13:59.595 | Send | http.send | `POST /api/v1/workers/6e00082c-dcb3-4ee0-9757-6939a2f7e28f/complete {"result":"done"}` |
| 14 | 07:13:59.596 | Recv | sql:workers | `[{"id":"6e00082c-dcb3-4ee0-9757-6939a2f7e28f","job_id":"b8af5b2d-5a35-4018-ab10-9cbd84c47507","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.588026557+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.597 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.598 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.600 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "6e00082c-dcb3-4ee0-9757-6939a2f7e28f",
    "job_id": "b8af5b2d-5a35-4018-ab10-9cbd84c47507",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.588026557+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "6e00082c-dcb3-4ee0-9757-6939a2f7e28f",
    "job_id": "b8af5b2d-5a35-4018-ab10-9cbd84c47507",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.588026557+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.601 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 07:13:59.601 | Response | http response | `200 {"name":"numeric-route","stages":3,"valid":true}` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.603 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 07:13:59.603 | Response | http response | `200 {"name":"simple","stages":2,"valid":true}` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.604 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 07:13:59.605 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.605 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 07:13:59.605 | Response | http response | `200 {"name":"minimal","stages":1,"valid":true}` |

---

## checkpoint advances to next stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.611 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.611 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239610-acsuuu","description":"Advance stages","workflow":"feature"}` |
| 3 | 07:13:59.612 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.613 | Response | http response | `200 {"job_id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e"}` |
| 5 | 07:13:59.613 | Send | http.send | `POST /api/v1/workers {"job_id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e","provider":"test"}` |
| 6 | 07:13:59.613 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.615 | Response | http response | `200 {"worker_id":"e9cde93e-9632-41b6-9203-ece3b19b41a0"}` |
| 8 | 07:13:59.615 | Send | http.send | `POST /api/v1/workers/e9cde93e-9632-41b6-9203-ece3b19b41a0/register {"job_id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e"}` |
| 9 | 07:13:59.615 | Recv | sql:workers | `[{"id":"e9cde93e-9632-41b6-9203-ece3b19b41a0","job_id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.613643276+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.615 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.616 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.618 | Response | http response | `200 ` |
| 13 | 07:13:59.618 | Send | http.send | `POST /api/v1/workers/e9cde93e-9632-41b6-9203-ece3b19b41a0/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 14 | 07:13:59.618 | Recv | sql:workers | `[{"id":"e9cde93e-9632-41b6-9203-ece3b19b41a0","job_id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.613643276+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.618 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.619 | Recv | sql:jobs | `[{"id":"eb0e54f3-0228-44b6-97b5-08554d4ad49e","project_id":"test-1778829239610-acsuuu","description":"Advance stages","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 17 | 07:13:59.620 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.622 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "e9cde93e-9632-41b6-9203-ece3b19b41a0",
    "job_id": "eb0e54f3-0228-44b6-97b5-08554d4ad49e",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.613643276+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "e9cde93e-9632-41b6-9203-ece3b19b41a0",
    "job_id": "eb0e54f3-0228-44b6-97b5-08554d4ad49e",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.613643276+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "eb0e54f3-0228-44b6-97b5-08554d4ad49e",
    "project_id": "test-1778829239610-acsuuu",
    "description": "Advance stages",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.612104549+00:00",
    "updated_at": "2026-05-15T07:13:59.616682903+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## multi-stage progression through feature workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.623 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.623 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239622-py9jkz","description":"Multi-stage","workflow":"feature"}` |
| 3 | 07:13:59.624 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.625 | Response | http response | `200 {"job_id":"46205ea0-8241-4ac8-96e5-d646118727aa"}` |
| 5 | 07:13:59.625 | Send | http.send | `POST /api/v1/workers {"job_id":"46205ea0-8241-4ac8-96e5-d646118727aa","provider":"test"}` |
| 6 | 07:13:59.625 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.626 | Response | http response | `200 {"worker_id":"3b5ce5ee-8360-4407-a68b-3a1d2593b14f"}` |
| 8 | 07:13:59.626 | Send | http.send | `POST /api/v1/workers/3b5ce5ee-8360-4407-a68b-3a1d2593b14f/register {"job_id":"46205ea0-8241-4ac8-96e5-d646118727aa"}` |
| 9 | 07:13:59.627 | Recv | sql:workers | `[{"id":"3b5ce5ee-8360-4407-a68b-3a1d2593b14f","job_id":"46205ea0-8241-4ac8-96e5-d646118727aa","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.625463117+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.627 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.628 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.629 | Response | http response | `200 ` |
| 13 | 07:13:59.629 | Send | http.send | `POST /api/v1/workers/3b5ce5ee-8360-4407-a68b-3a1d2593b14f/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":{"prompt_token...` |
| 14 | 07:13:59.630 | Recv | sql:workers | `[{"id":"3b5ce5ee-8360-4407-a68b-3a1d2593b14f","job_id":"46205ea0-8241-4ac8-96e5-d646118727aa","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.625463117+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.630 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 16 | 07:13:59.631 | Recv | sql:jobs | `[{"id":"46205ea0-8241-4ac8-96e5-d646118727aa","project_id":"test-1778829239622-py9jkz","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created...` |
| 17 | 07:13:59.631 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 18 | 07:13:59.633 | Response | http response | `200 ` |
| 19 | 07:13:59.633 | Send | http.send | `POST /api/v1/workers/3b5ce5ee-8360-4407-a68b-3a1d2593b14f/checkpoint {"stage":"implement","response":{"success":true},"session_path":"/tmp/s2.json","git_sha":"bbb222","token_usage":{"prompt_tokens"...` |
| 20 | 07:13:59.633 | Recv | sql:workers | `[{"id":"3b5ce5ee-8360-4407-a68b-3a1d2593b14f","job_id":"46205ea0-8241-4ac8-96e5-d646118727aa","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.625463117+00:00","destroyed_at":null}]` |
| 21 | 07:13:59.633 | Recv | sql:checkpoints | `{"sql":"INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)","changes":1}` |
| 22 | 07:13:59.635 | Recv | sql:jobs | `[{"id":"46205ea0-8241-4ac8-96e5-d646118727aa","project_id":"test-1778829239622-py9jkz","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,...` |
| 23 | 07:13:59.635 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 24 | 07:13:59.636 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "3b5ce5ee-8360-4407-a68b-3a1d2593b14f",
    "job_id": "46205ea0-8241-4ac8-96e5-d646118727aa",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.625463117+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "3b5ce5ee-8360-4407-a68b-3a1d2593b14f",
    "job_id": "46205ea0-8241-4ac8-96e5-d646118727aa",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.625463117+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
[
  {
    "id": "46205ea0-8241-4ac8-96e5-d646118727aa",
    "project_id": "test-1778829239622-py9jkz",
    "description": "Multi-stage",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.623978350+00:00",
    "updated_at": "2026-05-15T07:13:59.628383184+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>20. Recv sql:workers</summary>

```json
[
  {
    "id": "3b5ce5ee-8360-4407-a68b-3a1d2593b14f",
    "job_id": "46205ea0-8241-4ac8-96e5-d646118727aa",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.625463117+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>21. Recv sql:checkpoints</summary>

```json
{
  "sql": "INSERT INTO checkpoints (id, job_id, stage, response, session_path, git_sha, token_usage, files_changed, created_at) VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9)",
  "changes": 1
}
```

</details>

<details><summary>22. Recv sql:jobs</summary>

```json
[
  {
    "id": "46205ea0-8241-4ac8-96e5-d646118727aa",
    "project_id": "test-1778829239622-py9jkz",
    "description": "Multi-stage",
    "status": "running",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": "implement",
    "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"}]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.623978350+00:00",
    "updated_at": "2026-05-15T07:13:59.631685537+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>23. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET current_stage = ?1, stage_history = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

---

## complete finishes the job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.637 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.637 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239636-2hrbe3","description":"Complete workflow","workflow":"simple"}` |
| 3 | 07:13:59.638 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.639 | Response | http response | `200 {"job_id":"28e1e594-69ea-481b-8ae5-ab138f9d63cb"}` |
| 5 | 07:13:59.639 | Send | http.send | `POST /api/v1/workers {"job_id":"28e1e594-69ea-481b-8ae5-ab138f9d63cb","provider":"test"}` |
| 6 | 07:13:59.640 | Recv | sql:workers | `{"sql":"INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)","changes":1}` |
| 7 | 07:13:59.641 | Response | http response | `200 {"worker_id":"beba44d0-f445-4a71-b054-82325f1e0ddc"}` |
| 8 | 07:13:59.641 | Send | http.send | `POST /api/v1/workers/beba44d0-f445-4a71-b054-82325f1e0ddc/register {"job_id":"28e1e594-69ea-481b-8ae5-ab138f9d63cb"}` |
| 9 | 07:13:59.641 | Recv | sql:workers | `[{"id":"beba44d0-f445-4a71-b054-82325f1e0ddc","job_id":"28e1e594-69ea-481b-8ae5-ab138f9d63cb","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.639905777+00:00","destroyed_at":null}]` |
| 10 | 07:13:59.641 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = ?1 WHERE id = ?2","changes":1}` |
| 11 | 07:13:59.642 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3","changes":1}` |
| 12 | 07:13:59.644 | Response | http response | `200 ` |
| 13 | 07:13:59.644 | Send | http.send | `POST /api/v1/workers/beba44d0-f445-4a71-b054-82325f1e0ddc/complete {"result":"all done"}` |
| 14 | 07:13:59.644 | Recv | sql:workers | `[{"id":"beba44d0-f445-4a71-b054-82325f1e0ddc","job_id":"28e1e594-69ea-481b-8ae5-ab138f9d63cb","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-15T07:13:59.639905777+00:00","destroyed_at":null}]` |
| 15 | 07:13:59.644 | Recv | sql:jobs | `{"sql":"UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4","changes":1}` |
| 16 | 07:13:59.645 | Recv | sql:workers | `{"sql":"UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2","changes":1}` |
| 17 | 07:13:59.646 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "sql": "INSERT INTO workers (id, job_id, provider, status, created_at) VALUES (?1, ?2, ?3, 'creating', ?4)",
  "changes": 1
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
[
  {
    "id": "beba44d0-f445-4a71-b054-82325f1e0ddc",
    "job_id": "28e1e594-69ea-481b-8ae5-ab138f9d63cb",
    "provider": "test",
    "provider_id": null,
    "status": "creating",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.639905777+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>10. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

<details><summary>11. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET status = ?1, updated_at = ?2 WHERE id = ?3",
  "changes": 1
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
[
  {
    "id": "beba44d0-f445-4a71-b054-82325f1e0ddc",
    "job_id": "28e1e594-69ea-481b-8ae5-ab138f9d63cb",
    "provider": "test",
    "provider_id": null,
    "status": "running",
    "ip_address": null,
    "workspace_path": null,
    "heartbeat_at": null,
    "created_at": "2026-05-15T07:13:59.639905777+00:00",
    "destroyed_at": null
  }
]
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "sql": "UPDATE jobs SET result = ?1, status = 'completed', finished_at = ?2, updated_at = ?3 WHERE id = ?4",
  "changes": 1
}
```

</details>

<details><summary>16. Recv sql:workers</summary>

```json
{
  "sql": "UPDATE workers SET status = 'stopped', destroyed_at = ?1 WHERE id = ?2",
  "changes": 1
}
```

</details>

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.649 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.649 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239648-makzo4","description":"Add a hello world function","workflow":"simple"}` |
| 3 | 07:13:59.649 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.650 | Response | http response | `200 {"job_id":"faded7d8-b4af-452d-9106-315c21448aae"}` |
| 5 | 07:13:59.650 | Send | http.send | `GET /api/v1/jobs/faded7d8-b4af-452d-9106-315c21448aae/config` |
| 6 | 07:13:59.651 | Recv | sql:jobs | `[{"id":"faded7d8-b4af-452d-9106-315c21448aae","project_id":"test-1778829239648-makzo4","description":"Add a hello world function","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":...` |
| 7 | 07:13:59.651 | Recv | sql:workflows | `[{"name":"simple","content":"name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read, glob, grep]\n max_tokens: 8000\n routes:\n - when: 'response.complexity == \"simple\"'\n next: done\n - when: 'true'...` |
| 8 | 07:13:59.651 | Response | http response | `200 {"job_id":"faded7d8-b4af-452d-9106-315c21448aae","stage":"","prompt":"Add a hello world function","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepsee...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "faded7d8-b4af-452d-9106-315c21448aae",
    "project_id": "test-1778829239648-makzo4",
    "description": "Add a hello world function",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": "simple",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.649598825+00:00",
    "updated_at": "2026-05-15T07:13:59.649598825+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>7. Recv sql:workflows</summary>

```json
[
  {
    "name": "simple",
    "content": "name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n  plan:\n    skill: plan\n    prompt: \"Plan: {{input}}\"\n    tools: [bash, read, glob, grep]\n    max_tokens: 8000\n    routes:\n      - when: 'response.complexity == \"simple\"'\n        next: done\n      - when: 'true'\n        next: done\n  done:\n    skill: pause\n    prompt: \"Done\"\n    routes: null\n",
    "source": "builtin",
    "project_id": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

</details>

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.652 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.652 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239651-lslqy6","description":"Build feature X","workflow":"feature"}` |
| 3 | 07:13:59.653 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.654 | Response | http response | `200 {"job_id":"a0e300b7-2c6a-4951-add5-6db0705fdcc6"}` |
| 5 | 07:13:59.654 | Send | http.send | `GET /api/v1/jobs/a0e300b7-2c6a-4951-add5-6db0705fdcc6/config` |
| 6 | 07:13:59.654 | Recv | sql:jobs | `[{"id":"a0e300b7-2c6a-4951-add5-6db0705fdcc6","project_id":"test-1778829239651-lslqy6","description":"Build feature X","status":"queued","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 7 | 07:13:59.655 | Recv | sql:workflows | `[{"name":"feature","content":"name: feature\ndescription: \"Feature implementation workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Create a plan for: {{input}}\"\n tools: [bash, read, glob, grep]\n max_tokens: 8000\n routes:\n - when: 'response.complexity == \"simple\"'\n next: implement\n ...` |
| 8 | 07:13:59.655 | Response | http response | `200 {"job_id":"a0e300b7-2c6a-4951-add5-6db0705fdcc6","stage":"","prompt":"Build feature X","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "a0e300b7-2c6a-4951-add5-6db0705fdcc6",
    "project_id": "test-1778829239651-lslqy6",
    "description": "Build feature X",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": "feature",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.652966637+00:00",
    "updated_at": "2026-05-15T07:13:59.652966637+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>7. Recv sql:workflows</summary>

```json
[
  {
    "name": "feature",
    "content": "name: feature\ndescription: \"Feature implementation workflow\"\nstages:\n  plan:\n    skill: plan\n    prompt: \"Create a plan for: {{input}}\"\n    tools: [bash, read, glob, grep]\n    max_tokens: 8000\n    routes:\n      - when: 'response.complexity == \"simple\"'\n        next: implement\n      - when: 'response.complexity == \"complex\"'\n        next: plan_detail\n  plan_detail:\n    skill: plan_detail\n    prompt: \"Detailed plan based on: {{stages.plan.output}}\"\n    tools: [bash, read, glob, grep]\n    max_tokens: 8000\n    routes:\n      - when: 'true'\n        next: implement\n  implement:\n    skill: implement\n    prompt: \"Implement: {{input}}\"\n    tools: [bash, read, write, edit, glob, grep]\n    max_tokens: 8096\n    checkpoint: true\n    routes:\n      - when: 'response.success'\n        next: done\n      - when: 'true'\n        next: implement\n  done:\n    skill: pause\n    prompt: \"Complete\"\n    routes: null\n",
    "source": "builtin",
    "project_id": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

</details>

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.656 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.656 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239655-gkx7d6","description":"Plan the feature","workflow":"simple"}` |
| 3 | 07:13:59.656 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.657 | Response | http response | `200 {"job_id":"105e13f1-18ff-430f-8dc9-19726f5cc99f"}` |
| 5 | 07:13:59.657 | Send | http.send | `GET /api/v1/jobs/105e13f1-18ff-430f-8dc9-19726f5cc99f/config` |
| 6 | 07:13:59.657 | Recv | sql:jobs | `[{"id":"105e13f1-18ff-430f-8dc9-19726f5cc99f","project_id":"test-1778829239655-gkx7d6","description":"Plan the feature","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 7 | 07:13:59.658 | Recv | sql:workflows | `[{"name":"simple","content":"name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read, glob, grep]\n max_tokens: 8000\n routes:\n - when: 'response.complexity == \"simple\"'\n next: done\n - when: 'true'...` |
| 8 | 07:13:59.658 | Response | http response | `200 {"job_id":"105e13f1-18ff-430f-8dc9-19726f5cc99f","stage":"","prompt":"Plan the feature","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
[
  {
    "id": "105e13f1-18ff-430f-8dc9-19726f5cc99f",
    "project_id": "test-1778829239655-gkx7d6",
    "description": "Plan the feature",
    "status": "queued",
    "worker_id": null,
    "branch": null,
    "workflow_name": "simple",
    "current_stage": null,
    "stage_history": "[]",
    "attempt": 1,
    "max_attempts": 3,
    "result": null,
    "error": null,
    "created_at": "2026-05-15T07:13:59.656555532+00:00",
    "updated_at": "2026-05-15T07:13:59.656555532+00:00",
    "started_at": null,
    "finished_at": null
  }
]
```

</details>

<details><summary>7. Recv sql:workflows</summary>

```json
[
  {
    "name": "simple",
    "content": "name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n  plan:\n    skill: plan\n    prompt: \"Plan: {{input}}\"\n    tools: [bash, read, glob, grep]\n    max_tokens: 8000\n    routes:\n      - when: 'response.complexity == \"simple\"'\n        next: done\n      - when: 'true'\n        next: done\n  done:\n    skill: pause\n    prompt: \"Done\"\n    routes: null\n",
    "source": "builtin",
    "project_id": null,
    "created_at": "2026-01-01T00:00:00Z",
    "updated_at": "2026-01-01T00:00:00Z"
  }
]
```

</details>

---

## workflow seeded in DB is accessible via config

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:13:59.659 | Send | sql.put | `1 rows` |
| 2 | 07:13:59.659 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778829239658-kaot90","description":"Test","workflow":"simple"}` |
| 3 | 07:13:59.659 | Recv | sql:jobs | `{"sql":"INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)","changes":1}` |
| 4 | 07:13:59.661 | Response | http response | `200 {"job_id":"a8e32635-2275-47e9-9ece-44d18017db3e"}` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "sql": "INSERT INTO jobs (id, project_id, description, status, workflow_name, branch, created_at, updated_at) VALUES (?1, ?2, ?3, 'queued', ?4, ?5, ?6, ?7)",
  "changes": 1
}
```

</details>

---

