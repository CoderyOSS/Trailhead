/* global React, Icon, IconButton, Eyebrow, StatusDot, Button, WORKFLOWS_LIST */
const { useState: useStateWS } = React;

// ──────────────────────────────────────────────────────────────────────────
// Build mode sidebar — list of workflows.
// Click a workflow to load it in the builder canvas. Active workflows show
// a live-job pip beside their name (with count).
// ──────────────────────────────────────────────────────────────────────────

function WorkflowRow({ wf, active, onClick }) {
  const [hover, setHover] = useStateWS(false);
  return (
    <button
      type="button"
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "grid",
        gridTemplateColumns: "1fr auto",
        alignItems: "center",
        gap: 8,
        width: "calc(100% - 12px)",
        margin: "0 6px",
        padding: "8px 10px",
        background: active ? "var(--co-bg-3)" : hover ? "var(--co-bg-2)" : "transparent",
        border: "none",
        borderRadius: 6,
        textAlign: "left",
        cursor: "pointer",
        position: "relative",
        transition: "background 140ms var(--co-ease-out)",
      }}
    >
      {active && (
        <span style={{ position: "absolute", left: -6, top: 8, bottom: 8, width: 2, borderRadius: 2, background: "var(--co-accent)" }} />
      )}
      <div style={{ minWidth: 0 }}>
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 12.5,
          color: active ? "var(--co-text-strong)" : "var(--co-text)",
          fontWeight: active ? 600 : 500,
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        }}>{wf.name}</div>
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 10,
          color: "var(--co-text-subtle)",
          marginTop: 1,
        }}>
          {wf.runs.toLocaleString()} runs · last {wf.last}
        </div>
      </div>
      {wf.active > 0 && (
        <span style={{
          display: "inline-flex", alignItems: "center", gap: 4,
          fontFamily: "var(--co-font-mono)", fontSize: 10,
          color: "var(--co-accent)",
        }}>
          <StatusDot status="running" pulse size={5} />
          {wf.active}
        </span>
      )}
    </button>
  );
}

function WorkflowsSidebar({ activeId, onPick }) {
  return (
    <aside style={{
      width: 240, flex: "0 0 240px",
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
          }}>Workflows</div>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10.5,
            color: "var(--co-text-subtle)", marginTop: 2,
          }}>edit plans · {WORKFLOWS_LIST.length} total</div>
        </div>
        <Button variant="secondary" size="sm" icon="plus">new workflow</Button>
      </div>

      <div style={{ flex: 1, overflowY: "auto", padding: "8px 0" }}>
        <div style={{
          padding: "0 14px 6px",
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          letterSpacing: "0.08em", textTransform: "uppercase",
          color: "var(--co-text-subtle)", fontWeight: 500,
        }}>all</div>
        <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
          {WORKFLOWS_LIST.map(wf => (
            <WorkflowRow key={wf.id} wf={wf} active={wf.id === activeId} onClick={() => onPick(wf.id)} />
          ))}
        </div>
      </div>
    </aside>
  );
}

Object.assign(window, { WorkflowsSidebar });
