/* global React, ReactDOM,
   ModeRail, WorkflowsSidebar, JobsSidebar,
   TopBar, Canvas, StageDrawer, Filmstrip, RunsView,
   TweaksPanel, TweakSection, TweakRadio, useTweaks,
   WORKFLOW, JOB, SNAPSHOTS, WORKFLOWS_LIST, JOBS_LOG */

const { useState: useStateApp, useEffect: useEffectApp, useMemo: useMemoApp } = React;

const TWEAK_DEFAULTS = /*EDITMODE-BEGIN*/{
  "theme": "slate",
  "canvasStyle": "graph",
  "edgeStyle": "curved",
  "density": "comfortable",
  "inflightAnim": "tokens",
  "accent": "orange"
}/*EDITMODE-END*/;

const ACTIVE_STATUSES_APP  = new Set(["running", "paused", "queued", "retrying"]);
const HISTORY_STATUSES_APP = new Set(["passed",  "failed", "cancelled"]);

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  // mode is the top-level concern. The rail is the only thing that mutates it.
  const [mode, setMode] = useStateApp("active");

  // Per-mode state — each mode keeps its own selection so flipping modes
  // doesn't blow away what you were looking at.
  const [activeWfId, setActiveWfId]       = useStateApp(WORKFLOW.id);
  const [buildSelectedStage, setBuildSel] = useStateApp(null);

  const [activeJobId, setActiveJobId]     = useStateApp("r_8f2a91c");
  const [activeStageSel, setActiveStage]  = useStateApp(null);
  const [jobState, setJobState]           = useStateApp(JOB.state);
  const [activeSnap, setActiveSnap]       = useStateApp("s5");
  const [activeJobsView, setActiveJobsView] = useStateApp("grouped");

  const [historyJobId, setHistoryJobId]   = useStateApp(null);
  const [historyStageSel, setHistoryStage] = useStateApp(null);
  const [historyJobsView, setHistoryJobsView] = useStateApp("grouped");

  // Theme + accent → data-attrs on root.
  useEffectApp(() => {
    document.documentElement.dataset.themeVariant = t.theme;
    document.documentElement.dataset.theme = t.theme === "paper" ? "light" : "dark";
    document.documentElement.dataset.accent = t.accent;
  }, [t.theme, t.accent]);

  const activeJobs  = useMemoApp(() => JOBS_LOG.filter(j => ACTIVE_STATUSES_APP.has(j.status)),  []);
  const historyJobs = useMemoApp(() => JOBS_LOG.filter(j => HISTORY_STATUSES_APP.has(j.status)), []);
  const activeJobCount = activeJobs.length;

  // ── Derive what the main area shows ────────────────────────────────────
  // The selected job in active/history maps to JOB (the single mock job
  // with full stage/edge status) when its id matches; otherwise we show a
  // placeholder. Real impl would fetch per-job.
  const currentJob = useMemoApp(() => {
    if (mode === "active") {
      const j = activeJobs.find(j => j.id === activeJobId);
      return j ? { ...JOB, ...j, workflowVersion: 14 } : null;
    }
    if (mode === "history" && historyJobId) {
      const j = historyJobs.find(j => j.id === historyJobId);
      return j ? { ...JOB, ...j, workflowVersion: 14 } : null;
    }
    return null;
  }, [mode, activeJobId, historyJobId, activeJobs, historyJobs]);

  const selectedStage = mode === "build"   ? buildSelectedStage
                      : mode === "active"  ? activeStageSel
                      :                       historyStageSel;
  const setSelectedStage = mode === "build"   ? setBuildSel
                         : mode === "active"  ? setActiveStage
                         :                       setHistoryStage;

  const stage = selectedStage ? WORKFLOW.stages.find(s => s.id === selectedStage) : null;
  const stageStatus = stage && currentJob ? JOB.stageStatus[stage.id] : null;

  // ── Sidebar selection ──────────────────────────────────────────────────
  let sidebar;
  if (mode === "build") {
    sidebar = (
      <WorkflowsSidebar
        activeId={activeWfId}
        onPick={(id) => { setActiveWfId(id); setBuildSel(null); }}
      />
    );
  } else if (mode === "active") {
    sidebar = (
      <JobsSidebar
        kind="active"
        jobs={JOBS_LOG}
        viewMode={activeJobsView}
        onViewMode={setActiveJobsView}
        activeId={activeJobId}
        onPick={(id) => { setActiveJobId(id); setActiveStage(null); }}
      />
    );
  } else {
    // History: the sidebar is a navigator between jobs — only useful once
    // you've drilled into one. With no selection we show the full table
    // alone, so the sidebar would just duplicate it.
    sidebar = historyJobId ? (
      <JobsSidebar
        kind="history"
        jobs={JOBS_LOG}
        viewMode={historyJobsView}
        onViewMode={setHistoryJobsView}
        activeId={historyJobId}
        onPick={(id) => { setHistoryJobId(id); setHistoryStage(null); }}
      />
    ) : null;
  }

  // ── Main canvas + filmstrip column (drawer is a sibling, not overlay) ──
  let canvasArea = null;
  let drawerEl = null;
  if (mode === "build") {
    canvasArea = (
      <Canvas
        workflow={WORKFLOW}
        job={JOB}
        view="builder"
        selectedId={selectedStage}
        onSelect={(id) => setSelectedStage(id === selectedStage ? null : id)}
        canvasStyle={t.canvasStyle}
        edgeStyle={t.edgeStyle}
        density={t.density}
        inflightAnim={t.inflightAnim}
        drawerOpen={!!stage}
      />
    );
    if (stage) {
      drawerEl = <StageDrawer stage={stage} status={null} view="builder" onClose={() => setSelectedStage(null)} />;
    }
  } else if (mode === "active") {
    if (!currentJob) {
      canvasArea = <EmptyMain icon="activity" title="No job selected" subtitle="Pick a running job from the sidebar." />;
    } else {
      canvasArea = (
        <Canvas
          workflow={WORKFLOW}
          job={JOB}
          view="job"
          selectedId={selectedStage}
          onSelect={(id) => setSelectedStage(id === selectedStage ? null : id)}
          canvasStyle={t.canvasStyle}
          edgeStyle={t.edgeStyle}
          density={t.density}
          inflightAnim={t.inflightAnim}
          drawerOpen={!!stage}
        />
      );
      if (stage) drawerEl = <StageDrawer stage={stage} status={stageStatus} view="job" onClose={() => setSelectedStage(null)} />;
    }
  } else {
    // history
    if (!historyJobId) {
      canvasArea = (
        <RunsView
          jobs={historyJobs}
          onPick={(id) => { setHistoryJobId(id); setHistoryStage(null); }}
          activeId={historyJobId}
          viewMode={historyJobsView}
          onViewMode={setHistoryJobsView}
        />
      );
    } else {
      canvasArea = (
        <Canvas
          workflow={WORKFLOW}
          job={JOB}
          view="job"
          selectedId={selectedStage}
          onSelect={(id) => setSelectedStage(id === selectedStage ? null : id)}
          canvasStyle={t.canvasStyle}
          edgeStyle={t.edgeStyle}
          density={t.density}
          inflightAnim={"off"}
          drawerOpen={!!stage}
        />
      );
      if (stage) drawerEl = <StageDrawer stage={stage} status={stageStatus} view="job" onClose={() => setSelectedStage(null)} />;
    }
  }

  // Filmstrip — only in active or history-with-selection
  const showFilmstrip = (mode === "active" && currentJob) || (mode === "history" && historyJobId);

  return (
    <div style={{
      display: "flex", height: "100vh",
      background: "var(--co-bg-0)",
      color: "var(--co-text)",
      fontFamily: "var(--co-font-sans)",
      overflow: "hidden",
    }}>
      <ModeRail mode={mode} onMode={setMode} activeCount={activeJobCount} />
      {sidebar}

      <main style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, position: "relative" }}>
        <TopBar
          mode={mode}
          workflow={WORKFLOW}
          job={currentJob}
          jobState={mode === "history" && currentJob ? currentJob.status : jobState}
          onPlay={() => setJobState("running")}
          onPause={() => setJobState("paused")}
          onStop={() => setJobState("cancelled")}
          onRestart={() => setJobState("running")}
          onSnapshot={() => {}}
          onClearJob={() => { if (mode === "active") setActiveJobId(null); else setHistoryJobId(null); }}
          historyCount={historyJobs.length}
        />

        {/* Below-header region: canvas+filmstrip column on the left,
            drawer on the right. The drawer is a flex sibling, so opening it
            actually narrows the canvas + filmstrip rather than overlaying
            them — they share the available width. */}
        <div style={{ flex: 1, display: "flex", flexDirection: "row", minHeight: 0 }}>
          <div style={{
            flex: 1, minWidth: 0, minHeight: 0,
            display: "flex", flexDirection: "column",
          }}>
            <div style={{ flex: 1, display: "flex", minHeight: 0, position: "relative" }}>
              {canvasArea}
            </div>
            {showFilmstrip && (
              <Filmstrip snapshots={SNAPSHOTS} activeId={activeSnap} onPick={setActiveSnap} />
            )}
          </div>
          {drawerEl}
        </div>
      </main>

      <AppTweaks t={t} setTweak={setTweak} />
    </div>
  );
}

