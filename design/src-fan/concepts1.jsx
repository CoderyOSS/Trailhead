/* global React, Icon, FAN, MiniCanvas, MiniNode, EdgeLayer, Eb, Chip, Chevron, Dot, useHover */
// ──────────────────────────────────────────────────────────────────────────
// Concepts A · B · C  — classic → diagrammatic fan-out / fan-in containers.
// Each is one interactive node: click the header to expand ↔ collapse.
// ──────────────────────────────────────────────────────────────────────────
const { useState: useStateC1 } = React;

// Shared canvas geometry
const LSTUB_X = 16, STUB_W = 112, LX = 200, OUT_GAP = 56;

// Stage: hearth canvas + upstream/downstream stubs + the two connecting edges.
// The concept positions its container absolutely and reports inlet/outlet pts.
function Stage({ w, h, inlet, outlet, activeIn, activeOut, upstream = "full-review", downstream = "critic", children }) {
  const cy = h / 2;
  const rightX = w - 16 - STUB_W;
  const edges = [
    { a: { x: LSTUB_X + STUB_W, y: cy }, b: inlet, active: activeIn },
    { a: outlet, b: { x: rightX, y: cy }, active: activeOut },
  ];
  return (
    <MiniCanvas w={w} h={h}>
      <EdgeLayer w={w} h={h} edges={edges} />
      <MiniNode label={upstream} x={LSTUB_X} y={cy} status={activeIn ? "passed" : undefined} dim />
      <MiniNode label={downstream} x={rightX} y={cy} dim />
      {children}
    </MiniCanvas>
  );
}

// Inlet / outlet handle — a small badge sitting on the container border at cy.
function Handle({ cx, cy, icon, active }) {
  return (
    <div style={{
      position: "absolute", left: cx - 11, top: cy - 11, width: 22, height: 22,
      display: "flex", alignItems: "center", justifyContent: "center",
      borderRadius: 7, background: "var(--co-bg-3)",
      border: `1px solid ${active ? "var(--co-accent)" : "var(--co-border-3)"}`,
      color: active ? "var(--co-accent)" : "var(--co-text-muted)",
      boxShadow: "var(--co-shadow-1)", zIndex: 3,
    }}>
      <Icon name={icon} size={13} />
    </div>
  );
}

// Per-item ghost chip (the body's input item / output result).
function GhostChip({ children }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", height: 24, padding: "0 9px",
      borderRadius: 7, border: "1px dashed var(--co-border-3)",
      background: "color-mix(in oklab, var(--co-bg-2) 60%, transparent)",
      fontFamily: "var(--co-font-mono)", fontSize: 11, color: "var(--co-text-muted)",
      whiteSpace: "nowrap",
    }}>{children}</span>
  );
}

