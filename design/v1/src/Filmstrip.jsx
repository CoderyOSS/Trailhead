/* global React, Icon, IconButton, StatusDot, SNAPSHOTS */
const { useState: useStateFS } = React;

// ──────────────────────────────────────────────────────────────────────────
// Snapshot filmstrip — bottom panel during job view. Each snapshot is a
// thumbnail of the canvas state at that moment, plus a label and time.
// ──────────────────────────────────────────────────────────────────────────

function SnapshotCard({ snap, active, onClick }) {
  const isLive = snap.kind === "live";
  const isManual = snap.kind === "manual";
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        flex: "0 0 180px",
        display: "flex", flexDirection: "column",
        background: active ? "var(--co-bg-3)" : "var(--co-bg-2)",
        border: `1px solid ${active ? "var(--co-accent)" : "var(--co-border-1)"}`,
        borderRadius: 8,
        padding: 8,
        cursor: "pointer",
        textAlign: "left",
        position: "relative",
        boxShadow: active ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 18%, transparent)" : "none",
        transition: "border-color 140ms, box-shadow 140ms, transform 100ms",
      }}
      onMouseEnter={e => { if (!active) e.currentTarget.style.transform = "translateY(-1px)"; }}
      onMouseLeave={e => { e.currentTarget.style.transform = ""; }}
    >
      {/* thumbnail */}
      <SnapshotThumbnail snap={snap} active={active} />

      {/* meta */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 7, gap: 6 }}>
        <div style={{ minWidth: 0, flex: 1 }}>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            color: "var(--co-text-strong)", fontWeight: 500,
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          }}>{snap.label}</div>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)",
          }}>
            {snap.at} · {snap.kind}
          </div>
        </div>
        {isLive && <StatusDot status="running" pulse size={6} />}
        {isManual && (
          <span title="manual snapshot" style={{ color: "var(--co-accent)" }}>
            <Icon name="bookmark" size={11} />
          </span>
        )}
      </div>

      {/* note */}
      {snap.note && (
        <div style={{
          marginTop: 4,
          fontSize: 10.5,
          color: "var(--co-text-muted)",
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          fontStyle: isManual ? "italic" : "normal",
        }}>{snap.note}</div>
      )}
    </button>
  );
}

// Tiny graph sketch — abstract dots-and-lines preview of pipeline state.
function SnapshotThumbnail({ snap, active }) {
  // Use a fixed 12-stage abstraction: 5 dots before, current is bigger, rest queued.
  const stages = [
    { x: 12,  c: "passed" },
    { x: 36,  c: "passed" },
    { x: 60,  c: "passed" },
    { x: 84,  c: snap.cursor === "ingest"     ? "active" : "passed" },
    { x: 100, c: snap.cursor === "classify"   ? "active" : "passed" },
    { x: 116, c: snap.cursor === "route_risk" ? "active" : (snap.label === "classified" || snap.label === "fan-out" || snap.label === "pinned" || snap.label === "now") ? "passed" : "pending" },
  ];
  // After route_risk, two parallel branches.
  const isAfterFanout = snap.cursor === "full_review" || snap.label === "fan-out";
  const branches = [
    { y: 4, c: isAfterFanout ? "active" : "pending" },
    { y: 16, c: isAfterFanout ? "active" : "pending" },
  ];
  return (
    <div style={{
      width: "100%", aspectRatio: "16 / 9",
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 6,
      position: "relative",
      overflow: "hidden",
    }}>
      <svg viewBox="0 0 164 36" width="100%" height="100%" style={{ position: "absolute", inset: 0 }}>
        {/* main spine */}
        <line x1="6"  y1="18" x2="140" y2="18" stroke="var(--co-border-2)" strokeWidth="1" />
        {/* branch lines after fan-out */}
        <path d={`M ${116} 18 L ${130} 10 L ${152} 10`} fill="none" stroke={isAfterFanout ? "var(--co-accent)" : "var(--co-border-2)"} strokeWidth="1" strokeDasharray={isAfterFanout ? "0" : "2 2"} />
        <path d={`M ${116} 18 L ${130} 26 L ${152} 26`} fill="none" stroke={isAfterFanout ? "var(--co-accent)" : "var(--co-border-2)"} strokeWidth="1" strokeDasharray={isAfterFanout ? "0" : "2 2"} />

        {/* stage dots */}
        {stages.map((s, i) => {
          const fill = s.c === "passed" ? "var(--co-success)" : s.c === "active" ? "var(--co-accent)" : "var(--co-fg-4)";
          return (
            <circle key={i} cx={s.x} cy={18} r={s.c === "active" ? 3.2 : 2.4} fill={fill}
              opacity={s.c === "pending" ? 0.4 : 1} />
          );
        })}
        {/* branch endpoints */}
        <circle cx="152" cy="10" r={isAfterFanout ? 3.2 : 2.4} fill={isAfterFanout ? "var(--co-accent)" : "var(--co-fg-4)"} opacity={isAfterFanout ? 1 : 0.4} />
        <circle cx="152" cy="26" r={isAfterFanout ? 3.2 : 2.4} fill={isAfterFanout ? "var(--co-accent)" : "var(--co-fg-4)"} opacity={isAfterFanout ? 1 : 0.4} />
      </svg>
    </div>
  );
}

function Filmstrip({ snapshots, activeId, onPick, onNew }) {
  return (
    <div style={{
      flex: "0 0 auto",
      borderTop: "1px solid var(--co-border-1)",
      background: "var(--co-bg-1)",
      padding: "10px 14px 12px",
      display: "flex", flexDirection: "column", gap: 8,
      zIndex: 5,
    }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            letterSpacing: "0.08em", textTransform: "uppercase",
            color: "var(--co-text-subtle)", fontWeight: 500,
          }}>snapshots · {snapshots.length}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)",
          }}>resume / rerun from any point</span>
        </div>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <button type="button" onClick={onNew} style={{
            display: "inline-flex", alignItems: "center", gap: 4,
            padding: "3px 8px",
            fontFamily: "var(--co-font-sans)", fontSize: 11,
            background: "transparent",
            color: "var(--co-text-muted)",
            border: "1px solid var(--co-border-2)",
            borderRadius: 5,
            cursor: "pointer",
          }}>
            <Icon name="bookmark" size={10} />
            snapshot now
          </button>
        </div>
      </div>
      <div style={{
        display: "flex", gap: 8, overflowX: "auto",
        paddingBottom: 2,
      }}>
        {snapshots.map(s => (
          <SnapshotCard key={s.id} snap={s} active={s.id === activeId} onClick={() => onPick(s.id)} />
        ))}
        <button type="button" style={{
          flex: "0 0 60px",
          display: "flex", alignItems: "center", justifyContent: "center",
          background: "transparent",
          border: "1px dashed var(--co-border-2)",
          borderRadius: 8,
          cursor: "pointer",
          color: "var(--co-text-subtle)",
        }} title="auto-snapshots are taken at every stage boundary">
          <Icon name="plus" size={14} />
        </button>
      </div>
    </div>
  );
}

Object.assign(window, { Filmstrip });
