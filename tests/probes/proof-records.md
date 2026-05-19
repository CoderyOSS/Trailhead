# Trailhead E2E Test Suite

**Date:** 2026-05-19T19:18:58.776Z
**Events:** 182
**Duration:** 3157ms

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:55.620 | Recv | sql:unknown | `{"changes":"batch"}` |
| 2 | 19:18:58.635 | Recv | sql:sqlite_master | `[{"name":"projects"},{"name":"jobs"},{"name":"workers"},{"name":"checkpoints"},{"name":"prompt_history"},{"name":"workflows"}]` |
| 3 | 19:18:58.636 | Recv | sql:projects | `{"changes":"batch"}` |
| 4 | 19:18:58.638 | Recv | sql:jobs | `{"changes":"batch"}` |
| 5 | 19:18:58.639 | Recv | sql:workers | `{"changes":"batch"}` |
| 6 | 19:18:58.640 | Recv | sql:checkpoints | `{"changes":"batch"}` |
| 7 | 19:18:58.641 | Recv | sql:prompt_history | `{"changes":"batch"}` |
| 8 | 19:18:58.642 | Recv | sql:workflows | `{"changes":"batch"}` |
| 9 | 19:18:58.642 | Send | sql.clear | `all tables` |
| 10 | 19:18:58.658 | Recv | sql:sqlite_master | `{"name":"workflows"}` |
| 11 | 19:18:58.659 | Recv | sql:workflows | `{"changes":1,"lastInsertRowid":1}` |
| 12 | 19:18:58.659 | Recv | sql:workflows | `{"changes":1,"lastInsertRowid":2}` |
| 13 | 19:18:58.661 | Send | sql.fixture | `2 rows` |
| 14 | 19:18:58.671 | Recv | sql:sqlite_master | `[{"name":"projects"},{"name":"jobs"},{"name":"workers"},{"name":"checkpoints"},{"name":"prompt_history"},{"name":"workflows"}]` |
| 15 | 19:18:58.672 | Recv | sql:projects | `{"changes":"batch"}` |
| 16 | 19:18:58.674 | Recv | sql:jobs | `{"changes":"batch"}` |
| 17 | 19:18:58.675 | Recv | sql:workers | `{"changes":"batch"}` |
| 18 | 19:18:58.676 | Recv | sql:checkpoints | `{"changes":"batch"}` |
| 19 | 19:18:58.677 | Recv | sql:prompt_history | `{"changes":"batch"}` |
| 20 | 19:18:58.678 | Recv | sql:workflows | `{"changes":"batch"}` |
| 21 | 19:18:58.678 | Send | sql.clear | `all tables` |
| 22 | 19:18:58.686 | Recv | sql:sqlite_master | `{"name":"workflows"}` |
| 23 | 19:18:58.686 | Recv | sql:workflows | `{"changes":1,"lastInsertRowid":1}` |
| 24 | 19:18:58.686 | Recv | sql:workflows | `{"changes":1,"lastInsertRowid":2}` |
| 25 | 19:18:58.687 | Send | sql.fixture | `2 rows` |
| 26 | 19:18:58.752 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 27 | 19:18:58.752 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":17}` |
| 28 | 19:18:58.753 | Send | sql.fixture | `1 rows` |
| 29 | 19:18:58.753 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338752-1e5qhr","description":"Hello world test"}` |
| 30 | 19:18:58.753 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:unknown</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>2. Recv sql:sqlite_master</summary>

```json
[
  {
    "name": "projects"
  },
  {
    "name": "jobs"
  },
  {
    "name": "workers"
  },
  {
    "name": "checkpoints"
  },
  {
    "name": "prompt_history"
  },
  {
    "name": "workflows"
  }
]
```

</details>

<details><summary>3. Recv sql:projects</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>4. Recv sql:jobs</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>5. Recv sql:workers</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>6. Recv sql:checkpoints</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>7. Recv sql:prompt_history</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>8. Recv sql:workflows</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>10. Recv sql:sqlite_master</summary>

```json
{
  "name": "workflows"
}
```

</details>

<details><summary>11. Recv sql:workflows</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 1
}
```

</details>

<details><summary>12. Recv sql:workflows</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 2
}
```

</details>

<details><summary>14. Recv sql:sqlite_master</summary>

```json
[
  {
    "name": "projects"
  },
  {
    "name": "jobs"
  },
  {
    "name": "workers"
  },
  {
    "name": "checkpoints"
  },
  {
    "name": "prompt_history"
  },
  {
    "name": "workflows"
  }
]
```

</details>

<details><summary>15. Recv sql:projects</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>16. Recv sql:jobs</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>17. Recv sql:workers</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>18. Recv sql:checkpoints</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>19. Recv sql:prompt_history</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>20. Recv sql:workflows</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>22. Recv sql:sqlite_master</summary>