// ════════════════════════════════════════════════════════════════════════
// Concept A — Subflow bracket
// Collapsed: one node with a multiplicity stack + ×7 badge.
// Expanded:  header + a dashed "repeats per item" frame around the body.
// ════════════════════════════════════════════════════════════════════════
function ConceptA({ initial = "collapsed" }) {
  const [open, setOpen] = useStateC1(initial === "expanded");
  const W_ART = 648, H_ART = 340, cy = H_ART / 2;
  const W = open ? 264 : 178;
  const H = open ? 196 : 70;
  const top = cy - H / 2;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + W, y: cy };
  const [hov, hb] = useHover();

  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet}>
      {/* multiplicity stack behind (collapsed only) */}
      {!open && [10, 5].map((o, i) => (
        <div key={i} style={{
          position: "absolute", left: LX + o, top: top + o, width: W, height: H,
          borderRadius: 10, background: "var(--co-bg-2)",
          border: "1px solid var(--co-border-1)", opacity: 0.5 - i * 0.18, zIndex: 1,
        }} />
      ))}

      <div {...hb} onClick={() => setOpen(o => !o)} style={{
        position: "absolute", left: LX, top, width: W, height: H, zIndex: 2,
        background: "var(--co-grad-loaf)",
        border: `1px solid ${open || hov ? "var(--co-accent)" : "var(--co-border-2)"}`,
        borderRadius: 11,
        boxShadow: `inset 3px 0 0 var(--co-accent), ${hov ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 16%, transparent)," : ""} var(--co-shadow-2)`,
        cursor: "pointer", overflow: "hidden",
        transition: "width 280ms var(--co-ease-out), height 280ms var(--co-ease-out), top 280ms var(--co-ease-out), border-color 160ms, box-shadow 160ms",
      }}>
        {/* header — always visible */}
        <div style={{ display: "flex", alignItems: "center", gap: 7, padding: "0 10px", height: 30 }}>
          <Icon name="forEach" size={14} color="var(--co-accent)" />
          <Eb accent>for-each</Eb>
          {open && <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-subtle)" }}>over ingest.files</span>}
          <span style={{ flex: 1 }} />
          {open && <Chip tone="accent">8 parallel</Chip>}
          <Chip tone="neutral">×7</Chip>
          <Chevron open={open} color="var(--co-text-muted)" />
        </div>

        {!open ? (
          <div style={{ padding: "0 12px", display: "flex", flexDirection: "column", justifyContent: "center", height: H - 30 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-file</span>
            <span style={{ fontFamily: "var(--co-font-sans)", fontSize: 11, color: "var(--co-text-subtle)" }}>per-file inline comment</span>
          </div>
        ) : (
          <div style={{ padding: "4px 14px 14px", animation: "fanFade 320ms var(--co-ease-out) both" }}>
            <Eb style={{ display: "block", marginBottom: 6 }}>repeats per item · ×7</Eb>
            <div style={{
              border: "1px dashed color-mix(in oklab, var(--co-accent) 45%, var(--co-border-3))",
              background: "color-mix(in oklab, var(--co-accent) 6%, transparent)",
              borderRadius: 10, padding: "12px 12px",
              display: "flex", alignItems: "center", gap: 8, justifyContent: "center",
            }}>
              <GhostChip>item</GhostChip>
              <Arrow />
              <MiniInline label="comment-file" />
              <Arrow />
              <GhostChip>result</GhostChip>
            </div>
          </div>
        )}
      </div>

      <Handle cx={inlet.x} cy={cy} icon="forEach" active={open} />
      <Handle cx={outlet.x} cy={cy} icon="merge" active={open} />
    </Stage>
  );
}

// Tiny inline worker for inside-frame bodies
function MiniInline({ label, status }) {
  const sc = status === "running" ? "var(--co-accent)" : status === "passed" ? "var(--co-success)" : "var(--co-border-2)";
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", height: 28, padding: "0 11px",
      borderRadius: 8, background: "var(--co-grad-loaf)", border: "1px solid var(--co-border-2)",
      boxShadow: `inset 3px 0 0 ${sc}`,
      fontFamily: "var(--co-font-mono)", fontSize: 12, fontWeight: 600, color: "var(--co-text-strong)",
      whiteSpace: "nowrap",
    }}>{label}</span>
  );
}
function Arrow() {
  return <Icon name="chevRight" size={13} color="var(--co-text-subtle)" />;
}

