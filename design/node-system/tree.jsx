/* global React, Icon, Spec */
// ──────────────────────────────────────────────────────────────────────────
// Built on the chosen direction F (role-tile + clean ports):
//   · Worker icon options — the F worker capsule shown with candidate glyphs.
//   · Tree mode           — the F family with connections running vertically
//                           (input on the top edge, outputs on the bottom).
// ──────────────────────────────────────────────────────────────────────────

const TR_MONO = "var(--co-font-mono)";
const GOLD = { bg: "var(--co-grad-crust)", fg: "var(--co-accent-ink)" };

const TR_CASES = [
  { case: "high",    muted: false },
  { case: "medium",  muted: false },
  { case: "low",     muted: false },
  { case: "default", muted: true  },
];
function trCaseColor(c) { return c.muted ? "var(--co-text-subtle)" : "var(--co-text)"; }

// ── ports ───────────────────────────────────────────────────────────────
// neutral dot — every node uses the same connector color.
const PORT = { width: 8, height: 8, borderRadius: 999, background: "var(--co-bg-3)", border: "1.5px solid var(--co-border-3)", zIndex: 3, position: "absolute" };
function PortInH()  { return <span style={{ ...PORT, left: -4,  top: "50%", transform: "translateY(-50%)" }} />; }
function PortOutH() { return <span style={{ ...PORT, right: -4, top: "50%", transform: "translateY(-50%)" }} />; }
function PortInV()  { return <span style={{ ...PORT, top: -4,    left: "50%", transform: "translateX(-50%)" }} />; }
function PortOutV() { return <span style={{ ...PORT, bottom: -4, left: "50%", transform: "translateX(-50%)" }} />; }
function PortBottom({ left }) { return <span style={{ ...PORT, bottom: -4, left, transform: "translateX(-50%)" }} />; }

// ── the F capsule, shared shell ───────────────────────────────────────────
const capsule = {
  position: "relative", zIndex: 2,
  width: "100%", height: "100%", boxSizing: "border-box",
  borderRadius: 10, overflow: "hidden", display: "flex", alignItems: "center",
  background: "var(--co-grad-loaf)", border: "1px solid var(--co-border-2)",
  boxShadow: "var(--co-shadow-1)",
};
const tileStyle = {
  width: 30, height: "100%", flexShrink: 0, display: "flex", alignItems: "center",
  justifyContent: "center", background: GOLD.bg, color: GOLD.fg,
  borderRight: "1px solid var(--co-border-2)",
};
const labelStyle = {
  flex: 1, minWidth: 0, padding: "0 10px", fontFamily: TR_MONO, fontSize: 13, fontWeight: 600,
  color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
};
function DynChip() {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px", borderRadius: 999, background: "color-mix(in oklab, var(--co-accent) 15%, transparent)", border: "1px solid color-mix(in oklab, var(--co-accent) 32%, transparent)", color: "var(--co-accent)", fontFamily: TR_MONO, fontSize: 9.5, fontWeight: 700 }}>
      ×<i style={{ marginLeft: 0.5 }}>n</i>
    </span>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  WORKER ICON OPTIONS — horizontal F worker capsule, candidate glyphs
// ══════════════════════════════════════════════════════════════════════════
function WorkerCapsuleH({ icon, label = "full-review", width = 168 }) {
  return (
    <div style={{ position: "relative", width, height: 36 }}>
      <div style={capsule}>
        <span style={tileStyle}><Icon name={icon} size={14} color="currentColor" /></span>
        <span style={labelStyle}>{label}</span>
      </div>
      <PortInH /><PortOutH />
    </div>
  );
}
const WORKER_ICONS = ["zap", "bot", "cpu", "sparkles", "terminal", "box", "activity", "play"];
function IconOptions() {
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "24px 28px", justifyContent: "center", maxWidth: 620 }}>
      {WORKER_ICONS.map((ic) => (
        <div key={ic} style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 9 }}>
          <WorkerCapsuleH icon={ic} width={166} />
          <span style={{ fontFamily: TR_MONO, fontSize: 10, letterSpacing: "0.05em", color: "var(--co-text-subtle)" }}>{ic}</span>
        </div>
      ))}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  TREE MODE — vertical connections
// ══════════════════════════════════════════════════════════════════════════
function TreeWorker({ icon = "bot", label = "full-review", stack }) {
  return (
    <div style={{ position: "relative", width: 168, height: 36 }}>
      <div style={capsule}>
        <span style={tileStyle}><Icon name={icon} size={14} color="currentColor" /></span>
        <span style={labelStyle}>{label}</span>
        {stack && <span style={{ paddingRight: 9 }}><DynChip /></span>}
      </div>
      <PortInV /><PortOutV />
    </div>
  );
}

// Branch — cases laid out as columns inside the bar; one output port drops
// from the bottom edge beneath each column, so the fork fans downward.
function TreeBranchInline({ cases = TR_CASES }) {
  const tileW = 30, cellW = 62, H = 40;
  const W = tileW + cases.length * cellW;
  return (
    <div style={{ position: "relative", width: W, height: H }}>
      <div style={{ ...capsule, alignItems: "stretch" }}>
        <span style={{ ...tileStyle, height: "auto" }}><Icon name="gitBranch" size={14} color="currentColor" /></span>
        <div style={{ flex: 1, display: "flex" }}>
          {cases.map((c, i) => (
            <div key={i} style={{ width: cellW, display: "flex", alignItems: "center", justifyContent: "center", borderLeft: i ? "1px solid var(--co-border-2)" : "none" }}>
              <span style={{ fontFamily: TR_MONO, fontSize: 11, fontWeight: c.muted ? 500 : 600, color: trCaseColor(c) }}>{c.case}</span>
            </div>
          ))}
        </div>
      </div>
      <PortInV />
      {cases.map((c, i) => <PortBottom key={i} left={tileW + i * cellW + cellW / 2} />)}
    </div>
  );
}

// Branch — compact: bar stays worker-width; case labels live in the connector
// lane beneath each output port.
function TreeBranchCompact({ cases = TR_CASES }) {
  const W = 168, n = cases.length, slot = W / n;
  return (
    <div style={{ position: "relative", width: W, height: 36, marginBottom: 24 }}>
      <div style={capsule}>
        <span style={tileStyle}><Icon name="gitBranch" size={14} color="currentColor" /></span>
        <span style={labelStyle}>branch</span>
      </div>
      <PortInV />
      {cases.map((c, i) => {
        const left = slot * (i + 0.5);
        return (
          <React.Fragment key={i}>
            <PortBottom left={left} />
            <span style={{ position: "absolute", top: 44, left, transform: "translateX(-50%)", fontFamily: TR_MONO, fontSize: 9.5, fontWeight: c.muted ? 500 : 600, color: trCaseColor(c), whiteSpace: "nowrap" }}>{c.case}</span>
          </React.Fragment>
        );
      })}
    </div>
  );
}

function TreeFamily() {
  return (
    <>
      <Spec caption="worker"><TreeWorker icon="bot" label="full-review" /></Spec>
      <Spec caption="branch"><TreeBranchCompact /></Spec>
      <Spec caption="map"><TreeWorker icon="forEach" label="comment-file" /></Spec>
    </>
  );
}

Object.assign(window, { IconOptions, TreeFamily });
