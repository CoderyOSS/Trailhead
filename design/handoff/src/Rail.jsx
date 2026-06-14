/* global React, Icon */
const { useState: useStateRail } = React;

// ──────────────────────────────────────────────────────────────────────────
// Mode rail — slim icon column on the far left. Three modes:
//   build   → workflow editor (no job state)
//   active  → running/paused/queued jobs (live inflight)
//   history → past jobs (passed/failed/cancelled)
//
// The rail is the *only* way to move between these three concerns. Each mode
// has its own inner sidebar; the top bar adapts; there is no in-page tab
// toggle that mixes them.
// ──────────────────────────────────────────────────────────────────────────

function RailButton({ icon, label, active, badge, onClick }) {
  const [hover, setHover] = useStateRail(false);
  return (
    <button
      type="button"
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      title={label}
      style={{
        position: "relative",
        width: 40, height: 40,
        margin: "2px 6px",
        display: "flex", alignItems: "center", justifyContent: "center",
        background: active ? "var(--co-bg-4)" : hover ? "var(--co-bg-3)" : "transparent",
        border: "none",
        borderRadius: 8,
        cursor: "pointer",
        color: active ? "var(--co-accent)" : hover ? "var(--co-text-strong)" : "var(--co-text-muted)",
        transition: "background 140ms var(--co-ease-out), color 140ms var(--co-ease-out)",
      }}
    >
      {active && (
        <span style={{
          position: "absolute", left: -6, top: 8, bottom: 8, width: 2,
          background: "var(--co-accent)", borderRadius: 2,
        }} />
      )}
      <Icon name={icon} size={16} color="currentColor" />

      {/* Mode label appears on hover as a flyout */}
      {hover && (
        <span style={{
          position: "absolute", left: "calc(100% + 8px)", top: "50%",
          transform: "translateY(-50%)",
          padding: "4px 8px",
          background: "var(--co-bg-4)",
          border: "1px solid var(--co-border-2)",
          borderRadius: 5,
          fontFamily: "var(--co-font-mono)", fontSize: 11,
          color: "var(--co-text-strong)",
          whiteSpace: "nowrap",
          boxShadow: "var(--co-shadow-2)",
          pointerEvents: "none",
          zIndex: 100,
        }}>{label}</span>
      )}

      {/* Numeric badge — e.g. active job count */}
      {badge != null && badge > 0 && (
        <span style={{
          position: "absolute", top: 4, right: 4,
          minWidth: 14, height: 14,
          padding: "0 4px",
          borderRadius: 999,
          background: active ? "var(--co-accent)" : "var(--co-bg-5)",
          color: active ? "var(--co-accent-ink)" : "var(--co-text-strong)",
          fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 700,
          display: "flex", alignItems: "center", justifyContent: "center",
          lineHeight: 1,
        }}>{badge}</span>
      )}
    </button>
  );
}

function ModeRail({ mode, onMode, activeCount }) {
  return (
    <div style={{
      width: 52, flex: "0 0 52px",
      height: "100vh",
      background: "var(--co-bg-0)",
      borderRight: "1px solid var(--co-border-1)",
      display: "flex", flexDirection: "column",
      alignItems: "stretch",
      zIndex: 40,
    }}>
      {/* Brand glyph */}
      <div style={{
        height: 52, flex: "0 0 52px",
        display: "flex", alignItems: "center", justifyContent: "center",
        borderBottom: "1px solid var(--co-border-1)",
      }}>
        <img src="assets/trailhead-logo.svg" alt="Trailhead" width="28" height="28" />
      </div>

      {/* Modes */}
      <div style={{ display: "flex", flexDirection: "column", paddingTop: 8, gap: 1 }}>
        <RailButton
          icon="pencil"
          label="Build · workflows"
          active={mode === "build"}
          onClick={() => onMode("build")}
        />
        <RailButton
          icon="stopwatch"
          label="Active · running jobs"
          active={mode === "active"}
          badge={activeCount}
          onClick={() => onMode("active")}
        />
        <RailButton
          icon="list"
          label="History · past jobs"
          active={mode === "history"}
          onClick={() => onMode("history")}
        />
      </div>

      {/* Bottom — secondary actions */}
      <div style={{
        marginTop: "auto", display: "flex", flexDirection: "column",
        paddingBottom: 8, gap: 1,
      }}>
        <RailButton icon="terminal" label="CLI · tokens" onClick={() => {}} />
        <RailButton icon="settings" label="Settings" onClick={() => {}} />
        <div style={{
          margin: "8px 12px 0",
          paddingTop: 8,
          borderTop: "1px solid var(--co-border-1)",
          display: "flex", justifyContent: "center",
        }}>
          <div style={{
            width: 28, height: 28, borderRadius: 999,
            background: "var(--co-grad-trail)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontFamily: "var(--co-font-mono)", fontSize: 10, color: "#fbf3e6", fontWeight: 700,
          }}>jb</div>
        </div>
      </div>
    </div>
  );
}

Object.assign(window, { ModeRail });