```json
{
  "name": "workflows"
}
```

</details>

<details><summary>23. Recv sql:workflows</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 1
}
```

</details>

<details><summary>24. Recv sql:workflows</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 2
}
```

</details>

<details><summary>26. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>27. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 17
}
```

</details>

---

## lists jobs via HTTP matching DB count

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.662 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.662 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":1}` |
| 3 | 19:18:58.663 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.664 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338662-xebrvj","description":"Job 1"}` |
| 5 | 19:18:58.670 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 1
}
```

</details>

---

## list workers via HTTP matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.688 | Send | http.send | `GET /api/v1/workers` |
| 2 | 19:18:58.689 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## GET /api/v1/jobs returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.694 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.694 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":1}` |
| 3 | 19:18:58.695 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.695 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338694-vp0egd","description":"Dashboard test job"}` |
| 5 | 19:18:58.696 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 1
}
```

</details>

---

## GET /api/v1/jobs/{id} returns detail matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.696 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.696 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":2}` |
| 3 | 19:18:58.698 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.698 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338696-y6miym","description":"Detail test"}` |
| 5 | 19:18:58.698 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 2
}
```

</details>

---

## GET /api/v1/workers returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.698 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.699 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":3}` |
| 3 | 19:18:58.700 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.700 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338698-ylsvss","description":"Worker list test"}` |
| 5 | 19:18:58.700 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 3
}
```

</details>

---

## POST /api/v1/jobs/{id}/cancel changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.701 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.701 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":4}` |
| 3 | 19:18:58.702 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.702 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338700-cpexdm","description":"Cancel via dashboard"}` |
| 5 | 19:18:58.702 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 4
}
```

</details>

---

## new job is queued in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.704 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.705 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":5}` |
| 3 | 19:18:58.706 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.706 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338703-9ikk5l","description":"State machine test"}` |
| 5 | 19:18:58.710 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |
| 6 | 19:18:58.764 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 7 | 19:18:58.764 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":19}` |
| 8 | 19:18:58.765 | Send | sql.fixture | `1 rows` |
| 9 | 19:18:58.765 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338764-9nwoiw","description":"Start at first stage"}` |
| 10 | 19:18:58.766 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 5
}
```

</details>

<details><summary>6. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>7. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 19
}
```

</details>

---

## running to paused via HTTP

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.711 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.711 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":6}` |
| 3 | 19:18:58.712 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.712 | Recv | sql:sqlite_master | `{"name":"jobs"}` |
| 5 | 19:18:58.713 | Recv | sql:jobs | `{"changes":1,"lastInsertRowid":1}` |
| 6 | 19:18:58.714 | Send | sql.fixture | `1 rows` |
| 7 | 19:18:58.714 | Send | http.send | `POST /api/v1/jobs/test-1779218338712-ege7ts/pause` |
| 8 | 19:18:58.714 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 6
}
```

</details>

<details><summary>4. Recv sql:sqlite_master</summary>

```json
{
  "name": "jobs"
}
```

</details>

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 1
}
```

</details>

---

## paused to resuming via HTTP

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.715 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.715 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":7}` |
| 3 | 19:18:58.716 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.716 | Recv | sql:sqlite_master | `{"name":"jobs"}` |
| 5 | 19:18:58.716 | Recv | sql:jobs | `{"changes":1,"lastInsertRowid":2}` |
| 6 | 19:18:58.718 | Send | sql.fixture | `1 rows` |
| 7 | 19:18:58.718 | Send | http.send | `POST /api/v1/jobs/test-1779218338716-72colh/resume` |
| 8 | 19:18:58.718 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 7
}
```

</details>

<details><summary>4. Recv sql:sqlite_master</summary>

```json
{
  "name": "jobs"
}
```

</details>

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 2
}
```

</details>

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.718 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.719 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":8}` |
| 3 | 19:18:58.720 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.720 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338718-sx235n","description":"Cancel queued"}` |
| 5 | 19:18:58.720 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 8
}
```

</details>

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.721 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.721 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":9}` |
| 3 | 19:18:58.722 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.722 | Recv | sql:sqlite_master | `{"name":"jobs"}` |
| 5 | 19:18:58.722 | Recv | sql:jobs | `{"changes":1,"lastInsertRowid":3}` |
| 6 | 19:18:58.726 | Send | sql.fixture | `1 rows` |
| 7 | 19:18:58.726 | Send | http.send | `POST /api/v1/jobs/test-1779218338722-rihbxo/cancel` |
| 8 | 19:18:58.726 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 9
}
```

</details>

<details><summary>4. Recv sql:sqlite_master</summary>

```json
{
  "name": "jobs"
}
```

</details>

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 3
}
```

</details>

---

