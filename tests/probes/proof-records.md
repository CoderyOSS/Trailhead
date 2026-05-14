# Trailhead E2E Test Suite

**Date:** 2026-05-14T08:38:48.489Z
**Events:** 379
**Duration:** 24471ms

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.037 | Send | sql.clear | `all tables` |
| 2 | 08:38:24.052 | Send | sql.put | `2 rows` |
| 3 | 08:38:24.076 | Send | sql.clear | `all tables` |
| 4 | 08:38:24.081 | Send | sql.put | `2 rows` |
| 5 | 08:38:24.316 | Send | sql.put | `1 rows` |
| 6 | 08:38:24.316 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904314-sqfdol","description":"Hello world test"}` |
| 7 | 08:38:24.318 | Response | http response | `200 {"job_id":"b7b77c2b-567e-4564-a59c-8111b3d6221a"}` |

---

## lists jobs via HTTP matching DB count

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.056 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.057 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904053-5343s4","description":"Job 1"}` |
| 3 | 08:38:24.062 | Response | http response | `200 {"job_id":"0c65ad20-8913-4fdc-a509-4888bf538178"}` |
| 4 | 08:38:24.062 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904053-5343s4","description":"Job 2"}` |
| 5 | 08:38:24.064 | Response | http response | `200 {"job_id":"02083918-5c47-48e4-958c-9fc52b40efa3"}` |
| 6 | 08:38:24.064 | Send | http.send | `GET /api/v1/jobs` |
| 7 | 08:38:24.065 | Response | http response | `200 [{"id":"0c65ad20-8913-4fdc-a509-4888bf538178","project_id":"test-1778747904053-5343s4","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"20...` |
| 8 | 08:38:24.065 | Recv | sql:jobs | `[{"id":"0c65ad20-8913-4fdc-a509-4888bf538178","project_id":"test-1778747904053-5343s4","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-0...` |
| 9 | 08:38:24.066 | Recv | sql:jobs | `[{"id":"0c65ad20-8913-4fdc-a509-4888bf538178","project_id":"test-1778747904053-5343s4","description":"Job 1","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-0...` |
| 10 | 08:38:24.066 | Recv | sql:jobs | `[{"id":"02083918-5c47-48e4-958c-9fc52b40efa3","project_id":"test-1778747904053-5343s4","description":"Job 2","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2026-0...` |

---

## list workers via HTTP matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.082 | Send | http.send | `GET /api/v1/workers` |
| 2 | 08:38:24.084 | Response | http response | `200 []` |
| 3 | 08:38:24.084 | Recv | sql:workers | `[]` |

---

