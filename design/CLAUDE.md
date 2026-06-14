# WorkflowManager — project notes

## Update-archive structure (IMPORTANT — read before building any update zip)

When the user asks for an archive/zip to update their **local** copy of the
project, the archive's internal paths MUST be project-root-relative so that
unzipping overlays directly onto their project (e.g. `src/YamlDrawer.jsx`,
`Flutter Handoff.html`, `handoff/src/…` at the TOP LEVEL of the zip).

### Do this
Download the **whole project**:

```
present_fs_item_for_download({ label: "WorkflowManager — local update" })
```

(omit `path`, or pass `""`). This zips with root-relative paths, so the user
extracts and merges the contents into their project folder and every changed
file overwrites its counterpart.

### Do NOT do this (this was the old bug)
Do **not** stage files into a subfolder (e.g. `export/`) and download that
folder. `present_fs_item_for_download({ path: "export" })` nests everything
under `export/…` inside the zip, so unzipping just creates a stray `export/`
directory and overwrites nothing. There is no way to get a scoped, root-relative
zip with this tool — a subfolder always becomes the archive prefix. The
whole-project download is the only structure that overlays cleanly, and it has
the bonus of also shipping `Workflow Builder.html` + `src/App.jsx` (the live app,
which the old `export/` scope missed).

If the extraction tool still wraps the contents in a single folder named after
the zip, tell the user to copy the **contents** of that folder into their
project root (not the folder itself).

## Project file map (what an update touches)
- `Flutter Handoff.html` — handoff doc; loads `src/*` (live components) + `handoff/src/handoff-*.jsx` (doc sections).
- `Workflow Builder.html` — the live app; loads `src/*` incl. `src/App.jsx`, `src/tweaks-panel.jsx`.
- `src/` — shared live-app component tree (Common, data, Rail, sidebars, TopBar, Canvas, BuilderOverlay, StageDrawer, YamlDrawer, Filmstrip, RunsView, App).
- `handoff/src/` — handoff-doc-only sections (shell, tokens, components, layouts, doc).
- `colors_and_type.css`, `themes.css`, `assets/` — shared styling + logos.

## YAML drawer feature (added)
- `src/YamlDrawer.jsx` — read-only right slide-over showing the workflow (build mode)
  or a run's resolved spec (active/history) as syntax-highlighted YAML. Opened by the
  YAML button in `TopBar`. Compiled via `workflowToYaml()` in `src/data.js`.
- Shares the right drawer slot with `StageDrawer` (mutually exclusive) — coordinated in `src/App.jsx`.
- Loaded by both `Workflow Builder.html` and `Flutter Handoff.html` (after `StageDrawer.jsx`).
- Documented in the handoff doc as a component card in `handoff/src/handoff-components-section.jsx`.
- `lock` icon added to `src/Common.jsx` ICONS map.
