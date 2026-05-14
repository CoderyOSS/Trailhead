# Trailhead E2E Test Suite

**Date:** 2026-05-14T20:47:16.479Z
**Events:** 470
**Duration:** 792ms

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.718 | Send | sql.clear | `all tables` |
| 2 | 20:47:15.726 | Send | sql.put | `2 rows` |
| 3 | 20:47:15.745 | Send | sql.clear | `all tables` |
| 4 | 20:47:15.751 | Send | sql.put | `2 rows` |
| 5 | 20:47:15.996 | Send | sql.put | `1 rows` |
| 6 | 20:47:15.997 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635995-wy4vvj","description":"Hello world test"}` |
| 7 | 20:47:15.999 | Response | http response | `200 {"job_id":"25d51952-3bfa-4174-ae57-8aa6f5d174db"}` |

---

## lists jobs via HTTP matching DB count

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.729 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.730 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635728-elmiku","description":"Job 1"}` |
| 3 | 20:47:15.732 | Recv | sql:jobs | `{"id":"243f2476-cbb1-4f79-973e-4d0473c3a23f","project_id":"test-1778791635728-elmiku","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-05...` |
| 4 | 20:47:15.734 | Response | http response | `200 {"job_id":"243f2476-cbb1-4f79-973e-4d0473c3a23f"}` |
| 5 | 20:47:15.735 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635728-elmiku","description":"Job 2"}` |
| 6 | 20:47:15.735 | Recv | sql:jobs | `{"id":"b8ed88df-68de-40a3-92fb-a55176d390aa","project_id":"test-1778791635728-elmiku","description":"Job 2","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-05...` |
| 7 | 20:47:15.737 | Response | http response | `200 {"job_id":"b8ed88df-68de-40a3-92fb-a55176d390aa"}` |
| 8 | 20:47:15.737 | Send | http.send | `GET /api/v1/jobs` |
| 9 | 20:47:15.737 | Response | http response | `200 [{"id":"243f2476-cbb1-4f79-973e-4d0473c3a23f","project_id":"test-1778791635728-elmiku","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "243f2476-cbb1-4f79-973e-4d0473c3a23f",
  "project_id": "test-1778791635728-elmiku",
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
  "created_at": "2026-05-14T20:47:15.732089048+00:00",
  "updated_at": "2026-05-14T20:47:15.732089048+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
{
  "id": "b8ed88df-68de-40a3-92fb-a55176d390aa",
  "project_id": "test-1778791635728-elmiku",
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
  "created_at": "2026-05-14T20:47:15.735344351+00:00",
  "updated_at": "2026-05-14T20:47:15.735344351+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## list workers via HTTP matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.752 | Send | http.send | `GET /api/v1/workers` |
| 2 | 20:47:15.754 | Response | http response | `200 []` |

---

## GET /api/v1/jobs returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.758 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.760 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635757-h3pmi5","description":"Dashboard test job"}` |
| 3 | 20:47:15.760 | Recv | sql:jobs | `{"id":"3c9705d4-21ac-4d45-95a3-2dcb46008979","project_id":"test-1778791635757-h3pmi5","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created...` |
| 4 | 20:47:15.762 | Response | http response | `200 {"job_id":"3c9705d4-21ac-4d45-95a3-2dcb46008979"}` |
| 5 | 20:47:15.762 | Send | http.send | `GET /api/v1/jobs` |
| 6 | 20:47:15.762 | Response | http response | `200 [{"id":"3c9705d4-21ac-4d45-95a3-2dcb46008979","project_id":"test-1778791635757-h3pmi5","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "3c9705d4-21ac-4d45-95a3-2dcb46008979",
  "project_id": "test-1778791635757-h3pmi5",
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
  "created_at": "2026-05-14T20:47:15.760290665+00:00",
  "updated_at": "2026-05-14T20:47:15.760290665+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## GET /api/v1/jobs/{id} returns detail matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.765 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.766 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635764-sqgaml","description":"Detail test"}` |
