# Trailhead E2E Test Suite

**Date:** 2026-05-14T07:24:42.824Z
**Events:** 388
**Duration:** 30900ms

---

## lists jobs with status filter

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.928 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451928-wrejq6","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.932 | Response | http response | `200 {"project_id":"943b8ded-ca90-4348-b44d-5e3dc6b6aeec"}` |
| 3 | 07:24:11.932 | Send | http.send | `POST /api/v1/jobs {"project_id":"943b8ded-ca90-4348-b44d-5e3dc6b6aeec","description":"Job 1"}` |
| 4 | 07:24:11.934 | Response | http response | `200 {"job_id":"e6f5556a-f38b-4af4-b870-277e88b7f833"}` |
| 5 | 07:24:11.934 | Send | http.send | `POST /api/v1/jobs {"project_id":"943b8ded-ca90-4348-b44d-5e3dc6b6aeec","description":"Job 2"}` |
| 6 | 07:24:11.936 | Response | http response | `200 {"job_id":"8bf7afc3-1218-46f8-b197-6686aee1f858"}` |
| 7 | 07:24:11.936 | Send | http.send | `GET /api/v1/jobs` |
| 8 | 07:24:11.938 | Response | http response | `200 [{"id":"d13bb9f9-5c45-4a53-8e56-cca338cfb2ba","project_id":"99592130-1904-4d05-94c8-f2813a388bf9","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null...` |

---

## list workers returns array

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.939 | Send | http.send | `GET /api/v1/workers` |
| 2 | 07:24:11.940 | Response | http response | `200 [{"id":"9b1abb6e-707a-4d66-b48f-cc51f4070de1","job_id":"b74c82f6-5314-444d-8094-953348bfff39","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T07:17:31.453953553+00:00","destroyed_at":null},{"id":"639f...` |

---

## GET /api/v1/jobs returns list

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.943 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451943-zj4o75","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.945 | Response | http response | `200 {"project_id":"2bf19e7f-349d-4fb1-ac0f-db2400d22382"}` |
| 3 | 07:24:11.945 | Send | http.send | `POST /api/v1/jobs {"project_id":"2bf19e7f-349d-4fb1-ac0f-db2400d22382","description":"Dashboard test job"}` |
| 4 | 07:24:11.947 | Response | http response | `200 {"job_id":"c537b116-b005-425f-815d-e0fdd58ed9ba"}` |
| 5 | 07:24:11.947 | Send | http.send | `GET /api/v1/jobs` |
| 6 | 07:24:11.949 | Response | http response | `200 [{"id":"d13bb9f9-5c45-4a53-8e56-cca338cfb2ba","project_id":"99592130-1904-4d05-94c8-f2813a388bf9","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null...` |

---

## GET /api/v1/jobs/{id} returns detail

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.949 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451949-9u0qos","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.951 | Response | http response | `200 {"project_id":"b3b259d9-fd1c-4e75-bb48-bd1ec0f3a7f2"}` |
| 3 | 07:24:11.951 | Send | http.send | `POST /api/v1/jobs {"project_id":"b3b259d9-fd1c-4e75-bb48-bd1ec0f3a7f2","description":"Detail test"}` |
| 4 | 07:24:11.952 | Response | http response | `200 {"job_id":"3702d6d4-4553-460e-a9d5-c9645de3f3b2"}` |
| 5 | 07:24:11.952 | Send | http.send | `GET /api/v1/jobs/3702d6d4-4553-460e-a9d5-c9645de3f3b2` |
| 6 | 07:24:11.953 | Response | http response | `200 {"id":"3702d6d4-4553-460e-a9d5-c9645de3f3b2","project_id":"b3b259d9-fd1c-4e75-bb48-bd1ec0f3a7f2","description":"Detail test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,...` |

---

## GET /api/v1/workers returns list

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.953 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451953-fanvjg","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.955 | Response | http response | `200 {"project_id":"73a46df6-814b-4dad-9191-2780ac63cf05"}` |
| 3 | 07:24:11.955 | Send | http.send | `POST /api/v1/jobs {"project_id":"73a46df6-814b-4dad-9191-2780ac63cf05","description":"Worker list test"}` |
| 4 | 07:24:11.957 | Response | http response | `200 {"job_id":"af1e7fe7-1b6f-4f93-a3ad-0b1aff7dc8d5"}` |
| 5 | 07:24:11.957 | Send | http.send | `POST /api/v1/workers {"job_id":"af1e7fe7-1b6f-4f93-a3ad-0b1aff7dc8d5","provider":"test"}` |
| 6 | 07:24:11.959 | Response | http response | `200 {"worker_id":"50e018e6-e540-4590-bc0f-8d1b2bc62841"}` |
| 7 | 07:24:11.959 | Send | http.send | `POST /api/v1/workers/50e018e6-e540-4590-bc0f-8d1b2bc62841/register {"job_id":"af1e7fe7-1b6f-4f93-a3ad-0b1aff7dc8d5"}` |
| 8 | 07:24:11.962 | Response | http response | `200 ` |
| 9 | 07:24:11.962 | Send | http.send | `GET /api/v1/workers` |
| 10 | 07:24:11.963 | Response | http response | `200 [{"id":"9b1abb6e-707a-4d66-b48f-cc51f4070de1","job_id":"b74c82f6-5314-444d-8094-953348bfff39","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T07:17:31.453953553+00:00","destroyed_at":null},{"id":"639f...` |

---

## POST /api/v1/jobs/{id}/pause changes status

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.963 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451963-8h1cc9","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.965 | Response | http response | `200 {"project_id":"95d7163d-dd60-4c17-ba43-bafe95673a39"}` |
| 3 | 07:24:11.965 | Send | http.send | `POST /api/v1/jobs {"project_id":"95d7163d-dd60-4c17-ba43-bafe95673a39","description":"Pause via dashboard"}` |
| 4 | 07:24:11.967 | Response | http response | `200 {"job_id":"b352a9f5-23aa-4d91-87bb-dde1384011c2"}` |
| 5 | 07:24:11.967 | Send | http.send | `POST /api/v1/workers {"job_id":"b352a9f5-23aa-4d91-87bb-dde1384011c2","provider":"test"}` |
| 6 | 07:24:11.968 | Response | http response | `200 {"worker_id":"b7c310d5-bc1b-4a01-9d76-bee19f51eacb"}` |
| 7 | 07:24:11.968 | Send | http.send | `POST /api/v1/workers/b7c310d5-bc1b-4a01-9d76-bee19f51eacb/register {"job_id":"b352a9f5-23aa-4d91-87bb-dde1384011c2"}` |
| 8 | 07:24:11.971 | Response | http response | `200 ` |
| 9 | 07:24:11.971 | Send | http.send | `POST /api/v1/jobs/b352a9f5-23aa-4d91-87bb-dde1384011c2/pause` |
| 10 | 07:24:11.973 | Response | http response | `200 ` |
| 11 | 07:24:11.973 | Send | http.send | `GET /api/v1/jobs/b352a9f5-23aa-4d91-87bb-dde1384011c2` |
| 12 | 07:24:11.973 | Response | http response | `200 {"id":"b352a9f5-23aa-4d91-87bb-dde1384011c2","project_id":"95d7163d-dd60-4c17-ba43-bafe95673a39","description":"Pause via dashboard","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"erro...` |

---

