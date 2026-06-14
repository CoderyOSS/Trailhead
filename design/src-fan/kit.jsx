/* global React, Icon */
// ──────────────────────────────────────────────────────────────────────────
// Shared kit for the fan-out / fan-in container exploration.
// Re-creates the real workflow canvas surface (hearth + dot grid) and a worker
// mini-node that matches src/Canvas.jsx WorkerNode, so every concept reads as
// native Trailhead canvas furniture.
// ──────────────────────────────────────────────────────────────────────────
const { useState: useStateK } = React;

// Canvas centerline geometry shared by every concept.
const FAN = {
  cy: null,            // set per canvas
  stubW: 120,
  stubH: 32,
  Lx: 150,             // container left edge (fixed inlet x)
  outGap: 60,          // gap from expanded outlet to downstream stub
};

// ── Mini canvas surface — grad-hearth + dot grid, exactly like Canvas.jsx ──
function MiniCanvas({ w, h, children }) {
  return (
    <div style={{
      position: "relative", width: w, height: h, overflow: "hidden",
      background: "var(--co-grad-hearth)",
      fontFamily: "var(--co-font-sans)",
    }}>
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: "radial-gradient(circle, var(--co-border-2) 1px, transparent 1px)",
        backgroundSize: "18px 18px",
        backgroundPosition: "9px 9px",
        opacity: 0.35, pointerEvents: "none",
      }} />
      {children}
    </div>
  );
}

// ── Worker mini-node — matches WorkerNode visual language ──────────────────
// Centered vertically on `cy`. status drives the left rail + border like the
// real node. `dim` fades context nodes so the container stays the hero.
function MiniNode({ label, x, y, w = FAN.stubW, h = FAN.stubH, status, dim, selected }) {
  const statusColor = status
    ? `var(--co-${status === "passed" ? "success" : status === "failed" ? "danger" : status === "running" ? "accent" : "info"})`
    : "var(--co-border-2)";
  return (
    <div style={{
      position: "absolute", left: x, top: y - h / 2, width: w, height: h,
      display: "flex", alignItems: "center", justifyContent: "center",
      padding: "0 10px",
      background: "var(--co-grad-loaf)",
      border: `1px solid ${selected ? "var(--co-accent)" : "var(--co-border-2)"}`,
      borderRadius: 10,
      boxShadow: `inset 3px 0 0 ${statusColor}, var(--co-shadow-1)`,
      opacity: dim ? 0.5 : 1,
      transition: "opacity 200ms",
    }}>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600,
        color: "var(--co-text-strong)",
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
      }}>{label}</span>
    </div>
  );
}

// ── SVG edge between two points, curved like the real canvas ───────────────
function edgePath(a, b) {
  const c = Math.max(28, Math.abs(b.x - a.x) * 0.5);
  return `M ${a.x} ${a.y} C ${a.x + c} ${a.y}, ${b.x - c} ${b.y}, ${b.x} ${b.y}`;
}

function EdgeLayer({ w, h, edges }) {
  return (
    <svg width={w} height={h} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none" }}>
      <defs>
        <marker id="fanArrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
          <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-3)" />
        </marker>
        <marker id="fanArrowA" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
          <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-accent)" />
        </marker>
      </defs>
      {edges.map((e, i) => (
        <path key={i} d={edgePath(e.a, e.b)} fill="none"
          stroke={e.active ? "var(--co-accent)" : "var(--co-fg-3)"}
          strokeWidth={e.active ? 2 : 1.5}
          strokeDasharray={e.dashed ? "4 4" : "0"}
          opacity={e.dashed ? 0.7 : 1}
          markerEnd={e.active ? "url(#fanArrowA)" : "url(#fanArrow)"} />
      ))}
    </svg>
  );
}

// ── Small eyebrow / chip helpers ───────────────────────────────────────────
function Eb({ children, accent, style }) {
  return (
    <span style={{
      fontFamily: "var(--co-font-mono)", fontSize: 9.5, letterSpacing: "0.08em",
      textTransform: "uppercase", fontWeight: 600, whiteSpace: "nowrap",
      color: accent ? "var(--co-accent)" : "var(--co-text-subtle)",
      ...style,
    }}>{children}</span>
  );
}

// Count / concurrency chip
function Chip({ children, tone = "neutral", mono = true, style }) {
  const tones = {
    neutral: { bg: "var(--co-bg-3)",  fg: "var(--co-text-muted)",  bd: "var(--co-border-2)" },
    accent:  { bg: "color-mix(in oklab, var(--co-accent) 16%, transparent)", fg: "var(--co-accent)", bd: "color-mix(in oklab, var(--co-accent) 38%, transparent)" },
    ink:     { bg: "rgba(0,0,0,0.16)", fg: "var(--co-accent-ink)", bd: "rgba(255,255,255,0.22)" },
  };
  const t = tones[tone];
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      height: 18, padding: "0 7px", borderRadius: 999,
      background: t.bg, color: t.fg, border: `1px solid ${t.bd}`,
      fontFamily: mono ? "var(--co-font-mono)" : "var(--co-font-sans)",
      fontSize: 10, fontWeight: 600, lineHeight: 1, whiteSpace: "nowrap",
      ...style,
    }}>{children}</span>
  );
}

// Disclosure chevron that rotates with open state
function Chevron({ open, color = "currentColor" }) {
  return (
    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke={color}
      strokeWidth="2.4" strokeLinecap="round" strokeLinejoin="round"
      style={{ transform: open ? "rotate(90deg)" : "rotate(0deg)", transition: "transform 240ms var(--co-ease-out)", flexShrink: 0 }}>
      <polyline points="9,6 15,12 9,18" />
    </svg>
  );
}

// Status dot
function Dot({ status = "queued", pulse }) {
  const c = status === "passed" ? "var(--co-success)"
    : status === "running" ? "var(--co-accent)"
    : status === "failed" ? "var(--co-danger)"
    : "var(--co-text-subtle)";
  return (
    <span style={{
      width: 6, height: 6, borderRadius: 999, background: c, flexShrink: 0,
      "--co-pulse-c": c,
      animation: pulse ? "co-pulse-glow 1.1s var(--co-ease-in-out) infinite" : "none",
    }} />
  );
}

// Hover-lift wrapper for clickable container headers
function useHover() {
  const [h, setH] = useStateK(false);
  return [h, { onMouseEnter: () => setH(true), onMouseLeave: () => setH(false) }];
}

Object.assign(window, { FAN, MiniCanvas, MiniNode, EdgeLayer, edgePath, Eb, Chip, Chevron, Dot, useHover });
