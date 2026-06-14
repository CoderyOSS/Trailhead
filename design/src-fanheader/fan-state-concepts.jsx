/* global React, Icon */
// ──────────────────────────────────────────────────────────────────────────
// Fan capsule · deselected-state alternatives.
//
// The complaint: the idle (deselected) fan capsule borrows the accent border
// + accent glow — the exact chrome that means "selected" on a worker node.
// Every concept below keeps the gradient header bar but reserves the accent
// outline/halo for actual selection.
//
// Each board shows the same control row:
//   worker · deselected | worker · selected | fan · deselected | fan · selected
// ──────────────────────────────────────────────────────────────────────────

const FSC = { workerW: 168, nodeH: 64, fanW: 168, fanH: 76 };

// Selection chrome — identical to the live canvas (src/Canvas.jsx).
const FSC_SEL_WORKER =
  "0 0 0 1px var(--co-accent), 0 0 0 4px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)";
const FSC_SEL_FAN =
  "0 0 0 3px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)";

// ── Canvas surface — hearth + 32px dot grid, like the real builder ────────
function FscCanvas({ w, h, children }) {
  return (
    <div style={{ position: "relative", width: w, height: h, overflow: "hidden", background: "var(--co-grad-hearth)", backgroundColor: "var(--co-bg-0)" }}>
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: "radial-gradient(circle, var(--co-border-2) 1px, transparent 1px)",
        backgroundSize: "32px 32px", backgroundPosition: "16px 16px",
        opacity: 0.4, pointerEvents: "none",
      }}></div>
      {children}
    </div>
  );
}

function FscLabel({ x, w, y, title, sub }) {
  return (
    <div style={{ position: "absolute", left: x, top: y, width: w, textAlign: "center" }}>
      <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, fontWeight: 600, color: "var(--co-text-muted)", whiteSpace: "nowrap" }}>{title}</div>
      {sub && <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, color: "var(--co-text-subtle)", marginTop: 2, whiteSpace: "nowrap" }}>{sub}</div>}
    </div>
  );
}

// ── Worker node — matches src/Canvas.jsx WorkerNode exactly ───────────────
function FscWorker({ x, cy, selected, label = "lint-pass" }) {
  return (
    <div style={{
      position: "absolute", left: x, top: cy - FSC.nodeH / 2, width: FSC.workerW, height: FSC.nodeH,
      display: "flex", alignItems: "center", padding: "0 12px",
      background: "var(--co-grad-loaf)",
      border: `1px solid ${selected ? "var(--co-accent)" : "var(--co-border-2)"}`,
      borderRadius: 999,
      boxShadow: `inset 3px 0 0 var(--co-border-2), ${selected ? FSC_SEL_WORKER : "var(--co-shadow-1)"}`,
    }}>
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)", textAlign: "center", flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>{label}</span>
    </div>
  );
}

// ── Inlet / outlet connector badges (unchanged across concepts) ───────────
function FscHandle({ x, cy, icon }) {
  return (
    <div style={{
      position: "absolute", left: x - 10, top: cy - 10, width: 20, height: 20,
      display: "flex", alignItems: "center", justifyContent: "center",
      borderRadius: 6, background: "var(--co-bg-3)",
      border: "1px solid var(--co-accent)", color: "var(--co-accent)",
      boxShadow: "var(--co-shadow-1)", zIndex: 4,
    }}>
      <Icon name={icon} size={12} />
    </div>
  );
}

// ── Per-concept shell chrome ───────────────────────────────────────────────
function fscShell(variant, selected) {
  if (selected) return { border: "1px solid var(--co-accent)", boxShadow: FSC_SEL_FAN };
  switch (variant) {
    case "current":
      return {
        border: "1px solid color-mix(in oklab, var(--co-accent) 40%, var(--co-border-2))",
        boxShadow: "0 4px 16px color-mix(in oklab, var(--co-accent) 14%, transparent), var(--co-shadow-1)",
      };
    case "dashed":
      return { border: "1px dashed var(--co-border-3)", boxShadow: "var(--co-shadow-1)" };
    default: // quiet · toasted · rail · deck
      return { border: "1px solid var(--co-border-2)", boxShadow: "var(--co-shadow-1)" };
  }
}