## POST /api/v1/jobs/{id}/cancel changes status

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.974 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451974-pyd9oc","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.976 | Response | http response | `200 {"project_id":"1ea3dbdc-04c8-4385-bc08-e0af42d6755a"}` |
| 3 | 07:24:11.976 | Send | http.send | `POST /api/v1/jobs {"project_id":"1ea3dbdc-04c8-4385-bc08-e0af42d6755a","description":"Cancel via dashboard"}` |
| 4 | 07:24:11.978 | Response | http response | `200 {"job_id":"e0795e48-2c52-4de5-bddb-59eab3df3a3d"}` |
| 5 | 07:24:11.978 | Send | http.send | `POST /api/v1/jobs/e0795e48-2c52-4de5-bddb-59eab3df3a3d/cancel` |
| 6 | 07:24:11.980 | Response | http response | `200 ` |
| 7 | 07:24:11.980 | Send | http.send | `GET /api/v1/jobs/e0795e48-2c52-4de5-bddb-59eab3df3a3d` |
| 8 | 07:24:11.980 | Response | http response | `200 {"id":"e0795e48-2c52-4de5-bddb-59eab3df3a3d","project_id":"1ea3dbdc-04c8-4385-bc08-e0af42d6755a","description":"Cancel via dashboard","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"...` |

---

## new job is queued

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.983 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451983-rg4s1a","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.984 | Response | http response | `200 {"project_id":"538b4499-f4de-4270-b3e7-e25dbc6e5049"}` |
| 3 | 07:24:11.984 | Send | http.send | `POST /api/v1/jobs {"project_id":"538b4499-f4de-4270-b3e7-e25dbc6e5049","description":"State machine test"}` |
| 4 | 07:24:11.986 | Response | http response | `200 {"job_id":"28883e75-e3ac-4cf6-ad0c-8a807a37e721"}` |
| 5 | 07:24:11.986 | Send | http.send | `GET /api/v1/jobs/28883e75-e3ac-4cf6-ad0c-8a807a37e721` |
| 6 | 07:24:11.987 | Response | http response | `200 {"id":"28883e75-e3ac-4cf6-ad0c-8a807a37e721","project_id":"538b4499-f4de-4270-b3e7-e25dbc6e5049","description":"State machine test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error...` |

---

## running to paused

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:11.987 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451987-lvy605","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:11.989 | Response | http response | `200 {"project_id":"b8e08015-e523-448a-933b-0f79a50c3d8d"}` |
| 3 | 07:24:11.989 | Send | http.send | `POST /api/v1/jobs {"project_id":"b8e08015-e523-448a-933b-0f79a50c3d8d","description":"Pause test"}` |
| 4 | 07:24:11.991 | Response | http response | `200 {"job_id":"b4564146-7d23-4d6d-bb84-c576c41c0bee"}` |
| 5 | 07:24:11.991 | Send | http.send | `POST /api/v1/workers {"job_id":"b4564146-7d23-4d6d-bb84-c576c41c0bee","provider":"test"}` |
| 6 | 07:24:11.993 | Response | http response | `200 {"worker_id":"3cf12f7b-27f6-49d0-82ca-ac5d372c9a68"}` |
| 7 | 07:24:11.993 | Send | http.send | `POST /api/v1/workers/3cf12f7b-27f6-49d0-82ca-ac5d372c9a68/register {"job_id":"b4564146-7d23-4d6d-bb84-c576c41c0bee"}` |
| 8 | 07:24:11.996 | Response | http response | `200 ` |
| 9 | 07:24:11.996 | Send | http.send | `POST /api/v1/jobs/b4564146-7d23-4d6d-bb84-c576c41c0bee/pause` |
| 10 | 07:24:11.998 | Response | http response | `200 ` |
| 11 | 07:24:11.998 | Send | http.send | `GET /api/v1/jobs/b4564146-7d23-4d6d-bb84-c576c41c0bee` |
| 12 | 07:24:11.999 | Response | http response | `200 {"id":"b4564146-7d23-4d6d-bb84-c576c41c0bee","project_id":"b8e08015-e523-448a-933b-0f79a50c3d8d","description":"Pause test","status":"paused","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,"...` |

---

## paused to resuming

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.000 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743451999-md189k","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.001 | Response | http response | `200 {"project_id":"897c9c9b-9976-4b28-9b4b-716ee738b0e1"}` |
| 3 | 07:24:12.001 | Send | http.send | `POST /api/v1/jobs {"project_id":"897c9c9b-9976-4b28-9b4b-716ee738b0e1","description":"Resume test"}` |
| 4 | 07:24:12.004 | Response | http response | `200 {"job_id":"55cd625a-faa7-421f-97cc-7437354de6c2"}` |
| 5 | 07:24:12.004 | Send | http.send | `POST /api/v1/workers {"job_id":"55cd625a-faa7-421f-97cc-7437354de6c2","provider":"test"}` |
| 6 | 07:24:12.006 | Response | http response | `200 {"worker_id":"d9266f1c-4686-4b03-9dd4-8b3e0e7b3963"}` |
| 7 | 07:24:12.006 | Send | http.send | `POST /api/v1/workers/d9266f1c-4686-4b03-9dd4-8b3e0e7b3963/register {"job_id":"55cd625a-faa7-421f-97cc-7437354de6c2"}` |
| 8 | 07:24:12.010 | Response | http response | `200 ` |
| 9 | 07:24:12.010 | Send | http.send | `POST /api/v1/jobs/55cd625a-faa7-421f-97cc-7437354de6c2/pause` |
| 10 | 07:24:12.012 | Response | http response | `200 ` |
| 11 | 07:24:12.012 | Send | http.send | `POST /api/v1/jobs/55cd625a-faa7-421f-97cc-7437354de6c2/resume` |
| 12 | 07:24:12.014 | Response | http response | `200 ` |
| 13 | 07:24:12.014 | Send | http.send | `GET /api/v1/jobs/55cd625a-faa7-421f-97cc-7437354de6c2` |
| 14 | 07:24:12.014 | Response | http response | `200 {"id":"55cd625a-faa7-421f-97cc-7437354de6c2","project_id":"897c9c9b-9976-4b28-9b4b-716ee738b0e1","description":"Resume test","status":"resuming","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":nul...` |

---

## running to completed

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.014 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452014-37uxpz","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.016 | Response | http response | `200 {"project_id":"e6c26598-df4a-40ce-b0e5-86e26b572f40"}` |
| 3 | 07:24:12.016 | Send | http.send | `POST /api/v1/jobs {"project_id":"e6c26598-df4a-40ce-b0e5-86e26b572f40","description":"Complete test"}` |
| 4 | 07:24:12.018 | Response | http response | `200 {"job_id":"b8c1b4ca-d554-4859-9830-a7d65c7988f2"}` |
| 5 | 07:24:12.018 | Send | http.send | `POST /api/v1/workers {"job_id":"b8c1b4ca-d554-4859-9830-a7d65c7988f2","provider":"test"}` |
| 6 | 07:24:12.020 | Response | http response | `200 {"worker_id":"04f6ac96-76ff-41c4-bc83-58a84040441d"}` |
| 7 | 07:24:12.020 | Send | http.send | `POST /api/v1/workers/04f6ac96-76ff-41c4-bc83-58a84040441d/register {"job_id":"b8c1b4ca-d554-4859-9830-a7d65c7988f2"}` |
| 8 | 07:24:12.023 | Response | http response | `200 ` |
| 9 | 07:24:12.023 | Send | http.send | `POST /api/v1/workers/04f6ac96-76ff-41c4-bc83-58a84040441d/complete {"result":"success"}` |
| 10 | 07:24:12.026 | Response | http response | `200 ` |
| 11 | 07:24:12.026 | Send | http.send | `GET /api/v1/jobs/b8c1b4ca-d554-4859-9830-a7d65c7988f2` |
| 12 | 07:24:12.026 | Response | http response | `200 {"id":"b8c1b4ca-d554-4859-9830-a7d65c7988f2","project_id":"e6c26598-df4a-40ce-b0e5-86e26b572f40","description":"Complete test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","er...` |