// ════════════════════════════════════════════════════════════════════════
// Concept B — Stacked deck
// Collapsed: a deck of offset cards (N copies). Expanded: the deck fans into
// N ghosted iteration lanes, the representative lane solid.
// ════════════════════════════════════════════════════════════════════════
function ConceptB({ initial = "collapsed" }) {
  const [open, setOpen] = useStateC1(initial === "expanded");
  const W_ART = 634, H_ART = 366, cy = H_ART / 2;
  const W = open ? 250 : 168;
  const H = open ? 268 : 64;
  const top = cy - H / 2;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + W, y: cy };
  const [hov, hb] = useHover();
  const lanes = [0, 1, 2, 3, 4, 5, 6];

  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet}>
      {/* deck shadow cards behind (collapsed) */}
      {!open && [14, 7].map((o, i) => (
        <div key={i} style={{
          position: "absolute", left: LX + o, top: top - o, width: W, height: H,
          borderRadius: 10, background: "var(--co-bg-2)",
          border: "1px solid var(--co-border-2)", opacity: 0.65 - i * 0.22, zIndex: 1,
        }} />
      ))}

      <div {...hb} onClick={() => setOpen(o => !o)} style={{
        position: "absolute", left: LX, top, width: W, height: H, zIndex: 2,
        background: "var(--co-grad-loaf)",
        border: `1px solid ${open || hov ? "var(--co-accent)" : "var(--co-border-2)"}`,
        borderRadius: 11,
        boxShadow: `${hov ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 16%, transparent), " : ""}var(--co-shadow-2)`,
        cursor: "pointer", overflow: "hidden",
        transition: "width 300ms var(--co-ease-out), height 300ms var(--co-ease-out), top 300ms var(--co-ease-out), border-color 160ms, box-shadow 160ms",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7, padding: "0 10px", height: 30, borderBottom: open ? "1px solid var(--co-border-1)" : "none" }}>
          <Icon name="copy" size={13} color="var(--co-accent)" />
          <Eb accent>fan-out</Eb>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-subtle)" }}>ingest.files</span>
          <span style={{ flex: 1 }} />
          <Chip tone="accent">×7</Chip>
          <Chevron open={open} color="var(--co-text-muted)" />
        </div>

        {!open ? (
          <div style={{ padding: "0 12px", display: "flex", alignItems: "center", height: H - 30 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-file</span>
          </div>
        ) : (
          <div style={{ padding: "8px 10px", display: "flex", flexDirection: "column", gap: 4, animation: "fanFade 340ms var(--co-ease-out) both" }}>
            {lanes.map((n, i) => (
              <div key={n} style={{
                display: "flex", alignItems: "center", gap: 8, height: 26, padding: "0 9px",
                borderRadius: 7,
                background: i === 0 ? "var(--co-bg-3)" : "transparent",
                border: i === 0 ? "1px solid var(--co-border-2)" : "1px solid transparent",
                opacity: i === 0 ? 1 : 0.55,
              }}>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", width: 30 }}>{`[${n}]`}</span>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, fontWeight: i === 0 ? 600 : 500, color: i === 0 ? "var(--co-text-strong)" : "var(--co-text-muted)", flex: 1, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>comment-file</span>
                {i === 0 && <Eb>iteration</Eb>}
              </div>
            ))}
            <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 4, paddingTop: 8, borderTop: "1px solid var(--co-border-1)" }}>
              <Icon name="merge" size={13} color="var(--co-accent)" />
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-muted)" }}>join → 7 results</span>
            </div>
          </div>
        )}
      </div>

      <Handle cx={inlet.x} cy={cy} icon="forEach" active={open} />
      <Handle cx={outlet.x} cy={cy} icon="merge" active={open} />
    </Stage>
  );
}

