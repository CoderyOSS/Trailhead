/* global React */
const { useState, useMemo, useEffect } = React;

/* Canvas keyframes — injected once so every host page (app + handoff) shares
   the same source. Used by the worker-node running state + spinner. */
(function injectCanvasKeyframes() {
  if (typeof document === "undefined") return;
  if (document.getElementById("co-canvas-keyframes")) return;
  const s = document.createElement("style");
  s.id = "co-canvas-keyframes";
  s.textContent = `
    @keyframes co-spin { to { transform: rotate(360deg); } }
    @keyframes co-pulse-glow {
      0%, 100% {
        filter: brightness(0.74);
        box-shadow: 0 0 2px 0 color-mix(in oklab, var(--co-pulse-c, var(--co-accent)) 14%, transparent);
      }
      50% {
        filter: brightness(1.3);
        box-shadow: 0 0 9px 2px color-mix(in oklab, var(--co-pulse-c, var(--co-accent)) 68%, transparent);
      }
    }
    @keyframes co-node-running-glow {
      0%, 100% { box-shadow: inset 3px 0 0 var(--co-accent), 0 0 0 1px color-mix(in oklab, var(--co-accent) 48%, transparent), 0 0 9px color-mix(in oklab, var(--co-accent) 18%, transparent), 0 4px 12px rgba(0,0,0,0.4); }
      50%      { box-shadow: inset 3px 0 0 var(--co-accent), 0 0 0 1px color-mix(in oklab, var(--co-accent) 82%, transparent), 0 0 24px color-mix(in oklab, var(--co-accent) 50%, transparent), 0 4px 12px rgba(0,0,0,0.4); }
    }`;
  (document.head || document.documentElement).appendChild(s);
})();

/* ─────────────────────────────────────────────
   Icon — inline Lucide-style strokes
   ───────────────────────────────────────────── */