---

## running to failed_retryable on first attempt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.027 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452027-3cr9we","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.028 | Response | http response | `200 {"project_id":"b1425ec8-bc16-4740-b394-05a088cd98da"}` |
| 3 | 07:24:12.028 | Send | http.send | `POST /api/v1/jobs {"project_id":"b1425ec8-bc16-4740-b394-05a088cd98da","description":"Fail test"}` |
| 4 | 07:24:12.029 | Response | http response | `200 {"job_id":"bfae9e80-e81e-43bf-abb3-68e88a11fd08"}` |
| 5 | 07:24:12.029 | Send | http.send | `POST /api/v1/workers {"job_id":"bfae9e80-e81e-43bf-abb3-68e88a11fd08","provider":"test"}` |
| 6 | 07:24:12.031 | Response | http response | `200 {"worker_id":"e26dade0-1879-4daf-abf5-7ba7dd8988b0"}` |
| 7 | 07:24:12.031 | Send | http.send | `POST /api/v1/workers/e26dade0-1879-4daf-abf5-7ba7dd8988b0/register {"job_id":"bfae9e80-e81e-43bf-abb3-68e88a11fd08"}` |
| 8 | 07:24:12.034 | Response | http response | `200 ` |
| 9 | 07:24:12.034 | Send | http.send | `POST /api/v1/workers/e26dade0-1879-4daf-abf5-7ba7dd8988b0/fail {"error":"transient failure"}` |
| 10 | 07:24:12.037 | Response | http response | `200 ` |
| 11 | 07:24:12.038 | Send | http.send | `GET /api/v1/jobs/bfae9e80-e81e-43bf-abb3-68e88a11fd08` |
| 12 | 07:24:12.038 | Response | http response | `200 {"id":"bfae9e80-e81e-43bf-abb3-68e88a11fd08","project_id":"b1425ec8-bc16-4740-b394-05a088cd98da","description":"Fail test","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"erro...` |

---

## cannot resume completed job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.038 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452038-ceki02","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.040 | Response | http response | `200 {"project_id":"83f4bf71-51b4-4fbb-a31e-996a16845d43"}` |
| 3 | 07:24:12.040 | Send | http.send | `POST /api/v1/jobs {"project_id":"83f4bf71-51b4-4fbb-a31e-996a16845d43","description":"Terminal test"}` |
| 4 | 07:24:12.041 | Response | http response | `200 {"job_id":"e3a13b40-8c15-4c84-96e3-1ed3ca016a3d"}` |
| 5 | 07:24:12.041 | Send | http.send | `POST /api/v1/workers {"job_id":"e3a13b40-8c15-4c84-96e3-1ed3ca016a3d","provider":"test"}` |
| 6 | 07:24:12.043 | Response | http response | `200 {"worker_id":"351555ca-0447-4882-a3b3-c10c40348bcd"}` |
| 7 | 07:24:12.043 | Send | http.send | `POST /api/v1/workers/351555ca-0447-4882-a3b3-c10c40348bcd/register {"job_id":"e3a13b40-8c15-4c84-96e3-1ed3ca016a3d"}` |
| 8 | 07:24:12.046 | Response | http response | `200 ` |
| 9 | 07:24:12.046 | Send | http.send | `POST /api/v1/workers/351555ca-0447-4882-a3b3-c10c40348bcd/complete {"result":"done"}` |
| 10 | 07:24:12.049 | Response | http response | `200 ` |
| 11 | 07:24:12.049 | Send | http.send | `POST /api/v1/jobs/e3a13b40-8c15-4c84-96e3-1ed3ca016a3d/resume` |
| 12 | 07:24:12.050 | Response | http response | `409 invalid transition: completed -> resuming` |

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.050 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452050-9jd4a6","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.052 | Response | http response | `200 {"project_id":"cd4ae229-2b4d-4995-b39c-98d2d07e4ba4"}` |
| 3 | 07:24:12.052 | Send | http.send | `POST /api/v1/jobs {"project_id":"cd4ae229-2b4d-4995-b39c-98d2d07e4ba4","description":"Cancel queued"}` |
| 4 | 07:24:12.053 | Response | http response | `200 {"job_id":"0c2ea6a5-667f-4c46-8114-27979d77b5bc"}` |
| 5 | 07:24:12.053 | Send | http.send | `POST /api/v1/jobs/0c2ea6a5-667f-4c46-8114-27979d77b5bc/cancel` |
| 6 | 07:24:12.055 | Response | http response | `200 ` |
| 7 | 07:24:12.055 | Send | http.send | `GET /api/v1/jobs/0c2ea6a5-667f-4c46-8114-27979d77b5bc` |
| 8 | 07:24:12.055 | Response | http response | `200 {"id":"0c2ea6a5-667f-4c46-8114-27979d77b5bc","project_id":"cd4ae229-2b4d-4995-b39c-98d2d07e4ba4","description":"Cancel queued","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":...` |

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.055 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452055-40zj2m","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.057 | Response | http response | `200 {"project_id":"40b31e3f-1897-432c-8bf8-a251d6a495fe"}` |
| 3 | 07:24:12.057 | Send | http.send | `POST /api/v1/jobs {"project_id":"40b31e3f-1897-432c-8bf8-a251d6a495fe","description":"Cancel running"}` |
| 4 | 07:24:12.058 | Response | http response | `200 {"job_id":"4a22a42c-5dd7-46b0-b373-6c44be510845"}` |
| 5 | 07:24:12.058 | Send | http.send | `POST /api/v1/workers {"job_id":"4a22a42c-5dd7-46b0-b373-6c44be510845","provider":"test"}` |
| 6 | 07:24:12.059 | Response | http response | `200 {"worker_id":"d6602380-3a13-4a25-8019-593937f417d8"}` |
| 7 | 07:24:12.059 | Send | http.send | `POST /api/v1/workers/d6602380-3a13-4a25-8019-593937f417d8/register {"job_id":"4a22a42c-5dd7-46b0-b373-6c44be510845"}` |
| 8 | 07:24:12.062 | Response | http response | `200 ` |
| 9 | 07:24:12.062 | Send | http.send | `POST /api/v1/jobs/4a22a42c-5dd7-46b0-b373-6c44be510845/cancel` |
| 10 | 07:24:12.064 | Response | http response | `200 ` |
| 11 | 07:24:12.064 | Send | http.send | `GET /api/v1/jobs/4a22a42c-5dd7-46b0-b373-6c44be510845` |
| 12 | 07:24:12.064 | Response | http response | `200 {"id":"4a22a42c-5dd7-46b0-b373-6c44be510845","project_id":"40b31e3f-1897-432c-8bf8-a251d6a495fe","description":"Cancel running","status":"cancelled","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error"...` |

---

## worker register sets job to running

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.066 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452066-o2kwqs","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.068 | Response | http response | `200 {"project_id":"609b710e-286f-49fa-9a44-d9cead0517a6"}` |
| 3 | 07:24:12.068 | Send | http.send | `POST /api/v1/jobs {"project_id":"609b710e-286f-49fa-9a44-d9cead0517a6","description":"E2E test job"}` |
| 4 | 07:24:12.069 | Response | http response | `200 {"job_id":"721c9647-a8f2-46fe-b2d9-29c2947ba3f0"}` |
| 5 | 07:24:12.069 | Send | http.send | `POST /api/v1/workers {"job_id":"721c9647-a8f2-46fe-b2d9-29c2947ba3f0","provider":"test"}` |
| 6 | 07:24:12.071 | Response | http response | `200 {"worker_id":"b14b90fb-fa86-4f79-8ef1-7af8c1e23ade"}` |
| 7 | 07:24:12.071 | Send | http.send | `POST /api/v1/workers/b14b90fb-fa86-4f79-8ef1-7af8c1e23ade/register {"job_id":"721c9647-a8f2-46fe-b2d9-29c2947ba3f0"}` |
| 8 | 07:24:12.074 | Response | http response | `200 ` |
| 9 | 07:24:12.074 | Send | http.send | `GET /api/v1/jobs/721c9647-a8f2-46fe-b2d9-29c2947ba3f0` |
| 10 | 07:24:12.074 | Response | http response | `200 {"id":"721c9647-a8f2-46fe-b2d9-29c2947ba3f0","project_id":"609b710e-286f-49fa-9a44-d9cead0517a6","description":"E2E test job","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":nul...` |

