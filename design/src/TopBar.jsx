/* global React, Icon, IconButton, Button, StatusDot, StatusTag, Tag */
const { useState: useStateTB } = React;

// ──────────────────────────────────────────────────────────────────────────
// Top bar — adapts to the active mode. The mode rail (on the far left)
// is the sole selector for build / active / history. This bar focuses on
// context + actions for whatever the user is currently doing.
// ──────────────────────────────────────────────────────────────────────────

function ContextChip({ icon, label, value, accent }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 5,
      fontFamily: "var(--co-font-mono)", fontSize: 11,
      color: accent ? "var(--co-accent)" : "var(--co-text)",
    }}>
      {icon && <Icon name={icon} size={11} color="currentColor" />}
      {label && <span style={{ color: "var(--co-text-subtle)" }}>{label}</span>}
      <span style={{ fontVariantNumeric: "tabular-nums" }}>{value}</span>
    </span>
  );
}

function JobControls({ state, onPlay, onPause, onStop, onRestart, onSnapshot }) {
  const running = state === "running";
  return (
    <div style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      padding: 3,
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
    }}>
      {running ? (
        <button type="button" onClick={onPause} title="Pause" style={ctrlBtn(false)}>
          <span style={{ display: "inline-flex", gap: 2 }}>
            <span style={{ width: 3, height: 11, background: "currentColor", borderRadius: 1 }} />
            <span style={{ width: 3, height: 11, background: "currentColor", borderRadius: 1 }} />
          </span>
          <span>pause</span>
        </button>
      ) : (
        <button type="button" onClick={onPlay} title="Resume" style={ctrlBtn(true)}>
          <Icon name="play" size={11} />
          <span>{state === "paused" ? "resume" : state === "queued" ? "start" : "resume"}</span>
        </button>
      )}
      <button type="button" onClick={onStop} title="Stop" style={ctrlBtn(false)}>
        <span style={{ width: 9, height: 9, background: "currentColor", display: "inline-block", borderRadius: 1 }} />
        <span>stop</span>
      </button>
      <button type="button" onClick={onRestart} title="Restart from scratch" style={ctrlBtn(false)}>
        <Icon name="refresh" size={11} />
      </button>
      <button type="button" onClick={onSnapshot} title="Take a snapshot" style={ctrlBtn(false)}>
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

// ──────────────────────────────────────────────────────────────────────────

function ModeBadge({ mode }) {
  const meta = mode === "build"   ? { label: "BUILD",   color: "var(--co-text-strong)", bg: "var(--co-bg-3)" }
            : mode === "active"  ? { label: "ACTIVE",  color: "var(--co-accent)",      bg: "var(--co-accent-soft)" }
            :                       { label: "HISTORY", color: "var(--co-text-muted)",  bg: "var(--co-bg-3)" };
  return (
    <span style={{
      fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 700,
      letterSpacing: "0.10em",
      padding: "3px 8px",
      borderRadius: 4,
      background: meta.bg,
      color: meta.color,
      border: `1px solid color-mix(in oklab, ${meta.color} 22%, transparent)`,
    }}>{meta.label}</span>
  );
}

function BuildBar({ workflow }) {
  return (
    <div style={{
      flex: 1,
      display: "flex", alignItems: "center", gap: 12,
      minWidth: 0,
    }}>
      <ModeBadge mode="build" />
      <div style={{ display: "flex", alignItems: "center", gap: 9, flex: "0 1 auto", minWidth: 0 }}>
        <div style={{
          width: 26, height: 26, borderRadius: 6,
          background: "var(--co-grad-trail)",
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: "var(--co-font-mono)", fontSize: 11, color: "#fbf3e6", fontWeight: 700,
          flex: "0 0 26px",
        }}>wf</div>
        <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.15, minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 6, minWidth: 0 }}>
            <span style={{
              fontFamily: "var(--co-font-display)", fontSize: 15, fontWeight: 600,
              color: "var(--co-text-strong)", letterSpacing: "-0.01em",
              overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            }}>{workflow.name}</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", flex: "0 0 auto" }}>v{workflow.version}</span>
            {workflow.draft && workflow.draft !== workflow.version && (
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-warning)",
                background: "var(--co-warning-soft)", padding: "1px 5px", borderRadius: 3, flex: "0 0 auto",
              }}>draft v{workflow.draft}</span>
            )}
          </div>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>
            {workflow.updated}
          </span>
        </div>
      </div>

      <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 8, flex: "0 0 auto" }}>
        <Button variant="ghost" size="sm" icon="copy">duplicate</Button>
        <Button variant="ghost" size="sm" icon="file">YAML</Button>
        <span style={{ width: 1, height: 22, background: "var(--co-border-1)", margin: "0 2px" }} />
        <Button variant="secondary" size="sm">save draft</Button>
        <Button variant="trail" size="sm" icon="play">launch</Button>
      </div>
    </div>
  );
}

