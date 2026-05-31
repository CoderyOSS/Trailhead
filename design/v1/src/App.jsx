/* global React, ReactDOM,
   Sidebar, TopBar, Canvas, StageDrawer, Filmstrip, RunsView,
   TweaksPanel, TweakSection, TweakRadio, TweakColor, TweakSlider, TweakToggle, useTweaks,
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

function App() {
  const [t, setTweak] = useTweaks(TWEAK_DEFAULTS);

  const [view, setView]            = useStateApp("job");        // builder | job | runs
  const [activeWf, setActiveWf]    = useStateApp(WORKFLOW.id);
  const [activeJob, setActiveJob]  = useStateApp(JOB.id);
  const [selectedId, setSelectedId] = useStateApp(null);
  const [activeSnap, setActiveSnap] = useStateApp("s5");
  const [jobState, setJobState]    = useStateApp(JOB.state);

  // Apply theme + accent via data attributes — themes.css does the rest.
  useEffectApp(() => {
    document.documentElement.dataset.themeVariant = t.theme || "hearth";
    // Toggle the underlying [data-theme] for any component (or built-in
    // light/dark token in colors_and_type.css) that keys off it.
    document.documentElement.dataset.theme = t.theme === "paper" ? "light" : "dark";
    document.documentElement.dataset.accent = t.accent;
  }, [t.theme, t.accent]);

  // (Drawer starts closed — the canvas is the first thing the user sees.)

  const stage = selectedId ? WORKFLOW.stages.find(s => s.id === selectedId) : null;
  const stageStatus = stage ? JOB.stageStatus[stage.id] : null;

  return (
    <div style={{
      display: "flex", height: "100vh",
      background: "var(--co-bg-0)",
      color: "var(--co-text)",
      fontFamily: "var(--co-font-sans)",
      overflow: "hidden",
    }}>
      <Sidebar
        activeWorkflow={activeWf} onWorkflow={setActiveWf}
        activeJob={activeJob} onJob={(id) => { setActiveJob(id); setView("job"); }}
        jobs={JOBS_LOG}
      />

      <main style={{ flex: 1, display: "flex", flexDirection: "column", minWidth: 0, position: "relative" }}>
        <TopBar
          workflow={WORKFLOW}
          job={JOB}
          view={view}
          onView={setView}
          jobState={jobState}
          onPlay={() => setJobState("running")}
          onPause={() => setJobState("paused")}
          onStop={() => setJobState("cancelled")}
          onRestart={() => setJobState("running")}
          onSnapshot={() => {}}
        />

        <div style={{ flex: 1, display: "flex", minHeight: 0, position: "relative" }}>
          {view !== "runs" ? (
            <>
              <Canvas
                workflow={WORKFLOW}
                job={JOB}
                view={view}
                selectedId={selectedId}
                onSelect={(id) => setSelectedId(id === selectedId ? null : id)}
                canvasStyle={t.canvasStyle}
                edgeStyle={t.edgeStyle}
                density={t.density}
                inflightAnim={t.inflightAnim}
                drawerOpen={!!stage}
              />
              {stage && (
                <StageDrawer
                  stage={stage}
                  status={view === "job" ? stageStatus : null}
                  view={view}
                  onClose={() => setSelectedId(null)}
                />
              )}
            </>
          ) : (
            <RunsView jobs={JOBS_LOG} onPick={(id) => { setActiveJob(id); setView("job"); }} activeId={activeJob} />
          )}
        </div>

        {/* Filmstrip — only in job view */}
        {view === "job" && (
          <Filmstrip
            snapshots={SNAPSHOTS}
            activeId={activeSnap}
            onPick={setActiveSnap}
            onNew={() => {}}
          />
        )}
      </main>

      <AppTweaks t={t} setTweak={setTweak} />
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
            { value: "hearth",    label: "Hearth" },
            { value: "slate",     label: "Slate" },
            { value: "trailhead", label: "Forest" },
            { value: "paper",     label: "Paper" },
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
