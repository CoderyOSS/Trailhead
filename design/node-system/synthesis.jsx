/* global React, Icon, NS_MONO, nsBigLabel, nsSubLabel, ChassisChip, Spec */
// ──────────────────────────────────────────────────────────────────────────
// Synthesis directions — built from round-1 feedback:
//   · keep C's leading role-tile        (shared identity anchor)
//   · keep D's consistent header strips  (role legible at a glance)
//   · keep E's clean connector dots      (role read at the edges)
//   · map has ONE output; parallelism is dynamic (×n, never a fixed count)
// ──────────────────────────────────────────────────────────────────────────

const SY_MONO = "var(--co-font-mono)";

// A branch can route to many cases — demo set of 4 to show "variable height".
const BRANCH_CASES = [
  { case: "high",    muted: false },
  { case: "medium",  muted: false },
  { case: "low",     muted: false },
  { case: "default", muted: true  },
];
function caseColor(c) { return c.muted ? "var(--co-text-subtle)" : "var(--co-text)"; }
// One accent output port at an absolute y on the node's right edge.
function CasePort({ top }) {
  return <span style={{ position: "absolute", right: -4, top, transform: "translateY(-50%)", width: 8, height: 8, borderRadius: 999, background: "var(--co-bg-3)", border: "1.5px solid var(--co-border-3)", zIndex: 3 }} />;
}

// ── shared connector ports ────────────────────────────────────────────────
function SyIn() {
  return <span style={{ position: "absolute", left: -4, top: "50%", transform: "translateY(-50%)", width: 8, height: 8, borderRadius: 999, background: "var(--co-bg-3)", border: "1.5px solid var(--co-border-3)", zIndex: 3 }} />;
}
// worker + map → ONE output. branch → a fork of N case outputs (accent).
function SyOut({ fork }) {
  if (fork) {
    return <>{[18, 50, 82].map((t, i) => (
      <span key={i} style={{ position: "absolute", right: -4, top: t + "%", transform: "translateY(-50%)", width: 8, height: 8, borderRadius: 999, background: "var(--co-bg-3)", border: "1.5px solid var(--co-accent)", zIndex: 3 }} />
    ))}</>;
  }
  return <span style={{ position: "absolute", right: -4, top: "50%", transform: "translateY(-50%)", width: 8, height: 8, borderRadius: 999, background: "var(--co-bg-3)", border: "1.5px solid var(--co-border-3)", zIndex: 3 }} />;
}
// Dynamic-multiplicity chip: ×n  (n italic) — parallelism unknown at plan time.
function DynChip() {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px", borderRadius: 999, background: "color-mix(in oklab, var(--co-accent) 15%, transparent)", border: "1px solid color-mix(in oklab, var(--co-accent) 32%, transparent)", color: "var(--co-accent)", fontFamily: SY_MONO, fontSize: 9.5, fontWeight: 700 }}>
      ×<i style={{ marginLeft: 0.5 }}>n</i>
    </span>
  );
}

