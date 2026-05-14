# Trailhead E2E Test Suite

**Date:** 2026-05-14T04:44:31.204Z
**Events:** 8
**Duration:** 14ms

---

## parses valid workflow YAML

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 04:44:31.199 | Send | http.send | `POST /api/v1/workflows/validate {"yaml":"\nname: simple\ndescription: \"Simple workflow\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan: {{input}}\"\n tools: [bash, read]\n max_tokens: 8000\n rou...` |
| 2 | 04:44:31.200 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects empty stages

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 04:44:31.201 | Send | http.send | `POST /api/v1/workflows/validate {"yaml":"\nname: empty\ndescription: \"No stages\"\nstages: {}\n"}` |
| 2 | 04:44:31.201 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects unknown route target

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 04:44:31.201 | Send | http.send | `POST /api/v1/workflows/validate {"yaml":"\nname: bad-route\ndescription: \"Routes to nonexistent stage\"\nstages:\n plan:\n skill: plan\n prompt: \"Plan\"\n tools: [bash]\n max_tokens: 8000\n route...` |
| 2 | 04:44:31.201 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

## rejects missing skill

| # | Time | Direction | Step | Detail |
|---|------|-----------|------|--------|
| 1 | 04:44:31.202 | Send | http.send | `POST /api/v1/workflows/validate {"yaml":"\nname: no-skill\ndescription: \"Stage without skill\"\nstages:\n plan:\n prompt: \"Plan\"\n tools: [bash]\n max_tokens: 8000\n routes:\n - when: 'true'\n n...` |
| 2 | 04:44:31.202 | Response | http response | `error: Unable to connect. Is the computer able to access the url?` |

---

