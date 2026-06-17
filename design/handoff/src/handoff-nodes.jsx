/* global React, Icon */
// ──────────────────────────────────────────────────────────────────────────
// Faithful node specimens for the handoff doc — a 1:1 reproduction of the
// chosen "Direction F" family from the Node System Exploration:
//   · one single-line capsule, led by a golden role-tile (the shared anchor)
//   · neutral connector dots on the edges (no colored status rail)
//   · branch grows tall, one labeled output port per case
//   · map = a plain worker capsule (forEach glyph), single output, no ×n chip
// Status (passed / failed / running) shows in the straddling top pill; a
// selected node gets the crisp accent ring. There is NO left-edge highlight.
// Graph layout wires left→right; tree layout wires top→bottom.
// ──────────────────────────────────────────────────────────────────────────

const HN_MONO = "var(--co-font-mono)";

// ── connector dot — neutral on every node, every role ──────────────────────
const HN_DOT = {
  position: "absolute", width: 8, height: 8, borderRadius: 999,
  background: "var(--co-bg-3)", border: "1.5px solid var(--co-border-3)", zIndex: 4,
};
const hnInH  = { ...HN_DOT, left: -4,   top: "50%", transform: "translateY(-50%)" };
const hnOutH = { ...HN_DOT, right: -4,  top: "50%", transform: "translateY(-50%)" };
const hnInV  = { ...HN_DOT, top: -4,    left: "50%", transform: "translateX(-50%)" };
const hnOutV = { ...HN_DOT, bottom: -4, left: "50%", transform: "translateX(-50%)" };

// ── selected connector dot — the orange output-handle treatment (12px accent
//    dot, bg-1 ring, accent glow), applied to a selected node's connectors ──
const HN_DOT_SEL = {
  position: "absolute", width: 12, height: 12, borderRadius: 999,
  background: "var(--co-accent)", border: "2px solid var(--co-bg-1)",
  boxShadow: "0 0 0 1px var(--co-accent), 0 0 8px color-mix(in oklab, var(--co-accent) 50%, transparent)",
  zIndex: 4,
};
const hnSelInH  = { ...HN_DOT_SEL, left: -6,   top: "50%", transform: "translateY(-50%)" };
const hnSelOutH = { ...HN_DOT_SEL, right: -6,  top: "50%", transform: "translateY(-50%)" };
const hnSelInV  = { ...HN_DOT_SEL, top: -6,    left: "50%", transform: "translateX(-50%)" };
const hnSelOutV = { ...HN_DOT_SEL, bottom: -6, left: "50%", transform: "translateX(-50%)" };

// ── shared capsule shell ────────────────────────────────────────────────
function hnShell(selected, running) {
  return {
    position: "relative", zIndex: 2,
    width: "100%", height: "100%", boxSizing: "border-box",
    borderRadius: 10, overflow: "hidden", display: "flex",
    background: running
      ? "linear-gradient(180deg, color-mix(in oklab, var(--co-accent) 12%, var(--co-bg-2)) 0%, var(--co-bg-2) 70%)"
      : "var(--co-grad-loaf)",
    border: `1px solid ${selected ? "var(--co-accent)" : "var(--co-border-2)"}`,
    boxShadow: selected
      ? "0 0 0 1px var(--co-accent), 0 0 0 4px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)"
      : running
        ? "0 0 14px color-mix(in oklab, var(--co-accent) 30%, transparent), var(--co-shadow-1)"
        : "var(--co-shadow-1)",
  };
}
const hnTile = {
  width: 30, flexShrink: 0, alignSelf: "stretch", display: "flex", alignItems: "center",
  justifyContent: "center", background: "var(--co-grad-crust)", color: "var(--co-accent-ink)",
  borderRight: "1px solid var(--co-border-2)",
};
const hnLabel = {
  flex: 1, minWidth: 0, padding: "0 10px", fontFamily: HN_MONO, fontSize: 13, fontWeight: 600,
  color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
  display: "flex", alignItems: "center",
};