---

## worker heartbeat succeeds

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.075 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452075-z4o8x6","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.076 | Response | http response | `200 {"project_id":"0ab54aa5-7ffd-4efd-ab5a-326b9349bd1f"}` |
| 3 | 07:24:12.076 | Send | http.send | `POST /api/v1/jobs {"project_id":"0ab54aa5-7ffd-4efd-ab5a-326b9349bd1f","description":"E2E test job"}` |
| 4 | 07:24:12.078 | Response | http response | `200 {"job_id":"273b4982-16dd-40b5-9a33-0ab8ac936d56"}` |
| 5 | 07:24:12.078 | Send | http.send | `POST /api/v1/workers {"job_id":"273b4982-16dd-40b5-9a33-0ab8ac936d56","provider":"test"}` |
| 6 | 07:24:12.080 | Response | http response | `200 {"worker_id":"476875e3-5f39-4986-a213-99ce4707b780"}` |
| 7 | 07:24:12.080 | Send | http.send | `POST /api/v1/workers/476875e3-5f39-4986-a213-99ce4707b780/register {"job_id":"273b4982-16dd-40b5-9a33-0ab8ac936d56"}` |
| 8 | 07:24:12.083 | Response | http response | `200 ` |
| 9 | 07:24:12.083 | Send | http.send | `POST /api/v1/workers/476875e3-5f39-4986-a213-99ce4707b780/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":500,"completion_tokens":200},"files_changed":0,"tool_ca...` |
| 10 | 07:24:12.084 | Response | http response | `200 ` |

---

## worker checkpoint saves stage data

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.085 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452085-3gwvfx","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.086 | Response | http response | `200 {"project_id":"90906914-5bc2-4d6b-8001-0e5bc3afa031"}` |
| 3 | 07:24:12.087 | Send | http.send | `POST /api/v1/jobs {"project_id":"90906914-5bc2-4d6b-8001-0e5bc3afa031","description":"E2E test job"}` |
| 4 | 07:24:12.088 | Response | http response | `200 {"job_id":"85645d5d-6ff3-4f98-a1f2-46149f54de45"}` |
| 5 | 07:24:12.088 | Send | http.send | `POST /api/v1/workers {"job_id":"85645d5d-6ff3-4f98-a1f2-46149f54de45","provider":"test"}` |
| 6 | 07:24:12.090 | Response | http response | `200 {"worker_id":"12925754-0d89-48d4-af2e-371207ea3816"}` |
| 7 | 07:24:12.090 | Send | http.send | `POST /api/v1/workers/12925754-0d89-48d4-af2e-371207ea3816/register {"job_id":"85645d5d-6ff3-4f98-a1f2-46149f54de45"}` |
| 8 | 07:24:12.093 | Response | http response | `200 ` |
| 9 | 07:24:12.093 | Send | http.send | `POST /api/v1/workers/12925754-0d89-48d4-af2e-371207ea3816/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"def456","token_usage":{"prompt_...` |
| 10 | 07:24:12.095 | Response | http response | `200 ` |

---

## worker complete marks job completed

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.096 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452096-k6l9dc","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.097 | Response | http response | `200 {"project_id":"620ace58-9fbf-4cb7-9422-14f4e576ccfc"}` |
| 3 | 07:24:12.097 | Send | http.send | `POST /api/v1/jobs {"project_id":"620ace58-9fbf-4cb7-9422-14f4e576ccfc","description":"E2E test job"}` |
| 4 | 07:24:12.099 | Response | http response | `200 {"job_id":"1ea4ef70-73d6-4683-ab22-8a694876becb"}` |
| 5 | 07:24:12.099 | Send | http.send | `POST /api/v1/workers {"job_id":"1ea4ef70-73d6-4683-ab22-8a694876becb","provider":"test"}` |
| 6 | 07:24:12.100 | Response | http response | `200 {"worker_id":"338ac85b-1824-477e-94b1-71596939f0dc"}` |
| 7 | 07:24:12.100 | Send | http.send | `POST /api/v1/workers/338ac85b-1824-477e-94b1-71596939f0dc/register {"job_id":"1ea4ef70-73d6-4683-ab22-8a694876becb"}` |
| 8 | 07:24:12.102 | Response | http response | `200 ` |
| 9 | 07:24:12.103 | Send | http.send | `POST /api/v1/workers/338ac85b-1824-477e-94b1-71596939f0dc/complete {"result":"success"}` |
| 10 | 07:24:12.105 | Response | http response | `200 ` |
| 11 | 07:24:12.105 | Send | http.send | `GET /api/v1/jobs/1ea4ef70-73d6-4683-ab22-8a694876becb` |
| 12 | 07:24:12.105 | Response | http response | `200 {"id":"1ea4ef70-73d6-4683-ab22-8a694876becb","project_id":"620ace58-9fbf-4cb7-9422-14f4e576ccfc","description":"E2E test job","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"success","err...` |

---

