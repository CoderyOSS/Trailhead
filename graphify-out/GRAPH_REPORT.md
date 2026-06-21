# Graph Report - .  (2026-06-21)

## Corpus Check
- Large corpus: 474 files · ~1,058,724 words. Semantic extraction will be expensive (many Claude tokens). Consider running on a subfolder.

## Summary
- 1655 nodes · 2817 edges · 112 communities (89 shown, 23 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 18 edges (avg confidence: 0.81)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- [[_COMMUNITY_App Shell & Sidebar|App Shell & Sidebar]]
- [[_COMMUNITY_Database Schema (SQLite)|Database Schema (SQLite)]]
- [[_COMMUNITY_Top Bar Workflow Picker|Top Bar Workflow Picker]]
- [[_COMMUNITY_Graph Canvas Gestures|Graph Canvas Gestures]]
- [[_COMMUNITY_Web API Types|Web API Types]]
- [[_COMMUNITY_Settings Modal|Settings Modal]]
- [[_COMMUNITY_Workflow Node Model|Workflow Node Model]]
- [[_COMMUNITY_REST API Contracts|REST API Contracts]]
- [[_COMMUNITY_Stage Drawer Tabs|Stage Drawer Tabs]]
- [[_COMMUNITY_MCP Tool Server|MCP Tool Server]]
- [[_COMMUNITY_Workflow Stage Model|Workflow Stage Model]]
- [[_COMMUNITY_Scheduler Config|Scheduler Config]]
- [[_COMMUNITY_Editor Settings Tab|Editor Settings Tab]]
- [[_COMMUNITY_Jobs Sidebar|Jobs Sidebar]]
- [[_COMMUNITY_Stage Data Model|Stage Data Model]]
- [[_COMMUNITY_Job Log View|Job Log View]]
- [[_COMMUNITY_Mock Data Provider|Mock Data Provider]]
- [[_COMMUNITY_Workflow Node Shapes|Workflow Node Shapes]]
- [[_COMMUNITY_Node Menu Provider|Node Menu Provider]]
- [[_COMMUNITY_Theme Controller|Theme Controller]]
- [[_COMMUNITY_Runs Table|Runs Table]]
- [[_COMMUNITY_Job Summary & YAML Drawer|Job Summary & YAML Drawer]]
- [[_COMMUNITY_Connection Painter|Connection Painter]]
- [[_COMMUNITY_Canvas Handle Widgets|Canvas Handle Widgets]]
- [[_COMMUNITY_Worker Adapter (Opencode)|Worker Adapter (Opencode)]]
- [[_COMMUNITY_Workflow YAML Parser|Workflow YAML Parser]]
- [[_COMMUNITY_Selection Notifier|Selection Notifier]]
- [[_COMMUNITY_Drawer Keys State|Drawer Keys State]]
- [[_COMMUNITY_Canvas Controller PanZoom|Canvas Controller Pan/Zoom]]
- [[_COMMUNITY_Community 29|Community 29]]
- [[_COMMUNITY_Docker Provider|Docker Provider]]
- [[_COMMUNITY_Community 31|Community 31]]
- [[_COMMUNITY_Community 32|Community 32]]
- [[_COMMUNITY_Community 33|Community 33]]
- [[_COMMUNITY_Community 34|Community 34]]
- [[_COMMUNITY_Community 35|Community 35]]
- [[_COMMUNITY_Community 36|Community 36]]
- [[_COMMUNITY_Community 37|Community 37]]
- [[_COMMUNITY_Community 38|Community 38]]
- [[_COMMUNITY_Community 39|Community 39]]
- [[_COMMUNITY_Community 40|Community 40]]
- [[_COMMUNITY_Community 41|Community 41]]
- [[_COMMUNITY_Community 42|Community 42]]
- [[_COMMUNITY_Community 43|Community 43]]
- [[_COMMUNITY_Community 44|Community 44]]
- [[_COMMUNITY_Community 45|Community 45]]
- [[_COMMUNITY_Community 46|Community 46]]
- [[_COMMUNITY_Community 47|Community 47]]
- [[_COMMUNITY_Community 48|Community 48]]
- [[_COMMUNITY_Community 49|Community 49]]
- [[_COMMUNITY_Community 50|Community 50]]
- [[_COMMUNITY_Community 51|Community 51]]
- [[_COMMUNITY_Community 52|Community 52]]
- [[_COMMUNITY_Community 53|Community 53]]
- [[_COMMUNITY_Community 54|Community 54]]
- [[_COMMUNITY_Community 55|Community 55]]
- [[_COMMUNITY_Community 56|Community 56]]
- [[_COMMUNITY_Community 57|Community 57]]
- [[_COMMUNITY_Community 58|Community 58]]
- [[_COMMUNITY_Community 59|Community 59]]
- [[_COMMUNITY_Community 60|Community 60]]
- [[_COMMUNITY_Community 61|Community 61]]
- [[_COMMUNITY_Community 62|Community 62]]
- [[_COMMUNITY_Community 63|Community 63]]
- [[_COMMUNITY_Community 64|Community 64]]
- [[_COMMUNITY_Community 65|Community 65]]
- [[_COMMUNITY_Community 66|Community 66]]
- [[_COMMUNITY_Community 67|Community 67]]
- [[_COMMUNITY_Community 68|Community 68]]
- [[_COMMUNITY_Community 69|Community 69]]
- [[_COMMUNITY_Community 70|Community 70]]
- [[_COMMUNITY_Community 71|Community 71]]
- [[_COMMUNITY_Community 72|Community 72]]
- [[_COMMUNITY_Community 73|Community 73]]
- [[_COMMUNITY_Community 74|Community 74]]
- [[_COMMUNITY_Community 75|Community 75]]
- [[_COMMUNITY_Community 76|Community 76]]
- [[_COMMUNITY_Community 77|Community 77]]
- [[_COMMUNITY_Community 78|Community 78]]
- [[_COMMUNITY_Community 79|Community 79]]
- [[_COMMUNITY_Community 80|Community 80]]
- [[_COMMUNITY_Community 81|Community 81]]
- [[_COMMUNITY_Community 82|Community 82]]
- [[_COMMUNITY_Community 83|Community 83]]
- [[_COMMUNITY_Community 84|Community 84]]
- [[_COMMUNITY_Community 85|Community 85]]
- [[_COMMUNITY_Community 86|Community 86]]
- [[_COMMUNITY_Community 87|Community 87]]
- [[_COMMUNITY_Community 88|Community 88]]
- [[_COMMUNITY_Community 89|Community 89]]
- [[_COMMUNITY_Community 90|Community 90]]
- [[_COMMUNITY_Community 91|Community 91]]
- [[_COMMUNITY_Community 92|Community 92]]
- [[_COMMUNITY_Community 93|Community 93]]
- [[_COMMUNITY_Community 94|Community 94]]
- [[_COMMUNITY_Community 95|Community 95]]
- [[_COMMUNITY_Community 96|Community 96]]
- [[_COMMUNITY_Community 98|Community 98]]
- [[_COMMUNITY_Community 99|Community 99]]
- [[_COMMUNITY_Community 100|Community 100]]
- [[_COMMUNITY_Community 101|Community 101]]
- [[_COMMUNITY_Community 102|Community 102]]
- [[_COMMUNITY_Community 105|Community 105]]
- [[_COMMUNITY_Community 106|Community 106]]
- [[_COMMUNITY_Community 107|Community 107]]
- [[_COMMUNITY_Community 108|Community 108]]
- [[_COMMUNITY_Community 109|Community 109]]
- [[_COMMUNITY_Community 110|Community 110]]

## God Nodes (most connected - your core abstractions)
1. `Database` - 38 edges
2. `Result` - 32 edges
3. `String` - 27 edges
4. `TrailheadMcpServer` - 26 edges
5. `workflowProvider` - 25 edges
6. `_GraphCanvasState` - 22 edges
7. `String` - 19 edges
8. `build` - 18 edges
9. `run_stage()` - 16 edges
10. `Arc` - 15 edges

## Surprising Connections (you probably didn't know these)
- `TrailheadApp` --references--> `Codery dark slate design system`  [INFERRED]
  frontend/lib/main.dart → frontend/AGENTS.md
- `TrailheadApp` --implements--> `Riverpod manual StateProviders`  [INFERRED]
  frontend/lib/main.dart → frontend/AGENTS.md
- `job_config()` --semantically_similar_to--> `Engine::resolve_stage_prompt`  [INFERRED] [semantically similar]
  crates/trailhead-service/src/api.rs → crates/trailhead-service/src/workflow/mod.rs
- `trailhead-service Cargo.toml` --references--> `src/main.rs`  [EXTRACTED]
  crates/trailhead-service/Cargo.toml → crates/trailhead-service/src/main.rs
- `web_routes (axum Router)` --semantically_similar_to--> `api_routes (internal)`  [INFERRED] [semantically similar]
  crates/trailhead-service/src/web.rs → crates/trailhead-service/src/api.rs

## Import Cycles
- 1-file cycle: `crates/trailhead-service/build.rs -> crates/trailhead-service/build.rs`
- 1-file cycle: `crates/trailhead-service/src/api.rs -> crates/trailhead-service/src/api.rs`
- 1-file cycle: `crates/trailhead-service/src/config.rs -> crates/trailhead-service/src/config.rs`
- 1-file cycle: `crates/trailhead-service/src/db.rs -> crates/trailhead-service/src/db.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/cursor.rs -> crates/trailhead-service/src/ide/cursor.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/mod.rs -> crates/trailhead-service/src/ide/mod.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/opencode.rs -> crates/trailhead-service/src/ide/opencode.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/shell.rs -> crates/trailhead-service/src/ide/shell.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/ssh.rs -> crates/trailhead-service/src/ide/ssh.rs`
- 1-file cycle: `crates/trailhead-service/src/ide/vscode.rs -> crates/trailhead-service/src/ide/vscode.rs`
- 1-file cycle: `crates/trailhead-service/src/mcp.rs -> crates/trailhead-service/src/mcp.rs`
- 1-file cycle: `crates/trailhead-service/src/provider/docker.rs -> crates/trailhead-service/src/provider/docker.rs`
- 1-file cycle: `crates/trailhead-service/src/provider/mod.rs -> crates/trailhead-service/src/provider/mod.rs`
- 1-file cycle: `crates/trailhead-service/src/scheduler.rs -> crates/trailhead-service/src/scheduler.rs`
- 1-file cycle: `crates/trailhead-service/src/workflow/mod.rs -> crates/trailhead-service/src/workflow/mod.rs`
- 1-file cycle: `crates/trailhead-service/src/web.rs -> crates/trailhead-service/src/web.rs`
- 1-file cycle: `crates/trailhead-service/src/workflow/parser.rs -> crates/trailhead-service/src/workflow/parser.rs`
- 1-file cycle: `crates/trailhead-service/src/workflow/resolver.rs -> crates/trailhead-service/src/workflow/resolver.rs`
- 1-file cycle: `crates/trailhead-service/src/workflow/router.rs -> crates/trailhead-service/src/workflow/router.rs`

## Hyperedges (group relationships)
- **App shell composition (ProviderScope + ThemeController + TrailheadShell)** — main_trailheadapp, main_trailheadshell, main_buildsidebar [EXTRACTED 0.95]
- **Trailhead core data model (Job/Workflow/Worker)** — concept_job, concept_workflow, concept_worker [INFERRED 0.95]
- **WorkerNode capsule rendering system** — canvas_worker_node, canvas_worker_node_connector_dot, canvas_worker_node_status_badge [EXTRACTED 1.00]
- **Canvas node visual contract (168x36 capsule, AppColors, tokens)** — canvas_worker_node, theme_tokens, widgets_status_tag [INFERRED 0.85]
- **daemon_cmd bootstrap: db + provider + scheduler + api/web/mcp routers wired onto single axum app** — src_main_rs, src_db_rs, src_scheduler_rs, src_mcp_rs [EXTRACTED 0.95]
- **Event-driven job execution pipeline: db watch channel → scheduler::run → launch_worker_for_job → run_stage (opencode adapter + workflow engine + git checkpoint)** — trailheadservice_db_jobnotify, src_scheduler_rs, trailheadservice_scheduler_runstage, trailheadservice_jobs_statemachine [EXTRACTED 0.95]
- **External control surface: MCP tools + CLI subcommands + REST handlers all funnel into Database with shared jobs state machine** — src_mcp_rs, src_main_rs, trailheadservice_db_database, trailheadservice_jobs_statemachine [INFERRED 0.85]
- **Workflow engine subsystem (parser+resolver+router)** — src_workflow_parser_parse, src_workflow_mod_engine, src_workflow_mod_process_response [INFERRED 0.95]
- **WorkerProvider abstraction (trait+spec+handle+docker impl)** — src_provider_mod_trait, src_provider_mod_spec, src_provider_mod_handle, src_provider_docker_provider [EXTRACTED 1.00]
- **HTTP API surface (web+api routes)** — src_web_routes, src_api_routes, src_web_serve_spa [EXTRACTED 0.95]

## Communities (112 total, 23 thin omitted)

### Community 0 - "App Shell & Sidebar"
Cohesion: 0.06
Nodes (79): build, CanvasToolbar, canvas_controller.dart, _beginMarquee, build, _cancelMarquee, _commitMarquee, GraphCanvas (+71 more)

### Community 1 - "Database Schema (SQLite)"
Cohesion: 0.11
Nodes (24): Connection, Arc, Option, Path, Result, Self, String, Value (+16 more)

### Community 2 - "Top Bar Workflow Picker"
Cohesion: 0.04
Nodes (54): FocusNode, mode_rail.dart, OverlayEntry?, active, activeWfId, big, _cancel, _cancelRename (+46 more)

### Community 3 - "Graph Canvas Gestures"
Cohesion: 0.04
Nodes (52): _cancelTapTimer, createRenderObject, createState, dispose, _doubleClickDragActive, _doubleClickStartPos, _doubleTapMaxDist, _doubleTapMaxMs (+44 more)

### Community 4 - "Web API Types"
Cohesion: 0.15
Nodes (48): Arc, Database, Item, JobRow, Json, Option, Path, Result (+40 more)

### Community 5 - "Settings Modal"
Cohesion: 0.04
Nodes (46): _AccentData, accent, _AccentData, _accents, _buildBody, _buildCompactNav, _buildHeader, _buildLabel (+38 more)

### Community 6 - "Workflow Node Model"
Cohesion: 0.05
Nodes (43): body, branches, branchPadY, branchRowHeight, branchWidth, cases, collect, concurrency (+35 more)

### Community 7 - "REST API Contracts"
Cohesion: 0.09
Nodes (37): AppState, Arc, Database, Json, Option, Path, Result, Router (+29 more)

### Community 8 - "Stage Drawer Tabs"
Cohesion: 0.05
Nodes (40): dart:convert, editor_prompt_tab.dart, editor_result_tab.dart, editor_settings_tab.dart, job_log_view.dart, stageDrawerTabProvider, accent, borderColor (+32 more)

### Community 9 - "MCP Tool Server"
Cohesion: 0.14
Nodes (19): Arc, Database, Option, Self, String, NeverSessionManager, Parameters, AddProjectParams (+11 more)

### Community 10 - "Workflow Stage Model"
Cohesion: 0.10
Nodes (32): HashMap, Option, ProjectVars, Result, Self, Stage, StageOutput, String (+24 more)

### Community 11 - "Scheduler Config"
Cohesion: 0.13
Nodes (25): Arc, CommitInfo, Database, JobRow, Option, Path, PathBuf, Result (+17 more)

### Community 12 - "Editor Settings Tab"
Cohesion: 0.06
Nodes (32): BranchOutput, body, build, _concurrencyCtrl, _ConfigList, _ConfigListState, configs, controller (+24 more)

### Community 13 - "Jobs Sidebar"
Cohesion: 0.07
Nodes (31): active, activeId, _activeStatuses, count, createState, _DeleteBackground, _FilterButton, _FlatView (+23 more)

### Community 14 - "Stage Data Model"
Cohesion: 0.06
Nodes (30): args, BranchCase, copyWith, durMs, id, label, loop, match (+22 more)

### Community 15 - "Job Log View"
Cohesion: 0.07
Nodes (30): accent, build, call, child, createState, didUpdateWidget, exec, ExecutionDetail (+22 more)

### Community 16 - "Mock Data Provider"
Cohesion: 0.07
Nodes (27): ../../models/stage_data.dart, active, by, copyWith, costUsd, draft, edges, elapsedSec (+19 more)

### Community 17 - "Workflow Node Shapes"
Cohesion: 0.08
Nodes (24): build, _ConnectorDot, EntrypointNode, left, node, onEnter, onExit, selected (+16 more)

### Community 18 - "Node Menu Provider"
Cohesion: 0.09
Nodes (20): package:flutter_riverpod/flutter_riverpod.dart, package:flutter_test/flutter_test.dart, package:frontend/main.dart, package:frontend/providers/canvas_controller.dart, package:frontend/providers/selection_notifier.dart, package:frontend/widgets/canvas/marquee_painter.dart, package:frontend/widgets/mode_rail.dart, package:frontend/widgets/top_bar.dart (+12 more)

### Community 19 - "Theme Controller"
Cohesion: 0.08
Nodes (25): static final Map, static final ThemeController, String get, theme_data.dart, _accent, _AccentData, accentInk, border3 (+17 more)

### Community 20 - "Runs Table"
Cohesion: 0.08
Nodes (24): static const, view_toggle.dart, active, _cell, _colFlex, count, createState, _Footer (+16 more)

### Community 21 - "Job Summary & YAML Drawer"
Cohesion: 0.09
Nodes (22): app_button.dart, package:flutter/services.dart, JobSummary, ../utils/clipboard_stub.dart, ../utils/workflow_to_yaml.dart, build, _buildLine, _copied (+14 more)

### Community 22 - "Connection Painter"
Cohesion: 0.09
Nodes (22): _bezierPoint, _branchExitPoint, connectionDrag, _controlMax, _controlMin, draggingNodeId, dragOffset, _drawArrowhead (+14 more)

### Community 23 - "Canvas Handle Widgets"
Cohesion: 0.09
Nodes (22): _InputHandle, _OutputHandle, _AccentChip, _FieldLabel, Seg, SettingRow, _ThemeCard, Toggle (+14 more)

### Community 24 - "Worker Adapter (Opencode)"
Cohesion: 0.20
Nodes (11): Client, Result, Self, String, Value, Vec, HeaderMap, PermissionPolicy (+3 more)

### Community 25 - "Workflow YAML Parser"
Cohesion: 0.14
Nodes (16): Option, Result, Route, Stage, String, Value, Vec, IndexMap (+8 more)

### Community 26 - "Selection Notifier"
Cohesion: 0.10
Nodes (19): int get, package:flutter/foundation.dart, active, base, beginMarquee, cancelMarquee, clear, commitMarquee (+11 more)

### Community 27 - "Drawer Keys State"
Cohesion: 0.10
Nodes (18): keyString, main, putIfAbsent, _stageDrawerKey, _stageDrawerKeys, _yamlDrawerKey, ../models/settings_state.dart, ../models/workflow_document.dart (+10 more)

### Community 28 - "Canvas Controller Pan/Zoom"
Cohesion: 0.11
Nodes (18): bool get, double?, beginScale, copyWith, endScale, fitToBounds, _isScaling, pan (+10 more)

### Community 29 - "Community 29"
Cohesion: 0.11
Nodes (18): anchor, build, canDuplicate, createState, danger, desc, _hover, icon (+10 more)

### Community 30 - "Docker Provider"
Cohesion: 0.18
Nodes (11): Option, Result, Self, String, Vec, WorkerProvider, Docker, DockerProvider (+3 more)

### Community 31 - "Community 31"
Cohesion: 0.11
Nodes (18): double get, EdgeInsets get, AppButton, AppButtonSize, _AppButtonState, AppButtonVariant, build, createState (+10 more)

### Community 32 - "Community 32"
Cohesion: 0.38
Nodes (7): createJob(), createJobWithStatus(), createWorker(), isRecord(), seedProject(), test(), uniqueId()

### Community 33 - "Community 33"
Cohesion: 0.12
Nodes (17): AnimationController, SettingsDialog, _SettingsDialogState, SingleTickerProviderStateMixin, build, color, _controller, createState (+9 more)

### Community 34 - "Community 34"
Cohesion: 0.17
Nodes (17): Option, String, Value, Vec, MessagePart, MessagePartState, SessionStatusValue, MessagePart (+9 more)

### Community 35 - "Community 35"
Cohesion: 0.12
Nodes (16): Animation, build, _controller, createState, _dismissTimer, dispose, initState, mode (+8 more)

### Community 36 - "Community 36"
Cohesion: 0.12
Nodes (12): Any, Flutter, FlutterAppDelegate, Bool, AppDelegate, GeneratedPluginRegistrant, -registerWithRegistry, RunnerTests (+4 more)

### Community 37 - "Community 37"
Cohesion: 0.12
Nodes (16): anchor, build, createState, desc, _hover, icon, kind, label (+8 more)

### Community 38 - "Community 38"
Cohesion: 0.14
Nodes (13): paint, rect, shouldRepaint, icons.dart, package:flutter/material.dart, active, copyWith, MarqueeState (+5 more)

### Community 39 - "Community 39"
Cohesion: 0.13
Nodes (14): BranchNode, build, height, node, onEnter, onExit, _outputs, padY (+6 more)

### Community 40 - "Community 40"
Cohesion: 0.15
Nodes (14): build, _ConnectorDot private widget, _ConnectorDot, left, node, onEnter, onExit, selected (+6 more)

### Community 41 - "Community 41"
Cohesion: 0.14
Nodes (13): Color, Color border1, border2,, Color success, warning, danger,, gradient, accent, accentInk, border3, chartGrid (+5 more)

### Community 42 - "Community 42"
Cohesion: 0.20
Nodes (7): Option, Result, Route, String, Value, evaluate_condition(), evaluate_routes()

### Community 43 - "Community 43"
Cohesion: 0.14
Nodes (13): Map, package:flutter_svg/flutter_svg.dart, a, _bodies, body, build, color, icon (+5 more)

### Community 44 - "Community 44"
Cohesion: 0.14
Nodes (13): accent, canvasStyle, confirmStop, copyWith, defaultMode, density, edgeStyle, notifyFinish (+5 more)

### Community 45 - "Community 45"
Cohesion: 0.15
Nodes (13): ../../providers/settings_provider.dart, active, activeCount, AppMode, badge, _BrandGlyph, createState, _hovering (+5 more)

### Community 46 - "Community 46"
Cohesion: 0.24
Nodes (14): src/db.rs, src/ide.rs (module root), src/jobs.rs, src/main.rs, src/mcp.rs, src/scheduler.rs, trailhead-service AGENTS.md, trailhead-service Cargo.toml (+6 more)

### Community 47 - "Community 47"
Cohesion: 0.15
Nodes (13): active, build, createState, didUpdateWidget, _format, _FormatOption, _FormatOptionState, initState (+5 more)

### Community 48 - "Community 48"
Cohesion: 0.24
Nodes (11): Trailhead Service Agent Guide, Codery dark slate design system, Event-driven scheduling via tokio::sync::watch, Job (workflow execution), Mock backend data baked into Flutter build, Riverpod manual StateProviders, Flutter web build embedded in Rust binary via rust-embed, Worker (Docker container instance) (+3 more)

### Community 49 - "Community 49"
Cohesion: 0.24
Nodes (11): Box, Option, PathBuf, Send, String, Sync, Vec, auto_detect() (+3 more)

### Community 50 - "Community 50"
Cohesion: 0.23
Nodes (6): IdeAdapter, JobContext, Path, Result, CursorAdapter, which_exists()

### Community 51 - "Community 51"
Cohesion: 0.23
Nodes (6): IdeAdapter, JobContext, Path, Result, OpenCodeAdapter, which_exists()

### Community 52 - "Community 52"
Cohesion: 0.23
Nodes (6): IdeAdapter, JobContext, Path, Result, VsCodeAdapter, which_exists()

### Community 53 - "Community 53"
Cohesion: 0.50
Nodes (11): Result, String, daemon_cmd(), get_arg_index(), get_flag(), jobs_cmd(), main(), open_port_for_docker_bridges() (+3 more)

### Community 54 - "Community 54"
Cohesion: 0.17
Nodes (11): ../providers/mock_data.dart, buf, prefix, stageLines, toString, workflowToYaml, workflowToYamlWithLines, _writeJson (+3 more)

### Community 55 - "Community 55"
Cohesion: 0.17
Nodes (11): ValueChanged, active, build, createState, _hovering, _ItemState, label, onChange (+3 more)

### Community 56 - "Community 56"
Cohesion: 0.24
Nodes (5): IdeAdapter, JobContext, Path, Result, ShellAdapter

### Community 57 - "Community 57"
Cohesion: 0.24
Nodes (5): IdeAdapter, JobContext, Path, Result, SshAdapter

### Community 58 - "Community 58"
Cohesion: 0.25
Nodes (10): HashMap, Option, PathBuf, Send, String, Sync, WorkerHandle, WorkerProvider (+2 more)

### Community 59 - "Community 59"
Cohesion: 0.18
Nodes (10): stage_drawer.dart, build, createState, _ctrl, didUpdateWidget, dispose, initState, stage (+2 more)

### Community 60 - "Community 60"
Cohesion: 0.18
Nodes (11): _BranchOutputRow, _BranchOutputRowState, _BranchOutputsEditor, _BranchOutputsEditorState, _SelectField, _SelectFieldState, _SubworkflowSelector, _SubworkflowSelectorState (+3 more)

### Community 61 - "Community 61"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 62 - "Community 62"
Cohesion: 0.20
Nodes (9): ConnectionPainter, CutPathPainter, paint, points, shouldRepaint, DotGridPainter, MarqueePainter, CustomPainter (+1 more)

### Community 63 - "Community 63"
Cohesion: 0.20
Nodes (9): ConnectionDragState, copyWith, currentWorldPos, sourceIsOutput, sourceNodeId, sourcePort, targetIsOutput, targetNodeId (+1 more)

### Community 64 - "Community 64"
Cohesion: 0.28
Nodes (7): canvasSize, canvasSize, ../models/workflow_node.dart, ../providers/mode_provider.dart, ../../providers/scissors_provider.dart, Size, ../../widgets/mode_rail.dart

### Community 65 - "Community 65"
Cohesion: 0.22
Nodes (9): DockerProvider (bollard), WorkerProvider trait, Engine (workflow state machine), Engine::process_response_with_commits, StageResult struct, CommitPolicy enum, Route struct, Stage struct (+1 more)

### Community 66 - "Community 66"
Cohesion: 0.25
Nodes (6): dart:ui, package:frontend/models/workflow_edge.dart, package:frontend/models/workflow_node.dart, package:frontend/widgets/canvas/connection_painter.dart, main, main

### Community 67 - "Community 67"
Cohesion: 0.25
Nodes (7): copyWith, id, label, sourceId, sourcePort, targetId, WorkflowEdge

### Community 68 - "Community 68"
Cohesion: 0.29
Nodes (6): copyWith, viewport, workflow, WorkflowDocument, ../providers/canvas_controller.dart, WorkflowSummary

### Community 69 - "Community 69"
Cohesion: 0.33
Nodes (5): paint, pan, shouldRepaint, zoom, Offset

### Community 70 - "Community 70"
Cohesion: 0.33
Nodes (5): handle_new_rx_page(), __lldb_init_module(), Intercept NOTIFY_DEBUGGER_ABOUT_RX_PAGES and touch the pages., SBDebugger, SBFrame

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (5): int?, PickerAnchor, screenPos, sourceNodeId, sourcePort

### Community 72 - "Community 72"
Cohesion: 0.40
Nodes (4): adapter, extractField(), isRecord(), ServiceAdapter

### Community 73 - "Community 73"
Cohesion: 0.60
Nodes (4): Path, Result, copy_dir_recursive(), main()

### Community 74 - "Community 74"
Cohesion: 0.50
Nodes (3): Result, can_transition(), transition()

### Community 75 - "Community 75"
Cohesion: 0.60
Nodes (4): String, decide(), PermissionAction, PermissionPolicy

### Community 76 - "Community 76"
Cohesion: 0.40
Nodes (4): launcher.sh script, DEEPSEEK_API_KEY, MAX_GLOBAL_WORKERS, SCHEDULER_INTERVAL_SECS

### Community 77 - "Community 77"
Cohesion: 0.40
Nodes (4): name, private, scripts, test

### Community 78 - "Community 78"
Cohesion: 0.40
Nodes (5): CanvasController, CanvasViewport, SelectionNotifier, SelectionState, StateNotifier

### Community 79 - "Community 79"
Cohesion: 0.50
Nodes (4): @immutable, SettingsState, SettingsNotifier, TrailheadThemeData

### Community 80 - "Community 80"
Cohesion: 0.67
Nodes (3): ext(), fetch(), MIME

### Community 81 - "Community 81"
Cohesion: 0.50
Nodes (4): job icon (AMBIGUOUS: file missing at extraction time, inferred from filename), project icon (AMBIGUOUS: file missing at extraction time, inferred from filename), worker icon (AMBIGUOUS: file missing at extraction time, inferred from filename), workflow icon (AMBIGUOUS: file missing at extraction time, inferred from filename)

### Community 82 - "Community 82"
Cohesion: 0.67
Nodes (3): MultiHitStack, UnboundedHitStack, Stack

### Community 83 - "Community 83"
Cohesion: 0.67
Nodes (3): _RenderMultiHitStack, _RenderUnboundedHitStack, RenderStack

### Community 86 - "Community 86"
Cohesion: 0.67
Nodes (3): DockerProvider::create_worker, WorkerHandle struct, WorkerSpec struct

## Ambiguous Edges - Review These
- `worker icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` → `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`  [AMBIGUOUS]
  frontend/assets/images/job_icon.png · relation: conceptually_related_to
- `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` → `project icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`  [AMBIGUOUS]
  frontend/assets/images/job_icon.png · relation: conceptually_related_to
- `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` → `workflow icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`  [AMBIGUOUS]
  frontend/assets/images/job_icon.png · relation: conceptually_related_to

## Knowledge Gaps
- **775 isolated node(s):** `@opencode-ai/plugin`, `entrypoint.sh script`, `Result`, `Option`, `Vec` (+770 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **23 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **What is the exact relationship between `worker icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` and `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` and `project icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **What is the exact relationship between `job icon (AMBIGUOUS: file missing at extraction time, inferred from filename)` and `workflow icon (AMBIGUOUS: file missing at extraction time, inferred from filename)`?**
  _Edge tagged AMBIGUOUS (relation: conceptually_related_to) - confidence is low._
- **Why does `WorkflowNode` connect `Workflow Node Shapes` to `Workflow Node Model`, `Community 39`, `Community 40`, `Stage Drawer Tabs`, `Editor Settings Tab`, `Community 47`, `Job Log View`, `Community 59`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Why does `TrailheadApp` connect `Community 48` to `App Shell & Sidebar`, `Drawer Keys State`, `Canvas Handle Widgets`?**
  _High betweenness centrality (0.005) - this node is a cross-community bridge._
- **Why does `TrailheadIconData` connect `Community 43` to `Top Bar Workflow Picker`, `Settings Modal`, `Community 37`, `Stage Drawer Tabs`, `Community 45`, `Community 29`, `Community 31`?**
  _High betweenness centrality (0.004) - this node is a cross-community bridge._
- **What connects `@opencode-ai/plugin`, `entrypoint.sh script`, `Result` to the rest of the system?**
  _776 weakly-connected nodes found - possible documentation gaps or missing edges._