const ICONS = {
  play:    'M5 3 L19 12 L5 21 Z',
  plus:    'M12 5 v14 M5 12 h14',
  search:  'circle:11,11,8|line:21,21,16.65,16.65',
  refresh: 'polyline:23,4,23,10,17,10|polyline:1,20,1,14,7,14|path:M3.51 9a9 9 0 0 1 14.85-3.36L23 10 M1 14l4.64 4.36A9 9 0 0 0 20.49 15',
  settings:'circle:12,12,3|path:M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 0 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09a1.65 1.65 0 0 0-1-1.51 1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06A1.65 1.65 0 0 0 4.6 15a1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06A1.65 1.65 0 0 0 9 4.6 1.65 1.65 0 0 0 10 3.09V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z',
  layout:  'path:M3 3h18v18H3z|path:M3 9h18 M9 21V9',
  activity:'polyline:22,12,18,12,15,21,9,3,6,12,2,12',
  workflow:'path:M18 8h1a4 4 0 0 1 0 8h-1 M2 8h16v9a4 4 0 0 1-4 4H6a4 4 0 0 1-4-4z|line:6,1,6,4|line:10,1,10,4|line:14,1,14,4',
  gitBranch:'circle:18,18,3|circle:6,6,3|path:M6 21V9a9 9 0 0 0 9 9',
  bar:     'line:18,20,18,10|line:12,20,12,4|line:6,20,6,14',
  file:    'path:M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z|polyline:14,2,14,8,20,8',
  zap:     'polygon:13,2,3,14,12,14,11,22,21,10,12,10,13,2',
  bookmark:'path:M19 21l-7-5-7 5V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2z',
  bell:    'path:M18 8a6 6 0 0 0-12 0c0 7-3 9-3 9h18s-3-2-3-9|path:M13.73 21a2 2 0 0 1-3.46 0',
  clock:   'circle:12,12,10|polyline:12,6,12,12,16,14',
  sun:     'circle:12,12,5|line:12,1,12,3|line:12,21,12,23|line:4.22,4.22,5.64,5.64|line:18.36,18.36,19.78,19.78|line:1,12,3,12|line:21,12,23,12|line:4.22,19.78,5.64,18.36|line:18.36,5.64,19.78,4.22',
  moon:    'path:M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z',
  chevDown:'polyline:6,9,12,15,18,9',
  chevRight:'polyline:9,18,15,12,9,6',
  x:       'line:18,6,6,18|line:6,6,18,18',
  arrowUp: 'line:12,19,12,5|polyline:5,12,12,5,19,12',
  arrowDown:'line:12,5,12,19|polyline:19,12,12,19,5,12',
  copy:    'rect:9,9,13,13,2,2|path:M5 15H4a2 2 0 0 1-2-2V4a2 2 0 0 1 2-2h9a2 2 0 0 1 2 2v1',
  external:'path:M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6|polyline:15,3,21,3,21,9|line:10,14,21,3',
  terminal:'polyline:4,17,10,11,4,5|line:12,19,20,19',
  cmd:     'path:M18 3a3 3 0 0 0-3 3v12a3 3 0 1 0 3-3H6a3 3 0 1 0 3 3V6a3 3 0 1 0-3 3h12a3 3 0 1 0-3-3',
  check:   'polyline:20,6,9,17,4,12',
  // Build mode — pencil/edit
  pencil:  'path:M12 20h9 M16.5 3.5a2.121 2.121 0 0 1 3 3L7 19l-4 1 1-4 12.5-12.5z',
  // Active mode — running figure (Lucide PersonRunning approx)
  runner:  'circle:13,4,2|path:M4 22l5-7 2-4 3 3v6|path:M11 11l-3-3-4 1 1 4 6-2|line:18,8,21,5',
  // History mode — bullet list
  list:    'line:8,6,21,6|line:8,12,21,12|line:8,18,21,18|line:3,6,3.01,6|line:3,12,3.01,12|line:3,18,3.01,18',
  // Active mode — stopwatch
  stopwatch: 'circle:12,14,8|line:12,10,12,14|line:9,2,15,2|line:12,2,12,4|line:18.4,5.6,19.8,7',
  // for-each — fan-out: one source iterates out to many parallel items
  forEach: 'circle:4,12,2|circle:20,5,2|circle:20,12,2|circle:20,19,2|path:M6 12h6M12 5v14M12 5h6M12 12h6M12 19h6',
  // join — fan-in: many upstreams merge into one
  merge:   'circle:4,5,2|circle:4,12,2|circle:4,19,2|circle:20,12,2|path:M6 5h6M6 12h6M6 19h6M12 5v14M12 12h6',
  // node toolbar — kebab "more" menu trigger
  moreVertical: 'circle:12,5,1.3|circle:12,12,1.3|circle:12,19,1.3',
  // remove + collapse — parent wired straight through to child
  collapseLink: 'circle:3.2,12,2.2|circle:20.8,12,2.2|line:5.4,12,18.6,12',
  // file / external-file / save-to-file — subworkflow file linkage
  file:     'path:M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z|polyline:14,2,14,8,20,8',
  fileOpen: 'path:M15 3h6v6|line:10,14,21,3|path:M18 13v6a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h6',
  save:     'path:M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z|polyline:17,21,17,13,7,13,7,21|polyline:7,3,7,8,15,8',
};

function Icon({ name, size = 16, color = "currentColor", strokeWidth = 1.5, style }) {
  const def = ICONS[name];
  if (!def) return null;
  const parts = def.split("|");
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round" style={style}>
      {parts.map((p, i) => {
        if (p.startsWith("circle:")) { const [cx,cy,r] = p.slice(7).split(",").map(Number); return <circle key={i} cx={cx} cy={cy} r={r} />; }
        if (p.startsWith("line:"))   { const [x1,y1,x2,y2] = p.slice(5).split(",").map(Number); return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} />; }
        if (p.startsWith("rect:"))   { const [x,y,w,h,rx,ry] = p.slice(5).split(",").map(Number); return <rect key={i} x={x} y={y} width={w} height={h} rx={rx} ry={ry} />; }
        if (p.startsWith("polyline:")){ return <polyline key={i} points={p.slice(9)} />; }
        if (p.startsWith("polygon:")) { return <polygon key={i} points={p.slice(8)} />; }
        if (p.startsWith("path:"))    { return <path key={i} d={p.slice(5)} />; }
        return <path key={i} d={p} />;
      })}
    </svg>
  );
}