// ── status pill — solid fill, straddles the top border ──────────────────────
function HNStatusTag({ st }) {
  if (!st || st === "queued") return null;
  const solid = {
    passed:  { bg: "var(--co-success)", fg: "color-mix(in oklab, var(--co-success) 32%, #000)" },
    failed:  { bg: "var(--co-danger)",  fg: "color-mix(in oklab, var(--co-danger) 34%, #000)" },
    running: { bg: "var(--co-accent)",  fg: "color-mix(in oklab, var(--co-accent) 38%, #000)" },
  }[st] || { bg: "var(--co-bg-4)", fg: "var(--co-text-strong)" };
  return (
    <div style={{
      position: "absolute", top: -8, right: 8, zIndex: 5,
      display: "inline-flex", alignItems: "center", gap: 4,
      height: 16, padding: "0 7px", borderRadius: 999,
      fontFamily: HN_MONO, fontSize: 9, fontWeight: 600,
      letterSpacing: "0.02em", lineHeight: 1, whiteSpace: "nowrap",
      background: solid.bg, color: solid.fg,
    }}>
      {st === "running" && (
        <span style={{
          width: 10, height: 10, borderRadius: "50%",
          background: `radial-gradient(farthest-side, ${solid.fg} 94%, transparent) top/2px 2px no-repeat, conic-gradient(transparent 30%, ${solid.fg})`,
          WebkitMask: "radial-gradient(farthest-side, transparent calc(100% - 2px), #000 0)",
          mask: "radial-gradient(farthest-side, transparent calc(100% - 2px), #000 0)",
          animation: "co-spin 0.8s infinite linear", flexShrink: 0,
        }} />
      )}
      {st}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  WORKER + MAP — one single-line capsule (map only differs by glyph + label)
// ══════════════════════════════════════════════════════════════════════════
function HNWorker({ icon = "bot", label = "full-review", status, selected, layout = "graph" }) {
  const st = status && status.status;
  const running = st === "running";
  const tree = layout === "tree";
  return (
    <div style={{ position: "relative", width: 168, height: 36 }}>
      <div style={{ ...hnShell(selected, running), alignItems: "center" }}>
        <span style={hnTile}><Icon name={icon} size={14} color="currentColor" /></span>
        <span style={hnLabel}>{label}</span>
      </div>
      <HNStatusTag st={st} />
      <span style={selected ? (tree ? hnSelInV : hnSelInH) : (tree ? hnInV : hnInH)} />
      <span style={selected ? (tree ? hnSelOutV : hnSelOutH) : (tree ? hnOutV : hnOutH)} />
    </div>
  );
}

const HN_CASES = [
  { case: "high",    muted: false },
  { case: "medium",  muted: false },
  { case: "low",     muted: false },
  { case: "default", muted: true  },
];
const hnCaseColor = (c) => (c.muted ? "var(--co-text-subtle)" : "var(--co-text)");

// ── branch · graph layout — grows tall, one labeled output port per case ────
function HNBranchGraph({ status, selected }) {
  const st = status && status.status;
  const running = st === "running";
  const rowH = 27, padY = 9;
  const H = padY * 2 + HN_CASES.length * rowH;
  return (
    <div style={{ position: "relative", width: 130, height: H }}>
      <div style={hnShell(selected, running)}>
        <span style={hnTile}><Icon name="gitBranch" size={14} color="currentColor" /></span>
        <div style={{ flex: 1, minWidth: 0, padding: `${padY}px 0`, display: "flex", flexDirection: "column" }}>
          {HN_CASES.map((c, i) => (
            <div key={i} style={{ height: rowH, display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "0 12px 0 11px" }}>
              <span style={{ fontFamily: HN_MONO, fontSize: 12, fontWeight: c.muted ? 500 : 600, color: hnCaseColor(c), whiteSpace: "nowrap" }}>{c.case}</span>
            </div>
          ))}
        </div>
      </div>
      <HNStatusTag st={st} />
      <span style={hnInH} />
      {HN_CASES.map((c, i) => (
        <span key={i} style={{ ...HN_DOT, right: -4, top: padY + i * rowH + rowH / 2, transform: "translateY(-50%)" }} />
      ))}
    </div>
  );
}

// ── branch · tree layout — worker-width bar, case ports fan along the bottom,
//    labels sit in the connector lane beneath each port ──────────────────────
function HNBranchTree({ status, selected }) {
  const st = status && status.status;
  const running = st === "running";
  const W = 168, n = HN_CASES.length, slot = W / n;
  return (
    <div style={{ position: "relative", width: W, height: 36, marginBottom: 24 }}>
      <div style={{ ...hnShell(selected, running), alignItems: "center" }}>
        <span style={hnTile}><Icon name="gitBranch" size={14} color="currentColor" /></span>
        <span style={hnLabel}>branch</span>
      </div>
      <HNStatusTag st={st} />
      <span style={hnInV} />
      {HN_CASES.map((c, i) => {
        const left = slot * (i + 0.5);
        return (
          <React.Fragment key={i}>
            <span style={{ ...HN_DOT, bottom: -4, left, transform: "translateX(-50%)" }} />
            <span style={{ position: "absolute", top: 44, left, transform: "translateX(-50%)", fontFamily: HN_MONO, fontSize: 9.5, fontWeight: c.muted ? 500 : 600, color: hnCaseColor(c), whiteSpace: "nowrap" }}>{c.case}</span>
          </React.Fragment>
        );
      })}
    </div>
  );
}

// ── labelled specimen wrapper — caption under each node, on a dot-grid stage ─
function HNSpec({ caption, children }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 12 }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>{children}</div>
      <span style={{ fontFamily: HN_MONO, fontSize: 10.5, letterSpacing: "0.05em", color: "var(--co-text-subtle)" }}>{caption}</span>
    </div>
  );
}

function HNFamilyRow({ layout }) {
  const Branch = layout === "tree" ? HNBranchTree : HNBranchGraph;
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: "36px 48px", alignItems: layout === "tree" ? "flex-start" : "center", justifyContent: "center", padding: "10px 0 6px" }}>
      <HNSpec caption="worker"><HNWorker icon="bot" label="full-review" layout={layout} /></HNSpec>
      <HNSpec caption="branch"><Branch /></HNSpec>
      <HNSpec caption="map"><HNWorker icon="forEach" label="comment-file" layout={layout} /></HNSpec>
    </div>
  );
}

Object.assign(window, { HNWorker, HNBranchGraph, HNBranchTree, HNSpec, HNFamilyRow, HN_CASES });
