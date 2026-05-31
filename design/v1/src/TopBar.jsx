/* global React, Icon, IconButton, Button, StatusDot, StatusTag, Tag */
const { useState: useStateTB } = React;

// Segmented control — "Builder" / "Job" / "Runs".
function ViewToggle({ value, onChange, options }) {
  return (
    <div style={{
      display: "inline-flex",
      padding: 2,
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
      gap: 0,
      fontFamily: "var(--co-font-sans)",
    }}>
      {options.map(o => {
        const active = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            style={{
              padding: "4px 12px",
              fontSize: 12,
              fontWeight: 500,
              border: "none",
              background: active ? "var(--co-bg-4)" : "transparent",
              color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
              borderRadius: 6,
              cursor: "pointer",
              display: "inline-flex", alignItems: "center", gap: 5,
              transition: "background 120ms var(--co-ease-out)",
            }}
          >
            {o.icon && <Icon name={o.icon} size={12} color={active ? "var(--co-accent)" : "currentColor"} />}
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

function JobMeta({ job }) {
  const fmt = (n) => n.toLocaleString();
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 12, fontFamily: "var(--co-font-mono)", fontSize: 11 }}>
      <span style={{ color: "var(--co-text-subtle)" }}>{job.id}</span>
      <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}>
        <Icon name="clock" size={11} color="var(--co-text-subtle)" />
        <span style={{ color: "var(--co-text)" }}>{Math.floor(job.elapsedSec/60)}m{String(job.elapsedSec%60).padStart(2,"0")}s</span>
      </span>
      <span style={{ color: "var(--co-text-subtle)" }}>·</span>
      <span style={{ color: "var(--co-text)" }}>{fmt(job.tokens)} tok</span>
      <span style={{ color: "var(--co-text-subtle)" }}>·</span>
      <span style={{ color: "var(--co-text)" }}>${job.costUsd.toFixed(2)}</span>
    </div>
  );
}

function JobControls({ state, onPlay, onPause, onStop, onRestart, onSnapshot }) {
  const running = state === "running";
  return (
    <div style={{ display: "inline-flex", alignItems: "center", gap: 4, padding: 3, background: "var(--co-bg-2)", border: "1px solid var(--co-border-1)", borderRadius: 8 }}>
      {running ? (
        <button type="button" onClick={onPause} title="Pause"
          style={ctrlBtn(false)}>
          <Icon name="zap" size={13} />
          <span>pause</span>
        </button>
      ) : (
        <button type="button" onClick={onPlay} title="Resume"
          style={ctrlBtn(true)}>
          <Icon name="play" size={11} />
          <span>{state === "paused" ? "resume" : "start"}</span>
        </button>
      )}
      <button type="button" onClick={onStop} title="Stop" style={ctrlBtn(false)}>
        <span style={{ width: 9, height: 9, background: "currentColor", display: "inline-block", borderRadius: 1 }} />
        <span>stop</span>
      </button>
      <button type="button" onClick={onRestart} title="Restart" style={ctrlBtn(false)}>
        <Icon name="refresh" size={11} />
      </button>
      <button type="button" onClick={onSnapshot} title="Snapshot" style={ctrlBtn(false)}>
        <Icon name="bookmark" size={11} />
      </button>
    </div>
  );
}
function ctrlBtn(primary) {
  return {
    display: "inline-flex", alignItems: "center", gap: 5,
    padding: "3px 10px",
    fontSize: 11.5, fontWeight: 500,
    fontFamily: "var(--co-font-sans)",
    background: primary ? "var(--co-grad-crust)" : "transparent",
    color: primary ? "var(--co-accent-ink)" : "var(--co-text)",
    border: "none",
    borderRadius: 5,
    cursor: "pointer",
    boxShadow: primary ? "0 1px 0 0 rgba(255,255,255,0.16) inset, 0 2px 6px color-mix(in oklab, var(--co-accent-400) 30%, transparent)" : "none",
  };
}

function TopBar({
  workflow, job, view, onView,
  jobState, onPlay, onPause, onStop, onRestart, onSnapshot,
}) {
  return (
    <header style={{
      height: 52, flex: "0 0 52px",
      borderBottom: "1px solid var(--co-border-1)",
      background: "color-mix(in oklab, var(--co-bg-1) 92%, transparent)",
      backdropFilter: "blur(8px)",
      display: "flex", alignItems: "center", gap: 10,
      padding: "0 14px",
      position: "relative",
      zIndex: 30,
      whiteSpace: "nowrap",
    }}>
      {/* Workflow identity */}
      <div style={{ display: "flex", alignItems: "center", gap: 9, flex: "0 0 auto" }}>
        <div style={{
          width: 26, height: 26, borderRadius: 6,
          background: "var(--co-grad-trail)",
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: "var(--co-font-mono)", fontSize: 11, color: "#fbf3e6", fontWeight: 700,
          flex: "0 0 26px",
        }}>wf</div>
        <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.15 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <span style={{ fontFamily: "var(--co-font-display)", fontSize: 15, fontWeight: 600, color: "var(--co-text-strong)", letterSpacing: "-0.01em" }}>
              {workflow.name}
            </span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>v{workflow.version}</span>
            {workflow.draft && workflow.draft !== workflow.version && (
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-warning)",
                background: "var(--co-warning-soft)", padding: "1px 5px", borderRadius: 3,
              }}>draft v{workflow.draft}</span>
            )}
          </div>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>
            {workflow.updated}
          </span>
        </div>
      </div>

      <span style={{ width: 1, height: 22, background: "var(--co-border-1)", margin: "0 2px", flex: "0 0 1px" }} />

      <ViewToggle value={view} onChange={onView} options={[
        { value: "builder", label: "builder", icon: "layout" },
        { value: "job",     label: "job",     icon: "activity" },
        { value: "runs",    label: "runs",    icon: "file" },
      ]} />

      {view === "job" && job && (
        <div style={{ display: "flex", alignItems: "center", gap: 10, flex: "0 1 auto", minWidth: 0, overflow: "hidden" }}>
          <span style={{ width: 1, height: 22, background: "var(--co-border-1)", flex: "0 0 1px" }} />
          <span style={{ flex: "0 0 auto" }}><StatusTag status={jobState === "paused" ? "queued" : jobState === "passed" ? "passed" : "running"} /></span>
          <JobMeta job={job} />
        </div>
      )}

      <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 8, flex: "0 0 auto" }}>
        {view === "builder" && (
          <>
            <Button variant="ghost" size="sm" icon="copy">duplicate</Button>
            <Button variant="ghost" size="sm" icon="file">YAML</Button>
            <span style={{ width: 1, height: 22, background: "var(--co-border-1)", margin: "0 2px" }} />
            <Button variant="secondary" size="sm">save draft</Button>
            <Button variant="trail" size="sm" icon="play">test run</Button>
          </>
        )}
        {view === "job" && (
          <JobControls
            state={jobState}
            onPlay={onPlay} onPause={onPause}
            onStop={onStop} onRestart={onRestart} onSnapshot={onSnapshot}
          />
        )}
        {view === "runs" && (
          <>
            <Button variant="ghost" size="sm" icon="refresh">refresh</Button>
            <Button variant="primary" size="sm" icon="play">new run</Button>
          </>
        )}
      </div>
    </header>
  );
}

Object.assign(window, { TopBar });
