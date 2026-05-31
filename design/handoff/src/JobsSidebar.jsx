/* global React, Icon, IconButton, StatusDot, StatusTag, Button */
const { useState: useStateJS, useMemo: useMemoJS } = React;

// ──────────────────────────────────────────────────────────────────────────
// Jobs sidebar — used in both Active and History modes.
//
// Two view modes (toggleable):
//   grouped  → jobs nested under their workflow header
//   flat     → flat list with workflow shown as a tag chip
//
// `kind` controls which job statuses are shown:
//   kind="active"   → running, paused, queued, retrying
//   kind="history"  → passed, failed, cancelled
// ──────────────────────────────────────────────────────────────────────────

const ACTIVE_STATUSES  = new Set(["running", "paused", "queued", "retrying"]);
const HISTORY_STATUSES = new Set(["passed",  "failed", "cancelled"]);

function ViewToggle({ value, onChange }) {
  return (
    <div style={{
      display: "inline-flex",
      background: "var(--co-bg-3)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 6,
      padding: 2,
    }}>
      {[
        { v: "grouped", icon: "workflow", label: "grouped" },
        { v: "flat",    icon: "file",     label: "flat" },
      ].map(o => {
        const active = o.v === value;
        return (
          <button
            key={o.v}
            type="button"
            onClick={() => onChange(o.v)}
            title={o.label}
            style={{
              padding: "3px 8px",
              display: "inline-flex", alignItems: "center", gap: 4,
              background: active ? "var(--co-bg-4)" : "transparent",
              color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
              border: "none",
              borderRadius: 4,
              cursor: "pointer",
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
            }}
          >
            <Icon name={o.icon} size={10} color={active ? "var(--co-accent)" : "currentColor"} />
            {o.label}
          </button>
        );
      })}
    </div>
  );
}

function WorkflowTag({ name }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 3,
      fontFamily: "var(--co-font-mono)", fontSize: 9.5,
      padding: "1px 5px",
      background: "var(--co-bg-3)",
      color: "var(--co-text-muted)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 3,
      whiteSpace: "nowrap",
    }}>
      <span style={{ width: 3, height: 3, background: "var(--co-fg-3)", borderRadius: 999 }} />
      {name}
    </span>
  );
}

function JobRowFlat({ job, active, onClick }) {
  const [hover, setHover] = useStateJS(false);
  return (
    <button
      type="button"
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "grid",
        gridTemplateColumns: "10px 1fr auto",
        alignItems: "center",
        gap: 8,
        width: "calc(100% - 12px)",
        margin: "0 6px",
        padding: "7px 10px",
        background: active ? "var(--co-bg-3)" : hover ? "var(--co-bg-2)" : "transparent",
        border: "none",
        borderRadius: 6,
        textAlign: "left",
        cursor: "pointer",
        position: "relative",
      }}
    >
      {active && (
        <span style={{ position: "absolute", left: -6, top: 7, bottom: 7, width: 2, borderRadius: 2, background: "var(--co-accent)" }} />
      )}
      <StatusDot status={job.status} pulse={job.status === "running"} size={6} />
      <div style={{ minWidth: 0 }}>
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 11.5,
          color: active ? "var(--co-text-strong)" : "var(--co-text)",
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          display: "flex", alignItems: "center", gap: 6,
        }}>
          <span>{job.input}</span>
        </div>
        <div style={{
          display: "flex", alignItems: "center", gap: 5,
          marginTop: 2,
        }}>
          <WorkflowTag name={job.workflow} />
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 9.5,
            color: "var(--co-text-subtle)",
          }}>{job.id.slice(2, 9)}</span>
        </div>
      </div>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        color: "var(--co-text-subtle)",
        fontVariantNumeric: "tabular-nums",
      }}>{job.started}</span>
    </button>
  );
}

function JobRowGrouped({ job, active, onClick }) {
  const [hover, setHover] = useStateJS(false);
  return (
    <button
      type="button"
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "grid",
        gridTemplateColumns: "10px 1fr auto",
        alignItems: "center",
        gap: 8,
        width: "calc(100% - 24px)",
        margin: "0 6px 0 18px",
        padding: "5px 10px",
        background: active ? "var(--co-bg-3)" : hover ? "var(--co-bg-2)" : "transparent",
        border: "none",
        borderRadius: 6,
        textAlign: "left",
        cursor: "pointer",
        position: "relative",
      }}
    >
      {active && (
        <span style={{ position: "absolute", left: -18, top: 6, bottom: 6, width: 2, borderRadius: 2, background: "var(--co-accent)" }} />
      )}
      <StatusDot status={job.status} pulse={job.status === "running"} size={6} />
      <div style={{
        fontFamily: "var(--co-font-mono)", fontSize: 11.5,
        color: active ? "var(--co-text-strong)" : "var(--co-text)",
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
      }}>
        {job.input}
        <span style={{ color: "var(--co-text-subtle)", marginLeft: 6, fontSize: 10 }}>{job.id.slice(2, 9)}</span>
      </div>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        color: "var(--co-text-subtle)",
        fontVariantNumeric: "tabular-nums",
      }}>{job.started}</span>
    </button>
  );
}