| 3 | 20:47:15.767 | Recv | sql:jobs | `{"id":"d6110d89-816f-48b7-ada6-dbfea96f8b91","project_id":"test-1778791635764-sqgaml","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 4 | 20:47:15.768 | Response | http response | `200 {"job_id":"d6110d89-816f-48b7-ada6-dbfea96f8b91"}` |
| 5 | 20:47:15.768 | Send | http.send | `GET /api/v1/jobs/d6110d89-816f-48b7-ada6-dbfea96f8b91` |
| 6 | 20:47:15.768 | Response | http response | `200 {"id":"d6110d89-816f-48b7-ada6-dbfea96f8b91","project_id":"test-1778791635764-sqgaml","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "d6110d89-816f-48b7-ada6-dbfea96f8b91",
  "project_id": "test-1778791635764-sqgaml",
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
  "created_at": "2026-05-14T20:47:15.767047953+00:00",
  "updated_at": "2026-05-14T20:47:15.767047953+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## GET /api/v1/workers returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.771 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.772 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635770-tdbopr","description":"Worker list test"}` |
| 3 | 20:47:15.772 | Recv | sql:jobs | `{"id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","project_id":"test-1778791635770-tdbopr","description":"Worker list test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |
| 4 | 20:47:15.774 | Response | http response | `200 {"job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016"}` |
| 5 | 20:47:15.774 | Send | http.send | `POST /api/v1/workers {"job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","provider":"test"}` |
| 6 | 20:47:15.775 | Recv | sql:workers | `{"id":"a5a458d9-4863-46d5-b438-bc79aec927ec","job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.774897245+00:00","destroyed_at":null}` |
| 7 | 20:47:15.776 | Response | http response | `200 {"worker_id":"a5a458d9-4863-46d5-b438-bc79aec927ec"}` |
| 8 | 20:47:15.776 | Send | http.send | `POST /api/v1/workers/a5a458d9-4863-46d5-b438-bc79aec927ec/register {"job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016"}` |
| 9 | 20:47:15.776 | Recv | sql:workers | `{"id":"a5a458d9-4863-46d5-b438-bc79aec927ec","job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.774897245+00:00","destroyed_at":null}` |
| 10 | 20:47:15.778 | Recv | sql:jobs | `{"id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","project_id":"test-1778791635770-tdbopr","description":"Worker list test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |
| 11 | 20:47:15.779 | Response | http response | `200 ` |
| 12 | 20:47:15.779 | Send | http.send | `GET /api/v1/workers` |
| 13 | 20:47:15.779 | Response | http response | `200 [{"id":"a5a458d9-4863-46d5-b438-bc79aec927ec","job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.774897245+00:00","destroyed_at":null}]` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "625c3be2-1fbe-4e97-b531-0ecbdd308016",
  "project_id": "test-1778791635770-tdbopr",
  "description": "Worker list test",
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
  "created_at": "2026-05-14T20:47:15.772784262+00:00",
  "updated_at": "2026-05-14T20:47:15.772784262+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "a5a458d9-4863-46d5-b438-bc79aec927ec",
  "job_id": "625c3be2-1fbe-4e97-b531-0ecbdd308016",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.774897245+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "a5a458d9-4863-46d5-b438-bc79aec927ec",
  "job_id": "625c3be2-1fbe-4e97-b531-0ecbdd308016",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.774897245+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "625c3be2-1fbe-4e97-b531-0ecbdd308016",
  "project_id": "test-1778791635770-tdbopr",
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
  "created_at": "2026-05-14T20:47:15.772784262+00:00",
  "updated_at": "2026-05-14T20:47:15.778061862+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## POST /api/v1/jobs/{id}/pause changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.782 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.783 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635781-xr2e9d","description":"Pause via dashboard"}` |
| 3 | 20:47:15.783 | Recv | sql:jobs | `{"id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","project_id":"test-1778791635781-xr2e9d","description":"Pause via dashboard","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 4 | 20:47:15.785 | Response | http response | `200 {"job_id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71"}` |
| 5 | 20:47:15.785 | Send | http.send | `POST /api/v1/workers {"job_id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","provider":"test"}` |
| 6 | 20:47:15.785 | Recv | sql:workers | `{"id":"c981d522-1ef4-478b-b4e5-b4c7e65cd70b","job_id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.785400085+00:00","destroyed_at":null}` |
| 7 | 20:47:15.786 | Response | http response | `200 {"worker_id":"c981d522-1ef4-478b-b4e5-b4c7e65cd70b"}` |
| 8 | 20:47:15.786 | Send | http.send | `POST /api/v1/workers/c981d522-1ef4-478b-b4e5-b4c7e65cd70b/register {"job_id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71"}` |
| 9 | 20:47:15.786 | Recv | sql:workers | `{"id":"c981d522-1ef4-478b-b4e5-b4c7e65cd70b","job_id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.785400085+00:00","destroyed_at":null}` |
| 10 | 20:47:15.787 | Recv | sql:jobs | `{"id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","project_id":"test-1778791635781-xr2e9d","description":"Pause via dashboard","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 11 | 20:47:15.788 | Response | http response | `200 ` |
| 12 | 20:47:15.788 | Send | http.send | `POST /api/v1/jobs/aea9d4c1-9748-4d32-9f69-75c2d795fe71/pause` |
| 13 | 20:47:15.788 | Recv | sql:jobs | `{"id":"aea9d4c1-9748-4d32-9f69-75c2d795fe71","project_id":"test-1778791635781-xr2e9d","description":"Pause via dashboard","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 14 | 20:47:15.790 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "aea9d4c1-9748-4d32-9f69-75c2d795fe71",
  "project_id": "test-1778791635781-xr2e9d",
  "description": "Pause via dashboard",
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
  "created_at": "2026-05-14T20:47:15.783699864+00:00",
  "updated_at": "2026-05-14T20:47:15.783699864+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "c981d522-1ef4-478b-b4e5-b4c7e65cd70b",
  "job_id": "aea9d4c1-9748-4d32-9f69-75c2d795fe71",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.785400085+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "c981d522-1ef4-478b-b4e5-b4c7e65cd70b",
  "job_id": "aea9d4c1-9748-4d32-9f69-75c2d795fe71",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.785400085+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "aea9d4c1-9748-4d32-9f69-75c2d795fe71",
  "project_id": "test-1778791635781-xr2e9d",
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
  "created_at": "2026-05-14T20:47:15.783699864+00:00",
  "updated_at": "2026-05-14T20:47:15.787539086+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "aea9d4c1-9748-4d32-9f69-75c2d795fe71",
  "project_id": "test-1778791635781-xr2e9d",
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
  "created_at": "2026-05-14T20:47:15.783699864+00:00",
  "updated_at": "2026-05-14T20:47:15.788724722+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## POST /api/v1/jobs/{id}/cancel changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.793 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.794 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635792-0b33hb","description":"Cancel via dashboard"}` |
| 3 | 20:47:15.795 | Recv | sql:jobs | `{"id":"806af2be-0a9a-4799-9786-2c7633f5483e","project_id":"test-1778791635792-0b33hb","description":"Cancel via dashboard","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 4 | 20:47:15.796 | Response | http response | `200 {"job_id":"806af2be-0a9a-4799-9786-2c7633f5483e"}` |
| 5 | 20:47:15.796 | Send | http.send | `POST /api/v1/jobs/806af2be-0a9a-4799-9786-2c7633f5483e/cancel` |
| 6 | 20:47:15.797 | Recv | sql:jobs | `{"id":"806af2be-0a9a-4799-9786-2c7633f5483e","project_id":"test-1778791635792-0b33hb","description":"Cancel via dashboard","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |
| 7 | 20:47:15.799 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "806af2be-0a9a-4799-9786-2c7633f5483e",
  "project_id": "test-1778791635792-0b33hb",
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
  "created_at": "2026-05-14T20:47:15.795001686+00:00",
  "updated_at": "2026-05-14T20:47:15.795001686+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:jobs</summary>

```json
{
  "id": "806af2be-0a9a-4799-9786-2c7633f5483e",
  "project_id": "test-1778791635792-0b33hb",
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
  "created_at": "2026-05-14T20:47:15.795001686+00:00",
  "updated_at": "2026-05-14T20:47:15.797205085+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## new job is queued in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.805 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.807 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635804-dzudsx","description":"State machine test"}` |
| 3 | 20:47:15.808 | Recv | sql:jobs | `{"id":"9297666a-32f8-4dea-ac84-6fc36980edc2","project_id":"test-1778791635804-dzudsx","description":"State machine test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created...` |
| 4 | 20:47:15.810 | Response | http response | `200 {"job_id":"9297666a-32f8-4dea-ac84-6fc36980edc2"}` |
| 5 | 20:47:16.429 | Send | sql.put | `1 rows` |
| 6 | 20:47:16.430 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636428-w2z1na","description":"Start at first stage"}` |
| 7 | 20:47:16.430 | Recv | sql:jobs | `{"id":"81495f15-b87c-4642-ba1c-7578125a2f68","project_id":"test-1778791636428-w2z1na","description":"Start at first stage","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 8 | 20:47:16.431 | Response | http response | `200 {"job_id":"81495f15-b87c-4642-ba1c-7578125a2f68"}` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "9297666a-32f8-4dea-ac84-6fc36980edc2",
  "project_id": "test-1778791635804-dzudsx",
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
  "created_at": "2026-05-14T20:47:15.808160176+00:00",
  "updated_at": "2026-05-14T20:47:15.808160176+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>7. Recv sql:jobs</summary>

```json
{
  "id": "81495f15-b87c-4642-ba1c-7578125a2f68",
  "project_id": "test-1778791636428-w2z1na",
  "description": "Start at first stage",
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
  "created_at": "2026-05-14T20:47:16.430387477+00:00",
  "updated_at": "2026-05-14T20:47:16.430387477+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## running to paused via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.814 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.816 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635812-8z9o52","description":"Pause test"}` |
| 3 | 20:47:15.816 | Recv | sql:jobs | `{"id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","project_id":"test-1778791635812-8z9o52","description":"Pause test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |
| 4 | 20:47:15.818 | Response | http response | `200 {"job_id":"bc610f4e-2364-42b0-8a15-5106e75cc28e"}` |
| 5 | 20:47:15.818 | Send | http.send | `POST /api/v1/workers {"job_id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","provider":"test"}` |
| 6 | 20:47:15.819 | Recv | sql:workers | `{"id":"4676aa33-f18e-469f-aeef-0899a57b038d","job_id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.818886061+00:00","destroyed_at":null}` |
| 7 | 20:47:15.820 | Response | http response | `200 {"worker_id":"4676aa33-f18e-469f-aeef-0899a57b038d"}` |
| 8 | 20:47:15.820 | Send | http.send | `POST /api/v1/workers/4676aa33-f18e-469f-aeef-0899a57b038d/register {"job_id":"bc610f4e-2364-42b0-8a15-5106e75cc28e"}` |
| 9 | 20:47:15.821 | Recv | sql:workers | `{"id":"4676aa33-f18e-469f-aeef-0899a57b038d","job_id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.818886061+00:00","destroyed_at":null}` |
| 10 | 20:47:15.822 | Recv | sql:jobs | `{"id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","project_id":"test-1778791635812-8z9o52","description":"Pause test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 11 | 20:47:15.825 | Response | http response | `200 ` |
| 12 | 20:47:15.825 | Send | http.send | `POST /api/v1/jobs/bc610f4e-2364-42b0-8a15-5106e75cc28e/pause` |
| 13 | 20:47:15.825 | Recv | sql:jobs | `{"id":"bc610f4e-2364-42b0-8a15-5106e75cc28e","project_id":"test-1778791635812-8z9o52","description":"Pause test","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |
| 14 | 20:47:15.827 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "bc610f4e-2364-42b0-8a15-5106e75cc28e",
  "project_id": "test-1778791635812-8z9o52",
  "description": "Pause test",
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
  "created_at": "2026-05-14T20:47:15.816759728+00:00",
  "updated_at": "2026-05-14T20:47:15.816759728+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "4676aa33-f18e-469f-aeef-0899a57b038d",
  "job_id": "bc610f4e-2364-42b0-8a15-5106e75cc28e",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.818886061+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "4676aa33-f18e-469f-aeef-0899a57b038d",
  "job_id": "bc610f4e-2364-42b0-8a15-5106e75cc28e",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.818886061+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "bc610f4e-2364-42b0-8a15-5106e75cc28e",
  "project_id": "test-1778791635812-8z9o52",
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
  "created_at": "2026-05-14T20:47:15.816759728+00:00",
  "updated_at": "2026-05-14T20:47:15.822598993+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "bc610f4e-2364-42b0-8a15-5106e75cc28e",
  "project_id": "test-1778791635812-8z9o52",
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
  "created_at": "2026-05-14T20:47:15.816759728+00:00",
  "updated_at": "2026-05-14T20:47:15.825514444+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## paused to resuming via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.831 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.832 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635829-8trhi9","description":"Resume test"}` |
| 3 | 20:47:15.832 | Recv | sql:jobs | `{"id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","project_id":"test-1778791635829-8trhi9","description":"Resume test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 4 | 20:47:15.833 | Response | http response | `200 {"job_id":"4e202e31-6c6b-401a-9d5d-f0cb50064533"}` |
| 5 | 20:47:15.834 | Send | http.send | `POST /api/v1/workers {"job_id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","provider":"test"}` |
| 6 | 20:47:15.834 | Recv | sql:workers | `{"id":"d849bf92-fe7f-494d-8b79-71db79153c56","job_id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.834194458+00:00","destroyed_at":null}` |
| 7 | 20:47:15.835 | Response | http response | `200 {"worker_id":"d849bf92-fe7f-494d-8b79-71db79153c56"}` |
| 8 | 20:47:15.835 | Send | http.send | `POST /api/v1/workers/d849bf92-fe7f-494d-8b79-71db79153c56/register {"job_id":"4e202e31-6c6b-401a-9d5d-f0cb50064533"}` |
| 9 | 20:47:15.835 | Recv | sql:workers | `{"id":"d849bf92-fe7f-494d-8b79-71db79153c56","job_id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.834194458+00:00","destroyed_at":null}` |
| 10 | 20:47:15.836 | Recv | sql:jobs | `{"id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","project_id":"test-1778791635829-8trhi9","description":"Resume test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 11 | 20:47:15.837 | Response | http response | `200 ` |
| 12 | 20:47:15.837 | Send | http.send | `POST /api/v1/jobs/4e202e31-6c6b-401a-9d5d-f0cb50064533/pause` |
| 13 | 20:47:15.837 | Recv | sql:jobs | `{"id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","project_id":"test-1778791635829-8trhi9","description":"Resume test","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 14 | 20:47:15.839 | Response | http response | `200 ` |
| 15 | 20:47:15.839 | Send | http.send | `POST /api/v1/jobs/4e202e31-6c6b-401a-9d5d-f0cb50064533/resume` |
| 16 | 20:47:15.839 | Recv | sql:jobs | `{"id":"4e202e31-6c6b-401a-9d5d-f0cb50064533","project_id":"test-1778791635829-8trhi9","description":"Resume test","status":"resuming","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 17 | 20:47:15.842 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "project_id": "test-1778791635829-8trhi9",
  "description": "Resume test",
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
  "created_at": "2026-05-14T20:47:15.832834470+00:00",
  "updated_at": "2026-05-14T20:47:15.832834470+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "d849bf92-fe7f-494d-8b79-71db79153c56",
  "job_id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.834194458+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "d849bf92-fe7f-494d-8b79-71db79153c56",
  "job_id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.834194458+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "project_id": "test-1778791635829-8trhi9",
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
  "created_at": "2026-05-14T20:47:15.832834470+00:00",
  "updated_at": "2026-05-14T20:47:15.836287531+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "project_id": "test-1778791635829-8trhi9",
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
  "created_at": "2026-05-14T20:47:15.832834470+00:00",
  "updated_at": "2026-05-14T20:47:15.837910445+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
{
  "id": "4e202e31-6c6b-401a-9d5d-f0cb50064533",
  "project_id": "test-1778791635829-8trhi9",
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
  "created_at": "2026-05-14T20:47:15.832834470+00:00",
  "updated_at": "2026-05-14T20:47:15.839670386+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## running to completed, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.846 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.847 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635844-xvdks6","description":"Complete test"}` |
| 3 | 20:47:15.848 | Recv | sql:jobs | `{"id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","project_id":"test-1778791635844-xvdks6","description":"Complete test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 4 | 20:47:15.849 | Response | http response | `200 {"job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5"}` |
| 5 | 20:47:15.849 | Send | http.send | `POST /api/v1/workers {"job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","provider":"test"}` |
| 6 | 20:47:15.849 | Recv | sql:workers | `{"id":"c968190f-2f07-4bc7-a847-c04adbb7eb7a","job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.849530647+00:00","destroyed_at":null}` |
| 7 | 20:47:15.850 | Response | http response | `200 {"worker_id":"c968190f-2f07-4bc7-a847-c04adbb7eb7a"}` |
| 8 | 20:47:15.850 | Send | http.send | `POST /api/v1/workers/c968190f-2f07-4bc7-a847-c04adbb7eb7a/register {"job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5"}` |
| 9 | 20:47:15.851 | Recv | sql:workers | `{"id":"c968190f-2f07-4bc7-a847-c04adbb7eb7a","job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.849530647+00:00","destroyed_at":null}` |
| 10 | 20:47:15.852 | Recv | sql:jobs | `{"id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","project_id":"test-1778791635844-xvdks6","description":"Complete test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 11 | 20:47:15.853 | Response | http response | `200 ` |
| 12 | 20:47:15.853 | Send | http.send | `POST /api/v1/workers/c968190f-2f07-4bc7-a847-c04adbb7eb7a/complete {"result":"success"}` |
| 13 | 20:47:15.854 | Recv | sql:jobs | `{"id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","project_id":"test-1778791635844-xvdks6","description":"Complete test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","error":null,"crea...` |
| 14 | 20:47:15.855 | Recv | sql:workers | `{"id":"c968190f-2f07-4bc7-a847-c04adbb7eb7a","job_id":"f6876741-2fcb-4630-8f6d-9bb4df4413a5","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.849530647+00:00","destroyed_at":"2026-05-14T20:47:15.8...` |
| 15 | 20:47:15.856 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "project_id": "test-1778791635844-xvdks6",
  "description": "Complete test",
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
  "created_at": "2026-05-14T20:47:15.847797386+00:00",
  "updated_at": "2026-05-14T20:47:15.847797386+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "c968190f-2f07-4bc7-a847-c04adbb7eb7a",
  "job_id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.849530647+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "c968190f-2f07-4bc7-a847-c04adbb7eb7a",
  "job_id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.849530647+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "project_id": "test-1778791635844-xvdks6",
  "description": "Complete test",
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
  "created_at": "2026-05-14T20:47:15.847797386+00:00",
  "updated_at": "2026-05-14T20:47:15.852220108+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "project_id": "test-1778791635844-xvdks6",
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
  "created_at": "2026-05-14T20:47:15.847797386+00:00",
  "updated_at": "2026-05-14T20:47:15.854136604+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.854136604+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "c968190f-2f07-4bc7-a847-c04adbb7eb7a",
  "job_id": "f6876741-2fcb-4630-8f6d-9bb4df4413a5",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.849530647+00:00",
  "destroyed_at": "2026-05-14T20:47:15.855317153+00:00"
}
```

</details>

---

## running to failed_retryable, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.861 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.865 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635859-thgjal","description":"Fail test"}` |
| 3 | 20:47:15.866 | Recv | sql:jobs | `{"id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","project_id":"test-1778791635859-thgjal","description":"Fail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"202...` |
| 4 | 20:47:15.867 | Response | http response | `200 {"job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8"}` |
| 5 | 20:47:15.867 | Send | http.send | `POST /api/v1/workers {"job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","provider":"test"}` |
| 6 | 20:47:15.868 | Recv | sql:workers | `{"id":"8f52ad50-1085-4d3a-b2c9-a39421c87aa4","job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.868047107+00:00","destroyed_at":null}` |
| 7 | 20:47:15.869 | Response | http response | `200 {"worker_id":"8f52ad50-1085-4d3a-b2c9-a39421c87aa4"}` |
| 8 | 20:47:15.869 | Send | http.send | `POST /api/v1/workers/8f52ad50-1085-4d3a-b2c9-a39421c87aa4/register {"job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8"}` |
| 9 | 20:47:15.869 | Recv | sql:workers | `{"id":"8f52ad50-1085-4d3a-b2c9-a39421c87aa4","job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.868047107+00:00","destroyed_at":null}` |
| 10 | 20:47:15.870 | Recv | sql:jobs | `{"id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","project_id":"test-1778791635859-thgjal","description":"Fail test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |
| 11 | 20:47:15.871 | Response | http response | `200 ` |
| 12 | 20:47:15.871 | Send | http.send | `POST /api/v1/workers/8f52ad50-1085-4d3a-b2c9-a39421c87aa4/fail {"error":"transient failure"}` |
| 13 | 20:47:15.871 | Recv | sql:jobs | `{"id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","project_id":"test-1778791635859-thgjal","description":"Fail test","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":"transient f...` |
| 14 | 20:47:15.872 | Recv | sql:workers | `{"id":"8f52ad50-1085-4d3a-b2c9-a39421c87aa4","job_id":"2cc52335-1e4b-44b2-a247-1bd1850c2fd8","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.868047107+00:00","destroyed_at":"2026-05-14T20:47:15.8...` |
| 15 | 20:47:15.873 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "project_id": "test-1778791635859-thgjal",
  "description": "Fail test",
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
  "created_at": "2026-05-14T20:47:15.865873322+00:00",
  "updated_at": "2026-05-14T20:47:15.865873322+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "8f52ad50-1085-4d3a-b2c9-a39421c87aa4",
  "job_id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.868047107+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "8f52ad50-1085-4d3a-b2c9-a39421c87aa4",
  "job_id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.868047107+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "project_id": "test-1778791635859-thgjal",
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
  "created_at": "2026-05-14T20:47:15.865873322+00:00",
  "updated_at": "2026-05-14T20:47:15.870089472+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "project_id": "test-1778791635859-thgjal",
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
  "created_at": "2026-05-14T20:47:15.865873322+00:00",
  "updated_at": "2026-05-14T20:47:15.871628931+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.871628931+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "8f52ad50-1085-4d3a-b2c9-a39421c87aa4",
  "job_id": "2cc52335-1e4b-44b2-a247-1bd1850c2fd8",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.868047107+00:00",
  "destroyed_at": "2026-05-14T20:47:15.872414625+00:00"
}
```

</details>

---

## cannot resume completed job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.875 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.876 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635874-geg761","description":"Terminal test"}` |
| 3 | 20:47:15.876 | Recv | sql:jobs | `{"id":"c9a7f918-864c-440b-a46e-97ced89df59a","project_id":"test-1778791635874-geg761","description":"Terminal test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 4 | 20:47:15.877 | Response | http response | `200 {"job_id":"c9a7f918-864c-440b-a46e-97ced89df59a"}` |
| 5 | 20:47:15.877 | Send | http.send | `POST /api/v1/workers {"job_id":"c9a7f918-864c-440b-a46e-97ced89df59a","provider":"test"}` |
| 6 | 20:47:15.877 | Recv | sql:workers | `{"id":"2a53e41d-96ef-4292-be09-e0c02a017779","job_id":"c9a7f918-864c-440b-a46e-97ced89df59a","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.877797763+00:00","destroyed_at":null}` |
| 7 | 20:47:15.878 | Response | http response | `200 {"worker_id":"2a53e41d-96ef-4292-be09-e0c02a017779"}` |
| 8 | 20:47:15.878 | Send | http.send | `POST /api/v1/workers/2a53e41d-96ef-4292-be09-e0c02a017779/register {"job_id":"c9a7f918-864c-440b-a46e-97ced89df59a"}` |
| 9 | 20:47:15.878 | Recv | sql:workers | `{"id":"2a53e41d-96ef-4292-be09-e0c02a017779","job_id":"c9a7f918-864c-440b-a46e-97ced89df59a","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.877797763+00:00","destroyed_at":null}` |
| 10 | 20:47:15.879 | Recv | sql:jobs | `{"id":"c9a7f918-864c-440b-a46e-97ced89df59a","project_id":"test-1778791635874-geg761","description":"Terminal test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 11 | 20:47:15.880 | Response | http response | `200 ` |
| 12 | 20:47:15.880 | Send | http.send | `POST /api/v1/workers/2a53e41d-96ef-4292-be09-e0c02a017779/complete {"result":"done"}` |
| 13 | 20:47:15.880 | Recv | sql:jobs | `{"id":"c9a7f918-864c-440b-a46e-97ced89df59a","project_id":"test-1778791635874-geg761","description":"Terminal test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"created...` |
| 14 | 20:47:15.881 | Recv | sql:workers | `{"id":"2a53e41d-96ef-4292-be09-e0c02a017779","job_id":"c9a7f918-864c-440b-a46e-97ced89df59a","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.877797763+00:00","destroyed_at":"2026-05-14T20:47:15.8...` |
| 15 | 20:47:15.882 | Response | http response | `200 ` |
| 16 | 20:47:15.882 | Send | http.send | `POST /api/v1/jobs/c9a7f918-864c-440b-a46e-97ced89df59a/resume` |
| 17 | 20:47:15.882 | Response | http response | `409 invalid transition: completed -> resuming` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "project_id": "test-1778791635874-geg761",
  "description": "Terminal test",
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
  "created_at": "2026-05-14T20:47:15.876763736+00:00",
  "updated_at": "2026-05-14T20:47:15.876763736+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "2a53e41d-96ef-4292-be09-e0c02a017779",
  "job_id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.877797763+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "2a53e41d-96ef-4292-be09-e0c02a017779",
  "job_id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.877797763+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "project_id": "test-1778791635874-geg761",
  "description": "Terminal test",
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
  "created_at": "2026-05-14T20:47:15.876763736+00:00",
  "updated_at": "2026-05-14T20:47:15.879489952+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "project_id": "test-1778791635874-geg761",
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
  "created_at": "2026-05-14T20:47:15.876763736+00:00",
  "updated_at": "2026-05-14T20:47:15.880713704+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.880713704+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "2a53e41d-96ef-4292-be09-e0c02a017779",
  "job_id": "c9a7f918-864c-440b-a46e-97ced89df59a",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.877797763+00:00",
  "destroyed_at": "2026-05-14T20:47:15.881387459+00:00"
}
```

</details>

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.884 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.884 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635883-0ytpwr","description":"Cancel queued"}` |
| 3 | 20:47:15.884 | Recv | sql:jobs | `{"id":"eaec230e-f5d9-4b68-b13b-c28e977dfb83","project_id":"test-1778791635883-0ytpwr","description":"Cancel queued","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 4 | 20:47:15.886 | Response | http response | `200 {"job_id":"eaec230e-f5d9-4b68-b13b-c28e977dfb83"}` |
| 5 | 20:47:15.886 | Send | http.send | `POST /api/v1/jobs/eaec230e-f5d9-4b68-b13b-c28e977dfb83/cancel` |
| 6 | 20:47:15.886 | Response | http response | `200 ` |
| 7 | 20:47:15.886 | Recv | sql:jobs | `{"id":"eaec230e-f5d9-4b68-b13b-c28e977dfb83","project_id":"test-1778791635883-0ytpwr","description":"Cancel queued","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "eaec230e-f5d9-4b68-b13b-c28e977dfb83",
  "project_id": "test-1778791635883-0ytpwr",
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
  "created_at": "2026-05-14T20:47:15.884910786+00:00",
  "updated_at": "2026-05-14T20:47:15.884910786+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>7. Recv sql:jobs</summary>

```json
{
  "id": "eaec230e-f5d9-4b68-b13b-c28e977dfb83",
  "project_id": "test-1778791635883-0ytpwr",
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
  "created_at": "2026-05-14T20:47:15.884910786+00:00",
  "updated_at": "2026-05-14T20:47:15.886168981+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.888 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.889 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635887-zu2p4y","description":"Cancel running"}` |
| 3 | 20:47:15.889 | Recv | sql:jobs | `{"id":"621511fa-13c6-4c85-85bc-c03e866308ca","project_id":"test-1778791635887-zu2p4y","description":"Cancel running","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 4 | 20:47:15.890 | Response | http response | `200 {"job_id":"621511fa-13c6-4c85-85bc-c03e866308ca"}` |
| 5 | 20:47:15.890 | Send | http.send | `POST /api/v1/workers {"job_id":"621511fa-13c6-4c85-85bc-c03e866308ca","provider":"test"}` |
| 6 | 20:47:15.891 | Response | http response | `200 {"worker_id":"9c21b4c3-263e-4fcc-9a3f-41218398b42e"}` |
| 7 | 20:47:15.891 | Send | http.send | `POST /api/v1/workers/9c21b4c3-263e-4fcc-9a3f-41218398b42e/register {"job_id":"621511fa-13c6-4c85-85bc-c03e866308ca"}` |
| 8 | 20:47:15.891 | Recv | sql:workers | `{"id":"9c21b4c3-263e-4fcc-9a3f-41218398b42e","job_id":"621511fa-13c6-4c85-85bc-c03e866308ca","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.890975471+00:00","destroyed_at":null}` |
| 9 | 20:47:15.891 | Recv | sql:workers | `{"id":"9c21b4c3-263e-4fcc-9a3f-41218398b42e","job_id":"621511fa-13c6-4c85-85bc-c03e866308ca","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.890975471+00:00","destroyed_at":null}` |
| 10 | 20:47:15.892 | Recv | sql:jobs | `{"id":"621511fa-13c6-4c85-85bc-c03e866308ca","project_id":"test-1778791635887-zu2p4y","description":"Cancel running","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 11 | 20:47:15.893 | Response | http response | `200 ` |
| 12 | 20:47:15.893 | Send | http.send | `POST /api/v1/jobs/621511fa-13c6-4c85-85bc-c03e866308ca/cancel` |
| 13 | 20:47:15.893 | Recv | sql:jobs | `{"id":"621511fa-13c6-4c85-85bc-c03e866308ca","project_id":"test-1778791635887-zu2p4y","description":"Cancel running","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |
| 14 | 20:47:15.894 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "621511fa-13c6-4c85-85bc-c03e866308ca",
  "project_id": "test-1778791635887-zu2p4y",
  "description": "Cancel running",
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
  "created_at": "2026-05-14T20:47:15.889628822+00:00",
  "updated_at": "2026-05-14T20:47:15.889628822+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>8. Recv sql:workers</summary>

```json
{
  "id": "9c21b4c3-263e-4fcc-9a3f-41218398b42e",
  "job_id": "621511fa-13c6-4c85-85bc-c03e866308ca",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.890975471+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "9c21b4c3-263e-4fcc-9a3f-41218398b42e",
  "job_id": "621511fa-13c6-4c85-85bc-c03e866308ca",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.890975471+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "621511fa-13c6-4c85-85bc-c03e866308ca",
  "project_id": "test-1778791635887-zu2p4y",
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
  "created_at": "2026-05-14T20:47:15.889628822+00:00",
  "updated_at": "2026-05-14T20:47:15.892662582+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "621511fa-13c6-4c85-85bc-c03e866308ca",
  "project_id": "test-1778791635887-zu2p4y",
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
  "created_at": "2026-05-14T20:47:15.889628822+00:00",
  "updated_at": "2026-05-14T20:47:15.893865905+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## worker register sets job to running in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.897 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.898 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635896-xwoqy3","description":"E2E test job"}` |
| 3 | 20:47:15.898 | Recv | sql:jobs | `{"id":"38bf948b-5649-493d-9812-5bc5c6995cc2","project_id":"test-1778791635896-xwoqy3","description":"E2E test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.899 | Response | http response | `200 {"job_id":"38bf948b-5649-493d-9812-5bc5c6995cc2"}` |
| 5 | 20:47:15.899 | Send | http.send | `POST /api/v1/workers {"job_id":"38bf948b-5649-493d-9812-5bc5c6995cc2","provider":"test"}` |
| 6 | 20:47:15.899 | Recv | sql:workers | `{"id":"9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7","job_id":"38bf948b-5649-493d-9812-5bc5c6995cc2","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.899945471+00:00","destroyed_at":null}` |
| 7 | 20:47:15.900 | Response | http response | `200 {"worker_id":"9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7"}` |
| 8 | 20:47:15.900 | Send | http.send | `POST /api/v1/workers/9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7/register {"job_id":"38bf948b-5649-493d-9812-5bc5c6995cc2"}` |
| 9 | 20:47:15.900 | Recv | sql:workers | `{"id":"9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7","job_id":"38bf948b-5649-493d-9812-5bc5c6995cc2","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.899945471+00:00","destroyed_at":null}` |
| 10 | 20:47:15.901 | Recv | sql:jobs | `{"id":"38bf948b-5649-493d-9812-5bc5c6995cc2","project_id":"test-1778791635896-xwoqy3","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.902 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "38bf948b-5649-493d-9812-5bc5c6995cc2",
  "project_id": "test-1778791635896-xwoqy3",
  "description": "E2E test job",
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
  "created_at": "2026-05-14T20:47:15.898662188+00:00",
  "updated_at": "2026-05-14T20:47:15.898662188+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7",
  "job_id": "38bf948b-5649-493d-9812-5bc5c6995cc2",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.899945471+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "9b1f93f8-5ef7-45e6-b00d-fea3ee19caf7",
  "job_id": "38bf948b-5649-493d-9812-5bc5c6995cc2",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.899945471+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "38bf948b-5649-493d-9812-5bc5c6995cc2",
  "project_id": "test-1778791635896-xwoqy3",
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
  "created_at": "2026-05-14T20:47:15.898662188+00:00",
  "updated_at": "2026-05-14T20:47:15.901561565+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## worker heartbeat updates timestamp in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.904 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.905 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635903-y0lqa8","description":"E2E test job"}` |
| 3 | 20:47:15.905 | Recv | sql:jobs | `{"id":"7d0fb8d3-7819-45bc-a714-488e0876940a","project_id":"test-1778791635903-y0lqa8","description":"E2E test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.906 | Response | http response | `200 {"job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a"}` |
| 5 | 20:47:15.906 | Send | http.send | `POST /api/v1/workers {"job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a","provider":"test"}` |
| 6 | 20:47:15.906 | Recv | sql:workers | `{"id":"36f99bb9-7935-4c99-8bdb-b39c36921479","job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.906526964+00:00","destroyed_at":null}` |
| 7 | 20:47:15.907 | Response | http response | `200 {"worker_id":"36f99bb9-7935-4c99-8bdb-b39c36921479"}` |
| 8 | 20:47:15.907 | Send | http.send | `POST /api/v1/workers/36f99bb9-7935-4c99-8bdb-b39c36921479/register {"job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a"}` |
| 9 | 20:47:15.907 | Recv | sql:workers | `{"id":"36f99bb9-7935-4c99-8bdb-b39c36921479","job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.906526964+00:00","destroyed_at":null}` |
| 10 | 20:47:15.908 | Recv | sql:jobs | `{"id":"7d0fb8d3-7819-45bc-a714-488e0876940a","project_id":"test-1778791635903-y0lqa8","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.909 | Response | http response | `200 ` |
| 12 | 20:47:15.909 | Send | http.send | `POST /api/v1/workers/36f99bb9-7935-4c99-8bdb-b39c36921479/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":500,"completion_tokens":200},"files_changed":0,"tool_ca...` |
| 13 | 20:47:15.909 | Recv | sql:workers | `{"id":"36f99bb9-7935-4c99-8bdb-b39c36921479","job_id":"7d0fb8d3-7819-45bc-a714-488e0876940a","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T20:47:15.909600674+00:00","created_at":"2026-05-14T20:47:15.906526964+00:00","des...` |
| 14 | 20:47:15.910 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "7d0fb8d3-7819-45bc-a714-488e0876940a",
  "project_id": "test-1778791635903-y0lqa8",
  "description": "E2E test job",
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
  "created_at": "2026-05-14T20:47:15.905346927+00:00",
  "updated_at": "2026-05-14T20:47:15.905346927+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "36f99bb9-7935-4c99-8bdb-b39c36921479",
  "job_id": "7d0fb8d3-7819-45bc-a714-488e0876940a",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.906526964+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "36f99bb9-7935-4c99-8bdb-b39c36921479",
  "job_id": "7d0fb8d3-7819-45bc-a714-488e0876940a",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.906526964+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "7d0fb8d3-7819-45bc-a714-488e0876940a",
  "project_id": "test-1778791635903-y0lqa8",
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
  "created_at": "2026-05-14T20:47:15.905346927+00:00",
  "updated_at": "2026-05-14T20:47:15.908599246+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:workers</summary>

```json
{
  "id": "36f99bb9-7935-4c99-8bdb-b39c36921479",
  "job_id": "7d0fb8d3-7819-45bc-a714-488e0876940a",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": "2026-05-14T20:47:15.909600674+00:00",
  "created_at": "2026-05-14T20:47:15.906526964+00:00",
  "destroyed_at": null
}
```

</details>

---

## worker checkpoint writes to jobs and checkpoints tables

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.912 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.913 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635911-73glum","description":"E2E test job"}` |
| 3 | 20:47:15.913 | Recv | sql:jobs | `{"id":"739ae416-fa93-4b41-bf1e-0874e35c244f","project_id":"test-1778791635911-73glum","description":"E2E test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.914 | Response | http response | `200 {"job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f"}` |
| 5 | 20:47:15.914 | Send | http.send | `POST /api/v1/workers {"job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f","provider":"test"}` |
| 6 | 20:47:15.914 | Recv | sql:workers | `{"id":"7d48025c-2a7a-40e4-af6a-b5017217f02b","job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.914586223+00:00","destroyed_at":null}` |
| 7 | 20:47:15.915 | Response | http response | `200 {"worker_id":"7d48025c-2a7a-40e4-af6a-b5017217f02b"}` |
| 8 | 20:47:15.915 | Send | http.send | `POST /api/v1/workers/7d48025c-2a7a-40e4-af6a-b5017217f02b/register {"job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f"}` |
| 9 | 20:47:15.915 | Recv | sql:workers | `{"id":"7d48025c-2a7a-40e4-af6a-b5017217f02b","job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.914586223+00:00","destroyed_at":null}` |
| 10 | 20:47:15.916 | Recv | sql:jobs | `{"id":"739ae416-fa93-4b41-bf1e-0874e35c244f","project_id":"test-1778791635911-73glum","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.917 | Response | http response | `200 ` |
| 12 | 20:47:15.917 | Send | http.send | `POST /api/v1/workers/7d48025c-2a7a-40e4-af6a-b5017217f02b/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"def456","token_usage":{"prompt_...` |
| 13 | 20:47:15.917 | Recv | sql:checkpoints | `{"id":"1dc986c7-72b1-4d35-bef2-03d00094774a","job_id":"739ae416-fa93-4b41-bf1e-0874e35c244f","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"def456","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[\"src/lib.r...` |
| 14 | 20:47:15.918 | Response | http response | `200 ` |
| 15 | 20:47:15.918 | Recv | sql:jobs | `{"id":"739ae416-fa93-4b41-bf1e-0874e35c244f","project_id":"test-1778791635911-73glum","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"max_...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "project_id": "test-1778791635911-73glum",
  "description": "E2E test job",
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
  "created_at": "2026-05-14T20:47:15.913311833+00:00",
  "updated_at": "2026-05-14T20:47:15.913311833+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "7d48025c-2a7a-40e4-af6a-b5017217f02b",
  "job_id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.914586223+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "7d48025c-2a7a-40e4-af6a-b5017217f02b",
  "job_id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.914586223+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "project_id": "test-1778791635911-73glum",
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
  "created_at": "2026-05-14T20:47:15.913311833+00:00",
  "updated_at": "2026-05-14T20:47:15.916093223+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "1dc986c7-72b1-4d35-bef2-03d00094774a",
  "job_id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/tmp/session.json",
  "git_sha": "def456",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[\"src/lib.rs\"]",
  "created_at": "2026-05-14T20:47:15.917249645+00:00"
}
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "id": "739ae416-fa93-4b41-bf1e-0874e35c244f",
  "project_id": "test-1778791635911-73glum",
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
  "created_at": "2026-05-14T20:47:15.913311833+00:00",
  "updated_at": "2026-05-14T20:47:15.917978492+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## worker complete sets result and destroys worker

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.921 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.922 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635920-zvscip","description":"E2E test job"}` |
| 3 | 20:47:15.922 | Recv | sql:jobs | `{"id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","project_id":"test-1778791635920-zvscip","description":"E2E test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.923 | Response | http response | `200 {"job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927"}` |
| 5 | 20:47:15.923 | Send | http.send | `POST /api/v1/workers {"job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","provider":"test"}` |
| 6 | 20:47:15.923 | Recv | sql:workers | `{"id":"5778cca4-e17a-431f-92ce-f23c97d2ba0b","job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.923651747+00:00","destroyed_at":null}` |
| 7 | 20:47:15.924 | Response | http response | `200 {"worker_id":"5778cca4-e17a-431f-92ce-f23c97d2ba0b"}` |
| 8 | 20:47:15.924 | Send | http.send | `POST /api/v1/workers/5778cca4-e17a-431f-92ce-f23c97d2ba0b/register {"job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927"}` |
| 9 | 20:47:15.924 | Recv | sql:workers | `{"id":"5778cca4-e17a-431f-92ce-f23c97d2ba0b","job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.923651747+00:00","destroyed_at":null}` |
| 10 | 20:47:15.925 | Recv | sql:jobs | `{"id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","project_id":"test-1778791635920-zvscip","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.926 | Response | http response | `200 ` |
| 12 | 20:47:15.926 | Send | http.send | `POST /api/v1/workers/5778cca4-e17a-431f-92ce-f23c97d2ba0b/complete {"result":"success"}` |
| 13 | 20:47:15.926 | Recv | sql:jobs | `{"id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","project_id":"test-1778791635920-zvscip","description":"E2E test job","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","error":null,"creat...` |
| 14 | 20:47:15.927 | Recv | sql:workers | `{"id":"5778cca4-e17a-431f-92ce-f23c97d2ba0b","job_id":"c3bf8f3b-5e08-4792-a370-fdfdacb24927","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.923651747+00:00","destroyed_at":"2026-05-14T20:47:15.9...` |
| 15 | 20:47:15.928 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "project_id": "test-1778791635920-zvscip",
  "description": "E2E test job",
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
  "created_at": "2026-05-14T20:47:15.922355234+00:00",
  "updated_at": "2026-05-14T20:47:15.922355234+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "5778cca4-e17a-431f-92ce-f23c97d2ba0b",
  "job_id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.923651747+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "5778cca4-e17a-431f-92ce-f23c97d2ba0b",
  "job_id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.923651747+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "project_id": "test-1778791635920-zvscip",
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
  "created_at": "2026-05-14T20:47:15.922355234+00:00",
  "updated_at": "2026-05-14T20:47:15.925391057+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "project_id": "test-1778791635920-zvscip",
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
  "created_at": "2026-05-14T20:47:15.922355234+00:00",
  "updated_at": "2026-05-14T20:47:15.926653178+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.926653178+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "5778cca4-e17a-431f-92ce-f23c97d2ba0b",
  "job_id": "c3bf8f3b-5e08-4792-a370-fdfdacb24927",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.923651747+00:00",
  "destroyed_at": "2026-05-14T20:47:15.927382426+00:00"
}
```

</details>

---

## worker fail sets error in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.930 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.931 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635929-luevdg","description":"E2E test job"}` |
| 3 | 20:47:15.931 | Recv | sql:jobs | `{"id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","project_id":"test-1778791635929-luevdg","description":"E2E test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.932 | Response | http response | `200 {"job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14"}` |
| 5 | 20:47:15.932 | Send | http.send | `POST /api/v1/workers {"job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","provider":"test"}` |
| 6 | 20:47:15.932 | Recv | sql:workers | `{"id":"dfd76c1b-1e66-4bf6-882c-3c2aa10f024e","job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.932386674+00:00","destroyed_at":null}` |
| 7 | 20:47:15.933 | Response | http response | `200 {"worker_id":"dfd76c1b-1e66-4bf6-882c-3c2aa10f024e"}` |
| 8 | 20:47:15.933 | Send | http.send | `POST /api/v1/workers/dfd76c1b-1e66-4bf6-882c-3c2aa10f024e/register {"job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14"}` |
| 9 | 20:47:15.933 | Recv | sql:workers | `{"id":"dfd76c1b-1e66-4bf6-882c-3c2aa10f024e","job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.932386674+00:00","destroyed_at":null}` |
| 10 | 20:47:15.933 | Recv | sql:jobs | `{"id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","project_id":"test-1778791635929-luevdg","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.934 | Response | http response | `200 ` |
| 12 | 20:47:15.934 | Send | http.send | `POST /api/v1/workers/dfd76c1b-1e66-4bf6-882c-3c2aa10f024e/fail {"error":"build failed"}` |
| 13 | 20:47:15.935 | Recv | sql:jobs | `{"id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","project_id":"test-1778791635929-luevdg","description":"E2E test job","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":"build fa...` |
| 14 | 20:47:15.935 | Recv | sql:workers | `{"id":"dfd76c1b-1e66-4bf6-882c-3c2aa10f024e","job_id":"9b3849fa-0233-4b82-b156-1d9e4855fc14","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.932386674+00:00","destroyed_at":"2026-05-14T20:47:15.9...` |
| 15 | 20:47:15.936 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "project_id": "test-1778791635929-luevdg",
  "description": "E2E test job",
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
  "created_at": "2026-05-14T20:47:15.931237733+00:00",
  "updated_at": "2026-05-14T20:47:15.931237733+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "dfd76c1b-1e66-4bf6-882c-3c2aa10f024e",
  "job_id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.932386674+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "dfd76c1b-1e66-4bf6-882c-3c2aa10f024e",
  "job_id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.932386674+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "project_id": "test-1778791635929-luevdg",
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
  "created_at": "2026-05-14T20:47:15.931237733+00:00",
  "updated_at": "2026-05-14T20:47:15.933957380+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "project_id": "test-1778791635929-luevdg",
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
  "created_at": "2026-05-14T20:47:15.931237733+00:00",
  "updated_at": "2026-05-14T20:47:15.935114102+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.935114102+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "dfd76c1b-1e66-4bf6-882c-3c2aa10f024e",
  "job_id": "9b3849fa-0233-4b82-b156-1d9e4855fc14",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.932386674+00:00",
  "destroyed_at": "2026-05-14T20:47:15.935847867+00:00"
}
```

</details>

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.939 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.940 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635938-zp5bnf","description":"E2E test job"}` |
| 3 | 20:47:15.941 | Response | http response | `200 {"job_id":"0a56c57d-6b5d-483e-a064-91a006ec6c33"}` |
| 4 | 20:47:15.941 | Send | http.send | `POST /api/v1/workers {"job_id":"0a56c57d-6b5d-483e-a064-91a006ec6c33","provider":"test"}` |
| 5 | 20:47:15.942 | Response | http response | `200 {"worker_id":"f19a8c82-4f22-47b0-9eed-551f68cd7ce7"}` |
| 6 | 20:47:15.942 | Send | http.send | `POST /api/v1/workers/f19a8c82-4f22-47b0-9eed-551f68cd7ce7/register {"job_id":"0a56c57d-6b5d-483e-a064-91a006ec6c33"}` |
| 7 | 20:47:15.944 | Response | http response | `200 ` |
| 8 | 20:47:15.944 | Send | http.send | `GET /api/v1/jobs/0a56c57d-6b5d-483e-a064-91a006ec6c33/config` |
| 9 | 20:47:15.944 | Response | http response | `200 {"job_id":"0a56c57d-6b5d-483e-a064-91a006ec6c33","stage":"","prompt":"E2E test job","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","api...` |

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.946 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.947 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635944-4singy","description":"E2E test job"}` |
| 3 | 20:47:15.947 | Response | http response | `200 {"job_id":"b48759cd-cb3d-49cc-a517-8378f15015d7"}` |
| 4 | 20:47:15.948 | Send | http.send | `POST /api/v1/workers {"job_id":"b48759cd-cb3d-49cc-a517-8378f15015d7","provider":"test"}` |
| 5 | 20:47:15.948 | Response | http response | `200 {"worker_id":"33af3de9-e236-4318-8545-009966272b23"}` |
| 6 | 20:47:15.948 | Send | http.send | `POST /api/v1/workers/33af3de9-e236-4318-8545-009966272b23/register {"job_id":"b48759cd-cb3d-49cc-a517-8378f15015d7"}` |
| 7 | 20:47:15.950 | Response | http response | `200 ` |
| 8 | 20:47:15.950 | Send | http.send | `GET /api/v1/jobs/b48759cd-cb3d-49cc-a517-8378f15015d7/skill/plan` |
| 9 | 20:47:15.951 | Response | http response | `200 {"content":"You are a senior software engineer tasked with creating an implementation plan.\n\n## Instructions\n\n- Explore the project structure first using glob and grep\n- Identify all files and modules relevant to the task\n- Produce a clear, step-by-step implementation plan\n- Estimate t...` |

---

## unknown worker returns 404

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.951 | Send | http.send | `POST /api/v1/workers/nonexistent-id/register {"job_id":"fake-job"}` |
| 2 | 20:47:15.951 | Response | http response | `404 worker not found` |

---

## creates project via SQL seed and reads via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.953 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.954 | Send | http.send | `GET /api/v1/projects` |
| 3 | 20:47:15.954 | Response | http response | `200 [{"id":"test-1778791635757-h3pmi5","repo_url":"https://github.com/test/test-1778791635757-h3pmi5","branch":"main","created_at":"2026-05-14T20:47:15.757Z","updated_at":"2026-05-14T20:47:15.757Z"},{"id":"test-1778791635764-sqgaml","repo_url":"https://github.com/test/test-1778791635764-sqgaml","...` |

---

## creates job via HTTP, verifies via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.956 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.957 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635955-o6775y","description":"DB test job"}` |
| 3 | 20:47:15.957 | Recv | sql:jobs | `{"id":"9908cddc-8e22-4dfb-b84a-169d23430290","project_id":"test-1778791635955-o6775y","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |
| 4 | 20:47:15.958 | Response | http response | `200 {"job_id":"9908cddc-8e22-4dfb-b84a-169d23430290"}` |
| 5 | 20:47:15.958 | Send | http.send | `GET /api/v1/jobs/9908cddc-8e22-4dfb-b84a-169d23430290` |
| 6 | 20:47:15.958 | Response | http response | `200 {"id":"9908cddc-8e22-4dfb-b84a-169d23430290","project_id":"test-1778791635955-o6775y","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "9908cddc-8e22-4dfb-b84a-169d23430290",
  "project_id": "test-1778791635955-o6775y",
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
  "created_at": "2026-05-14T20:47:15.957511897+00:00",
  "updated_at": "2026-05-14T20:47:15.957511897+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## stores checkpoint and verifies via SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.960 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.961 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635960-b1nfyn","description":"Checkpoint test"}` |
| 3 | 20:47:15.962 | Recv | sql:jobs | `{"id":"78862015-5129-4619-91cd-eb5f0b7728f3","project_id":"test-1778791635960-b1nfyn","description":"Checkpoint test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 4 | 20:47:15.963 | Response | http response | `200 {"job_id":"78862015-5129-4619-91cd-eb5f0b7728f3"}` |
| 5 | 20:47:15.963 | Send | http.send | `POST /api/v1/workers {"job_id":"78862015-5129-4619-91cd-eb5f0b7728f3","provider":"test"}` |
| 6 | 20:47:15.963 | Recv | sql:workers | `{"id":"e3853172-8471-41ce-8fff-364a3aec55af","job_id":"78862015-5129-4619-91cd-eb5f0b7728f3","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.963421418+00:00","destroyed_at":null}` |
| 7 | 20:47:15.964 | Response | http response | `200 {"worker_id":"e3853172-8471-41ce-8fff-364a3aec55af"}` |
| 8 | 20:47:15.964 | Send | http.send | `POST /api/v1/workers/e3853172-8471-41ce-8fff-364a3aec55af/register {"job_id":"78862015-5129-4619-91cd-eb5f0b7728f3"}` |
| 9 | 20:47:15.964 | Recv | sql:workers | `{"id":"e3853172-8471-41ce-8fff-364a3aec55af","job_id":"78862015-5129-4619-91cd-eb5f0b7728f3","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.963421418+00:00","destroyed_at":null}` |
| 10 | 20:47:15.965 | Recv | sql:jobs | `{"id":"78862015-5129-4619-91cd-eb5f0b7728f3","project_id":"test-1778791635960-b1nfyn","description":"Checkpoint test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |
| 11 | 20:47:15.966 | Response | http response | `200 ` |
| 12 | 20:47:15.966 | Send | http.send | `POST /api/v1/workers/e3853172-8471-41ce-8fff-364a3aec55af/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 13 | 20:47:15.966 | Recv | sql:checkpoints | `{"id":"ecd98407-7c24-483c-904d-78b82b61476c","job_id":"78862015-5129-4619-91cd-eb5f0b7728f3","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[\"src/main....` |
| 14 | 20:47:15.967 | Recv | sql:jobs | `{"id":"78862015-5129-4619-91cd-eb5f0b7728f3","project_id":"test-1778791635960-b1nfyn","description":"Checkpoint test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"max_at...` |
| 15 | 20:47:15.968 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "project_id": "test-1778791635960-b1nfyn",
  "description": "Checkpoint test",
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
  "created_at": "2026-05-14T20:47:15.961934619+00:00",
  "updated_at": "2026-05-14T20:47:15.961934619+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "e3853172-8471-41ce-8fff-364a3aec55af",
  "job_id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.963421418+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "e3853172-8471-41ce-8fff-364a3aec55af",
  "job_id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.963421418+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "project_id": "test-1778791635960-b1nfyn",
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
  "created_at": "2026-05-14T20:47:15.961934619+00:00",
  "updated_at": "2026-05-14T20:47:15.965340879+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "ecd98407-7c24-483c-904d-78b82b61476c",
  "job_id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/tmp/session.json",
  "git_sha": "abc123",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[\"src/main.rs\"]",
  "created_at": "2026-05-14T20:47:15.966752085+00:00"
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
{
  "id": "78862015-5129-4619-91cd-eb5f0b7728f3",
  "project_id": "test-1778791635960-b1nfyn",
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
  "created_at": "2026-05-14T20:47:15.961934619+00:00",
  "updated_at": "2026-05-14T20:47:15.967651519+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## tracks worker heartbeat in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.971 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.972 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635970-anrw7e","description":"Heartbeat test"}` |
| 3 | 20:47:15.972 | Recv | sql:jobs | `{"id":"57e0c608-1280-49c8-879f-d37db6de5156","project_id":"test-1778791635970-anrw7e","description":"Heartbeat test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 4 | 20:47:15.974 | Response | http response | `200 {"job_id":"57e0c608-1280-49c8-879f-d37db6de5156"}` |
| 5 | 20:47:15.974 | Send | http.send | `POST /api/v1/workers {"job_id":"57e0c608-1280-49c8-879f-d37db6de5156","provider":"test"}` |
| 6 | 20:47:15.974 | Recv | sql:workers | `{"id":"194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9","job_id":"57e0c608-1280-49c8-879f-d37db6de5156","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.974613776+00:00","destroyed_at":null}` |
| 7 | 20:47:15.975 | Response | http response | `200 {"worker_id":"194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9"}` |
| 8 | 20:47:15.975 | Send | http.send | `POST /api/v1/workers/194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9/register {"job_id":"57e0c608-1280-49c8-879f-d37db6de5156"}` |
| 9 | 20:47:15.975 | Recv | sql:workers | `{"id":"194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9","job_id":"57e0c608-1280-49c8-879f-d37db6de5156","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.974613776+00:00","destroyed_at":null}` |
| 10 | 20:47:15.976 | Recv | sql:jobs | `{"id":"57e0c608-1280-49c8-879f-d37db6de5156","project_id":"test-1778791635970-anrw7e","description":"Heartbeat test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 11 | 20:47:15.977 | Response | http response | `200 ` |
| 12 | 20:47:15.978 | Send | http.send | `POST /api/v1/workers/194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 13 | 20:47:15.978 | Response | http response | `200 ` |
| 14 | 20:47:15.978 | Recv | sql:workers | `{"id":"194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9","job_id":"57e0c608-1280-49c8-879f-d37db6de5156","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T20:47:15.978103452+00:00","created_at":"2026-05-14T20:47:15.974613776+00:00","des...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "57e0c608-1280-49c8-879f-d37db6de5156",
  "project_id": "test-1778791635970-anrw7e",
  "description": "Heartbeat test",
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
  "created_at": "2026-05-14T20:47:15.972445050+00:00",
  "updated_at": "2026-05-14T20:47:15.972445050+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9",
  "job_id": "57e0c608-1280-49c8-879f-d37db6de5156",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.974613776+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9",
  "job_id": "57e0c608-1280-49c8-879f-d37db6de5156",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.974613776+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "57e0c608-1280-49c8-879f-d37db6de5156",
  "project_id": "test-1778791635970-anrw7e",
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
  "created_at": "2026-05-14T20:47:15.972445050+00:00",
  "updated_at": "2026-05-14T20:47:15.976707579+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "194e1815-1ad1-4e0e-b9f1-9ad85c9a1ba9",
  "job_id": "57e0c608-1280-49c8-879f-d37db6de5156",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": "2026-05-14T20:47:15.978103452+00:00",
  "created_at": "2026-05-14T20:47:15.974613776+00:00",
  "destroyed_at": null
}
```

</details>

---

## destroyed workers removed from DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.981 | Send | sql.put | `1 rows` |
| 2 | 20:47:15.982 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791635980-dfj7o9","description":"Destroy test"}` |
| 3 | 20:47:15.982 | Recv | sql:jobs | `{"id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","project_id":"test-1778791635980-dfj7o9","description":"Destroy test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |
| 4 | 20:47:15.984 | Response | http response | `200 {"job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6"}` |
| 5 | 20:47:15.984 | Send | http.send | `POST /api/v1/workers {"job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","provider":"test"}` |
| 6 | 20:47:15.984 | Recv | sql:workers | `{"id":"59ea0b33-9211-42f8-a5f0-8c15bd47cba4","job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.984581940+00:00","destroyed_at":null}` |
| 7 | 20:47:15.986 | Response | http response | `200 {"worker_id":"59ea0b33-9211-42f8-a5f0-8c15bd47cba4"}` |
| 8 | 20:47:15.986 | Send | http.send | `POST /api/v1/workers/59ea0b33-9211-42f8-a5f0-8c15bd47cba4/register {"job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6"}` |
| 9 | 20:47:15.986 | Recv | sql:workers | `{"id":"59ea0b33-9211-42f8-a5f0-8c15bd47cba4","job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.984581940+00:00","destroyed_at":null}` |
| 10 | 20:47:15.987 | Recv | sql:jobs | `{"id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","project_id":"test-1778791635980-dfj7o9","description":"Destroy test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":...` |
| 11 | 20:47:15.988 | Response | http response | `200 ` |
| 12 | 20:47:15.988 | Send | http.send | `POST /api/v1/workers/59ea0b33-9211-42f8-a5f0-8c15bd47cba4/complete {"result":"done"}` |
| 13 | 20:47:15.988 | Recv | sql:jobs | `{"id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","project_id":"test-1778791635980-dfj7o9","description":"Destroy test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"created_...` |
| 14 | 20:47:15.990 | Recv | sql:workers | `{"id":"59ea0b33-9211-42f8-a5f0-8c15bd47cba4","job_id":"6696359c-1142-4b7d-8ef2-27ef67cae6b6","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.984581940+00:00","destroyed_at":"2026-05-14T20:47:15.9...` |
| 15 | 20:47:15.991 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "project_id": "test-1778791635980-dfj7o9",
  "description": "Destroy test",
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
  "created_at": "2026-05-14T20:47:15.982692323+00:00",
  "updated_at": "2026-05-14T20:47:15.982692323+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "59ea0b33-9211-42f8-a5f0-8c15bd47cba4",
  "job_id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.984581940+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "59ea0b33-9211-42f8-a5f0-8c15bd47cba4",
  "job_id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.984581940+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "project_id": "test-1778791635980-dfj7o9",
  "description": "Destroy test",
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
  "created_at": "2026-05-14T20:47:15.982692323+00:00",
  "updated_at": "2026-05-14T20:47:15.987472884+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "project_id": "test-1778791635980-dfj7o9",
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
  "created_at": "2026-05-14T20:47:15.982692323+00:00",
  "updated_at": "2026-05-14T20:47:15.988887435+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:15.988887435+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "59ea0b33-9211-42f8-a5f0-8c15bd47cba4",
  "job_id": "6696359c-1142-4b7d-8ef2-27ef67cae6b6",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:15.984581940+00:00",
  "destroyed_at": "2026-05-14T20:47:15.990331741+00:00"
}
```

</details>

---

## creates a job with hello-world workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:15.997 | Recv | sql:jobs | `{"id":"25d51952-3bfa-4174-ae57-8aa6f5d174db","project_id":"test-1778791635995-wy4vvj","description":"Hello world test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |

<details><summary>1. Recv sql:jobs</summary>

```json
{
  "id": "25d51952-3bfa-4174-ae57-8aa6f5d174db",
  "project_id": "test-1778791635995-wy4vvj",
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
  "created_at": "2026-05-14T20:47:15.997742442+00:00",
  "updated_at": "2026-05-14T20:47:15.997742442+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.001 | Send | http.send | `GET /api/v1/jobs/25d51952-3bfa-4174-ae57-8aa6f5d174db/config` |
| 2 | 20:47:16.002 | Response | http response | `200 {"job_id":"25d51952-3bfa-4174-ae57-8aa6f5d174db","stage":"","prompt":"Hello world test","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

## create project → create job → register worker → complete

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.006 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.007 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636004-0oustv","description":"Full lifecycle test"}` |
| 3 | 20:47:16.008 | Recv | sql:jobs | `{"id":"11779e92-0fbe-4196-8a09-32c5650df911","project_id":"test-1778791636004-0oustv","description":"Full lifecycle test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 4 | 20:47:16.009 | Response | http response | `200 {"job_id":"11779e92-0fbe-4196-8a09-32c5650df911"}` |
| 5 | 20:47:16.011 | Send | http.send | `POST /api/v1/workers {"job_id":"11779e92-0fbe-4196-8a09-32c5650df911","provider":"test"}` |
| 6 | 20:47:16.012 | Recv | sql:workers | `{"id":"8528164a-e0cd-46fa-9cf5-c368f01e3f89","job_id":"11779e92-0fbe-4196-8a09-32c5650df911","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.012117905+00:00","destroyed_at":null}` |
| 7 | 20:47:16.014 | Response | http response | `200 {"worker_id":"8528164a-e0cd-46fa-9cf5-c368f01e3f89"}` |
| 8 | 20:47:16.014 | Send | http.send | `POST /api/v1/workers/8528164a-e0cd-46fa-9cf5-c368f01e3f89/register {"job_id":"11779e92-0fbe-4196-8a09-32c5650df911"}` |
| 9 | 20:47:16.014 | Recv | sql:workers | `{"id":"8528164a-e0cd-46fa-9cf5-c368f01e3f89","job_id":"11779e92-0fbe-4196-8a09-32c5650df911","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.012117905+00:00","destroyed_at":null}` |
| 10 | 20:47:16.015 | Recv | sql:jobs | `{"id":"11779e92-0fbe-4196-8a09-32c5650df911","project_id":"test-1778791636004-0oustv","description":"Full lifecycle test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 11 | 20:47:16.017 | Response | http response | `200 ` |
| 12 | 20:47:16.019 | Send | http.send | `POST /api/v1/workers/8528164a-e0cd-46fa-9cf5-c368f01e3f89/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 13 | 20:47:16.019 | Recv | sql:workers | `{"id":"8528164a-e0cd-46fa-9cf5-c368f01e3f89","job_id":"11779e92-0fbe-4196-8a09-32c5650df911","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T20:47:16.019627986+00:00","created_at":"2026-05-14T20:47:16.012117905+00:00","des...` |
| 14 | 20:47:16.021 | Response | http response | `200 ` |
| 15 | 20:47:16.023 | Send | http.send | `POST /api/v1/workers/8528164a-e0cd-46fa-9cf5-c368f01e3f89/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_us...` |
| 16 | 20:47:16.023 | Recv | sql:checkpoints | `{"id":"e95b8410-3612-4ef5-bb29-5459551f06a6","job_id":"11779e92-0fbe-4196-8a09-32c5650df911","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed"...` |
| 17 | 20:47:16.025 | Recv | sql:jobs | `{"id":"11779e92-0fbe-4196-8a09-32c5650df911","project_id":"test-1778791636004-0oustv","description":"Full lifecycle test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"ma...` |
| 18 | 20:47:16.026 | Response | http response | `200 ` |
| 19 | 20:47:16.028 | Send | http.send | `POST /api/v1/workers/8528164a-e0cd-46fa-9cf5-c368f01e3f89/complete {"result":"Job completed successfully"}` |
| 20 | 20:47:16.029 | Recv | sql:jobs | `{"id":"11779e92-0fbe-4196-8a09-32c5650df911","project_id":"test-1778791636004-0oustv","description":"Full lifecycle test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"...` |
| 21 | 20:47:16.030 | Recv | sql:workers | `{"id":"8528164a-e0cd-46fa-9cf5-c368f01e3f89","job_id":"11779e92-0fbe-4196-8a09-32c5650df911","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T20:47:16.019627986+00:00","created_at":"2026-05-14T20:47:16.012117905+00:00","des...` |
| 22 | 20:47:16.032 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "project_id": "test-1778791636004-0oustv",
  "description": "Full lifecycle test",
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
  "created_at": "2026-05-14T20:47:16.008167354+00:00",
  "updated_at": "2026-05-14T20:47:16.008167354+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "8528164a-e0cd-46fa-9cf5-c368f01e3f89",
  "job_id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.012117905+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "8528164a-e0cd-46fa-9cf5-c368f01e3f89",
  "job_id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.012117905+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "project_id": "test-1778791636004-0oustv",
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
  "created_at": "2026-05-14T20:47:16.008167354+00:00",
  "updated_at": "2026-05-14T20:47:16.015601200+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:workers</summary>

```json
{
  "id": "8528164a-e0cd-46fa-9cf5-c368f01e3f89",
  "job_id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": "2026-05-14T20:47:16.019627986+00:00",
  "created_at": "2026-05-14T20:47:16.012117905+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>16. Recv sql:checkpoints</summary>

```json
{
  "id": "e95b8410-3612-4ef5-bb29-5459551f06a6",
  "job_id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/workspace/.codery/session.json",
  "git_sha": "abc123",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[]",
  "created_at": "2026-05-14T20:47:16.023368720+00:00"
}
```

</details>

<details><summary>17. Recv sql:jobs</summary>

```json
{
  "id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "project_id": "test-1778791636004-0oustv",
  "description": "Full lifecycle test",
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
  "created_at": "2026-05-14T20:47:16.008167354+00:00",
  "updated_at": "2026-05-14T20:47:16.025436534+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>20. Recv sql:jobs</summary>

```json
{
  "id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "project_id": "test-1778791636004-0oustv",
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
  "created_at": "2026-05-14T20:47:16.008167354+00:00",
  "updated_at": "2026-05-14T20:47:16.029288917+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:16.029288917+00:00"
}
```

</details>

<details><summary>21. Recv sql:workers</summary>

```json
{
  "id": "8528164a-e0cd-46fa-9cf5-c368f01e3f89",
  "job_id": "11779e92-0fbe-4196-8a09-32c5650df911",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": "2026-05-14T20:47:16.019627986+00:00",
  "created_at": "2026-05-14T20:47:16.012117905+00:00",
  "destroyed_at": "2026-05-14T20:47:16.030696357+00:00"
}
```

</details>

---

## lists jobs and workers via HTTP matches DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.034 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 20:47:16.035 | Response | http response | `200 [{"id":"3c9705d4-21ac-4d45-95a3-2dcb46008979","project_id":"test-1778791635757-h3pmi5","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |
| 3 | 20:47:16.036 | Send | http.send | `GET /api/v1/workers` |
| 4 | 20:47:16.036 | Response | http response | `200 [{"id":"a5a458d9-4863-46d5-b438-bc79aec927ec","job_id":"625c3be2-1fbe-4e97-b531-0ecbdd308016","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:15.774897245+00:00","destroyed_at":null},{"id":"c981...` |

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.037 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 20:47:16.037 | Response | http response | `200 {"name":"test","stages":1,"valid":true}` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.038 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 20:47:16.038 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## routes based on string equality in response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.383 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.384 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636380-5d27oc","description":"Build feature","workflow":"feature"}` |
| 3 | 20:47:16.385 | Recv | sql:jobs | `{"id":"fb0cb83a-844f-4e6d-9e08-662fef884486","project_id":"test-1778791636380-5d27oc","description":"Build feature","status":"queued","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created...` |
| 4 | 20:47:16.387 | Response | http response | `200 {"job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486"}` |
| 5 | 20:47:16.387 | Send | http.send | `POST /api/v1/workers {"job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486","provider":"test"}` |
| 6 | 20:47:16.387 | Recv | sql:workers | `{"id":"055eadea-e360-4388-8fcb-9c2f85aacf3e","job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.387203543+00:00","destroyed_at":null}` |
| 7 | 20:47:16.388 | Response | http response | `200 {"worker_id":"055eadea-e360-4388-8fcb-9c2f85aacf3e"}` |
| 8 | 20:47:16.388 | Send | http.send | `POST /api/v1/workers/055eadea-e360-4388-8fcb-9c2f85aacf3e/register {"job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486"}` |
| 9 | 20:47:16.388 | Recv | sql:workers | `{"id":"055eadea-e360-4388-8fcb-9c2f85aacf3e","job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.387203543+00:00","destroyed_at":null}` |
| 10 | 20:47:16.390 | Recv | sql:jobs | `{"id":"fb0cb83a-844f-4e6d-9e08-662fef884486","project_id":"test-1778791636380-5d27oc","description":"Build feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 11 | 20:47:16.391 | Response | http response | `200 ` |
| 12 | 20:47:16.391 | Send | http.send | `POST /api/v1/workers/055eadea-e360-4388-8fcb-9c2f85aacf3e/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 13 | 20:47:16.392 | Recv | sql:checkpoints | `{"id":"b86377a5-255b-4aeb-8bdd-6c3d3625aa00","job_id":"fb0cb83a-844f-4e6d-9e08-662fef884486","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","created...` |
| 14 | 20:47:16.393 | Recv | sql:jobs | `{"id":"fb0cb83a-844f-4e6d-9e08-662fef884486","project_id":"test-1778791636380-5d27oc","description":"Build feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1...` |
| 15 | 20:47:16.394 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "project_id": "test-1778791636380-5d27oc",
  "description": "Build feature",
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
  "created_at": "2026-05-14T20:47:16.384972474+00:00",
  "updated_at": "2026-05-14T20:47:16.384972474+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "055eadea-e360-4388-8fcb-9c2f85aacf3e",
  "job_id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.387203543+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "055eadea-e360-4388-8fcb-9c2f85aacf3e",
  "job_id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.387203543+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "project_id": "test-1778791636380-5d27oc",
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
  "created_at": "2026-05-14T20:47:16.384972474+00:00",
  "updated_at": "2026-05-14T20:47:16.390607101+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "b86377a5-255b-4aeb-8bdd-6c3d3625aa00",
  "job_id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/tmp/session.json",
  "git_sha": "abc123",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[]",
  "created_at": "2026-05-14T20:47:16.392115242+00:00"
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
{
  "id": "fb0cb83a-844f-4e6d-9e08-662fef884486",
  "project_id": "test-1778791636380-5d27oc",
  "description": "Build feature",
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
  "created_at": "2026-05-14T20:47:16.384972474+00:00",
  "updated_at": "2026-05-14T20:47:16.393212064+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## routes to plan_detail on complex response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.397 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.398 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636395-dof6wc","description":"Complex feature","workflow":"feature"}` |
| 3 | 20:47:16.399 | Recv | sql:jobs | `{"id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","project_id":"test-1778791636395-dof6wc","description":"Complex feature","status":"queued","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 4 | 20:47:16.400 | Response | http response | `200 {"job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52"}` |
| 5 | 20:47:16.400 | Send | http.send | `POST /api/v1/workers {"job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","provider":"test"}` |
| 6 | 20:47:16.400 | Recv | sql:workers | `{"id":"fc8e94c6-9999-4f62-a195-21fb23a0f3f7","job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.400555715+00:00","destroyed_at":null}` |
| 7 | 20:47:16.401 | Response | http response | `200 {"worker_id":"fc8e94c6-9999-4f62-a195-21fb23a0f3f7"}` |
| 8 | 20:47:16.401 | Send | http.send | `POST /api/v1/workers/fc8e94c6-9999-4f62-a195-21fb23a0f3f7/register {"job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52"}` |
| 9 | 20:47:16.401 | Recv | sql:workers | `{"id":"fc8e94c6-9999-4f62-a195-21fb23a0f3f7","job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.400555715+00:00","destroyed_at":null}` |
| 10 | 20:47:16.403 | Response | http response | `200 ` |
| 11 | 20:47:16.403 | Send | http.send | `POST /api/v1/workers/fc8e94c6-9999-4f62-a195-21fb23a0f3f7/checkpoint {"stage":"plan","response":{"complexity":"complex"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt...` |
| 12 | 20:47:16.403 | Recv | sql:jobs | `{"id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","project_id":"test-1778791636395-dof6wc","description":"Complex feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 13 | 20:47:16.404 | Recv | sql:checkpoints | `{"id":"818292dd-b075-4b2a-bf9e-2f31556021f2","job_id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","stage":"plan","response":"{\"complexity\":\"complex\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","create...` |
| 14 | 20:47:16.405 | Response | http response | `200 ` |
| 15 | 20:47:16.405 | Recv | sql:jobs | `{"id":"36fd1512-d8b6-49b9-80b4-3a04bb0b2f52","project_id":"test-1778791636395-dof6wc","description":"Complex feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"plan_detail","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attemp...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "project_id": "test-1778791636395-dof6wc",
  "description": "Complex feature",
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
  "created_at": "2026-05-14T20:47:16.398954683+00:00",
  "updated_at": "2026-05-14T20:47:16.398954683+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "fc8e94c6-9999-4f62-a195-21fb23a0f3f7",
  "job_id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.400555715+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "fc8e94c6-9999-4f62-a195-21fb23a0f3f7",
  "job_id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.400555715+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>12. Recv sql:jobs</summary>

```json
{
  "id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "project_id": "test-1778791636395-dof6wc",
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
  "created_at": "2026-05-14T20:47:16.398954683+00:00",
  "updated_at": "2026-05-14T20:47:16.403100858+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "818292dd-b075-4b2a-bf9e-2f31556021f2",
  "job_id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "stage": "plan",
  "response": "{\"complexity\":\"complex\"}",
  "session_path": "/tmp/session.json",
  "git_sha": "abc123",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[]",
  "created_at": "2026-05-14T20:47:16.404123979+00:00"
}
```

</details>

<details><summary>15. Recv sql:jobs</summary>

```json
{
  "id": "36fd1512-d8b6-49b9-80b4-3a04bb0b2f52",
  "project_id": "test-1778791636395-dof6wc",
  "description": "Complex feature",
  "status": "running",
  "worker_id": null,
  "branch": null,
  "workflow_name": "feature",
  "current_stage": "plan_detail",
  "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"}]",
  "attempt": 1,
  "max_attempts": 3,
  "result": null,
  "error": null,
  "created_at": "2026-05-14T20:47:16.398954683+00:00",
  "updated_at": "2026-05-14T20:47:16.405044546+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## completes workflow when routes is null

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.408 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.409 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636407-lbuh2d","description":"Simple task","workflow":"simple"}` |
| 3 | 20:47:16.409 | Recv | sql:jobs | `{"id":"08d615d8-af02-42c6-ba91-c3515e311a04","project_id":"test-1778791636407-lbuh2d","description":"Simple task","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 4 | 20:47:16.410 | Response | http response | `200 {"job_id":"08d615d8-af02-42c6-ba91-c3515e311a04"}` |
| 5 | 20:47:16.410 | Send | http.send | `POST /api/v1/workers {"job_id":"08d615d8-af02-42c6-ba91-c3515e311a04","provider":"test"}` |
| 6 | 20:47:16.410 | Recv | sql:workers | `{"id":"28269452-09d4-48ad-af5b-1fc85ef1507c","job_id":"08d615d8-af02-42c6-ba91-c3515e311a04","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.410931242+00:00","destroyed_at":null}` |
| 7 | 20:47:16.412 | Response | http response | `200 {"worker_id":"28269452-09d4-48ad-af5b-1fc85ef1507c"}` |
| 8 | 20:47:16.412 | Send | http.send | `POST /api/v1/workers/28269452-09d4-48ad-af5b-1fc85ef1507c/register {"job_id":"08d615d8-af02-42c6-ba91-c3515e311a04"}` |
| 9 | 20:47:16.412 | Recv | sql:workers | `{"id":"28269452-09d4-48ad-af5b-1fc85ef1507c","job_id":"08d615d8-af02-42c6-ba91-c3515e311a04","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.410931242+00:00","destroyed_at":null}` |
| 10 | 20:47:16.413 | Recv | sql:jobs | `{"id":"08d615d8-af02-42c6-ba91-c3515e311a04","project_id":"test-1778791636407-lbuh2d","description":"Simple task","status":"running","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |
| 11 | 20:47:16.414 | Response | http response | `200 ` |
| 12 | 20:47:16.414 | Send | http.send | `POST /api/v1/workers/28269452-09d4-48ad-af5b-1fc85ef1507c/complete {"result":"done"}` |
| 13 | 20:47:16.414 | Recv | sql:jobs | `{"id":"08d615d8-af02-42c6-ba91-c3515e311a04","project_id":"test-1778791636407-lbuh2d","description":"Simple task","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"creat...` |
| 14 | 20:47:16.415 | Recv | sql:workers | `{"id":"28269452-09d4-48ad-af5b-1fc85ef1507c","job_id":"08d615d8-af02-42c6-ba91-c3515e311a04","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.410931242+00:00","destroyed_at":"2026-05-14T20:47:16.4...` |
| 15 | 20:47:16.421 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "project_id": "test-1778791636407-lbuh2d",
  "description": "Simple task",
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
  "created_at": "2026-05-14T20:47:16.409574338+00:00",
  "updated_at": "2026-05-14T20:47:16.409574338+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "28269452-09d4-48ad-af5b-1fc85ef1507c",
  "job_id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.410931242+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "28269452-09d4-48ad-af5b-1fc85ef1507c",
  "job_id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.410931242+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "project_id": "test-1778791636407-lbuh2d",
  "description": "Simple task",
  "status": "running",
  "worker_id": null,
  "branch": null,
  "workflow_name": "simple",
  "current_stage": null,
  "stage_history": "[]",
  "attempt": 1,
  "max_attempts": 3,
  "result": null,
  "error": null,
  "created_at": "2026-05-14T20:47:16.409574338+00:00",
  "updated_at": "2026-05-14T20:47:16.413825932+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "project_id": "test-1778791636407-lbuh2d",
  "description": "Simple task",
  "status": "completed",
  "worker_id": null,
  "branch": null,
  "workflow_name": "simple",
  "current_stage": null,
  "stage_history": "[]",
  "attempt": 1,
  "max_attempts": 3,
  "result": "done",
  "error": null,
  "created_at": "2026-05-14T20:47:16.409574338+00:00",
  "updated_at": "2026-05-14T20:47:16.414959349+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:16.414959349+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "28269452-09d4-48ad-af5b-1fc85ef1507c",
  "job_id": "08d615d8-af02-42c6-ba91-c3515e311a04",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.410931242+00:00",
  "destroyed_at": "2026-05-14T20:47:16.415885063+00:00"
}
```

</details>

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.423 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 20:47:16.423 | Response | http response | `200 {"name":"numeric-route","stages":3,"valid":true}` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.426 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 20:47:16.426 | Response | http response | `200 {"name":"simple","stages":2,"valid":true}` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.427 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 20:47:16.427 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.427 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 20:47:16.427 | Response | http response | `200 {"name":"minimal","stages":1,"valid":true}` |

---

## checkpoint advances to next stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.434 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.434 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636432-plimvt","description":"Advance stages","workflow":"feature"}` |
| 3 | 20:47:16.435 | Recv | sql:jobs | `{"id":"bdb92928-306e-49f6-9874-7dc514b973b3","project_id":"test-1778791636432-plimvt","description":"Advance stages","status":"queued","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 4 | 20:47:16.436 | Response | http response | `200 {"job_id":"bdb92928-306e-49f6-9874-7dc514b973b3"}` |
| 5 | 20:47:16.436 | Send | http.send | `POST /api/v1/workers {"job_id":"bdb92928-306e-49f6-9874-7dc514b973b3","provider":"test"}` |
| 6 | 20:47:16.436 | Recv | sql:workers | `{"id":"023b9739-14b4-4b9d-ac51-404710cfdd4d","job_id":"bdb92928-306e-49f6-9874-7dc514b973b3","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.436629849+00:00","destroyed_at":null}` |
| 7 | 20:47:16.437 | Response | http response | `200 {"worker_id":"023b9739-14b4-4b9d-ac51-404710cfdd4d"}` |
| 8 | 20:47:16.437 | Send | http.send | `POST /api/v1/workers/023b9739-14b4-4b9d-ac51-404710cfdd4d/register {"job_id":"bdb92928-306e-49f6-9874-7dc514b973b3"}` |
| 9 | 20:47:16.438 | Recv | sql:workers | `{"id":"023b9739-14b4-4b9d-ac51-404710cfdd4d","job_id":"bdb92928-306e-49f6-9874-7dc514b973b3","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.436629849+00:00","destroyed_at":null}` |
| 10 | 20:47:16.439 | Recv | sql:jobs | `{"id":"bdb92928-306e-49f6-9874-7dc514b973b3","project_id":"test-1778791636432-plimvt","description":"Advance stages","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 11 | 20:47:16.440 | Response | http response | `200 ` |
| 12 | 20:47:16.440 | Send | http.send | `POST /api/v1/workers/023b9739-14b4-4b9d-ac51-404710cfdd4d/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 13 | 20:47:16.440 | Recv | sql:checkpoints | `{"id":"758cff26-9839-41a4-8a5b-b9cdee44f7fd","job_id":"bdb92928-306e-49f6-9874-7dc514b973b3","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","created...` |
| 14 | 20:47:16.441 | Recv | sql:jobs | `{"id":"bdb92928-306e-49f6-9874-7dc514b973b3","project_id":"test-1778791636432-plimvt","description":"Advance stages","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":...` |
| 15 | 20:47:16.442 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "project_id": "test-1778791636432-plimvt",
  "description": "Advance stages",
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
  "created_at": "2026-05-14T20:47:16.435147817+00:00",
  "updated_at": "2026-05-14T20:47:16.435147817+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "023b9739-14b4-4b9d-ac51-404710cfdd4d",
  "job_id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.436629849+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "023b9739-14b4-4b9d-ac51-404710cfdd4d",
  "job_id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.436629849+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "project_id": "test-1778791636432-plimvt",
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
  "created_at": "2026-05-14T20:47:16.435147817+00:00",
  "updated_at": "2026-05-14T20:47:16.439365430+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "758cff26-9839-41a4-8a5b-b9cdee44f7fd",
  "job_id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/tmp/session.json",
  "git_sha": "abc123",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[]",
  "created_at": "2026-05-14T20:47:16.440638818+00:00"
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
{
  "id": "bdb92928-306e-49f6-9874-7dc514b973b3",
  "project_id": "test-1778791636432-plimvt",
  "description": "Advance stages",
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
  "created_at": "2026-05-14T20:47:16.435147817+00:00",
  "updated_at": "2026-05-14T20:47:16.441768990+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## multi-stage progression through feature workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.445 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.445 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636444-vhrqk3","description":"Multi-stage","workflow":"feature"}` |
| 3 | 20:47:16.446 | Response | http response | `200 {"job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f"}` |
| 4 | 20:47:16.446 | Send | http.send | `POST /api/v1/workers {"job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","provider":"test"}` |
| 5 | 20:47:16.446 | Recv | sql:jobs | `{"id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","project_id":"test-1778791636444-vhrqk3","description":"Multi-stage","status":"queued","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_a...` |
| 6 | 20:47:16.446 | Recv | sql:workers | `{"id":"c134834a-632f-41c6-8cf3-3dfa2b471ffc","job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.446836292+00:00","destroyed_at":null}` |
| 7 | 20:47:16.447 | Response | http response | `200 {"worker_id":"c134834a-632f-41c6-8cf3-3dfa2b471ffc"}` |
| 8 | 20:47:16.447 | Send | http.send | `POST /api/v1/workers/c134834a-632f-41c6-8cf3-3dfa2b471ffc/register {"job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f"}` |
| 9 | 20:47:16.447 | Recv | sql:workers | `{"id":"c134834a-632f-41c6-8cf3-3dfa2b471ffc","job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.446836292+00:00","destroyed_at":null}` |
| 10 | 20:47:16.448 | Recv | sql:jobs | `{"id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","project_id":"test-1778791636444-vhrqk3","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |
| 11 | 20:47:16.449 | Response | http response | `200 ` |
| 12 | 20:47:16.449 | Send | http.send | `POST /api/v1/workers/c134834a-632f-41c6-8cf3-3dfa2b471ffc/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":{"prompt_token...` |
| 13 | 20:47:16.449 | Recv | sql:checkpoints | `{"id":"2e0f26e1-08f6-4446-ae2f-0c9acd67d855","job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","created_at":...` |
| 14 | 20:47:16.450 | Recv | sql:jobs | `{"id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","project_id":"test-1778791636444-vhrqk3","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"...` |
| 15 | 20:47:16.451 | Response | http response | `200 ` |
| 16 | 20:47:16.451 | Send | http.send | `POST /api/v1/workers/c134834a-632f-41c6-8cf3-3dfa2b471ffc/checkpoint {"stage":"implement","response":{"success":true},"session_path":"/tmp/s2.json","git_sha":"bbb222","token_usage":{"prompt_tokens"...` |
| 17 | 20:47:16.451 | Recv | sql:checkpoints | `{"id":"30de60cc-b884-4cad-b38f-99fff6e5adbf","job_id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","stage":"implement","response":"{\"success\":true}","session_path":"/tmp/s2.json","git_sha":"bbb222","token_usage":"{\"prompt_tokens\":200,\"completion_tokens\":100}","files_changed":"[\"src/main.rs\"]","...` |
| 18 | 20:47:16.453 | Response | http response | `200 ` |
| 19 | 20:47:16.453 | Recv | sql:jobs | `{"id":"c8e31eaa-62e4-4672-ba32-db1ec035700f","project_id":"test-1778791636444-vhrqk3","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"},{\"stage\":\"impleme...` |

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "project_id": "test-1778791636444-vhrqk3",
  "description": "Multi-stage",
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
  "created_at": "2026-05-14T20:47:16.445968936+00:00",
  "updated_at": "2026-05-14T20:47:16.445968936+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "c134834a-632f-41c6-8cf3-3dfa2b471ffc",
  "job_id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.446836292+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "c134834a-632f-41c6-8cf3-3dfa2b471ffc",
  "job_id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.446836292+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>10. Recv sql:jobs</summary>

```json
{
  "id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "project_id": "test-1778791636444-vhrqk3",
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
  "created_at": "2026-05-14T20:47:16.445968936+00:00",
  "updated_at": "2026-05-14T20:47:16.448805077+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:checkpoints</summary>

```json
{
  "id": "2e0f26e1-08f6-4446-ae2f-0c9acd67d855",
  "job_id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "stage": "plan",
  "response": "{\"complexity\":\"simple\"}",
  "session_path": "/tmp/s1.json",
  "git_sha": "aaa111",
  "token_usage": "{\"prompt_tokens\":100,\"completion_tokens\":50}",
  "files_changed": "[]",
  "created_at": "2026-05-14T20:47:16.449701768+00:00"
}
```

</details>

<details><summary>14. Recv sql:jobs</summary>

```json
{
  "id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "project_id": "test-1778791636444-vhrqk3",
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
  "created_at": "2026-05-14T20:47:16.445968936+00:00",
  "updated_at": "2026-05-14T20:47:16.450408092+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>17. Recv sql:checkpoints</summary>

```json
{
  "id": "30de60cc-b884-4cad-b38f-99fff6e5adbf",
  "job_id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "stage": "implement",
  "response": "{\"success\":true}",
  "session_path": "/tmp/s2.json",
  "git_sha": "bbb222",
  "token_usage": "{\"prompt_tokens\":200,\"completion_tokens\":100}",
  "files_changed": "[\"src/main.rs\"]",
  "created_at": "2026-05-14T20:47:16.451830685+00:00"
}
```

</details>

<details><summary>19. Recv sql:jobs</summary>

```json
{
  "id": "c8e31eaa-62e4-4672-ba32-db1ec035700f",
  "project_id": "test-1778791636444-vhrqk3",
  "description": "Multi-stage",
  "status": "running",
  "worker_id": null,
  "branch": null,
  "workflow_name": "feature",
  "current_stage": "done",
  "stage_history": "[{\"stage\":\"plan\",\"status\":\"completed\"},{\"stage\":\"implement\",\"status\":\"completed\"}]",
  "attempt": 1,
  "max_attempts": 3,
  "result": null,
  "error": null,
  "created_at": "2026-05-14T20:47:16.445968936+00:00",
  "updated_at": "2026-05-14T20:47:16.453034658+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## complete finishes the job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.455 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.456 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636454-1ko7rd","description":"Complete workflow","workflow":"simple"}` |
| 3 | 20:47:16.456 | Recv | sql:jobs | `{"id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","project_id":"test-1778791636454-1ko7rd","description":"Complete workflow","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 4 | 20:47:16.457 | Response | http response | `200 {"job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd"}` |
| 5 | 20:47:16.457 | Send | http.send | `POST /api/v1/workers {"job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","provider":"test"}` |
| 6 | 20:47:16.457 | Recv | sql:workers | `{"id":"c1183b43-2eb5-4c41-a4c3-d8620c09ccb7","job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","provider":"test","provider_id":null,"status":"creating","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.457728318+00:00","destroyed_at":null}` |
| 7 | 20:47:16.458 | Response | http response | `200 {"worker_id":"c1183b43-2eb5-4c41-a4c3-d8620c09ccb7"}` |
| 8 | 20:47:16.458 | Send | http.send | `POST /api/v1/workers/c1183b43-2eb5-4c41-a4c3-d8620c09ccb7/register {"job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd"}` |
| 9 | 20:47:16.458 | Recv | sql:workers | `{"id":"c1183b43-2eb5-4c41-a4c3-d8620c09ccb7","job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.457728318+00:00","destroyed_at":null}` |
| 10 | 20:47:16.459 | Response | http response | `200 ` |
| 11 | 20:47:16.459 | Send | http.send | `POST /api/v1/workers/c1183b43-2eb5-4c41-a4c3-d8620c09ccb7/complete {"result":"all done"}` |
| 12 | 20:47:16.459 | Recv | sql:jobs | `{"id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","project_id":"test-1778791636454-1ko7rd","description":"Complete workflow","status":"running","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cre...` |
| 13 | 20:47:16.460 | Recv | sql:jobs | `{"id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","project_id":"test-1778791636454-1ko7rd","description":"Complete workflow","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"all done","error":n...` |
| 14 | 20:47:16.460 | Recv | sql:workers | `{"id":"c1183b43-2eb5-4c41-a4c3-d8620c09ccb7","job_id":"e1009550-8ed7-4c95-b5fe-a7935238ccbd","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T20:47:16.457728318+00:00","destroyed_at":"2026-05-14T20:47:16.4...` |
| 15 | 20:47:16.461 | Response | http response | `200 ` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "project_id": "test-1778791636454-1ko7rd",
  "description": "Complete workflow",
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
  "created_at": "2026-05-14T20:47:16.456466337+00:00",
  "updated_at": "2026-05-14T20:47:16.456466337+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>6. Recv sql:workers</summary>

```json
{
  "id": "c1183b43-2eb5-4c41-a4c3-d8620c09ccb7",
  "job_id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "provider": "test",
  "provider_id": null,
  "status": "creating",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.457728318+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>9. Recv sql:workers</summary>

```json
{
  "id": "c1183b43-2eb5-4c41-a4c3-d8620c09ccb7",
  "job_id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "provider": "test",
  "provider_id": null,
  "status": "running",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.457728318+00:00",
  "destroyed_at": null
}
```

</details>

<details><summary>12. Recv sql:jobs</summary>

```json
{
  "id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "project_id": "test-1778791636454-1ko7rd",
  "description": "Complete workflow",
  "status": "running",
  "worker_id": null,
  "branch": null,
  "workflow_name": "simple",
  "current_stage": null,
  "stage_history": "[]",
  "attempt": 1,
  "max_attempts": 3,
  "result": null,
  "error": null,
  "created_at": "2026-05-14T20:47:16.456466337+00:00",
  "updated_at": "2026-05-14T20:47:16.459239203+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>13. Recv sql:jobs</summary>

```json
{
  "id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "project_id": "test-1778791636454-1ko7rd",
  "description": "Complete workflow",
  "status": "completed",
  "worker_id": null,
  "branch": null,
  "workflow_name": "simple",
  "current_stage": null,
  "stage_history": "[]",
  "attempt": 1,
  "max_attempts": 3,
  "result": "all done",
  "error": null,
  "created_at": "2026-05-14T20:47:16.456466337+00:00",
  "updated_at": "2026-05-14T20:47:16.460001642+00:00",
  "started_at": null,
  "finished_at": "2026-05-14T20:47:16.460001642+00:00"
}
```

</details>

<details><summary>14. Recv sql:workers</summary>

```json
{
  "id": "c1183b43-2eb5-4c41-a4c3-d8620c09ccb7",
  "job_id": "e1009550-8ed7-4c95-b5fe-a7935238ccbd",
  "provider": "test",
  "provider_id": null,
  "status": "stopped",
  "ip_address": null,
  "workspace_path": null,
  "heartbeat_at": null,
  "created_at": "2026-05-14T20:47:16.457728318+00:00",
  "destroyed_at": "2026-05-14T20:47:16.460883560+00:00"
}
```

</details>

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.464 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.465 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636463-nezrco","description":"Add a hello world function","workflow":"simple"}` |
| 3 | 20:47:16.465 | Recv | sql:jobs | `{"id":"035886ae-58dd-4e26-aff6-5202a5dfc915","project_id":"test-1778791636463-nezrco","description":"Add a hello world function","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":n...` |
| 4 | 20:47:16.468 | Response | http response | `200 {"job_id":"035886ae-58dd-4e26-aff6-5202a5dfc915"}` |
| 5 | 20:47:16.468 | Send | http.send | `GET /api/v1/jobs/035886ae-58dd-4e26-aff6-5202a5dfc915/config` |
| 6 | 20:47:16.468 | Response | http response | `200 {"job_id":"035886ae-58dd-4e26-aff6-5202a5dfc915","stage":"","prompt":"Add a hello world function","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepsee...` |

<details><summary>3. Recv sql:jobs</summary>

```json
{
  "id": "035886ae-58dd-4e26-aff6-5202a5dfc915",
  "project_id": "test-1778791636463-nezrco",
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
  "created_at": "2026-05-14T20:47:16.465726464+00:00",
  "updated_at": "2026-05-14T20:47:16.465726464+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.470 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.471 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636470-rqnm3y","description":"Build feature X","workflow":"feature"}` |
| 3 | 20:47:16.472 | Response | http response | `200 {"job_id":"319927ee-68f6-4e82-b008-85e78a1e434e"}` |
| 4 | 20:47:16.472 | Send | http.send | `GET /api/v1/jobs/319927ee-68f6-4e82-b008-85e78a1e434e/config` |
| 5 | 20:47:16.472 | Response | http response | `200 {"job_id":"319927ee-68f6-4e82-b008-85e78a1e434e","stage":"","prompt":"Build feature X","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","...` |

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.473 | Send | sql.put | `1 rows` |
| 2 | 20:47:16.474 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636473-007tsl","description":"Plan the feature","workflow":"simple"}` |
| 3 | 20:47:16.475 | Response | http response | `200 {"job_id":"5dbc106d-3134-45ed-a1ad-84f7642a34d7"}` |
| 4 | 20:47:16.475 | Send | http.send | `GET /api/v1/jobs/5dbc106d-3134-45ed-a1ad-84f7642a34d7/config` |
| 5 | 20:47:16.475 | Response | http response | `200 {"job_id":"5dbc106d-3134-45ed-a1ad-84f7642a34d7","stage":"","prompt":"Plan the feature","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

## workflow seeded in DB is accessible via config

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:47:16.474 | Recv | sql:jobs | `{"id":"5dbc106d-3134-45ed-a1ad-84f7642a34d7","project_id":"test-1778791636473-007tsl","description":"Plan the feature","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 2 | 20:47:16.477 | Send | sql.put | `1 rows` |
| 3 | 20:47:16.477 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778791636476-i1885t","description":"Test","workflow":"simple"}` |
| 4 | 20:47:16.478 | Response | http response | `200 {"job_id":"4f61accb-4823-4724-851c-80a6c5bd82f1"}` |
| 5 | 20:47:16.478 | Recv | sql:jobs | `{"id":"4f61accb-4823-4724-851c-80a6c5bd82f1","project_id":"test-1778791636476-i1885t","description":"Test","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026...` |

<details><summary>1. Recv sql:jobs</summary>

```json
{
  "id": "5dbc106d-3134-45ed-a1ad-84f7642a34d7",
  "project_id": "test-1778791636473-007tsl",
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
  "created_at": "2026-05-14T20:47:16.474180678+00:00",
  "updated_at": "2026-05-14T20:47:16.474180678+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "id": "4f61accb-4823-4724-851c-80a6c5bd82f1",
  "project_id": "test-1778791636476-i1885t",
  "description": "Test",
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
  "created_at": "2026-05-14T20:47:16.478006160+00:00",
  "updated_at": "2026-05-14T20:47:16.478006160+00:00",
  "started_at": null,
  "finished_at": null
}
```

</details>

---