## worker fail marks job failed_retryable on first attempt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.106 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452106-pepe6a","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.107 | Response | http response | `200 {"project_id":"cdebba08-3f8f-4de7-97a4-6e7daaf0931a"}` |
| 3 | 07:24:12.107 | Send | http.send | `POST /api/v1/jobs {"project_id":"cdebba08-3f8f-4de7-97a4-6e7daaf0931a","description":"E2E test job"}` |
| 4 | 07:24:12.108 | Response | http response | `200 {"job_id":"f49b77e1-1968-43a4-adfe-104a50c11d44"}` |
| 5 | 07:24:12.109 | Send | http.send | `POST /api/v1/workers {"job_id":"f49b77e1-1968-43a4-adfe-104a50c11d44","provider":"test"}` |
| 6 | 07:24:12.110 | Response | http response | `200 {"worker_id":"12bcd3b8-6673-4353-b299-654bc9996046"}` |
| 7 | 07:24:12.110 | Send | http.send | `POST /api/v1/workers/12bcd3b8-6673-4353-b299-654bc9996046/register {"job_id":"f49b77e1-1968-43a4-adfe-104a50c11d44"}` |
| 8 | 07:24:12.112 | Response | http response | `200 ` |
| 9 | 07:24:12.112 | Send | http.send | `POST /api/v1/workers/12bcd3b8-6673-4353-b299-654bc9996046/fail {"error":"build failed"}` |
| 10 | 07:24:12.115 | Response | http response | `200 ` |
| 11 | 07:24:12.115 | Send | http.send | `GET /api/v1/jobs/f49b77e1-1968-43a4-adfe-104a50c11d44` |
| 12 | 07:24:12.115 | Response | http response | `200 {"id":"f49b77e1-1968-43a4-adfe-104a50c11d44","project_id":"cdebba08-3f8f-4de7-97a4-6e7daaf0931a","description":"E2E test job","status":"failed_retryable","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"e...` |

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.116 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452116-jt0dpr","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.117 | Response | http response | `200 {"project_id":"b3bfeb96-6047-49a6-9636-6e44aba0e06f"}` |
| 3 | 07:24:12.117 | Send | http.send | `POST /api/v1/jobs {"project_id":"b3bfeb96-6047-49a6-9636-6e44aba0e06f","description":"E2E test job"}` |
| 4 | 07:24:12.118 | Response | http response | `200 {"job_id":"af9602f3-5675-464b-b283-1238f780d765"}` |
| 5 | 07:24:12.118 | Send | http.send | `POST /api/v1/workers {"job_id":"af9602f3-5675-464b-b283-1238f780d765","provider":"test"}` |
| 6 | 07:24:12.120 | Response | http response | `200 {"worker_id":"4f3df403-f895-46c9-bdf4-b5ae2080037d"}` |
| 7 | 07:24:12.120 | Send | http.send | `POST /api/v1/workers/4f3df403-f895-46c9-bdf4-b5ae2080037d/register {"job_id":"af9602f3-5675-464b-b283-1238f780d765"}` |
| 8 | 07:24:12.122 | Response | http response | `200 ` |
| 9 | 07:24:12.122 | Send | http.send | `GET /api/v1/jobs/af9602f3-5675-464b-b283-1238f780d765/config` |
| 10 | 07:24:12.122 | Response | http response | `200 {"job_id":"af9602f3-5675-464b-b283-1238f780d765","stage":"","prompt":"E2E test job","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","api...` |

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.123 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452123-z2mz1j","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.124 | Response | http response | `200 {"project_id":"081a4ad1-3ccd-4316-b2d9-d9a3ef638193"}` |
| 3 | 07:24:12.124 | Send | http.send | `POST /api/v1/jobs {"project_id":"081a4ad1-3ccd-4316-b2d9-d9a3ef638193","description":"E2E test job"}` |
| 4 | 07:24:12.125 | Response | http response | `200 {"job_id":"9686e49d-78dc-4770-8bbd-25a2692a9825"}` |
| 5 | 07:24:12.125 | Send | http.send | `POST /api/v1/workers {"job_id":"9686e49d-78dc-4770-8bbd-25a2692a9825","provider":"test"}` |
| 6 | 07:24:12.127 | Response | http response | `200 {"worker_id":"d41d1b05-03b0-467a-b7d6-6624f7df8938"}` |
| 7 | 07:24:12.127 | Send | http.send | `POST /api/v1/workers/d41d1b05-03b0-467a-b7d6-6624f7df8938/register {"job_id":"9686e49d-78dc-4770-8bbd-25a2692a9825"}` |
| 8 | 07:24:12.129 | Response | http response | `200 ` |
| 9 | 07:24:12.129 | Send | http.send | `GET /api/v1/jobs/9686e49d-78dc-4770-8bbd-25a2692a9825/skill/plan` |
| 10 | 07:24:12.129 | Response | http response | `200 {"content":"You are a senior software engineer tasked with creating an implementation plan.\n\n## Instructions\n\n- Explore the project structure first using glob and grep\n- Identify all files and modules relevant to the task\n- Produce a clear, step-by-step implementation plan\n- Estimate t...` |

---

## unknown worker returns 404

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.130 | Send | http.send | `POST /api/v1/workers/nonexistent-id/register {"job_id":"fake-job"}` |
| 2 | 07:24:12.130 | Response | http response | `404 worker not found` |

---

## creates project and retrieves it

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.131 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452131-zpmhu1","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.133 | Response | http response | `200 {"project_id":"351c8f69-9c18-42ea-a5ad-a80efa9305aa"}` |
| 3 | 07:24:12.133 | Send | http.send | `GET /api/v1/projects` |
| 4 | 07:24:12.133 | Response | http response | `200 [{"id":"de9d2494-442f-4f77-bf0f-f117ae64e2ee","repo_url":"https://github.com/test/e2e","branch":"main","created_at":"2026-05-14T07:17:31.439586174+00:00","updated_at":"2026-05-14T07:17:31.439586174+00:00"},{"id":"99592130-1904-4d05-94c8-f2813a388bf9","repo_url":"https://github.com/test/e2e","...` |

---

## creates job linked to project

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.134 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452134-07grdl","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.135 | Response | http response | `200 {"project_id":"5b36d17b-8baa-4a2e-b93e-97ea734f858c"}` |
| 3 | 07:24:12.135 | Send | http.send | `POST /api/v1/jobs {"project_id":"5b36d17b-8baa-4a2e-b93e-97ea734f858c","description":"DB test job"}` |
| 4 | 07:24:12.137 | Response | http response | `200 {"job_id":"1ef8b1e3-48c7-4de4-8158-820153eec002"}` |
| 5 | 07:24:12.137 | Send | http.send | `GET /api/v1/jobs/1ef8b1e3-48c7-4de4-8158-820153eec002` |
| 6 | 07:24:12.137 | Response | http response | `200 {"id":"1ef8b1e3-48c7-4de4-8158-820153eec002","project_id":"5b36d17b-8baa-4a2e-b93e-97ea734f858c","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null,...` |

---