/* ─────────────────────────────────────────────
   Button family
   ───────────────────────────────────────────── */
function Button({ children, variant = "secondary", size = "md", icon, iconRight, onClick, disabled, style, type = "button" }) {
  const h = size === "sm" ? 26 : 32;
  const fs = size === "sm" ? 12 : 13;
  const pad = size === "sm" ? "0 8px" : "0 12px";
  const palettes = {
    primary:   { bg: "var(--co-grad-crust)", fg: "var(--co-accent-ink)", bd: "transparent", hover: "var(--co-grad-crust)", glow: true },
    trail:     { bg: "var(--co-grad-trail)", fg: "#fbf3e6", bd: "transparent", hover: "var(--co-grad-trail)", glow: "trail" },
    secondary: { bg: "var(--co-bg-3)",   fg: "var(--co-fg-0)",       bd: "var(--co-border-2)", hover: "var(--co-bg-4)" },
    ghost:     { bg: "transparent",       fg: "var(--co-fg-1)",       bd: "transparent",        hover: "var(--co-bg-3)" },
    danger:    { bg: "transparent",       fg: "var(--co-danger)",     bd: "color-mix(in oklab, var(--co-danger) 40%, transparent)", hover: "var(--co-danger-soft)" },
  };
  const p = palettes[variant];
  const boxShadow = p.glow === true
    ? "0 4px 12px color-mix(in oklab, var(--co-accent-400) 35%, transparent), 0 1px 0 0 rgba(255,255,255,0.16) inset"
    : p.glow === "trail"
    ? "0 4px 12px color-mix(in oklab, var(--co-trail-400) 35%, transparent), 0 1px 0 0 rgba(255,255,255,0.14) inset"
    : "none";
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled}
      className="co-focus-ring"
      style={{
        display: "inline-flex", alignItems: "center", gap: 6,
        height: h, padding: pad, fontSize: fs, lineHeight: 1, fontWeight: 600,
        fontFamily: "var(--co-font-sans)",
        color: p.fg, background: p.bg,
        border: `1px solid ${p.bd}`,
        borderRadius: 8, cursor: disabled ? "not-allowed" : "pointer",
        opacity: disabled ? 0.5 : 1,
        whiteSpace: "nowrap",
        boxShadow,
        transition: "transform 140ms var(--co-ease-out), background 140ms var(--co-ease-out), border-color 140ms var(--co-ease-out), box-shadow 140ms var(--co-ease-out)",
        ...style,
      }}
      onMouseEnter={e => { if (!disabled) { e.currentTarget.style.background = p.hover; if (p.glow) e.currentTarget.style.transform = "translateY(-1px)"; } }}
      onMouseLeave={e => { if (!disabled) { e.currentTarget.style.background = p.bg; e.currentTarget.style.transform = ""; } }}
    >
      {icon && <Icon name={icon} size={size === "sm" ? 12 : 14} />}
      {children}
      {iconRight && <Icon name={iconRight} size={size === "sm" ? 12 : 14} />}
    </button>
  );
}

function IconButton({ icon, onClick, title, size = 32, active = false, style }) {
  const [hover, setHover] = useState(false);
  return (
    <button
      type="button"
      title={title}
      onClick={onClick}
      className="co-focus-ring"
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        width: size, height: size,
        display: "inline-flex", alignItems: "center", justifyContent: "center",
        background: active ? "var(--co-bg-4)" : hover ? "var(--co-bg-3)" : "transparent",
        color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
        border: "1px solid transparent",
        borderRadius: 6, cursor: "pointer",
        transition: "background 140ms var(--co-ease-out), color 140ms var(--co-ease-out)",
        ...style,
      }}
    >
      <Icon name={icon} size={size === 28 ? 14 : 16} />
    </button>
  );
}