## GET /api/v1/jobs returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.091 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.092 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904089-2b75u1","description":"Dashboard test job"}` |
| 3 | 08:38:24.094 | Response | http response | `200 {"job_id":"ed363081-353b-44ef-83c5-d384f78ee89e"}` |
| 4 | 08:38:24.094 | Send | http.send | `GET /api/v1/jobs` |
| 5 | 08:38:24.095 | Response | http response | `200 [{"id":"ed363081-353b-44ef-83c5-d384f78ee89e","project_id":"test-1778747904089-2b75u1","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |
| 6 | 08:38:24.095 | Recv | sql:jobs | `[{"id":"ed363081-353b-44ef-83c5-d384f78ee89e","project_id":"test-1778747904089-2b75u1","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |

---

## GET /api/v1/jobs/{id} returns detail matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.098 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.098 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904096-i60avz","description":"Detail test"}` |
| 3 | 08:38:24.100 | Response | http response | `200 {"job_id":"95ef1048-09b1-472b-85e1-04dc2e8f97d7"}` |
| 4 | 08:38:24.100 | Send | http.send | `GET /api/v1/jobs/95ef1048-09b1-472b-85e1-04dc2e8f97d7` |
| 5 | 08:38:24.100 | Response | http response | `200 {"id":"95ef1048-09b1-472b-85e1-04dc2e8f97d7","project_id":"test-1778747904096-i60avz","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 6 | 08:38:24.100 | Recv | sql:jobs | `[{"id":"95ef1048-09b1-472b-85e1-04dc2e8f97d7","project_id":"test-1778747904096-i60avz","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |

---

## GET /api/v1/workers returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.101 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.101 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904100-ac8oyg","description":"Worker list test"}` |
| 3 | 08:38:24.103 | Response | http response | `200 {"job_id":"12035eef-722a-4998-abb1-04412ad0cbe8"}` |
| 4 | 08:38:24.103 | Send | http.send | `POST /api/v1/workers {"job_id":"12035eef-722a-4998-abb1-04412ad0cbe8","provider":"test"}` |
| 5 | 08:38:24.105 | Response | http response | `200 {"worker_id":"9522e768-d9f6-48d3-b3d0-3ef8eb443382"}` |
| 6 | 08:38:24.105 | Send | http.send | `POST /api/v1/workers/9522e768-d9f6-48d3-b3d0-3ef8eb443382/register {"job_id":"12035eef-722a-4998-abb1-04412ad0cbe8"}` |
| 7 | 08:38:24.108 | Response | http response | `200 ` |
| 8 | 08:38:24.108 | Send | http.send | `GET /api/v1/workers` |
| 9 | 08:38:24.108 | Response | http response | `200 [{"id":"9522e768-d9f6-48d3-b3d0-3ef8eb443382","job_id":"12035eef-722a-4998-abb1-04412ad0cbe8","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.103803117+00:00","destroyed_at":null}]` |
| 10 | 08:38:24.108 | Recv | sql:workers | `[{"id":"9522e768-d9f6-48d3-b3d0-3ef8eb443382","job_id":"12035eef-722a-4998-abb1-04412ad0cbe8","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.103803117+00:00","destroyed_at":null}]` |

---

## POST /api/v1/jobs/{id}/pause changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.110 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.110 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904109-8o2k7h","description":"Pause via dashboard"}` |
| 3 | 08:38:24.111 | Response | http response | `200 {"job_id":"06ec9301-9ccd-48d0-9a36-a5c985106b0f"}` |
| 4 | 08:38:24.111 | Send | http.send | `POST /api/v1/workers {"job_id":"06ec9301-9ccd-48d0-9a36-a5c985106b0f","provider":"test"}` |
| 5 | 08:38:24.112 | Response | http response | `200 {"worker_id":"d326aa4b-d8ea-4d24-9d12-4fc6f68381bb"}` |
| 6 | 08:38:24.112 | Send | http.send | `POST /api/v1/workers/d326aa4b-d8ea-4d24-9d12-4fc6f68381bb/register {"job_id":"06ec9301-9ccd-48d0-9a36-a5c985106b0f"}` |
| 7 | 08:38:24.115 | Response | http response | `200 ` |
| 8 | 08:38:24.115 | Send | http.send | `POST /api/v1/jobs/06ec9301-9ccd-48d0-9a36-a5c985106b0f/pause` |
| 9 | 08:38:24.116 | Response | http response | `200 ` |
| 10 | 08:38:24.116 | Recv | sql:jobs | `[{"id":"06ec9301-9ccd-48d0-9a36-a5c985106b0f","project_id":"test-1778747904109-8o2k7h","description":"Pause via dashboard","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |

---

## POST /api/v1/jobs/{id}/cancel changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.118 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.118 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904117-8nt98o","description":"Cancel via dashboard"}` |
| 3 | 08:38:24.119 | Response | http response | `200 {"job_id":"006ab524-f947-4c72-ada7-4ebffcab3e1e"}` |
| 4 | 08:38:24.119 | Send | http.send | `POST /api/v1/jobs/006ab524-f947-4c72-ada7-4ebffcab3e1e/cancel` |
| 5 | 08:38:24.120 | Response | http response | `200 ` |
| 6 | 08:38:24.121 | Recv | sql:jobs | `[{"id":"006ab524-f947-4c72-ada7-4ebffcab3e1e","project_id":"test-1778747904117-8nt98o","description":"Cancel via dashboard","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"c...` |

---

## new job is queued in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.125 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.125 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904123-a7524s","description":"State machine test"}` |
| 3 | 08:38:24.126 | Response | http response | `200 {"job_id":"3762a36f-9fbb-4415-9e1d-68550ff08e75"}` |
| 4 | 08:38:24.126 | Recv | sql:jobs | `[{"id":"3762a36f-9fbb-4415-9e1d-68550ff08e75","project_id":"test-1778747904123-a7524s","description":"State machine test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 5 | 08:38:48.439 | Send | sql.put | `1 rows` |
| 6 | 08:38:48.439 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928437-ce9uuw","description":"Start at first stage"}` |
| 7 | 08:38:48.440 | Response | http response | `200 {"job_id":"379bde44-f4c1-40a3-88d7-f7778a1ed1f9"}` |
| 8 | 08:38:48.441 | Recv | sql:jobs | `[{"id":"379bde44-f4c1-40a3-88d7-f7778a1ed1f9","project_id":"test-1778747928437-ce9uuw","description":"Start at first stage","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |

---

## running to paused via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.128 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.128 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904127-76t6hs","description":"Pause test"}` |
| 3 | 08:38:24.129 | Response | http response | `200 {"job_id":"2b3e61fa-cf71-4b43-900f-c17d87840ad5"}` |
| 4 | 08:38:24.130 | Send | http.send | `POST /api/v1/workers {"job_id":"2b3e61fa-cf71-4b43-900f-c17d87840ad5","provider":"test"}` |
| 5 | 08:38:24.132 | Response | http response | `200 {"worker_id":"9cf44bfd-4f06-4a9e-a50f-c9b634d8e97c"}` |
| 6 | 08:38:24.132 | Send | http.send | `POST /api/v1/workers/9cf44bfd-4f06-4a9e-a50f-c9b634d8e97c/register {"job_id":"2b3e61fa-cf71-4b43-900f-c17d87840ad5"}` |
| 7 | 08:38:24.135 | Response | http response | `200 ` |
| 8 | 08:38:24.135 | Send | http.send | `POST /api/v1/jobs/2b3e61fa-cf71-4b43-900f-c17d87840ad5/pause` |
| 9 | 08:38:24.136 | Response | http response | `200 ` |
| 10 | 08:38:24.137 | Recv | sql:jobs | `[{"id":"2b3e61fa-cf71-4b43-900f-c17d87840ad5","project_id":"test-1778747904127-76t6hs","description":"Pause test","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"2...` |

---

## paused to resuming via HTTP, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.138 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.138 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904137-1he6nn","description":"Resume test"}` |
| 3 | 08:38:24.139 | Response | http response | `200 {"job_id":"7bf84d0d-6d17-4743-8864-ee7c458bd5b1"}` |
| 4 | 08:38:24.139 | Send | http.send | `POST /api/v1/workers {"job_id":"7bf84d0d-6d17-4743-8864-ee7c458bd5b1","provider":"test"}` |
| 5 | 08:38:24.141 | Response | http response | `200 {"worker_id":"98c1b838-9c5b-43d2-b54b-ae7a42e4c95d"}` |
| 6 | 08:38:24.141 | Send | http.send | `POST /api/v1/workers/98c1b838-9c5b-43d2-b54b-ae7a42e4c95d/register {"job_id":"7bf84d0d-6d17-4743-8864-ee7c458bd5b1"}` |
| 7 | 08:38:24.143 | Response | http response | `200 ` |
| 8 | 08:38:24.143 | Send | http.send | `POST /api/v1/jobs/7bf84d0d-6d17-4743-8864-ee7c458bd5b1/pause` |
| 9 | 08:38:24.145 | Response | http response | `200 ` |
| 10 | 08:38:24.145 | Send | http.send | `POST /api/v1/jobs/7bf84d0d-6d17-4743-8864-ee7c458bd5b1/resume` |
| 11 | 08:38:24.146 | Response | http response | `200 ` |
| 12 | 08:38:24.146 | Recv | sql:jobs | `[{"id":"7bf84d0d-6d17-4743-8864-ee7c458bd5b1","project_id":"test-1778747904137-1he6nn","description":"Resume test","status":"resuming","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |

---

## running to completed, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.148 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.148 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904146-swz73k","description":"Complete test"}` |
| 3 | 08:38:24.149 | Response | http response | `200 {"job_id":"c4ee50e6-7998-4d85-94f8-2aae188016ce"}` |
| 4 | 08:38:24.149 | Send | http.send | `POST /api/v1/workers {"job_id":"c4ee50e6-7998-4d85-94f8-2aae188016ce","provider":"test"}` |
| 5 | 08:38:24.151 | Response | http response | `200 {"worker_id":"8ca07897-26bf-4428-ae81-59ff80980373"}` |
| 6 | 08:38:24.151 | Send | http.send | `POST /api/v1/workers/8ca07897-26bf-4428-ae81-59ff80980373/register {"job_id":"c4ee50e6-7998-4d85-94f8-2aae188016ce"}` |
| 7 | 08:38:24.153 | Response | http response | `200 ` |
| 8 | 08:38:24.153 | Send | http.send | `POST /api/v1/workers/8ca07897-26bf-4428-ae81-59ff80980373/complete {"result":"success"}` |
| 9 | 08:38:24.156 | Response | http response | `200 ` |
| 10 | 08:38:24.156 | Recv | sql:jobs | `[{"id":"c4ee50e6-7998-4d85-94f8-2aae188016ce","project_id":"test-1778747904146-swz73k","description":"Complete test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","error":null,"cre...` |

---

## running to failed_retryable, verified in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.158 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.158 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904157-b14la4","description":"Fail test"}` |
| 3 | 08:38:24.160 | Response | http response | `200 {"job_id":"0461d97d-a1d2-48d7-9eae-056b7d8c192b"}` |
| 4 | 08:38:24.160 | Send | http.send | `POST /api/v1/workers {"job_id":"0461d97d-a1d2-48d7-9eae-056b7d8c192b","provider":"test"}` |
| 5 | 08:38:24.162 | Response | http response | `200 {"worker_id":"0a86fb33-e267-4b3d-8fef-0af0c2dc59d0"}` |
| 6 | 08:38:24.162 | Send | http.send | `POST /api/v1/workers/0a86fb33-e267-4b3d-8fef-0af0c2dc59d0/register {"job_id":"0461d97d-a1d2-48d7-9eae-056b7d8c192b"}` |
| 7 | 08:38:24.165 | Response | http response | `200 ` |
| 8 | 08:38:24.165 | Send | http.send | `POST /api/v1/workers/0a86fb33-e267-4b3d-8fef-0af0c2dc59d0/fail {"error":"transient failure"}` |
| 9 | 08:38:24.167 | Response | http response | `200 ` |
| 10 | 08:38:24.168 | Recv | sql:jobs | `[{"id":"0461d97d-a1d2-48d7-9eae-056b7d8c192b","project_id":"test-1778747904157-b14la4","description":"Fail test","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":"transient ...` |

---

## cannot resume completed job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.169 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.169 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904168-vltr3t","description":"Terminal test"}` |
| 3 | 08:38:24.171 | Response | http response | `200 {"job_id":"1177d61c-4437-4bae-ac98-2944a7858ffe"}` |
| 4 | 08:38:24.171 | Send | http.send | `POST /api/v1/workers {"job_id":"1177d61c-4437-4bae-ac98-2944a7858ffe","provider":"test"}` |
| 5 | 08:38:24.172 | Response | http response | `200 {"worker_id":"580c9983-507a-419c-9bfe-ec5da94dc716"}` |
| 6 | 08:38:24.172 | Send | http.send | `POST /api/v1/workers/580c9983-507a-419c-9bfe-ec5da94dc716/register {"job_id":"1177d61c-4437-4bae-ac98-2944a7858ffe"}` |
| 7 | 08:38:24.174 | Response | http response | `200 ` |
| 8 | 08:38:24.174 | Send | http.send | `POST /api/v1/workers/580c9983-507a-419c-9bfe-ec5da94dc716/complete {"result":"done"}` |
| 9 | 08:38:24.177 | Response | http response | `200 ` |
| 10 | 08:38:24.177 | Send | http.send | `POST /api/v1/jobs/1177d61c-4437-4bae-ac98-2944a7858ffe/resume` |
| 11 | 08:38:24.177 | Response | http response | `409 invalid transition: completed -> resuming` |
| 12 | 08:38:24.177 | Recv | sql:jobs | `[{"id":"1177d61c-4437-4bae-ac98-2944a7858ffe","project_id":"test-1778747904168-vltr3t","description":"Terminal test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"create...` |

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.179 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.179 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904178-ed8dde","description":"Cancel queued"}` |
| 3 | 08:38:24.181 | Response | http response | `200 {"job_id":"82e80138-12de-4582-9c9f-5ddde2d90dc8"}` |
| 4 | 08:38:24.181 | Send | http.send | `POST /api/v1/jobs/82e80138-12de-4582-9c9f-5ddde2d90dc8/cancel` |
| 5 | 08:38:24.182 | Response | http response | `200 ` |
| 6 | 08:38:24.182 | Recv | sql:jobs | `[{"id":"82e80138-12de-4582-9c9f-5ddde2d90dc8","project_id":"test-1778747904178-ed8dde","description":"Cancel queued","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.184 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.184 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904183-ybgap3","description":"Cancel running"}` |
| 3 | 08:38:24.185 | Response | http response | `200 {"job_id":"4a5657a0-9db6-4465-b146-1c613a68a595"}` |
| 4 | 08:38:24.185 | Send | http.send | `POST /api/v1/workers {"job_id":"4a5657a0-9db6-4465-b146-1c613a68a595","provider":"test"}` |
| 5 | 08:38:24.187 | Response | http response | `200 {"worker_id":"05f22e77-5373-4302-ac50-8c9f6aee5ed3"}` |
| 6 | 08:38:24.187 | Send | http.send | `POST /api/v1/workers/05f22e77-5373-4302-ac50-8c9f6aee5ed3/register {"job_id":"4a5657a0-9db6-4465-b146-1c613a68a595"}` |
| 7 | 08:38:24.190 | Response | http response | `200 ` |
| 8 | 08:38:24.190 | Send | http.send | `POST /api/v1/jobs/4a5657a0-9db6-4465-b146-1c613a68a595/cancel` |
| 9 | 08:38:24.192 | Response | http response | `200 ` |
| 10 | 08:38:24.192 | Recv | sql:jobs | `[{"id":"4a5657a0-9db6-4465-b146-1c613a68a595","project_id":"test-1778747904183-ybgap3","description":"Cancel running","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created...` |

---

## worker register sets job to running in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.197 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.197 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904195-ynshfv","description":"E2E test job"}` |
| 3 | 08:38:24.199 | Response | http response | `200 {"job_id":"b1be55d5-937d-4139-b959-4d96f42f3f3f"}` |
| 4 | 08:38:24.199 | Send | http.send | `POST /api/v1/workers {"job_id":"b1be55d5-937d-4139-b959-4d96f42f3f3f","provider":"test"}` |
| 5 | 08:38:24.201 | Response | http response | `200 {"worker_id":"af3e3e2e-fac8-49ca-876c-038203f38ac0"}` |
| 6 | 08:38:24.201 | Send | http.send | `POST /api/v1/workers/af3e3e2e-fac8-49ca-876c-038203f38ac0/register {"job_id":"b1be55d5-937d-4139-b959-4d96f42f3f3f"}` |
| 7 | 08:38:24.204 | Response | http response | `200 ` |
| 8 | 08:38:24.204 | Recv | sql:jobs | `[{"id":"b1be55d5-937d-4139-b959-4d96f42f3f3f","project_id":"test-1778747904195-ynshfv","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at"...` |
| 9 | 08:38:24.204 | Recv | sql:workers | `[{"id":"af3e3e2e-fac8-49ca-876c-038203f38ac0","job_id":"b1be55d5-937d-4139-b959-4d96f42f3f3f","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.199677192+00:00","destroyed_at":null}]` |

---

## worker heartbeat updates timestamp in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.209 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.209 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904205-0dyy40","description":"E2E test job"}` |
| 3 | 08:38:24.211 | Response | http response | `200 {"job_id":"aacf1442-d8b0-4245-8e0d-804fde4636c4"}` |
| 4 | 08:38:24.211 | Send | http.send | `POST /api/v1/workers {"job_id":"aacf1442-d8b0-4245-8e0d-804fde4636c4","provider":"test"}` |
| 5 | 08:38:24.212 | Response | http response | `200 {"worker_id":"2adf5ea4-0538-4f2f-bff8-81df1d900e0c"}` |
| 6 | 08:38:24.212 | Send | http.send | `POST /api/v1/workers/2adf5ea4-0538-4f2f-bff8-81df1d900e0c/register {"job_id":"aacf1442-d8b0-4245-8e0d-804fde4636c4"}` |
| 7 | 08:38:24.215 | Response | http response | `200 ` |
| 8 | 08:38:24.215 | Send | http.send | `POST /api/v1/workers/2adf5ea4-0538-4f2f-bff8-81df1d900e0c/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":500,"completion_tokens":200},"files_changed":0,"tool_ca...` |
| 9 | 08:38:24.217 | Response | http response | `200 ` |
| 10 | 08:38:24.217 | Recv | sql:workers | `[{"id":"2adf5ea4-0538-4f2f-bff8-81df1d900e0c","job_id":"aacf1442-d8b0-4245-8e0d-804fde4636c4","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T08:38:24.215804825+00:00","created_at":"2026-05-14T08:38:24.211303267+00:00","de...` |

---

## worker checkpoint writes to jobs and checkpoints tables

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.218 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.218 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904217-hznjje","description":"E2E test job"}` |
| 3 | 08:38:24.220 | Response | http response | `200 {"job_id":"222627d0-8a9e-482d-ab10-c5ee4f17f699"}` |
| 4 | 08:38:24.220 | Send | http.send | `POST /api/v1/workers {"job_id":"222627d0-8a9e-482d-ab10-c5ee4f17f699","provider":"test"}` |
| 5 | 08:38:24.221 | Response | http response | `200 {"worker_id":"ca3856f1-dda9-4810-9759-0fc6ba1e91ee"}` |
| 6 | 08:38:24.221 | Send | http.send | `POST /api/v1/workers/ca3856f1-dda9-4810-9759-0fc6ba1e91ee/register {"job_id":"222627d0-8a9e-482d-ab10-c5ee4f17f699"}` |
| 7 | 08:38:24.224 | Response | http response | `200 ` |
| 8 | 08:38:24.224 | Send | http.send | `POST /api/v1/workers/ca3856f1-dda9-4810-9759-0fc6ba1e91ee/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"def456","token_usage":{"prompt_...` |
| 9 | 08:38:24.227 | Response | http response | `200 ` |
| 10 | 08:38:24.227 | Recv | sql:jobs | `[{"id":"222627d0-8a9e-482d-ab10-c5ee4f17f699","project_id":"test-1778747904217-hznjje","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"max...` |
| 11 | 08:38:24.228 | Recv | sql:checkpoints | `[{"id":"5a4e839d-b247-48a4-bba5-e31a4ae67de1","job_id":"222627d0-8a9e-482d-ab10-c5ee4f17f699","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"def456","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[\"src/lib....` |

---

## worker complete sets result and destroys worker

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.229 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.229 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904228-1m8cgz","description":"E2E test job"}` |
| 3 | 08:38:24.231 | Response | http response | `200 {"job_id":"bb4ab709-aa81-4fce-8210-7a2e257102b7"}` |
| 4 | 08:38:24.231 | Send | http.send | `POST /api/v1/workers {"job_id":"bb4ab709-aa81-4fce-8210-7a2e257102b7","provider":"test"}` |
| 5 | 08:38:24.232 | Response | http response | `200 {"worker_id":"1261cf82-682f-4d22-a772-7373003cf56a"}` |
| 6 | 08:38:24.232 | Send | http.send | `POST /api/v1/workers/1261cf82-682f-4d22-a772-7373003cf56a/register {"job_id":"bb4ab709-aa81-4fce-8210-7a2e257102b7"}` |
| 7 | 08:38:24.235 | Response | http response | `200 ` |
| 8 | 08:38:24.235 | Send | http.send | `POST /api/v1/workers/1261cf82-682f-4d22-a772-7373003cf56a/complete {"result":"success"}` |
| 9 | 08:38:24.238 | Response | http response | `200 ` |
| 10 | 08:38:24.239 | Recv | sql:jobs | `[{"id":"bb4ab709-aa81-4fce-8210-7a2e257102b7","project_id":"test-1778747904228-1m8cgz","description":"E2E test job","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","error":null,"crea...` |
| 11 | 08:38:24.239 | Recv | sql:workers | `[{"id":"1261cf82-682f-4d22-a772-7373003cf56a","job_id":"bb4ab709-aa81-4fce-8210-7a2e257102b7","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.231390192+00:00","destroyed_at":"2026-05-14T08:38:24....` |

---

## worker fail sets error in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.240 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.240 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904239-9r00wd","description":"E2E test job"}` |
| 3 | 08:38:24.242 | Response | http response | `200 {"job_id":"c88f2470-7895-4b7d-a024-b98060c8b752"}` |
| 4 | 08:38:24.242 | Send | http.send | `POST /api/v1/workers {"job_id":"c88f2470-7895-4b7d-a024-b98060c8b752","provider":"test"}` |
| 5 | 08:38:24.245 | Response | http response | `200 {"worker_id":"c08ffdb6-00fd-4fbe-9001-1f826ff562d5"}` |
| 6 | 08:38:24.245 | Send | http.send | `POST /api/v1/workers/c08ffdb6-00fd-4fbe-9001-1f826ff562d5/register {"job_id":"c88f2470-7895-4b7d-a024-b98060c8b752"}` |
| 7 | 08:38:24.247 | Response | http response | `200 ` |
| 8 | 08:38:24.248 | Send | http.send | `POST /api/v1/workers/c08ffdb6-00fd-4fbe-9001-1f826ff562d5/fail {"error":"build failed"}` |
| 9 | 08:38:24.250 | Response | http response | `200 ` |
| 10 | 08:38:24.250 | Recv | sql:jobs | `[{"id":"c88f2470-7895-4b7d-a024-b98060c8b752","project_id":"test-1778747904239-9r00wd","description":"E2E test job","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":"build f...` |
| 11 | 08:38:24.250 | Recv | sql:workers | `[{"id":"c08ffdb6-00fd-4fbe-9001-1f826ff562d5","job_id":"c88f2470-7895-4b7d-a024-b98060c8b752","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.242848735+00:00","destroyed_at":"2026-05-14T08:38:24....` |

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.252 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.252 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904251-ztbdl7","description":"E2E test job"}` |
| 3 | 08:38:24.254 | Response | http response | `200 {"job_id":"2dad7732-1e0d-4eed-ab86-d172c6992c21"}` |
| 4 | 08:38:24.254 | Send | http.send | `POST /api/v1/workers {"job_id":"2dad7732-1e0d-4eed-ab86-d172c6992c21","provider":"test"}` |
| 5 | 08:38:24.256 | Response | http response | `200 {"worker_id":"d4dd5d6b-6338-4af3-bad7-1ba8c2bb0538"}` |
| 6 | 08:38:24.256 | Send | http.send | `POST /api/v1/workers/d4dd5d6b-6338-4af3-bad7-1ba8c2bb0538/register {"job_id":"2dad7732-1e0d-4eed-ab86-d172c6992c21"}` |
| 7 | 08:38:24.259 | Response | http response | `200 ` |
| 8 | 08:38:24.259 | Send | http.send | `GET /api/v1/jobs/2dad7732-1e0d-4eed-ab86-d172c6992c21/config` |
| 9 | 08:38:24.260 | Response | http response | `200 {"job_id":"2dad7732-1e0d-4eed-ab86-d172c6992c21","stage":"","prompt":"E2E test job","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","api...` |

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.262 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.262 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904260-mx3k2p","description":"E2E test job"}` |
| 3 | 08:38:24.264 | Response | http response | `200 {"job_id":"db291747-f7e4-40ae-8e26-69059838d2ba"}` |
| 4 | 08:38:24.264 | Send | http.send | `POST /api/v1/workers {"job_id":"db291747-f7e4-40ae-8e26-69059838d2ba","provider":"test"}` |
| 5 | 08:38:24.266 | Response | http response | `200 {"worker_id":"9754aa1a-405a-4b63-8b1a-b802b0fb1b63"}` |
| 6 | 08:38:24.266 | Send | http.send | `POST /api/v1/workers/9754aa1a-405a-4b63-8b1a-b802b0fb1b63/register {"job_id":"db291747-f7e4-40ae-8e26-69059838d2ba"}` |
| 7 | 08:38:24.268 | Response | http response | `200 ` |
| 8 | 08:38:24.268 | Send | http.send | `GET /api/v1/jobs/db291747-f7e4-40ae-8e26-69059838d2ba/skill/plan` |
| 9 | 08:38:24.269 | Response | http response | `200 {"content":"You are a senior software engineer tasked with creating an implementation plan.\n\n## Instructions\n\n- Explore the project structure first using glob and grep\n- Identify all files and modules relevant to the task\n- Produce a clear, step-by-step implementation plan\n- Estimate t...` |

---

## unknown worker returns 404

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.269 | Send | http.send | `POST /api/v1/workers/nonexistent-id/register {"job_id":"fake-job"}` |
| 2 | 08:38:24.269 | Response | http response | `404 worker not found` |

---

## creates project via SQL seed and reads via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.274 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.274 | Send | http.send | `GET /api/v1/projects` |
| 3 | 08:38:24.274 | Response | http response | `200 [{"id":"test-1778747904089-2b75u1","repo_url":"https://github.com/test/test-1778747904089-2b75u1","branch":"main","created_at":"2026-05-14T08:38:24.089Z","updated_at":"2026-05-14T08:38:24.089Z"},{"id":"test-1778747904096-i60avz","repo_url":"https://github.com/test/test-1778747904096-i60avz","...` |
| 4 | 08:38:24.275 | Recv | sql:projects | `[{"id":"test-1778747904272-uhwxdo","repo_url":"https://github.com/test/test-1778747904272-uhwxdo","branch":"main","created_at":"2026-05-14T08:38:24.272Z","updated_at":"2026-05-14T08:38:24.272Z"}]` |

---

## creates job via HTTP, verifies via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.276 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.276 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904275-92xdy8","description":"DB test job"}` |
| 3 | 08:38:24.278 | Response | http response | `200 {"job_id":"7434d61a-eaf4-4e91-bba0-01bcbf3b6438"}` |
| 4 | 08:38:24.278 | Send | http.send | `GET /api/v1/jobs/7434d61a-eaf4-4e91-bba0-01bcbf3b6438` |
| 5 | 08:38:24.278 | Response | http response | `200 {"id":"7434d61a-eaf4-4e91-bba0-01bcbf3b6438","project_id":"test-1778747904275-92xdy8","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at...` |
| 6 | 08:38:24.278 | Recv | sql:jobs | `[{"id":"7434d61a-eaf4-4e91-bba0-01bcbf3b6438","project_id":"test-1778747904275-92xdy8","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"...` |

---

## stores checkpoint and verifies via SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.280 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.280 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904279-9yd453","description":"Checkpoint test"}` |
| 3 | 08:38:24.283 | Response | http response | `200 {"job_id":"07b9c3df-97b0-449a-ad45-45945221332a"}` |
| 4 | 08:38:24.283 | Send | http.send | `POST /api/v1/workers {"job_id":"07b9c3df-97b0-449a-ad45-45945221332a","provider":"test"}` |
| 5 | 08:38:24.284 | Response | http response | `200 {"worker_id":"a9cd46b2-6fa2-459b-bc30-65b366c350e5"}` |
| 6 | 08:38:24.284 | Send | http.send | `POST /api/v1/workers/a9cd46b2-6fa2-459b-bc30-65b366c350e5/register {"job_id":"07b9c3df-97b0-449a-ad45-45945221332a"}` |
| 7 | 08:38:24.287 | Response | http response | `200 ` |
| 8 | 08:38:24.287 | Send | http.send | `POST /api/v1/workers/a9cd46b2-6fa2-459b-bc30-65b366c350e5/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 9 | 08:38:24.291 | Response | http response | `200 ` |
| 10 | 08:38:24.291 | Recv | sql:jobs | `[{"id":"07b9c3df-97b0-449a-ad45-45945221332a","project_id":"test-1778747904279-9yd453","description":"Checkpoint test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"max_a...` |
| 11 | 08:38:24.291 | Recv | sql:checkpoints | `[{"id":"629dbb1d-c953-4bad-899c-cad240a43487","job_id":"07b9c3df-97b0-449a-ad45-45945221332a","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[\"src/main...` |

---

## tracks worker heartbeat in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.293 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.293 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904291-n7yo1r","description":"Heartbeat test"}` |
| 3 | 08:38:24.294 | Response | http response | `200 {"job_id":"3c81cc60-31ee-4684-97a2-6359ed8b9580"}` |
| 4 | 08:38:24.294 | Send | http.send | `POST /api/v1/workers {"job_id":"3c81cc60-31ee-4684-97a2-6359ed8b9580","provider":"test"}` |
| 5 | 08:38:24.296 | Response | http response | `200 {"worker_id":"924cd24d-2dca-47a2-bc38-6f26ccc6150b"}` |
| 6 | 08:38:24.296 | Send | http.send | `POST /api/v1/workers/924cd24d-2dca-47a2-bc38-6f26ccc6150b/register {"job_id":"3c81cc60-31ee-4684-97a2-6359ed8b9580"}` |
| 7 | 08:38:24.299 | Response | http response | `200 ` |
| 8 | 08:38:24.299 | Send | http.send | `POST /api/v1/workers/924cd24d-2dca-47a2-bc38-6f26ccc6150b/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 9 | 08:38:24.300 | Response | http response | `200 ` |
| 10 | 08:38:24.301 | Recv | sql:workers | `[{"id":"924cd24d-2dca-47a2-bc38-6f26ccc6150b","job_id":"3c81cc60-31ee-4684-97a2-6359ed8b9580","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T08:38:24.299505041+00:00","created_at":"2026-05-14T08:38:24.294891204+00:00","de...` |

---

## destroyed workers removed from DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.302 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.302 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904301-xpd8xs","description":"Destroy test"}` |
| 3 | 08:38:24.304 | Response | http response | `200 {"job_id":"efb018a3-205d-4fe6-9924-15905c47cc07"}` |
| 4 | 08:38:24.304 | Send | http.send | `POST /api/v1/workers {"job_id":"efb018a3-205d-4fe6-9924-15905c47cc07","provider":"test"}` |
| 5 | 08:38:24.306 | Response | http response | `200 {"worker_id":"cd0c2408-c4d3-4855-ae4c-ac9265542dbb"}` |
| 6 | 08:38:24.306 | Send | http.send | `POST /api/v1/workers/cd0c2408-c4d3-4855-ae4c-ac9265542dbb/register {"job_id":"efb018a3-205d-4fe6-9924-15905c47cc07"}` |
| 7 | 08:38:24.309 | Response | http response | `200 ` |
| 8 | 08:38:24.309 | Send | http.send | `POST /api/v1/workers/cd0c2408-c4d3-4855-ae4c-ac9265542dbb/complete {"result":"done"}` |
| 9 | 08:38:24.312 | Response | http response | `200 ` |
| 10 | 08:38:24.312 | Recv | sql:workers | `[{"id":"cd0c2408-c4d3-4855-ae4c-ac9265542dbb","job_id":"efb018a3-205d-4fe6-9924-15905c47cc07","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.304743729+00:00","destroyed_at":"2026-05-14T08:38:24....` |

---

## creates a job with hello-world workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.318 | Recv | sql:jobs | `[{"id":"b7b77c2b-567e-4564-a59c-8111b3d6221a","project_id":"test-1778747904314-sqfdol","description":"Hello world test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_...` |

---

## job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.318 | Send | http.send | `GET /api/v1/jobs/b7b77c2b-567e-4564-a59c-8111b3d6221a/config` |
| 2 | 08:38:24.319 | Response | http response | `200 {"job_id":"b7b77c2b-567e-4564-a59c-8111b3d6221a","stage":"","prompt":"Hello world test","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

## create project → create job → register worker → complete

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.322 | Send | sql.put | `1 rows` |
| 2 | 08:38:24.322 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747904320-qn2qz6","description":"Full lifecycle test"}` |
| 3 | 08:38:24.323 | Response | http response | `200 {"job_id":"6887280b-44df-4ee8-8814-b7a36907de82"}` |
| 4 | 08:38:24.323 | Recv | sql:jobs | `[{"id":"6887280b-44df-4ee8-8814-b7a36907de82","project_id":"test-1778747904320-qn2qz6","description":"Full lifecycle test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"creat...` |
| 5 | 08:38:24.323 | Send | http.send | `POST /api/v1/workers {"job_id":"6887280b-44df-4ee8-8814-b7a36907de82","provider":"test"}` |
| 6 | 08:38:24.325 | Response | http response | `200 {"worker_id":"233e30d1-3e8f-4c21-adaf-b74aa0419849"}` |
| 7 | 08:38:24.325 | Send | http.send | `POST /api/v1/workers/233e30d1-3e8f-4c21-adaf-b74aa0419849/register {"job_id":"6887280b-44df-4ee8-8814-b7a36907de82"}` |
| 8 | 08:38:24.328 | Response | http response | `200 ` |
| 9 | 08:38:24.328 | Recv | sql:jobs | `[{"id":"6887280b-44df-4ee8-8814-b7a36907de82","project_id":"test-1778747904320-qn2qz6","description":"Full lifecycle test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"crea...` |
| 10 | 08:38:24.328 | Recv | sql:workers | `[{"id":"233e30d1-3e8f-4c21-adaf-b74aa0419849","job_id":"6887280b-44df-4ee8-8814-b7a36907de82","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.323992141+00:00","destroyed_at":null}]` |
| 11 | 08:38:24.328 | Send | http.send | `POST /api/v1/workers/233e30d1-3e8f-4c21-adaf-b74aa0419849/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 12 | 08:38:24.330 | Response | http response | `200 ` |
| 13 | 08:38:24.330 | Recv | sql:workers | `[{"id":"233e30d1-3e8f-4c21-adaf-b74aa0419849","job_id":"6887280b-44df-4ee8-8814-b7a36907de82","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T08:38:24.328526548+00:00","created_at":"2026-05-14T08:38:24.323992141+00:00","de...` |
| 14 | 08:38:24.330 | Send | http.send | `POST /api/v1/workers/233e30d1-3e8f-4c21-adaf-b74aa0419849/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_us...` |
| 15 | 08:38:24.334 | Response | http response | `200 ` |
| 16 | 08:38:24.335 | Recv | sql:jobs | `[{"id":"6887280b-44df-4ee8-8814-b7a36907de82","project_id":"test-1778747904320-qn2qz6","description":"Full lifecycle test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,"m...` |
| 17 | 08:38:24.335 | Recv | sql:checkpoints | `[{"id":"c9a2cf3c-035e-4557-917d-32e5a0028a2d","job_id":"6887280b-44df-4ee8-8814-b7a36907de82","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed...` |
| 18 | 08:38:24.335 | Send | http.send | `POST /api/v1/workers/233e30d1-3e8f-4c21-adaf-b74aa0419849/complete {"result":"Job completed successfully"}` |
| 19 | 08:38:24.338 | Response | http response | `200 ` |
| 20 | 08:38:24.338 | Recv | sql:jobs | `[{"id":"6887280b-44df-4ee8-8814-b7a36907de82","project_id":"test-1778747904320-qn2qz6","description":"Full lifecycle test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":1,...` |
| 21 | 08:38:24.338 | Recv | sql:workers | `[{"id":"233e30d1-3e8f-4c21-adaf-b74aa0419849","job_id":"6887280b-44df-4ee8-8814-b7a36907de82","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":"2026-05-14T08:38:24.328526548+00:00","created_at":"2026-05-14T08:38:24.323992141+00:00","de...` |

---

## lists jobs and workers via HTTP matches DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.338 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 08:38:24.339 | Response | http response | `200 [{"id":"ed363081-353b-44ef-83c5-d384f78ee89e","project_id":"test-1778747904089-2b75u1","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"cr...` |
| 3 | 08:38:24.339 | Recv | sql:jobs | `[{"id":"ed363081-353b-44ef-83c5-d384f78ee89e","project_id":"test-1778747904089-2b75u1","description":"Dashboard test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"create...` |
| 4 | 08:38:24.339 | Send | http.send | `GET /api/v1/workers` |
| 5 | 08:38:24.340 | Response | http response | `200 [{"id":"9522e768-d9f6-48d3-b3d0-3ef8eb443382","job_id":"12035eef-722a-4998-abb1-04412ad0cbe8","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.103803117+00:00","destroyed_at":null},{"id":"d326...` |
| 6 | 08:38:24.340 | Recv | sql:workers | `[{"id":"9522e768-d9f6-48d3-b3d0-3ef8eb443382","job_id":"12035eef-722a-4998-abb1-04412ad0cbe8","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:24.103803117+00:00","destroyed_at":null},{"id":"d326aa4b...` |

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.340 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 08:38:24.340 | Response | http response | `200 {"name":"test","stages":1,"valid":true}` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:24.340 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 08:38:24.341 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## routes based on string equality in response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.393 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.393 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928390-x4h8zc","description":"Build feature","workflow":"feature"}` |
| 3 | 08:38:48.395 | Response | http response | `200 {"job_id":"da4ec9df-5c9a-487f-b3f7-66b00f3901e6"}` |
| 4 | 08:38:48.395 | Send | http.send | `POST /api/v1/workers {"job_id":"da4ec9df-5c9a-487f-b3f7-66b00f3901e6","provider":"test"}` |
| 5 | 08:38:48.396 | Response | http response | `200 {"worker_id":"116439af-424f-4e7f-a16c-1b1bf58f6466"}` |
| 6 | 08:38:48.396 | Send | http.send | `POST /api/v1/workers/116439af-424f-4e7f-a16c-1b1bf58f6466/register {"job_id":"da4ec9df-5c9a-487f-b3f7-66b00f3901e6"}` |
| 7 | 08:38:48.399 | Response | http response | `200 ` |
| 8 | 08:38:48.399 | Send | http.send | `POST /api/v1/workers/116439af-424f-4e7f-a16c-1b1bf58f6466/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 9 | 08:38:48.403 | Response | http response | `200 ` |
| 10 | 08:38:48.403 | Recv | sql:jobs | `[{"id":"da4ec9df-5c9a-487f-b3f7-66b00f3901e6","project_id":"test-1778747928390-x4h8zc","description":"Build feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt":...` |
| 11 | 08:38:48.403 | Recv | sql:checkpoints | `[{"id":"ea696dca-dff4-4dd2-87e8-9a942b953467","job_id":"da4ec9df-5c9a-487f-b3f7-66b00f3901e6","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","create...` |

---

## routes to plan_detail on complex response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.405 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.405 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928403-x0p6em","description":"Complex feature","workflow":"feature"}` |
| 3 | 08:38:48.407 | Response | http response | `200 {"job_id":"167beaf1-7f11-41a6-a609-9f239aa8a592"}` |
| 4 | 08:38:48.407 | Send | http.send | `POST /api/v1/workers {"job_id":"167beaf1-7f11-41a6-a609-9f239aa8a592","provider":"test"}` |
| 5 | 08:38:48.409 | Response | http response | `200 {"worker_id":"cca707c4-0c61-4e06-a964-5c781f66aa25"}` |
| 6 | 08:38:48.409 | Send | http.send | `POST /api/v1/workers/cca707c4-0c61-4e06-a964-5c781f66aa25/register {"job_id":"167beaf1-7f11-41a6-a609-9f239aa8a592"}` |
| 7 | 08:38:48.415 | Response | http response | `200 ` |
| 8 | 08:38:48.415 | Send | http.send | `POST /api/v1/workers/cca707c4-0c61-4e06-a964-5c781f66aa25/checkpoint {"stage":"plan","response":{"complexity":"complex"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt...` |
| 9 | 08:38:48.419 | Response | http response | `200 ` |
| 10 | 08:38:48.419 | Recv | sql:jobs | `[{"id":"167beaf1-7f11-41a6-a609-9f239aa8a592","project_id":"test-1778747928403-x0p6em","description":"Complex feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"plan_detail","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attem...` |

---

## completes workflow when routes is null

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.422 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.422 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928420-i6ekk9","description":"Simple task","workflow":"simple"}` |
| 3 | 08:38:48.423 | Response | http response | `200 {"job_id":"b8f35ff0-7d62-4694-a430-b904f813cb3b"}` |
| 4 | 08:38:48.423 | Send | http.send | `POST /api/v1/workers {"job_id":"b8f35ff0-7d62-4694-a430-b904f813cb3b","provider":"test"}` |
| 5 | 08:38:48.425 | Response | http response | `200 {"worker_id":"24e2ba22-1c57-4814-9caf-319665e264e9"}` |
| 6 | 08:38:48.425 | Send | http.send | `POST /api/v1/workers/24e2ba22-1c57-4814-9caf-319665e264e9/register {"job_id":"b8f35ff0-7d62-4694-a430-b904f813cb3b"}` |
| 7 | 08:38:48.428 | Response | http response | `200 ` |
| 8 | 08:38:48.428 | Send | http.send | `POST /api/v1/workers/24e2ba22-1c57-4814-9caf-319665e264e9/complete {"result":"done"}` |
| 9 | 08:38:48.430 | Response | http response | `200 ` |
| 10 | 08:38:48.431 | Recv | sql:jobs | `[{"id":"b8f35ff0-7d62-4694-a430-b904f813cb3b","project_id":"test-1778747928420-i6ekk9","description":"Simple task","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","error":null,"crea...` |
| 11 | 08:38:48.431 | Recv | sql:workers | `[{"id":"24e2ba22-1c57-4814-9caf-319665e264e9","job_id":"b8f35ff0-7d62-4694-a430-b904f813cb3b","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:48.423944085+00:00","destroyed_at":"2026-05-14T08:38:48....` |

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.431 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 08:38:48.432 | Response | http response | `200 {"name":"numeric-route","stages":3,"valid":true}` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.434 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 08:38:48.435 | Response | http response | `200 {"name":"simple","stages":2,"valid":true}` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.435 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 08:38:48.435 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.435 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 08:38:48.436 | Response | http response | `200 {"name":"minimal","stages":1,"valid":true}` |

---

## checkpoint advances to next stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.443 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.443 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928441-tvvxwk","description":"Advance stages","workflow":"feature"}` |
| 3 | 08:38:48.444 | Response | http response | `200 {"job_id":"f72157ff-0565-475a-bac9-92cbbc2a9de0"}` |
| 4 | 08:38:48.444 | Send | http.send | `POST /api/v1/workers {"job_id":"f72157ff-0565-475a-bac9-92cbbc2a9de0","provider":"test"}` |
| 5 | 08:38:48.446 | Response | http response | `200 {"worker_id":"f1274720-b784-4e35-ab91-1a4bcb07d326"}` |
| 6 | 08:38:48.446 | Send | http.send | `POST /api/v1/workers/f1274720-b784-4e35-ab91-1a4bcb07d326/register {"job_id":"f72157ff-0565-475a-bac9-92cbbc2a9de0"}` |
| 7 | 08:38:48.449 | Response | http response | `200 ` |
| 8 | 08:38:48.449 | Send | http.send | `POST /api/v1/workers/f1274720-b784-4e35-ab91-1a4bcb07d326/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 9 | 08:38:48.451 | Response | http response | `200 ` |
| 10 | 08:38:48.452 | Recv | sql:jobs | `[{"id":"f72157ff-0565-475a-bac9-92cbbc2a9de0","project_id":"test-1778747928441-tvvxwk","description":"Advance stages","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","attempt"...` |
| 11 | 08:38:48.452 | Recv | sql:checkpoints | `[{"id":"d610a0fb-9dd3-42cf-96c7-08d2dd4df3f3","job_id":"f72157ff-0565-475a-bac9-92cbbc2a9de0","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/session.json","git_sha":"abc123","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","create...` |

---

## multi-stage progression through feature workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.453 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.453 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928452-4g5ilq","description":"Multi-stage","workflow":"feature"}` |
| 3 | 08:38:48.455 | Response | http response | `200 {"job_id":"5a084b3b-e99d-4c24-9e9e-9c2e5854ee05"}` |
| 4 | 08:38:48.455 | Send | http.send | `POST /api/v1/workers {"job_id":"5a084b3b-e99d-4c24-9e9e-9c2e5854ee05","provider":"test"}` |
| 5 | 08:38:48.457 | Response | http response | `200 {"worker_id":"be0945d4-b276-4f46-a609-1da0e801ef9a"}` |
| 6 | 08:38:48.457 | Send | http.send | `POST /api/v1/workers/be0945d4-b276-4f46-a609-1da0e801ef9a/register {"job_id":"5a084b3b-e99d-4c24-9e9e-9c2e5854ee05"}` |
| 7 | 08:38:48.460 | Response | http response | `200 ` |
| 8 | 08:38:48.460 | Send | http.send | `POST /api/v1/workers/be0945d4-b276-4f46-a609-1da0e801ef9a/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":{"prompt_token...` |
| 9 | 08:38:48.464 | Response | http response | `200 ` |
| 10 | 08:38:48.464 | Send | http.send | `POST /api/v1/workers/be0945d4-b276-4f46-a609-1da0e801ef9a/checkpoint {"stage":"implement","response":{"success":true},"session_path":"/tmp/s2.json","git_sha":"bbb222","token_usage":{"prompt_tokens"...` |
| 11 | 08:38:48.467 | Response | http response | `200 ` |
| 12 | 08:38:48.467 | Recv | sql:jobs | `[{"id":"5a084b3b-e99d-4c24-9e9e-9c2e5854ee05","project_id":"test-1778747928452-4g5ilq","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"},{\"stage\":\"implem...` |
| 13 | 08:38:48.467 | Recv | sql:checkpoints | `[{"id":"93d2c88b-8f89-4a1c-848d-a01295b97ce3","job_id":"5a084b3b-e99d-4c24-9e9e-9c2e5854ee05","stage":"plan","response":"{\"complexity\":\"simple\"}","session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":"{\"prompt_tokens\":100,\"completion_tokens\":50}","files_changed":"[]","created_at"...` |

---

## complete finishes the job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.469 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.469 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928468-1g6h4g","description":"Complete workflow","workflow":"simple"}` |
| 3 | 08:38:48.471 | Response | http response | `200 {"job_id":"07d9ba57-263e-4c51-888c-16dca8925224"}` |
| 4 | 08:38:48.471 | Send | http.send | `POST /api/v1/workers {"job_id":"07d9ba57-263e-4c51-888c-16dca8925224","provider":"test"}` |
| 5 | 08:38:48.472 | Response | http response | `200 {"worker_id":"bba3d130-01c5-4bfc-935d-24b5200dfb33"}` |
| 6 | 08:38:48.472 | Send | http.send | `POST /api/v1/workers/bba3d130-01c5-4bfc-935d-24b5200dfb33/register {"job_id":"07d9ba57-263e-4c51-888c-16dca8925224"}` |
| 7 | 08:38:48.474 | Response | http response | `200 ` |
| 8 | 08:38:48.474 | Send | http.send | `POST /api/v1/workers/bba3d130-01c5-4bfc-935d-24b5200dfb33/complete {"result":"all done"}` |
| 9 | 08:38:48.476 | Response | http response | `200 ` |
| 10 | 08:38:48.476 | Recv | sql:jobs | `[{"id":"07d9ba57-263e-4c51-888c-16dca8925224","project_id":"test-1778747928468-1g6h4g","description":"Complete workflow","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"all done","error":...` |
| 11 | 08:38:48.476 | Recv | sql:workers | `[{"id":"bba3d130-01c5-4bfc-935d-24b5200dfb33","job_id":"07d9ba57-263e-4c51-888c-16dca8925224","provider":"test","provider_id":null,"status":"stopped","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T08:38:48.471390624+00:00","destroyed_at":"2026-05-14T08:38:48....` |

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.478 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.478 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928477-fthqka","description":"Add a hello world function","workflow":"simple"}` |
| 3 | 08:38:48.480 | Response | http response | `200 {"job_id":"384def26-52bc-473d-b012-d7dea55427c8"}` |
| 4 | 08:38:48.480 | Send | http.send | `GET /api/v1/jobs/384def26-52bc-473d-b012-d7dea55427c8/config` |
| 5 | 08:38:48.480 | Response | http response | `200 {"job_id":"384def26-52bc-473d-b012-d7dea55427c8","stage":"","prompt":"Add a hello world function","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepsee...` |
| 6 | 08:38:48.480 | Recv | sql:jobs | `[{"id":"384def26-52bc-473d-b012-d7dea55427c8","project_id":"test-1778747928477-fthqka","description":"Add a hello world function","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":...` |

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.481 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.481 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928480-50z47l","description":"Build feature X","workflow":"feature"}` |
| 3 | 08:38:48.483 | Response | http response | `200 {"job_id":"2e53c4fa-7000-4aed-bd34-45bf07e78476"}` |
| 4 | 08:38:48.483 | Send | http.send | `GET /api/v1/jobs/2e53c4fa-7000-4aed-bd34-45bf07e78476/config` |
| 5 | 08:38:48.483 | Response | http response | `200 {"job_id":"2e53c4fa-7000-4aed-bd34-45bf07e78476","stage":"","prompt":"Build feature X","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","...` |

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.484 | Send | sql.put | `1 rows` |
| 2 | 08:38:48.484 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928483-apv2a2","description":"Plan the feature","workflow":"simple"}` |
| 3 | 08:38:48.486 | Response | http response | `200 {"job_id":"ed9012a0-c387-4caa-8975-cf1767c5317d"}` |
| 4 | 08:38:48.486 | Send | http.send | `GET /api/v1/jobs/ed9012a0-c387-4caa-8975-cf1767c5317d/config` |
| 5 | 08:38:48.486 | Response | http response | `200 {"job_id":"ed9012a0-c387-4caa-8975-cf1767c5317d","stage":"","prompt":"Plan the feature","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

## workflow seeded in DB is accessible via config

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 08:38:48.486 | Recv | sql:workflows | `[{"name":"simple","content":"name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read, glob, grep]\n max_tokens: 8000\n routes:\n - when: 'response.complexity == \"simple\"'\n next: done\n - when: 'true'...` |
| 2 | 08:38:48.487 | Send | sql.put | `1 rows` |
| 3 | 08:38:48.487 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778747928486-jenind","description":"Test","workflow":"simple"}` |
| 4 | 08:38:48.488 | Response | http response | `200 {"job_id":"d3a2d7df-ffe2-4661-b419-b71c246af68d"}` |
| 5 | 08:38:48.488 | Recv | sql:jobs | `[{"id":"d3a2d7df-ffe2-4661-b419-b71c246af68d","project_id":"test-1778747928486-jenind","description":"Test","status":"queued","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"created_at":"202...` |

---