## stores checkpoint for job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.137 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452137-0ap7uw","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.139 | Response | http response | `200 {"project_id":"2c5c9cbe-38a6-4fe6-b390-8fde4d6103f2"}` |
| 3 | 07:24:12.139 | Send | http.send | `POST /api/v1/jobs {"project_id":"2c5c9cbe-38a6-4fe6-b390-8fde4d6103f2","description":"Checkpoint test"}` |
| 4 | 07:24:12.140 | Response | http response | `200 {"job_id":"61a086a1-38b0-4eee-a063-c89c11462b3d"}` |
| 5 | 07:24:12.140 | Send | http.send | `POST /api/v1/workers {"job_id":"61a086a1-38b0-4eee-a063-c89c11462b3d","provider":"test"}` |
| 6 | 07:24:12.142 | Response | http response | `200 {"worker_id":"a7ad9501-985d-4996-bba4-2bc77f216ff1"}` |
| 7 | 07:24:12.142 | Send | http.send | `POST /api/v1/workers/a7ad9501-985d-4996-bba4-2bc77f216ff1/register {"job_id":"61a086a1-38b0-4eee-a063-c89c11462b3d"}` |
| 8 | 07:24:12.144 | Response | http response | `200 ` |
| 9 | 07:24:12.144 | Send | http.send | `POST /api/v1/workers/a7ad9501-985d-4996-bba4-2bc77f216ff1/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 10 | 07:24:12.147 | Response | http response | `200 ` |
| 11 | 07:24:12.147 | Send | http.send | `GET /api/v1/jobs/61a086a1-38b0-4eee-a063-c89c11462b3d` |
| 12 | 07:24:12.147 | Response | http response | `200 {"id":"61a086a1-38b0-4eee-a063-c89c11462b3d","project_id":"2c5c9cbe-38a6-4fe6-b390-8fde4d6103f2","description":"Checkpoint test","status":"running","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]","att...` |

---

## tracks worker heartbeat

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.147 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452147-p1p1cl","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.148 | Response | http response | `200 {"project_id":"83962304-27df-47f2-a517-bea91111e65c"}` |
| 3 | 07:24:12.148 | Send | http.send | `POST /api/v1/jobs {"project_id":"83962304-27df-47f2-a517-bea91111e65c","description":"Heartbeat test"}` |
| 4 | 07:24:12.150 | Response | http response | `200 {"job_id":"4dc1617b-a832-4d72-a9bd-b55d2c3123e1"}` |
| 5 | 07:24:12.150 | Send | http.send | `POST /api/v1/workers {"job_id":"4dc1617b-a832-4d72-a9bd-b55d2c3123e1","provider":"test"}` |
| 6 | 07:24:12.151 | Response | http response | `200 {"worker_id":"ddd3579f-293b-416b-a4c1-dbb6d418614f"}` |
| 7 | 07:24:12.151 | Send | http.send | `POST /api/v1/workers/ddd3579f-293b-416b-a4c1-dbb6d418614f/register {"job_id":"4dc1617b-a832-4d72-a9bd-b55d2c3123e1"}` |
| 8 | 07:24:12.154 | Response | http response | `200 ` |
| 9 | 07:24:12.154 | Send | http.send | `POST /api/v1/workers/ddd3579f-293b-416b-a4c1-dbb6d418614f/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 10 | 07:24:12.155 | Response | http response | `200 ` |

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.156 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452156-rlkiuk","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.157 | Response | http response | `200 {"project_id":"d17fe694-be63-410d-9ce0-0900c69e2c3f"}` |
| 3 | 07:24:12.157 | Send | http.send | `POST /api/v1/jobs {"project_id":"d17fe694-be63-410d-9ce0-0900c69e2c3f","description":"Hello world test","workflow":"hello-world"}` |
| 4 | 07:24:12.159 | Response | http response | `200 {"job_id":"b3f3e986-5a5b-4df8-a195-93f3586f20ea"}` |

---

## creates a job with hello-world workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.159 | Send | http.send | `GET /api/v1/jobs/b3f3e986-5a5b-4df8-a195-93f3586f20ea` |
| 2 | 07:24:12.159 | Response | http response | `200 {"id":"b3f3e986-5a5b-4df8-a195-93f3586f20ea","project_id":"d17fe694-be63-410d-9ce0-0900c69e2c3f","description":"Hello world test","status":"queued","worker_id":null,"branch":null,"workflow_name":"hello-world","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null...` |

---

## job config returns resolved workflow stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.159 | Send | http.send | `GET /api/v1/jobs/b3f3e986-5a5b-4df8-a195-93f3586f20ea/config` |
| 2 | 07:24:12.160 | Response | http response | `200 {"job_id":"b3f3e986-5a5b-4df8-a195-93f3586f20ea","stage":"","prompt":"Hello world test","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

## create project → create job → register worker → complete

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.161 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743452161-ivg42l","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:12.162 | Response | http response | `200 {"project_id":"f0d17172-391b-4bca-8109-04ae561f5f2d"}` |
| 3 | 07:24:12.162 | Send | http.send | `POST /api/v1/jobs {"project_id":"f0d17172-391b-4bca-8109-04ae561f5f2d","description":"Full lifecycle test"}` |
| 4 | 07:24:12.163 | Response | http response | `200 {"job_id":"5b700fd1-e2e8-4089-ab97-483b750e6b72"}` |
| 5 | 07:24:12.163 | Send | http.send | `GET /api/v1/jobs/5b700fd1-e2e8-4089-ab97-483b750e6b72` |
| 6 | 07:24:12.164 | Response | http response | `200 {"id":"5b700fd1-e2e8-4089-ab97-483b750e6b72","project_id":"f0d17172-391b-4bca-8109-04ae561f5f2d","description":"Full lifecycle test","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"erro...` |
| 7 | 07:24:12.164 | Send | http.send | `POST /api/v1/workers {"job_id":"5b700fd1-e2e8-4089-ab97-483b750e6b72","provider":"test"}` |
| 8 | 07:24:12.165 | Response | http response | `200 {"worker_id":"849bfc0d-575a-4519-957c-ea978396da57"}` |
| 9 | 07:24:12.165 | Send | http.send | `POST /api/v1/workers/849bfc0d-575a-4519-957c-ea978396da57/register {"job_id":"5b700fd1-e2e8-4089-ab97-483b750e6b72"}` |
| 10 | 07:24:12.167 | Response | http response | `200 ` |
| 11 | 07:24:12.167 | Send | http.send | `POST /api/v1/workers/849bfc0d-575a-4519-957c-ea978396da57/heartbeat {"status":"running","current_stage":"plan","token_usage":{"prompt_tokens":100,"completion_tokens":50},"files_changed":0,"tool_cal...` |
| 12 | 07:24:12.169 | Response | http response | `200 ` |
| 13 | 07:24:12.169 | Send | http.send | `POST /api/v1/workers/849bfc0d-575a-4519-957c-ea978396da57/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/workspace/.codery/session.json","git_sha":"abc123","token_us...` |
| 14 | 07:24:12.171 | Response | http response | `200 ` |
| 15 | 07:24:12.171 | Send | http.send | `POST /api/v1/workers/849bfc0d-575a-4519-957c-ea978396da57/complete {"result":"Job completed successfully"}` |
| 16 | 07:24:12.174 | Response | http response | `200 ` |
| 17 | 07:24:12.174 | Send | http.send | `GET /api/v1/jobs/5b700fd1-e2e8-4089-ab97-483b750e6b72` |
| 18 | 07:24:12.174 | Response | http response | `200 {"id":"5b700fd1-e2e8-4089-ab97-483b750e6b72","project_id":"f0d17172-391b-4bca-8109-04ae561f5f2d","description":"Full lifecycle test","status":"completed","worker_id":null,"branch":null,"workflow_name":null,"current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"}]...` |

---

## lists jobs and workers

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.174 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 07:24:12.176 | Response | http response | `200 [{"id":"d13bb9f9-5c45-4a53-8e56-cca338cfb2ba","project_id":"99592130-1904-4d05-94c8-f2813a388bf9","description":"DB test job","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"error":null...` |
| 3 | 07:24:12.176 | Send | http.send | `GET /api/v1/workers` |
| 4 | 07:24:12.177 | Response | http response | `200 [{"id":"9b1abb6e-707a-4d66-b48f-cc51f4070de1","job_id":"b74c82f6-5314-444d-8094-953348bfff39","provider":"test","provider_id":null,"status":"running","ip_address":null,"workspace_path":null,"heartbeat_at":null,"created_at":"2026-05-14T07:17:31.453953553+00:00","destroyed_at":null},{"id":"639f...` |

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.177 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 07:24:12.178 | Response | http response | `200 {"name":"test","stages":1,"valid":true}` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:12.178 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 07:24:12.178 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## routes based on string equality in response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.715 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482715-3pfedr","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.719 | Response | http response | `200 {"project_id":"1732cbf2-3ad9-4bc3-908f-5420195b7fc8"}` |
| 3 | 07:24:42.719 | Send | http.send | `POST /api/v1/jobs {"project_id":"1732cbf2-3ad9-4bc3-908f-5420195b7fc8","description":"Build feature","workflow":"feature"}` |
| 4 | 07:24:42.725 | Response | http response | `200 {"job_id":"f5285eba-e9bc-4a4a-ae45-a74a038bc185"}` |
| 5 | 07:24:42.725 | Send | http.send | `POST /api/v1/workers {"job_id":"f5285eba-e9bc-4a4a-ae45-a74a038bc185","provider":"test"}` |
| 6 | 07:24:42.728 | Response | http response | `200 {"worker_id":"2e828d03-c044-4ac7-811a-379692f4f171"}` |
| 7 | 07:24:42.728 | Send | http.send | `POST /api/v1/workers/2e828d03-c044-4ac7-811a-379692f4f171/register {"job_id":"f5285eba-e9bc-4a4a-ae45-a74a038bc185"}` |
| 8 | 07:24:42.731 | Response | http response | `200 ` |
| 9 | 07:24:42.731 | Send | http.send | `POST /api/v1/workers/2e828d03-c044-4ac7-811a-379692f4f171/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 10 | 07:24:42.733 | Response | http response | `200 ` |
| 11 | 07:24:42.733 | Send | http.send | `GET /api/v1/jobs/f5285eba-e9bc-4a4a-ae45-a74a038bc185` |
| 12 | 07:24:42.734 | Response | http response | `200 {"id":"f5285eba-e9bc-4a4a-ae45-a74a038bc185","project_id":"1732cbf2-3ad9-4bc3-908f-5420195b7fc8","description":"Build feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"...` |

---

## routes to plan_detail on complex response

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.734 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482734-m6loz0","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.736 | Response | http response | `200 {"project_id":"f94b7e66-77a2-4eb7-b722-78ebfda00156"}` |
| 3 | 07:24:42.736 | Send | http.send | `POST /api/v1/jobs {"project_id":"f94b7e66-77a2-4eb7-b722-78ebfda00156","description":"Complex feature","workflow":"feature"}` |
| 4 | 07:24:42.737 | Response | http response | `200 {"job_id":"4bd7dae7-e21b-4c06-a8dc-551c14a20e34"}` |
| 5 | 07:24:42.737 | Send | http.send | `POST /api/v1/workers {"job_id":"4bd7dae7-e21b-4c06-a8dc-551c14a20e34","provider":"test"}` |
| 6 | 07:24:42.739 | Response | http response | `200 {"worker_id":"61e42823-d19f-49e5-b119-d4eb7bfe5dcc"}` |
| 7 | 07:24:42.739 | Send | http.send | `POST /api/v1/workers/61e42823-d19f-49e5-b119-d4eb7bfe5dcc/register {"job_id":"4bd7dae7-e21b-4c06-a8dc-551c14a20e34"}` |
| 8 | 07:24:42.742 | Response | http response | `200 ` |
| 9 | 07:24:42.742 | Send | http.send | `POST /api/v1/workers/61e42823-d19f-49e5-b119-d4eb7bfe5dcc/checkpoint {"stage":"plan","response":{"complexity":"complex"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt...` |
| 10 | 07:24:42.745 | Response | http response | `200 ` |
| 11 | 07:24:42.745 | Send | http.send | `GET /api/v1/jobs/4bd7dae7-e21b-4c06-a8dc-551c14a20e34` |
| 12 | 07:24:42.745 | Response | http response | `200 {"id":"4bd7dae7-e21b-4c06-a8dc-551c14a20e34","project_id":"f94b7e66-77a2-4eb7-b722-78ebfda00156","description":"Complex feature","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"plan_detail","stage_history":"[{\"stage\":\"plan\",\"status\":\"complet...` |

---

## completes workflow when routes is null

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.746 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482746-rbhbow","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.747 | Response | http response | `200 {"project_id":"76c07037-e1ef-448f-a330-048c19e225e6"}` |
| 3 | 07:24:42.747 | Send | http.send | `POST /api/v1/jobs {"project_id":"76c07037-e1ef-448f-a330-048c19e225e6","description":"Simple task","workflow":"simple"}` |
| 4 | 07:24:42.748 | Response | http response | `200 {"job_id":"5e9100e8-a513-4185-abff-a7cedade6719"}` |
| 5 | 07:24:42.748 | Send | http.send | `POST /api/v1/workers {"job_id":"5e9100e8-a513-4185-abff-a7cedade6719","provider":"test"}` |
| 6 | 07:24:42.750 | Response | http response | `200 {"worker_id":"bc569679-e81f-49da-b6d0-457c21a192d7"}` |
| 7 | 07:24:42.750 | Send | http.send | `POST /api/v1/workers/bc569679-e81f-49da-b6d0-457c21a192d7/register {"job_id":"5e9100e8-a513-4185-abff-a7cedade6719"}` |
| 8 | 07:24:42.752 | Response | http response | `200 ` |
| 9 | 07:24:42.752 | Send | http.send | `POST /api/v1/workers/bc569679-e81f-49da-b6d0-457c21a192d7/complete {"result":"done"}` |
| 10 | 07:24:42.754 | Response | http response | `200 ` |
| 11 | 07:24:42.754 | Send | http.send | `GET /api/v1/jobs/5e9100e8-a513-4185-abff-a7cedade6719` |
| 12 | 07:24:42.755 | Response | http response | `200 {"id":"5e9100e8-a513-4185-abff-a7cedade6719","project_id":"76c07037-e1ef-448f-a330-048c19e225e6","description":"Simple task","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"done","err...` |

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.755 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 07:24:42.755 | Response | http response | `200 {"name":"numeric-route","stages":3,"valid":true}` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.757 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 07:24:42.757 | Response | http response | `200 {"name":"simple","stages":2,"valid":true}` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.758 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 07:24:42.758 | Response | http response | `200 {"error":"workflow needs at least one stage","valid":false}` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.758 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 07:24:42.759 | Response | http response | `200 {"name":"minimal","stages":1,"valid":true}` |

---

## new job starts at first stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.761 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482761-hnlm7c","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.763 | Response | http response | `200 {"project_id":"4fcc3f47-6b13-46d8-8b87-2b30dd898ac8"}` |
| 3 | 07:24:42.763 | Send | http.send | `POST /api/v1/jobs {"project_id":"4fcc3f47-6b13-46d8-8b87-2b30dd898ac8","description":"Start at first stage"}` |
| 4 | 07:24:42.765 | Response | http response | `200 {"job_id":"0e9eff56-d74c-4605-b15a-fb0bac96043e"}` |
| 5 | 07:24:42.765 | Send | http.send | `GET /api/v1/jobs/0e9eff56-d74c-4605-b15a-fb0bac96043e` |
| 6 | 07:24:42.765 | Response | http response | `200 {"id":"0e9eff56-d74c-4605-b15a-fb0bac96043e","project_id":"4fcc3f47-6b13-46d8-8b87-2b30dd898ac8","description":"Start at first stage","status":"queued","worker_id":null,"branch":null,"workflow_name":null,"current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":null,"err...` |

---

## checkpoint advances to next stage

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.766 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482766-7pqccf","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.768 | Response | http response | `200 {"project_id":"5c23bd3e-cfde-4a1c-8672-a7562cbe1f68"}` |
| 3 | 07:24:42.768 | Send | http.send | `POST /api/v1/jobs {"project_id":"5c23bd3e-cfde-4a1c-8672-a7562cbe1f68","description":"Advance stages","workflow":"feature"}` |
| 4 | 07:24:42.769 | Response | http response | `200 {"job_id":"cbb71529-ae6d-4acd-8888-60eada54e2c0"}` |
| 5 | 07:24:42.769 | Send | http.send | `POST /api/v1/workers {"job_id":"cbb71529-ae6d-4acd-8888-60eada54e2c0","provider":"test"}` |
| 6 | 07:24:42.771 | Response | http response | `200 {"worker_id":"b414d7a9-bad8-44c7-8854-005974d86d4f"}` |
| 7 | 07:24:42.771 | Send | http.send | `POST /api/v1/workers/b414d7a9-bad8-44c7-8854-005974d86d4f/register {"job_id":"cbb71529-ae6d-4acd-8888-60eada54e2c0"}` |
| 8 | 07:24:42.774 | Response | http response | `200 ` |
| 9 | 07:24:42.774 | Send | http.send | `POST /api/v1/workers/b414d7a9-bad8-44c7-8854-005974d86d4f/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/session.json","git_sha":"abc123","token_usage":{"prompt_...` |
| 10 | 07:24:42.778 | Response | http response | `200 ` |
| 11 | 07:24:42.778 | Send | http.send | `GET /api/v1/jobs/cbb71529-ae6d-4acd-8888-60eada54e2c0` |
| 12 | 07:24:42.779 | Response | http response | `200 {"id":"cbb71529-ae6d-4acd-8888-60eada54e2c0","project_id":"5c23bd3e-cfde-4a1c-8672-a7562cbe1f68","description":"Advance stages","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"implement","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\...` |

---

## multi-stage progression through feature workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.779 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482779-4ogrsl","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.781 | Response | http response | `200 {"project_id":"46e18003-079c-4ef8-8e2f-a49def3599f8"}` |
| 3 | 07:24:42.782 | Send | http.send | `POST /api/v1/jobs {"project_id":"46e18003-079c-4ef8-8e2f-a49def3599f8","description":"Multi-stage","workflow":"feature"}` |
| 4 | 07:24:42.784 | Response | http response | `200 {"job_id":"2464e41c-60ac-41e4-8759-92b27fff23c3"}` |
| 5 | 07:24:42.784 | Send | http.send | `POST /api/v1/workers {"job_id":"2464e41c-60ac-41e4-8759-92b27fff23c3","provider":"test"}` |
| 6 | 07:24:42.786 | Response | http response | `200 {"worker_id":"caf1dc2c-ed01-4eed-81b0-de12a9607e9d"}` |
| 7 | 07:24:42.786 | Send | http.send | `POST /api/v1/workers/caf1dc2c-ed01-4eed-81b0-de12a9607e9d/register {"job_id":"2464e41c-60ac-41e4-8759-92b27fff23c3"}` |
| 8 | 07:24:42.789 | Response | http response | `200 ` |
| 9 | 07:24:42.789 | Send | http.send | `POST /api/v1/workers/caf1dc2c-ed01-4eed-81b0-de12a9607e9d/checkpoint {"stage":"plan","response":{"complexity":"simple"},"session_path":"/tmp/s1.json","git_sha":"aaa111","token_usage":{"prompt_token...` |
| 10 | 07:24:42.792 | Response | http response | `200 ` |
| 11 | 07:24:42.792 | Send | http.send | `POST /api/v1/workers/caf1dc2c-ed01-4eed-81b0-de12a9607e9d/checkpoint {"stage":"implement","response":{"success":true},"session_path":"/tmp/s2.json","git_sha":"bbb222","token_usage":{"prompt_tokens"...` |
| 12 | 07:24:42.795 | Response | http response | `200 ` |
| 13 | 07:24:42.795 | Send | http.send | `GET /api/v1/jobs/2464e41c-60ac-41e4-8759-92b27fff23c3` |
| 14 | 07:24:42.795 | Response | http response | `200 {"id":"2464e41c-60ac-41e4-8759-92b27fff23c3","project_id":"46e18003-079c-4ef8-8e2f-a49def3599f8","description":"Multi-stage","status":"running","worker_id":null,"branch":null,"workflow_name":"feature","current_stage":"done","stage_history":"[{\"stage\":\"plan\",\"status\":\"completed\"},{\"st...` |

---

## complete finishes the job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.796 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482796-qy3dj0","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.798 | Response | http response | `200 {"project_id":"12dbac1f-28ad-4a2d-bea2-cfa74cecd7e5"}` |
| 3 | 07:24:42.798 | Send | http.send | `POST /api/v1/jobs {"project_id":"12dbac1f-28ad-4a2d-bea2-cfa74cecd7e5","description":"Complete workflow","workflow":"simple"}` |
| 4 | 07:24:42.800 | Response | http response | `200 {"job_id":"a2752e3d-7fc7-4984-8a75-43de3b87adef"}` |
| 5 | 07:24:42.800 | Send | http.send | `POST /api/v1/workers {"job_id":"a2752e3d-7fc7-4984-8a75-43de3b87adef","provider":"test"}` |
| 6 | 07:24:42.802 | Response | http response | `200 {"worker_id":"7ff02fa1-7fe1-40be-8c4e-fd09c6fa5115"}` |
| 7 | 07:24:42.802 | Send | http.send | `POST /api/v1/workers/7ff02fa1-7fe1-40be-8c4e-fd09c6fa5115/register {"job_id":"a2752e3d-7fc7-4984-8a75-43de3b87adef"}` |
| 8 | 07:24:42.805 | Response | http response | `200 ` |
| 9 | 07:24:42.805 | Send | http.send | `POST /api/v1/workers/7ff02fa1-7fe1-40be-8c4e-fd09c6fa5115/complete {"result":"all done"}` |
| 10 | 07:24:42.808 | Response | http response | `200 ` |
| 11 | 07:24:42.808 | Send | http.send | `GET /api/v1/jobs/a2752e3d-7fc7-4984-8a75-43de3b87adef` |
| 12 | 07:24:42.808 | Response | http response | `200 {"id":"a2752e3d-7fc7-4984-8a75-43de3b87adef","project_id":"12dbac1f-28ad-4a2d-bea2-cfa74cecd7e5","description":"Complete workflow","status":"completed","worker_id":null,"branch":null,"workflow_name":"simple","current_stage":null,"stage_history":"[]","attempt":1,"max_attempts":3,"result":"all ...` |

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.811 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482811-w6p9dk","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.813 | Response | http response | `200 {"project_id":"9d37b048-b355-4738-824b-8e009ad921ec"}` |
| 3 | 07:24:42.813 | Send | http.send | `POST /api/v1/jobs {"project_id":"9d37b048-b355-4738-824b-8e009ad921ec","description":"Add a hello world function","workflow":"simple"}` |
| 4 | 07:24:42.815 | Response | http response | `200 {"job_id":"890ec9f1-4bd7-4fe4-baf7-636068c9b6ce"}` |
| 5 | 07:24:42.815 | Send | http.send | `GET /api/v1/jobs/890ec9f1-4bd7-4fe4-baf7-636068c9b6ce/config` |
| 6 | 07:24:42.815 | Response | http response | `200 {"job_id":"890ec9f1-4bd7-4fe4-baf7-636068c9b6ce","stage":"","prompt":"Add a hello world function","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepsee...` |

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.816 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482816-pt2cqm","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.817 | Response | http response | `200 {"project_id":"b26999b9-d5b2-407b-a342-1f3178ec714e"}` |
| 3 | 07:24:42.817 | Send | http.send | `POST /api/v1/jobs {"project_id":"b26999b9-d5b2-407b-a342-1f3178ec714e","description":"Build feature X","workflow":"feature"}` |
| 4 | 07:24:42.819 | Response | http response | `200 {"job_id":"d67296da-ea09-4f8f-8498-0ffe7fad105f"}` |
| 5 | 07:24:42.819 | Send | http.send | `GET /api/v1/jobs/d67296da-ea09-4f8f-8498-0ffe7fad105f/config` |
| 6 | 07:24:42.820 | Response | http response | `200 {"job_id":"d67296da-ea09-4f8f-8498-0ffe7fad105f","stage":"","prompt":"Build feature X","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1","...` |

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 07:24:42.820 | Send | http.send | `POST /api/v1/projects {"name":"test-1778743482820-fda1b4","repo_url":"https://github.com/test/e2e"}` |
| 2 | 07:24:42.822 | Response | http response | `200 {"project_id":"567c1ce0-9d9f-425b-83b7-1f8f099c53f9"}` |
| 3 | 07:24:42.822 | Send | http.send | `POST /api/v1/jobs {"project_id":"567c1ce0-9d9f-425b-83b7-1f8f099c53f9","description":"Plan the feature","workflow":"simple"}` |
| 4 | 07:24:42.824 | Response | http response | `200 {"job_id":"50217f1d-4246-4f20-8b17-5dda342718ea"}` |
| 5 | 07:24:42.824 | Send | http.send | `GET /api/v1/jobs/50217f1d-4246-4f20-8b17-5dda342718ea/config` |
| 6 | 07:24:42.824 | Response | http response | `200 {"job_id":"50217f1d-4246-4f20-8b17-5dda342718ea","stage":"","prompt":"Plan the feature","tools":["bash","read","write","edit","glob","grep"],"max_tokens":8096,"timeout_secs":600,"skill_content":"","model":"deepseek-chat","provider":"openai-compatible","base_url":"https://api.deepseek.com/v1",...` |

---