// Role → tile palette (used by both synthesis directions).
function roleTile(role) {
  // Shared golden role-tile across every role — single identity anchor.
  return { bg: "var(--co-grad-crust)", fg: "var(--co-accent-ink)", bd: "transparent" };
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION F — Role-tile + clean ports   (C ⊕ E)
//  One single-line capsule for all. Leading role-tile is the shared anchor;
//  role also reads at the edges. Map keeps one output + an ×n chip for its
//  dynamic, runtime-set fan width.
// ══════════════════════════════════════════════════════════════════════════
function FNode({ icon, role, label, fork, stack }) {
  const t = roleTile(role);
  return (
    <div style={{ position: "relative", width: 196, height: 36 }}>
      <div style={{
        position: "relative", zIndex: 2,
        width: "100%", height: "100%", boxSizing: "border-box",
        borderRadius: 10, overflow: "hidden", display: "flex", alignItems: "center",
        background: "var(--co-grad-loaf)", border: "1px solid var(--co-border-2)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <span style={{ width: 30, height: "100%", flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: t.bg, borderRight: `1px solid ${t.bd === "transparent" ? "var(--co-border-2)" : t.bd}`, color: t.fg }}>
          <Icon name={icon} size={14} color="currentColor" />
        </span>
        <span style={{ flex: 1, minWidth: 0, padding: "0 10px", fontFamily: SY_MONO, fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{label}</span>
        {stack && <span style={{ paddingRight: 9 }}><DynChip /></span>}
      </div>
      <SyIn /><SyOut fork={fork} />
    </div>
  );
}
function DirF() {
  return (
    <>
      <Spec caption="worker"><FNode icon="bot" role="worker" label="full-review" /></Spec>
      <Spec caption="branch"><FBranchNode /></Spec>
      <Spec caption="map"><FNode icon="forEach" role="map" label="comment-file" /></Spec>
    </>
  );
}

// F branch — same leading role-tile, but grows tall to give every case its own
// labeled output port down the right edge.
function FBranchNode() {
  const t = roleTile("branch");
  const rowH = 27, padY = 9;
  const H = padY * 2 + BRANCH_CASES.length * rowH;
  return (
    <div style={{ position: "relative", width: 130, height: H }}>
      <div style={{
        position: "relative", zIndex: 2,
        width: "100%", height: "100%", boxSizing: "border-box",
        borderRadius: 10, overflow: "hidden", display: "flex",
        background: "var(--co-grad-loaf)", border: "1px solid var(--co-border-2)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <span style={{ width: 30, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: t.bg, borderRight: `1px solid ${t.bd}`, color: t.fg }}>
          <Icon name="gitBranch" size={14} color="currentColor" />
        </span>
        <div style={{ flex: 1, minWidth: 0, padding: `${padY}px 0`, display: "flex", flexDirection: "column" }}>
          {BRANCH_CASES.map((c, i) => (
            <div key={i} style={{ height: rowH, display: "flex", alignItems: "center", justifyContent: "flex-end", padding: "0 12px 0 11px" }}>
              <span style={{ fontFamily: SY_MONO, fontSize: 12, fontWeight: c.muted ? 500 : 600, color: caseColor(c), whiteSpace: "nowrap", flexShrink: 0 }}>{c.case}</span>
            </div>
          ))}
        </div>
      </div>
      <SyIn />
      {BRANCH_CASES.map((c, i) => <CasePort key={i} top={padY + i * rowH + rowH / 2} />)}
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION G — Header strip + clean ports   (D ⊕ E)
//  Every node = a header strip over a body, plus clean ports.
//  Map: ONE output + an ×n chip for its dynamic, runtime-set fan width.
// ══════════════════════════════════════════════════════════════════════════
function gHeader() {
  // One neutral header for every role. Golden/crust is reserved for the
  // selected state, so it never appears on a resting node — role reads from
  // the icon + kind label, not the header color.
  return { bg: "var(--co-bg-3)", fg: "var(--co-text-muted)" };
}
function GNode({ icon, role, kind, fork, stack, children }) {
  const h = gHeader(role);
  return (
    <div style={{ position: "relative", width: 180, height: 72 }}>
      <div style={{
        position: "relative", zIndex: 2,
        width: "100%", height: "100%", boxSizing: "border-box",
        borderRadius: 12, overflow: "hidden",
        background: "var(--co-bg-2)", border: "1px solid var(--co-border-2)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: 24, background: h.bg, color: h.fg }}>
          <Icon name={icon} size={12} color="currentColor" />
          <span style={{ flex: 1, fontFamily: SY_MONO, fontSize: 10, fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase" }}>{kind}</span>
          {stack && <DynChip />}
        </div>
        <div style={{ padding: "8px 11px" }}>{children}</div>
      </div>
      <SyIn /><SyOut fork={fork} />
    </div>
  );
}
function DirG() {
  return (
    <>
      <Spec caption="worker">
        <GNode icon="zap" role="worker" kind="worker">
          <div style={nsBigLabel}>full-review</div>
          <div style={nsSubLabel}>sonnet-4.5</div>
        </GNode>
      </Spec>
      <Spec caption="branch"><GBranchNode /></Spec>
      <Spec caption="map">
        <GNode icon="forEach" role="map" kind="map">
          <div style={nsBigLabel}>comment-file</div>
          <div style={nsSubLabel}>maps ingest.files</div>
        </GNode>
      </Spec>
    </>
  );
}

// G branch — header strip stays a pure label; the node grows tall and lists
// each case as a labeled row in the BODY, with its output port aligned to the
// row (never over the header).
function GBranchNode() {
  const h = gHeader("branch");
  const headerH = 24, padTop = 9, padBot = 9, rowH = 26;
  const H = headerH + padTop + BRANCH_CASES.length * rowH + padBot;
  const portTop = (i) => headerH + padTop + i * rowH + rowH / 2;
  return (
    <div style={{ position: "relative", width: 116, height: H }}>
      <div style={{
        position: "relative", zIndex: 2,
        width: "100%", height: "100%", boxSizing: "border-box",
        borderRadius: 12, overflow: "hidden",
        background: "var(--co-bg-2)", border: "1px solid var(--co-border-2)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: headerH, background: h.bg, color: h.fg }}>
          <Icon name="gitBranch" size={12} color="currentColor" />
          <span style={{ flex: 1, fontFamily: SY_MONO, fontSize: 10, fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase" }}>branch</span>
        </div>
        <div style={{ padding: `${padTop}px 0`, display: "flex", flexDirection: "column" }}>
          {BRANCH_CASES.map((c, i) => (
            <div key={i} style={{ height: rowH, display: "flex", alignItems: "center", justifyContent: "flex-start", paddingLeft: 27 }}>
              <span style={{ fontFamily: SY_MONO, fontSize: 12, fontWeight: c.muted ? 500 : 600, color: caseColor(c) }}>{c.case}</span>
            </div>
          ))}
        </div>
      </div>
      <SyIn />
      {BRANCH_CASES.map((c, i) => <CasePort key={i} top={portTop(i)} />)}
    </div>
  );
}

Object.assign(window, { DirF, DirG });