// ── Per-concept header treatment ───────────────────────────────────────────
function fscHeader(variant, selected) {
  if (variant === "toasted" && !selected) {
    return {
      bg: "linear-gradient(135deg, color-mix(in oklab, var(--co-accent) 32%, var(--co-bg-4)) 0%, color-mix(in oklab, var(--co-accent) 18%, var(--co-bg-3)) 100%)",
      fg: "var(--co-accent-200)", chipBg: "rgba(0,0,0,0.22)", chipFg: "var(--co-accent-200)",
    };
  }
  if (variant === "rail") {
    return { bg: "var(--co-bg-3)", fg: "var(--co-accent)", softChip: true, hairline: true };
  }
  return { bg: "var(--co-grad-crust)", fg: "var(--co-accent-ink)", chipBg: "rgba(0,0,0,0.18)", chipFg: "var(--co-accent-ink)" };
}

// ── The fan capsule ────────────────────────────────────────────────────────
function FscFan({ x, cy, variant, selected }) {
  const top = cy - FSC.fanH / 2;
  const hd = fscHeader(variant, selected);
  const rail = variant === "rail";
  return (
    <div style={{ position: "absolute", left: 0, top: 0 }}>
      {variant === "deck" && [2, 1].map((i) => (
        <div key={i} style={{
          position: "absolute", left: x + i * 5, top: top + i * 5,
          width: FSC.fanW, height: FSC.fanH, borderRadius: 13,
          background: "var(--co-bg-2)", border: "1px solid var(--co-border-2)",
          opacity: i === 1 ? 0.65 : 0.35,
        }}></div>
      ))}

      <div style={{
        position: "absolute", left: x, top: top, width: FSC.fanW, height: FSC.fanH,
        borderRadius: 13, overflow: "hidden", background: "var(--co-bg-2)",
        ...fscShell(variant, selected),
      }}>
        {rail && <div style={{ height: 3, background: "var(--co-grad-crust)" }}></div>}

        {/* header bar */}
        <div style={{
          display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: 26,
          background: hd.bg,
          borderBottom: hd.hairline ? "1px solid var(--co-border-1)" : "none",
        }}>
          <Icon name="forEach" size={13} color={hd.fg} />
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, fontWeight: 700, color: hd.fg, letterSpacing: "0.02em" }}>map</span>
          <span style={{ flex: 1 }}></span>
          {hd.softChip ? (
            <span style={{
              display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px", borderRadius: 999,
              background: "color-mix(in oklab, var(--co-accent) 14%, transparent)", color: "var(--co-accent)",
              border: "1px solid color-mix(in oklab, var(--co-accent) 34%, transparent)",
              fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600,
            }}>×7</span>
          ) : (
            <span style={{
              display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px", borderRadius: 999,
              background: hd.chipBg, color: hd.chipFg,
              fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 700,
            }}>×7</span>
          )}
          <span style={{ display: "flex", alignItems: "center", color: rail ? "var(--co-text-muted)" : hd.fg }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="9,6 15,12 9,18"></polyline></svg>
          </span>
        </div>

        {/* body */}
        <div style={{ padding: "0 11px", height: FSC.fanH - 26 - (rail ? 3 : 0), display: "flex", flexDirection: "column", justifyContent: "center", gap: 2 }}>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>comment-file</span>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)", whiteSpace: "nowrap" }}>over ingest.files</span>
        </div>
      </div>

      <FscHandle x={x} cy={cy} icon="forEach" />
      <FscHandle x={x + FSC.fanW} cy={cy} icon="merge" />
    </div>
  );
}

// ── Comparison board — the 4-node control row ─────────────────────────────
function FscBoard({ variant, fanIdleSub, fanSelSub }) {
  const cy = 96;
  const labelY = cy + 56;
  const X = { w1: 40, w2: 252, f1: 484, f2: 720 };
  return (
    <FscCanvas w={930} h={216}>
      <FscWorker x={X.w1} cy={cy} selected={false} />
      <FscWorker x={X.w2} cy={cy} selected={true} />
      <FscFan x={X.f1} cy={cy} variant={variant} selected={false} />
      <FscFan x={X.f2} cy={cy} variant={variant} selected={true} />

      <FscLabel x={X.w1} w={FSC.workerW} y={labelY} title="worker · deselected" />
      <FscLabel x={X.w2} w={FSC.workerW} y={labelY} title="worker · selected" sub="accent ring + halo" />
      <FscLabel x={X.f1} w={FSC.fanW} y={labelY} title="fan · deselected" sub={fanIdleSub} />
      <FscLabel x={X.f2} w={FSC.fanW} y={labelY} title="fan · selected" sub={fanSelSub || "same halo as worker"} />
    </FscCanvas>
  );
}

Object.assign(window, { FscBoard, FscCanvas, FscFan, FscWorker, FscLabel });