function JobBar({ job, mode, jobState, onPlay, onPause, onStop, onRestart, onSnapshot, onClear }) {
  if (!job) {
    return (
      <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 12 }}>
        <ModeBadge mode={mode} />
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text-subtle)" }}>
          {mode === "active" ? "select a running job from the sidebar" : "select a past job — or browse the table"}
        </span>
      </div>
    );
  }
  const stateForTag = jobState === "paused" ? "cancelled"
                    : jobState === "passed" ? "passed"
                    : jobState === "failed" ? "failed"
                    : jobState === "cancelled" ? "cancelled"
                    : "running";

  // Two-row layout. Row 1 is identity + status + actions; Row 2 is the
  // input string + execution stats. This is the only robust way to fit a
  // job id, a workflow tag, an input, a status, three stat values, and
  // five controls into a header at any viewport width.
  return (
    <div style={{
      flex: 1,
      display: "grid",
      gridTemplateRows: "auto auto",
      rowGap: 2,
      minWidth: 0,
    }}>
      {/* Row 1 — identity + status + actions */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, minWidth: 0 }}>
        <ModeBadge mode={mode} />

        <button type="button" onClick={onClear} title="back to list"
          style={{
            background: "transparent", border: "none", padding: 0, cursor: "pointer",
            color: "var(--co-text-subtle)",
            display: "inline-flex", alignItems: "center", justifyContent: "center",
            flex: "0 0 auto",
            width: 18, height: 18,
          }}>
          <span style={{ display: "inline-block", transform: "rotate(180deg)", lineHeight: 0 }}>
            <Icon name="chevRight" size={14} color="currentColor" />
          </span>
        </button>

        {/* Identity — id is the primary, workflow tag is the secondary */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, minWidth: 0, flex: "1 1 auto", overflow: "hidden" }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600,
            color: "var(--co-text-strong)",
            flex: "0 0 auto",
          }}>{job.id}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            padding: "1px 5px", borderRadius: 3,
            background: "var(--co-bg-3)", color: "var(--co-text-muted)",
            border: "1px solid var(--co-border-1)",
            flex: "0 1 auto",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            maxWidth: 180,
          }}>{job.workflow || "pr-reviewer"} · v{job.workflowVersion || 14}</span>
        </div>

        <StatusTag status={stateForTag} />

        {/* Actions — always pinned to the right of row 1 */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, flex: "0 0 auto" }}>
          {mode === "active" && (
            <JobControls state={jobState} onPlay={onPlay} onPause={onPause} onStop={onStop} onRestart={onRestart} onSnapshot={onSnapshot} />
          )}
          {mode === "history" && (
            <>
              <Button variant="ghost" size="sm" icon="file">YAML</Button>
              <Button variant="secondary" size="sm" icon="refresh">rerun</Button>
            </>
          )}
        </div>
      </div>

      {/* Row 2 — input + execution stats. Smaller, mono, single line. */}
      <div style={{
        display: "flex", alignItems: "center", gap: 8,
        fontFamily: "var(--co-font-mono)", fontSize: 11,
        color: "var(--co-text-subtle)",
        minWidth: 0,
        paddingLeft: 24, // align beneath the back arrow + identity
        whiteSpace: "nowrap",
      }}>
        <span style={{ color: "var(--co-text-subtle)" }}>input</span>
        <span style={{
          color: "var(--co-text-muted)",
          minWidth: 0,
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        }}>{job.input || "PR #1428"}</span>

        <span style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 10, flex: "0 0 auto" }}>
          <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}>
            <Icon name="clock" size={10} color="var(--co-text-subtle)" />
            <span style={{ color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
              {Math.floor(job.elapsedSec/60)}m{String(job.elapsedSec%60).padStart(2,"0")}s
            </span>
          </span>
          <span style={{ color: "var(--co-border-2)" }}>·</span>
          <span style={{ color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
            {(job.tokens/1000).toFixed(1)}k tok
          </span>
          <span style={{ color: "var(--co-border-2)" }}>·</span>
          <span style={{ color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
            ${job.costUsd.toFixed(2)}
          </span>
        </span>
      </div>
    </div>
  );
}

function HistoryListBar({ count }) {
  return (
    <div style={{ flex: 1, display: "flex", alignItems: "center", gap: 12 }}>
      <ModeBadge mode="history" />
      <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.15 }}>
        <span style={{
          fontFamily: "var(--co-font-display)", fontSize: 15, fontWeight: 600,
          color: "var(--co-text-strong)", letterSpacing: "-0.01em",
        }}>Past jobs</span>
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>
          {count} runs · last 24h
        </span>
      </div>
      <div style={{ marginLeft: "auto", display: "flex", alignItems: "center", gap: 8 }}>
        <Button variant="ghost" size="sm" icon="refresh">refresh</Button>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────

function TopBar({
  mode, workflow, job, jobState,
  onPlay, onPause, onStop, onRestart, onSnapshot, onClearJob,
  historyCount,
}) {
  // The job header needs two rows to fit identity + stats + actions at any
  // width. Build/list headers only need one — but keep min-height consistent
  // so the canvas position doesn't jump when modes change.
  const isJobView = (mode === "active" && job) || (mode === "history" && job);
  return (
    <header style={{
      minHeight: 56,
      flex: "0 0 auto",
      borderBottom: "1px solid var(--co-border-1)",
      background: "color-mix(in oklab, var(--co-bg-1) 92%, transparent)",
      backdropFilter: "blur(8px)",
      display: "flex", alignItems: "center",
      padding: isJobView ? "8px 14px" : "0 14px",
      position: "relative",
      zIndex: 30,
    }}>
      {mode === "build" && <BuildBar workflow={workflow} />}
      {mode === "active" && (
        <JobBar
          job={job} mode="active" jobState={jobState}
          onPlay={onPlay} onPause={onPause} onStop={onStop} onRestart={onRestart} onSnapshot={onSnapshot}
          onClear={onClearJob}
        />
      )}
      {mode === "history" && !job && <HistoryListBar count={historyCount} />}
      {mode === "history" && job && (
        <JobBar
          job={job} mode="history" jobState={jobState}
          onPlay={onPlay} onPause={onPause} onStop={onStop} onRestart={onRestart} onSnapshot={onSnapshot}
          onClear={onClearJob}
        />
      )}
    </header>
  );
}

Object.assign(window, { TopBar });
