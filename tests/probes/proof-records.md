# Trailhead E2E Test Suite

**Date:** 2026-05-16T17:41:39.712Z
**Events:** 101
**Duration:** 3182ms

---

## (setup)

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.576 | Send | sql.clear | `all tables` |
| 2 | 17:41:39.593 | Send | sql.put | `2 rows` |
| 3 | 17:41:39.614 | Send | sql.clear | `all tables` |
| 4 | 17:41:39.619 | Send | sql.put | `2 rows` |
| 5 | 17:41:39.692 | Send | sql.put | `1 rows` |
| 6 | 17:41:39.692 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299691-0og84d","description":"Hello world test"}` |
| 7 | 17:41:39.693 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## lists jobs via HTTP matching DB count

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.596 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.597 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299594-ckmjk4","description":"Job 1"}` |
| 3 | 17:41:39.602 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## list workers via HTTP matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.619 | Send | http.send | `GET /api/v1/workers` |
| 2 | 17:41:39.621 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## GET /api/v1/jobs returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.634 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.634 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299632-vd096z","description":"Dashboard test job"}` |
| 3 | 17:41:39.634 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## GET /api/v1/jobs/{id} returns detail matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.637 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.637 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299635-sq83np","description":"Detail test"}` |
| 3 | 17:41:39.639 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## GET /api/v1/workers returns list matching DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.642 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.642 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299640-dkzy2t","description":"Worker list test"}` |
| 3 | 17:41:39.642 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## POST /api/v1/jobs/{id}/cancel changes status in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.645 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.645 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299643-32ieq9","description":"Cancel via dashboard"}` |
| 3 | 17:41:39.645 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## new job is queued in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.649 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.649 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299647-jyj2xt","description":"State machine test"}` |
| 3 | 17:41:39.650 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |
| 4 | 17:41:39.701 | Send | sql.put | `1 rows` |
| 5 | 17:41:39.701 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299700-jsewge","description":"Start at first stage"}` |
| 6 | 17:41:39.701 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## running to paused via HTTP

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.652 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.654 | Send | sql.put | `1 rows` |
| 3 | 17:41:39.654 | Send | http.send | `POST /api/v1/jobs/test-1778953299652-cfr845/pause` |
| 4 | 17:41:39.655 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## paused to resuming via HTTP

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.658 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.659 | Send | sql.put | `1 rows` |
| 3 | 17:41:39.659 | Send | http.send | `POST /api/v1/jobs/test-1778953299658-phzlys/resume` |
| 4 | 17:41:39.660 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## cancel from queued state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.662 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.662 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299660-a7cig4","description":"Cancel queued"}` |
| 3 | 17:41:39.663 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## cancel from running state

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.664 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.667 | Send | sql.put | `1 rows` |
| 3 | 17:41:39.667 | Send | http.send | `POST /api/v1/jobs/test-1778953299665-scj2wt/cancel` |
| 4 | 17:41:39.667 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## cannot resume cancelled job

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.670 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.673 | Send | sql.put | `1 rows` |
| 3 | 17:41:39.673 | Send | http.send | `POST /api/v1/jobs/test-1778953299670-bj1kcj/resume` |
| 4 | 17:41:39.677 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## create worker returns worker_id

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.680 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.680 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299678-orth1z","description":"Worker create test"}` |
| 3 | 17:41:39.681 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## get job config returns resolved stage info

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.682 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.682 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299681-w57sg4","description":"Config test"}` |
| 3 | 17:41:39.683 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## get skill content returns markdown

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.684 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.684 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299683-01ihm5","description":"Skill test"}` |
| 3 | 17:41:39.684 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## creates project via SQL seed and reads via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.687 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.687 | Send | http.send | `GET /api/v1/projects` |
| 3 | 17:41:39.687 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## creates job via HTTP, verifies via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.688 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.689 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299688-fzz12f","description":"DB test job"}` |
| 3 | 17:41:39.689 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## creates worker record in DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.690 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.690 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299689-nsgta5","description":"Worker DB test"}` |
| 3 | 17:41:39.690 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## create project → create job → verify via HTTP and SQL

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.695 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.695 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299693-jb67d5","description":"Full lifecycle test"}` |
| 3 | 17:41:39.695 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## lists jobs and workers via HTTP matches DB

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.696 | Send | http.send | `GET /api/v1/jobs` |
| 2 | 17:41:39.696 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## validates workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.696 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: test\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash]\n routes: null\n"}` |
| 2 | 17:41:39.696 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects invalid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.696 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 17:41:39.696 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## validates numeric routing workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.697 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: numeric-route\ndescription: \"Numeric routing\"\nstages:\n check:\n skill: plan\n prompt: \"Check\"\n tools: [bash]\n max_tokens: 8000\n routes:\...` |
| 2 | 17:41:39.697 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects workflow with empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.698 | Send | http.send | `POST /api/v1/workflows/validate {"content":"name: bad\nstages: {}\n"}` |
| 2 | 17:41:39.698 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.699 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n ...` |
| 2 | 17:41:39.699 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.699 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 17:41:39.699 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## accepts single-stage workflow

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.699 | Send | http.send | `POST /api/v1/workflows/validate {"content":"\nname: minimal\ndescription: \"One stage\"\nstages:\n work:\n prompt: \"Do it\"\n tools: [bash]\n max_tokens: 4000\n routes: null\n"}` |
| 2 | 17:41:39.699 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## job with workflow has workflow_name set

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.703 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.703 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299702-2q7hq6","description":"Workflow job","workflow":"feature"}` |
| 3 | 17:41:39.703 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## job config resolves {{input}} in prompt

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.705 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.705 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299704-1552gb","description":"Add a hello world function","workflow":"simple"}` |
| 3 | 17:41:39.705 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## job config returns stage and tools

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.706 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.706 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299705-2xbhc1","description":"Build feature X","workflow":"feature"}` |
| 3 | 17:41:39.707 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## job config returns skill content for plan skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.708 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.708 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299707-jywdim","description":"Plan the feature","workflow":"simple"}` |
| 3 | 17:41:39.708 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## workflow seeded in DB is accessible via config

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 17:41:39.711 | Send | sql.put | `1 rows` |
| 2 | 17:41:39.711 | Send | http.send | `POST /api/v1/jobs {"project_id":"test-1778953299710-oooedw","description":"Test","workflow":"simple"}` |
| 3 | 17:41:39.712 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