/* ─────────────────────────────────────────────
   Status & tags
   ───────────────────────────────────────────── */
const STATUS = {
  running:   { color: "var(--co-accent)",  soft: "var(--co-accent-soft)",  label: "running"   },
  passed:    { color: "var(--co-success)", soft: "var(--co-success-soft)", label: "passed"    },
  retrying:  { color: "var(--co-warning)", soft: "var(--co-warning-soft)", label: "retrying"  },
  failed:    { color: "var(--co-danger)",  soft: "var(--co-danger-soft)",  label: "failed"    },
  queued:    { color: "var(--co-info)",    soft: "var(--co-info-soft)",    label: "queued"    },
  cancelled: { color: "var(--co-fg-3)",    soft: "var(--co-bg-3)",         label: "cancelled" },
  skipped:   { color: "var(--co-text-subtle)", soft: "var(--co-bg-3)",     label: "skipped"   },
};

function StatusDot({ status, pulse = false, size = 6 }) {
  const s = STATUS[status] || STATUS.queued;
  return (
    <span style={{
      display: "inline-block",
      width: size, height: size, borderRadius: 999,
      background: s.color,
      "--co-pulse-c": s.color,
      animation: pulse ? "co-pulse-glow 1.1s var(--co-ease-in-out) infinite" : "none",
      verticalAlign: 1,
    }} />
  );
}

function Spinner({ size = 12, stroke = 1.6, color = "var(--co-accent)" }) {
  return (
    <span style={{
      display: "inline-block",
      width: size, height: size,
      borderRadius: 999,
      border: `${stroke}px solid color-mix(in oklab, ${color} 24%, transparent)`,
      borderTopColor: color,
      animation: "co-spin 0.7s linear infinite",
      boxSizing: "border-box",
      flexShrink: 0,
    }} />
  );
}

function StatusTag({ status }) {
  const s = STATUS[status] || STATUS.queued;
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 6,
      padding: "2px 8px", borderRadius: 999,
      fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 500,
      background: s.soft, color: s.color,
    }}>
      <StatusDot status={status} pulse={status === "running"} />
      {s.label}
    </span>
  );
}

function Tag({ children, color, style }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 5,
      padding: "3px 8px", borderRadius: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 11,
      background: "var(--co-bg-3)", color: color || "var(--co-text)",
      border: "1px solid var(--co-border-1)",
      ...style,
    }}>{children}</span>
  );
}

/* ─────────────────────────────────────────────
   Surfaces
   ───────────────────────────────────────────── */
function Card({ children, raised = false, glow = false, padding = 16, style }) {
  return (
    <div style={{
      background: glow ? "var(--co-bg-2)" : raised ? "var(--co-bg-3)" : "var(--co-grad-loaf)",
      border: `1px solid ${glow ? "color-mix(in oklab, var(--co-accent) 30%, transparent)" : "var(--co-border-1)"}`,
      borderRadius: 14,
      padding,
      boxShadow: raised ? "var(--co-shadow-2)" : "none",
      position: "relative",
      overflow: glow ? "hidden" : undefined,
      ...style,
    }}>
      {glow && <div style={{ position: "absolute", inset: "-30px -30px auto", height: 80, background: "var(--co-grad-oven)", pointerEvents: "none" }} />}
      <div style={{ position: "relative" }}>{children}</div>
    </div>
  );
}

function Eyebrow({ children, accent = false, style }) {
  return (
    <div style={{
      fontFamily: "var(--co-font-mono)",
      fontSize: 10, letterSpacing: "0.08em", textTransform: "uppercase",
      color: accent ? "var(--co-accent)" : "var(--co-text-subtle)", fontWeight: 500,
      ...style,
    }}>{children}</div>
  );
}

/* expose */
Object.assign(window, { Icon, Button, IconButton, StatusDot, StatusTag, Spinner, Tag, Card, Eyebrow });