function EmptyMain({ icon, title, subtitle }) {
  return (
    <div style={{
      flex: 1,
      display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center",
      gap: 12,
      color: "var(--co-text-subtle)",
      background: "var(--co-grad-hearth)",
    }}>
      <div style={{
        width: 56, height: 56, borderRadius: 12,
        background: "var(--co-bg-2)",
        border: "1px solid var(--co-border-1)",
        display: "flex", alignItems: "center", justifyContent: "center",
      }}>
        <window.Icon name={icon} size={22} color="var(--co-text-subtle)" />
      </div>
      <div style={{ textAlign: "center" }}>
        <div style={{
          fontFamily: "var(--co-font-display)", fontSize: 16, fontWeight: 500,
          color: "var(--co-text)",
        }}>{title}</div>
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 11.5,
          color: "var(--co-text-subtle)", marginTop: 4,
        }}>{subtitle}</div>
      </div>
    </div>
  );
}

function AppTweaks({ t, setTweak }) {
  return (
    <TweaksPanel title="Tweaks · Trailhead">
      <TweakSection label="Theme">
        <TweakRadio
          label="Palette"
          value={t.theme}
          options={[
            { value: "slate", label: "Slate" },
            { value: "paper", label: "Paper" },
          ]}
          onChange={(v) => setTweak("theme", v)}
        />
        <TweakRadio
          label="Accent"
          value={t.accent}
          options={[
            { value: "orange", label: "Orange" },
            { value: "green",  label: "Green" },
          ]}
          onChange={(v) => setTweak("accent", v)}
        />
      </TweakSection>

      <TweakSection label="Canvas">
        <TweakRadio
          label="Layout"
          value={t.canvasStyle}
          options={[
            { value: "graph",     label: "graph" },
            { value: "swimlane",  label: "lanes" },
            { value: "tree",      label: "tree" },
          ]}
          onChange={(v) => setTweak("canvasStyle", v)}
        />
        <TweakRadio
          label="Edges"
          value={t.edgeStyle}
          options={[
            { value: "curved",     label: "curved" },
            { value: "orthogonal", label: "ortho" },
            { value: "straight",   label: "straight" },
          ]}
          onChange={(v) => setTweak("edgeStyle", v)}
        />
        <TweakRadio
          label="Density"
          value={t.density}
          options={[
            { value: "compact",      label: "compact" },
            { value: "comfortable",  label: "comfy" },
          ]}
          onChange={(v) => setTweak("density", v)}
        />
      </TweakSection>

      <TweakSection label="Job inflight">
        <TweakRadio
          label="Tokens"
          value={t.inflightAnim}
          options={[
            { value: "off",    label: "off" },
            { value: "pulse",  label: "pulse" },
            { value: "tokens", label: "flow" },
          ]}
          onChange={(v) => setTweak("inflightAnim", v)}
        />
      </TweakSection>
    </TweaksPanel>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<App />);