// ════════════════════════════════════════════════════════════════════════
// Concept C — Fan rails
// Literal splitter wedge (1 → N) on the inlet, collector wedge (N → 1) on the
// outlet, drawn as real geometry. Expanded reveals the parallel lanes.
// ════════════════════════════════════════════════════════════════════════
function ConceptC({ initial = "collapsed" }) {
  const [open, setOpen] = useStateC1(initial === "expanded");
  const W_ART = 684, H_ART = 344, cy = H_ART / 2;
  const WEDGE = 30;                 // wedge width
  const bodyW = open ? 244 : 150;   // body region between wedges
  const H = open ? 200 : 64;
  const top = cy - H / 2;
  const bodyLeft = LX + WEDGE;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + WEDGE + bodyW + WEDGE, y: cy };
  const [hov, hb] = useHover();
  const laneYs = open ? [top + 64, top + 110, top + 156] : [cy];

  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet}>
      {/* fan rails — splitter + collector lines */}
      <svg width={W_ART} height={H_ART} style={{ position: "absolute", inset: 0, overflow: "visible", pointerEvents: "none", zIndex: 3 }}>
        {open && laneYs.map((ly, i) => (
          <g key={i} stroke="var(--co-accent)" strokeWidth="1.5" fill="none" opacity="0.85">
            <path d={`M ${inlet.x} ${cy} C ${inlet.x + WEDGE} ${cy}, ${bodyLeft - 2} ${ly}, ${bodyLeft + 6} ${ly}`} />
            <path d={`M ${bodyLeft + bodyW - 6} ${ly} C ${outlet.x - WEDGE} ${ly}, ${outlet.x} ${cy}, ${outlet.x} ${cy}`} />
          </g>
        ))}
      </svg>

      {/* body container */}
      <div {...hb} onClick={() => setOpen(o => !o)} style={{
        position: "absolute", left: bodyLeft, top, width: bodyW, height: H, zIndex: 2,
        background: "var(--co-grad-loaf)",
        border: `1px solid ${open || hov ? "var(--co-accent)" : "var(--co-border-2)"}`,
        borderRadius: 11,
        boxShadow: `${hov ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 16%, transparent), " : ""}var(--co-shadow-2)`,
        cursor: "pointer", overflow: "hidden",
        transition: "width 280ms var(--co-ease-out), height 280ms var(--co-ease-out), top 280ms var(--co-ease-out), border-color 160ms, box-shadow 160ms",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 7, padding: "0 10px", height: 30, borderBottom: open ? "1px solid var(--co-border-1)" : "none" }}>
          <Icon name="workflow" size={13} color="var(--co-accent)" />
          <Eb accent>map</Eb>
          <span style={{ flex: 1 }} />
          <Chevron open={open} color="var(--co-text-muted)" />
        </div>
        {!open ? (
          <div style={{ padding: "0 12px", display: "flex", alignItems: "center", height: H - 30 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13.5, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-file</span>
          </div>
        ) : (
          <div style={{ padding: "10px 12px", display: "flex", flexDirection: "column", gap: 8, animation: "fanFade 320ms var(--co-ease-out) both" }}>
            {[0, 1, 2].map(n => (
              <div key={n} style={{ display: "flex", alignItems: "center", gap: 8 }}>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", width: 26 }}>{`[${n}]`}</span>
                <MiniInline label="comment-file" />
              </div>
            ))}
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", paddingLeft: 34 }}>… items 3–6</span>
          </div>
        )}
      </div>

      {/* splitter wedge */}
      <Wedge x={LX} cy={cy} h={H} top={top} w={WEDGE} dir="out" label="÷7" />
      {/* collector wedge */}
      <Wedge x={LX + WEDGE + bodyW} cy={cy} h={H} top={top} w={WEDGE} dir="in" label="join" />
    </Stage>
  );
}

// A triangular fan wedge. dir "out" = splitter (point at left), "in" = collector (point at right).
function Wedge({ x, cy, h, top, w, dir, label }) {
  const pts = dir === "out"
    ? `${x},${cy} ${x + w},${top} ${x + w},${top + h}`
    : `${x + w},${cy} ${x},${top} ${x},${top + h}`;
  return (
    <svg width={w + 2} height={h + 2} style={{ position: "absolute", left: x, top, overflow: "visible", zIndex: 2 }}>
      <polygon
        points={dir === "out"
          ? `0,${cy - top} ${w},0 ${w},${h}`
          : `${w},${cy - top} 0,0 0,${h}`}
        fill="color-mix(in oklab, var(--co-accent) 14%, var(--co-bg-2))"
        stroke="var(--co-accent)" strokeWidth="1.5" strokeLinejoin="round" />
      <text x={dir === "out" ? w - 6 : 6} y={cy - top + 3} textAnchor={dir === "out" ? "end" : "start"}
        style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600, fill: "var(--co-accent)" }}>{label}</text>
    </svg>
  );
}

Object.assign(window, { ConceptA, ConceptB, ConceptC, Stage, Handle, MiniInline, Arrow, GhostChip, LX, LSTUB_X, STUB_W });
