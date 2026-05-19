# Trailhead E2E Test Suite

**Date:** 2026-05-19T20:02:47.541Z
**Events:** 6
**Duration:** 3047ms

---

### Sequence

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 20:02:44.497 | Recv | sql:unknown | `{"changes":"batch"}` |
| 2 | 20:02:47.533 | Recv | sql:sqlite_master | `{"name":"projects"}` |
| 3 | 20:02:47.534 | Recv | sql:projects | `{"changes":1,"lastInsertRowid":25}` |
| 4 | 20:02:47.536 | Send | sql.fixture | `1 rows` |
| 5 | 20:02:47.537 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1779220967531-vxtgbi","description":"Hello world test"}` |
| 6 | 20:02:47.538 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

<details><summary>1. Recv sql:unknown</summary>

```json
{
  "changes": "batch"
}
```

</details>

<details><summary>2. Recv sql:sqlite_master</summary>

```json
{
  "name": "projects"
}
```

</details>

<details><summary>3. Recv sql:projects</summary>

```json
{
  "changes": 1,
  "lastInsertRowid": 25
}
```

</details>

---