## cannot resume cancelled job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.726 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.727 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":10}` |
| 3 | 19:18:58.728 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.728 | Recv | sql:sqlite_master | `{"name":"jobs"}` |
| 5 | 19:18:58.728 | Recv | sql:jobs | `{"changes":1,"lastInsertRowid":4}` |
| 6 | 19:18:58.729 | Send | sql.fixture | `1 rows` |
| 7 | 19:18:58.729 | Send | http.send | `POST /api/v1/jobs/test-1779218338728-4rwhzq/resume` |
| 8 | 19:18:58.731 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 10
}
```

</details>

<details><summary>4. Recv sql:sqlite_master</summary>

```json
{
  "name": "jobs"
}
```

</details>

<details><summary>5. Recv sql:jobs</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 4
}
```

</details>

---

## create worker returns worker_id

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.735 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.735 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":11}` |
| 3 | 19:18:58.736 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.736 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338735-g49gbm","description":"Worker create test"}` |
| 5 | 19:18:58.737 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 11
}
```

</details>

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.737 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.737 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":12}` |
| 3 | 19:18:58.739 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.739 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338737-zsp0ry","description":"Config test"}` |
| 5 | 19:18:58.739 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 12
}
```

</details>

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.740 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.740 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":13}` |
| 3 | 19:18:58.742 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.742 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338740-7w9zyc","description":"Skill test"}` |
| 5 | 19:18:58.742 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 13
}
```

</details>

---

## creates project via SQL seed and reads via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.743 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.743 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":14}` |
| 3 | 19:18:58.744 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.744 | Send | http.send | `GET /api/v1/projects` |
| 5 | 19:18:58.745 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 14
}
```

</details>

---

## creates job via HTTP, verifies via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.745 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.745 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":15}` |
| 3 | 19:18:58.746 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.746 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338745-scrabh","description":"DB test job"}` |
| 5 | 19:18:58.748 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 15
}
```

</details>

---

## creates worker record in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.749 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.749 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":16}` |
| 3 | 19:18:58.750 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.750 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338749-2ti0au","description":"Worker DB test"}` |
| 5 | 19:18:58.750 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 16
}
```

</details>

---

## create project → create job → verify via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.755 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.755 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":18}` |
| 3 | 19:18:58.758 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.758 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338755-exfq6f","description":"Full lifecycle test"}` |
| 5 | 19:18:58.758 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 18
}
```

</details>

---

## lists jobs and workers via HTTP matches DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.759 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 19:18:58.759 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.759 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 19:18:58.759 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.759 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 19:18:58.759 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.761 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 19:18:58.761 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects workflow with empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.761 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 19:18:58.761 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.762 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 19:18:58.762 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.762 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 19:18:58.763 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.763 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 19:18:58.763 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## job with workflow has workflow_name set

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.766 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.766 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":20}` |
| 3 | 19:18:58.767 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.767 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338766-vc6giy","description":"Workflow job","workflow":"feature"}` |
| 5 | 19:18:58.767 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 20
}
```

</details>

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.768 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.768 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":21}` |
| 3 | 19:18:58.771 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.771 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338768-ysy3yi","description":"Add a hello world function","workflow":"simple"}` |
| 5 | 19:18:58.771 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 21
}
```

</details>

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.772 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.772 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":22}` |
| 3 | 19:18:58.772 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.772 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338771-x0zmxq","description":"Build feature X","workflow":"feature"}` |
| 5 | 19:18:58.773 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 22
}
```

</details>

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.773 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 2 | 19:18:58.773 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":23}` |
| 3 | 19:18:58.773 | Send | sql.fixture | `1 rows` |
| 4 | 19:18:58.773 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338773-eglilj","description":"Plan the feature","workflow":"simple"}` |
| 5 | 19:18:58.774 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>2. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 23
}
```

</details>

---

## workflow seeded in DB is accessible via config

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 19:18:58.774 | Recv | sql:sqlite_master | `{"name":"workflows"}` |
| 2 | 19:18:58.774 | Recv | sql:workflows | `[{"name":"simple","content":"name: simple\ndescription: \"Simple two-stage workflow for testing\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read, glob, grep]\n max_tokens: 8000\n routes:\n - when: 'response.complexity == \"simple\"'\n next: done\n - when: 'true'...` |
| 3 | 19:18:58.775 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 4 | 19:18:58.775 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":24}` |
| 5 | 19:18:58.775 | Send | sql.fixture | `1 rows` |
| 6 | 19:18:58.775 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779218338774-k7yk9l","description":"Test","workflow":"simple"}` |
| 7 | 19:18:58.775 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:sqlite_master</summary>

```json
{
  "name": "workflows"
}
```

</details>

<details><summary>2. Recv sql:workflows</summary>

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

<details><summary>3. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>4. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 24
}
```

</details>

---