function GroupHeader({ name, count, open, onToggle }) {
  return (
    <button
      type="button"
      onClick={onToggle}
      style={{
        display: "flex", alignItems: "center", gap: 6,
        width: "calc(100% - 12px)",
        margin: "8px 6px 2px",
        padding: "4px 6px",
        background: "transparent",
        border: "none",
        borderRadius: 4,
        cursor: "pointer",
        textAlign: "left",
        color: "var(--co-text-muted)",
      }}
    >
      <Icon name="chevRight" size={9} color="currentColor" />
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 11,
        fontWeight: 600,
        color: "var(--co-text-strong)",
      }}>{name}</span>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        color: "var(--co-text-subtle)",
      }}>{count}</span>
    </button>
  );
}

// ──────────────────────────────────────────────────────────────────────────

function JobsSidebar({ kind, jobs, viewMode, onViewMode, activeId, onPick }) {
  // Filter by mode
  const filtered = useMemoJS(() => {
    const set = kind === "active" ? ACTIVE_STATUSES : HISTORY_STATUSES;
    return jobs.filter(j => set.has(j.status));
  }, [jobs, kind]);

  // Group for grouped mode
  const groups = useMemoJS(() => {
    const m = new Map();
    for (const j of filtered) {
      if (!m.has(j.workflow)) m.set(j.workflow, []);
      m.get(j.workflow).push(j);
    }
    return [...m.entries()].map(([name, items]) => ({ name, items }));
  }, [filtered]);

  const title = kind === "active" ? "Active jobs" : "History";
  const subtitle = kind === "active"
    ? `${filtered.length} running · paused · queued`
    : `${filtered.length} completed · last 24h`;

  return (
    <aside style={{
      width: 260, flex: "0 0 260px",
      height: "100vh",
      background: "var(--co-bg-1)",
      borderRight: "1px solid var(--co-border-1)",
      display: "flex", flexDirection: "column",
      fontFamily: "var(--co-font-sans)",
    }}>
      {/* Header */}
      <div style={{
        padding: "14px 14px 12px",
        borderBottom: "1px solid var(--co-border-1)",
        display: "flex", flexDirection: "column", gap: 10,
      }}>
        <div>
          <div style={{
            fontFamily: "var(--co-font-display)", fontSize: 15, fontWeight: 600,
            color: "var(--co-text-strong)", letterSpacing: "-0.01em",
          }}>{title}</div>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10.5,
            color: "var(--co-text-subtle)", marginTop: 2,
          }}>{subtitle}</div>
        </div>
        <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
          <ViewToggle value={viewMode} onChange={onViewMode} />
          {kind === "history" && (
            <button type="button" title="filter (no search yet)" style={{
              background: "transparent",
              border: "1px solid var(--co-border-1)",
              borderRadius: 5,
              padding: "3px 6px",
              cursor: "pointer",
              color: "var(--co-text-muted)",
              display: "inline-flex", alignItems: "center", gap: 4,
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
            }}>
              <Icon name="settings" size={10} />
              filter
            </button>
          )}
        </div>
      </div>

      {/* Body */}
      <div style={{ flex: 1, overflowY: "auto", padding: "4px 0 12px" }}>
        {filtered.length === 0 && <EmptyState kind={kind} />}

        {viewMode === "flat" && filtered.length > 0 && (
          <div style={{ display: "flex", flexDirection: "column", gap: 1, paddingTop: 4 }}>
            {filtered.map(j => (
              <JobRowFlat key={j.id} job={j} active={j.id === activeId} onClick={() => onPick(j.id)} />
            ))}
          </div>
        )}

        {viewMode === "grouped" && groups.map(g => (
          <div key={g.name}>
            <GroupHeader name={g.name} count={g.items.length} open onToggle={() => {}} />
            <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
              {g.items.map(j => (
                <JobRowGrouped key={j.id} job={j} active={j.id === activeId} onClick={() => onPick(j.id)} />
              ))}
            </div>
          </div>
        ))}
      </div>

      {/* Footer */}
      <div style={{
        padding: "8px 12px",
        borderTop: "1px solid var(--co-border-1)",
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        color: "var(--co-text-subtle)",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <span>showing {filtered.length}</span>
        {kind === "history" && <span>no search yet</span>}
        {kind === "active" && <span style={{ display: "inline-flex", alignItems: "center", gap: 4 }}><StatusDot status="running" pulse size={5} /> live</span>}
      </div>
    </aside>
  );
}

function EmptyState({ kind }) {
  return (
    <div style={{
      padding: "32px 20px",
      textAlign: "center",
      color: "var(--co-text-subtle)",
      fontFamily: "var(--co-font-mono)", fontSize: 11,
      lineHeight: 1.6,
    }}>
      {kind === "active"
        ? "no active jobs — start one from the Build view"
        : "no past jobs yet"}
    </div>
  );
}

Object.assign(window, { JobsSidebar, ViewToggle });
