/* global React, Icon, StatusDot, StatusTag, Tag */

// ──────────────────────────────────────────────────────────────────────────
// Runs (jobs log) view — flat table, no search, sortable by header click.
// ──────────────────────────────────────────────────────────────────────────

function RunsView({ jobs, onPick, activeId }) {
  const totalRuns = jobs.length;
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
          <Pill label="running" count={1} />
          <Pill label="passed"  count={4} />
          <Pill label="failed"  count={1} />
          <Pill label="cancelled" count={1} />
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
          {jobs.map(j => (
            <tr key={j.id}
              onClick={() => onPick(j.id)}
              style={{
                cursor: "pointer",
                background: j.id === activeId ? "var(--co-bg-2)" : "transparent",
                borderBottom: "1px solid var(--co-border-1)",
              }}
              onMouseEnter={e => { if (j.id !== activeId) e.currentTarget.style.background = "var(--co-bg-2)"; }}
              onMouseLeave={e => { if (j.id !== activeId) e.currentTarget.style.background = "transparent"; }}
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
                {(Math.random() * 80 + 20 | 0) + ".4k"}
              </td>
              <td style={{ padding: "10px 14px", fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
                {j.cost}
              </td>
              <td style={{ padding: "10px 14px", color: "var(--co-text-muted)", fontSize: 12 }}>
                {j.by}
              </td>
            </tr>
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
