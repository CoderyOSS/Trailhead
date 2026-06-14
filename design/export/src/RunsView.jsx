/* global React, Icon, StatusDot, StatusTag, Tag, ViewToggle */
const { useMemo: useMemoRuns } = React;

// ──────────────────────────────────────────────────────────────────────────
// Runs (jobs log) view — flat table, no search, sortable by header click.
// ──────────────────────────────────────────────────────────────────────────

function RunsView({ jobs, onPick, activeId, viewMode = "flat", onViewMode }) {
  const totalRuns = jobs.length;

  // Group by workflow for grouped mode — same grouping the sidebar uses.
  const groups = useMemoRuns(() => {
    const m = new Map();
    for (const j of jobs) {
      if (!m.has(j.workflow)) m.set(j.workflow, []);
      m.get(j.workflow).push(j);
    }
    return [...m.entries()].map(([name, items]) => ({ name, items }));
  }, [jobs]);
  return (
    <div style={{ flex: 1, overflow: "auto", background: "var(--co-bg-0)" }}>
      <div style={{
        padding: "20px 24px 12px",
        display: "flex", alignItems: "center", justifyContent: "space-between",
        borderBottom: "1px solid var(--co-border-1)",
      }}>
        <div>
          <div style={{
            fontFamily: "var(--co-font-display)", fontSize: 20, fontWeight: 600,
            color: "var(--co-text-strong)", letterSpacing: "-0.01em",
          }}>jobs · pr-reviewer</div>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11,
            color: "var(--co-text-subtle)", marginTop: 2,
          }}>{totalRuns.toLocaleString()} runs · last 24h</div>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
          <Pill label="all" count={totalRuns} active />
          <Pill label="passed"  count={4} />
          <Pill label="failed"  count={1} />
          <Pill label="cancelled" count={1} />
          {onViewMode && (
            <>
              <span style={{ width: 1, height: 18, background: "var(--co-border-1)", margin: "0 2px" }} />
              <ViewToggle value={viewMode} onChange={onViewMode} />
            </>
          )}
        </div>
      </div>

      <table style={{
        width: "100%", borderCollapse: "collapse",
        fontFamily: "var(--co-font-sans)", fontSize: 12.5,
      }}>
        <thead>
          <tr style={{ background: "var(--co-bg-1)" }}>
            {["", "run id", "input", "status", "started", "duration", "tokens", "cost", "by"].map((h, i) => (
              <th key={i} style={{
                textAlign: i === 0 ? "center" : "left",
                padding: "8px 14px",
                fontFamily: "var(--co-font-mono)", fontSize: 10,
                letterSpacing: "0.06em", textTransform: "uppercase",
                color: "var(--co-text-subtle)", fontWeight: 500,
                borderBottom: "1px solid var(--co-border-1)",
                whiteSpace: "nowrap",
              }}>{h}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {viewMode === "grouped"
            ? groups.map(g => (
                <React.Fragment key={g.name}>
                  <tr>
                    <td colSpan={9} style={{
                      padding: "9px 14px 5px",
                      background: "var(--co-bg-1)",
                      borderBottom: "1px solid var(--co-border-1)",
                    }}>
                      <span style={{
                        display: "inline-flex", alignItems: "center", gap: 7,
                        fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 600,
                        color: "var(--co-text-strong)",
                      }}>
                        <span style={{ width: 4, height: 4, borderRadius: 999, background: "var(--co-fg-3)" }} />
                        {g.name}
                        <span style={{ color: "var(--co-text-subtle)", fontWeight: 400 }}>{g.items.length}</span>
                      </span>
                    </td>
                  </tr>
                  {g.items.map(j => (
                    <RunRow key={j.id} job={j} active={j.id === activeId} onPick={onPick} />
                  ))}
                </React.Fragment>
              ))
            : jobs.map(j => (
                <RunRow key={j.id} job={j} active={j.id === activeId} onPick={onPick} />
              ))}
        </tbody>
      </table>

      <div style={{
        padding: "14px 24px",
        color: "var(--co-text-subtle)",
        fontFamily: "var(--co-font-mono)", fontSize: 11,
        textAlign: "center",
      }}>
        showing {jobs.length} of {totalRuns.toLocaleString()} · no search yet
      </div>
    </div>
  );
}

function RunRow({ job: j, active, onPick }) {
  return (
    <tr
      onClick={() => onPick(j.id)}
      style={{
        cursor: "pointer",
        background: active ? "var(--co-bg-2)" : "transparent",
        borderBottom: "1px solid var(--co-border-1)",
      }}
      onMouseEnter={e => { if (!active) e.currentTarget.style.background = "var(--co-bg-2)"; }}
      onMouseLeave={e => { if (!active) e.currentTarget.style.background = "transparent"; }}
    >
      <td style={{ padding: "10px 14px", textAlign: "center", width: 30 }}>
        <StatusDot status={j.status} pulse={j.status === "running"} />
      </td>
      <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text-strong)" }}>
        {j.id}
      </td>
      <td style={{ padding: "10px 14px", color: "var(--co-text)" }}>
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5 }}>{j.input}</span>
      </td>
      <td style={{ padding: "10px 14px" }}>
        <StatusTag status={j.status} />
      </td>
      <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
        {j.started}
      </td>
      <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
        {j.dur}
      </td>
      <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text-muted)", fontVariantNumeric: "tabular-nums" }}>
        {(() => {
          // Stable pseudo-token count derived from the id (no real field in the
          // mock). Deterministic so it doesn't flicker when the view re-renders.
          let h = 0; for (const c of j.id) h = (h * 31 + c.charCodeAt(0)) | 0;
          return (Math.abs(h) % 80 + 20).toFixed(0) + ".4k";
        })()}
      </td>
      <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
        {j.cost}
      </td>
      <td style={{ padding: "10px 14px", color: "var(--co-text-muted)", fontSize: 12 }}>
        {j.by}
      </td>
    </tr>
  );
}

function Pill({ label, count, active }) {
  return (
    <button type="button" style={{
      display: "inline-flex", alignItems: "center", gap: 6,
      padding: "4px 10px",
      fontFamily: "var(--co-font-mono)", fontSize: 11,
      background: active ? "var(--co-bg-3)" : "transparent",
      color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
      border: `1px solid ${active ? "var(--co-border-3)" : "var(--co-border-1)"}`,
      borderRadius: 999,
      cursor: "pointer",
    }}>
      {label}
      <span style={{ color: "var(--co-text-subtle)", fontVariantNumeric: "tabular-nums" }}>{count}</span>
    </button>
  );
}

Object.assign(window, { RunsView });
