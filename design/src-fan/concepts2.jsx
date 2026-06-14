/* global React, Icon, Stage, Handle, MiniInline, Eb, Chip, Chevron, Dot, useHover, LX */
// ──────────────────────────────────────────────────────────────────────────
// Concepts D · E — novel + scalable fan-out / fan-in containers.
// D · Capsule reactor (gradient, token flow, + a live running-job state)
// E · Group frame around an arbitrary multi-node sub-graph
// ──────────────────────────────────────────────────────────────────────────
const { useState: useStateC2 } = React;

// Animated tokens flowing along a path (the brand's token-flow metaphor).
function TokenFlow({ d, n = 3, dur = 2.2, color = "var(--co-accent)" }) {
  return (
    <>
      {Array.from({ length: n }).map((_, i) => (
        <circle key={i} r="3" fill={color}>
          <animateMotion dur={`${dur}s`} repeatCount="indefinite" begin={`${-(i / n) * dur}s`} path={d} />
        </circle>
      ))}
    </>
  );
}

// ════════════════════════════════════════════════════════════════════════
// Concept D — Capsule reactor
// A rounded capsule with a gradient header + inlet/outlet funnels. Items
// stream in as tokens, run the body, and merge out. Expanded reveals the
// chamber; a 3rd artboard shows the live running-job state.
// ════════════════════════════════════════════════════════════════════════
function CapsuleShell({ open, hov, W, H, top, children }) {
  return (
    <div style={{
      position: "absolute", left: LX, top, width: W, height: H, zIndex: 2,
      borderRadius: 16, overflow: "hidden",
      background: "var(--co-bg-2)",
      border: `1px solid ${open || hov ? "var(--co-accent)" : "color-mix(in oklab, var(--co-accent) 40%, var(--co-border-2))"}`,
      boxShadow: `0 0 0 ${hov ? 3 : 0}px color-mix(in oklab, var(--co-accent) 16%, transparent), 0 6px 20px color-mix(in oklab, var(--co-accent) 16%, transparent), var(--co-shadow-2)`,
      cursor: "pointer",
      transition: "width 300ms var(--co-ease-out), height 300ms var(--co-ease-out), top 300ms var(--co-ease-out), border-color 160ms, box-shadow 160ms",
    }}>{children}</div>
  );
}

function CapsuleHeader({ open, running }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 7, padding: "0 12px", height: 30,
      background: "var(--co-grad-crust)",
    }}>
      <Icon name="forEach" size={14} color="var(--co-accent-ink)" />
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 700, color: "var(--co-accent-ink)", letterSpacing: "0.02em" }}>map</span>
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-accent-ink)", opacity: 0.72 }}>ingest.files</span>
      <span style={{ flex: 1 }} />
      {running
        ? <Chip tone="ink"><Dot status="running" pulse />5 / 7</Chip>
        : <Chip tone="ink">×7</Chip>}
      {!running && <Chevron open={open} color="var(--co-accent-ink)" />}
    </div>
  );
}

function ConceptD({ initial = "collapsed" }) {
  const [open, setOpen] = useStateC2(initial === "expanded");
  const W_ART = 684, H_ART = 350, cy = H_ART / 2;
  const W = open ? 300 : 188;
  const H = open ? 168 : 72;
  const top = cy - H / 2;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + W, y: cy };
  const [hov, hb] = useHover();
  const chamberD = `M 8 30 C 70 30, 90 30, 150 30`;

  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet}>
      <div {...hb} onClick={() => setOpen(o => !o)} style={{ position: "absolute", inset: 0, zIndex: 2, pointerEvents: "none" }}>
        <div style={{ pointerEvents: "auto" }}>
          <CapsuleShell open={open} hov={hov} W={W} H={H} top={top}>
            <CapsuleHeader open={open} />
            {!open ? (
              <div style={{ padding: "0 14px", height: H - 30, display: "flex", alignItems: "center", gap: 12 }}>
                <div style={{ display: "flex", flexDirection: "column", lineHeight: 1 }}>
                  <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 22, fontWeight: 700, color: "var(--co-accent)" }}>7</span>
                  <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, color: "var(--co-text-subtle)", letterSpacing: "0.06em" }}>items</span>
                </div>
                <div style={{ width: 1, height: 26, background: "var(--co-border-2)" }} />
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-file</span>
              </div>
            ) : (
              <div style={{ padding: "12px 14px", animation: "fanFade 320ms var(--co-ease-out) both" }}>
                <Eb style={{ display: "block", marginBottom: 8 }}>chamber · runs per item</Eb>
                <div style={{ position: "relative", height: 60, borderRadius: 10, background: "var(--co-bg-0)", border: "1px solid var(--co-border-2)", display: "flex", alignItems: "center", justifyContent: "center" }}>
                  <svg width="100%" height="60" viewBox="0 0 272 60" preserveAspectRatio="none" style={{ position: "absolute", inset: 0 }}>
                    <path d="M 6 30 L 266 30" stroke="var(--co-border-2)" strokeWidth="1.5" strokeDasharray="3 4" fill="none" />
                    <TokenFlow d="M 6 30 L 266 30" n={4} dur={2.4} />
                  </svg>
                  <span style={{ position: "relative", zIndex: 1 }}><MiniInline label="comment-file" status="running" /></span>
                </div>
                <div style={{ display: "flex", gap: 6, marginTop: 10 }}>
                  <Chip tone="accent">8 parallel</Chip>
                  <Chip tone="neutral">join · all</Chip>
                </div>
              </div>
            )}
          </CapsuleShell>
        </div>
      </div>
      <Handle cx={inlet.x} cy={cy} icon="forEach" active />
      <Handle cx={outlet.x} cy={cy} icon="merge" active />
    </Stage>
  );
}

// Summary stat — colored dot + count + label, the running-state digest.
function Stat({ status, n, label, pulse }) {
  const c = status === "passed" ? "var(--co-success)"
    : status === "failed" ? "var(--co-danger)"
    : status === "running" ? "var(--co-accent)" : "var(--co-text-subtle)";
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}>
      <Dot status={status} pulse={pulse} />
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 12, fontWeight: 700, color: c }}>{n}</span>
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>{label}</span>
    </span>
  );
}

// Live running-job state — the capsule mid-execution. Body is a summary digest
// (N passed / failed / active), not a per-item grid.
function ConceptDRun() {
  const W_ART = 684, H_ART = 350, cy = H_ART / 2;
  const W = 300, H = 150, top = cy - H / 2;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + W, y: cy };
  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet} activeIn>
      <CapsuleShell open hov={false} W={W} H={H} top={top}>
        <CapsuleHeader running />
        <div style={{ padding: "12px 14px" }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, marginBottom: 11 }}>
            <MiniInline label="comment-file" status="running" />
            <span style={{ flex: 1 }} />
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>01:12 · $0.06</span>
          </div>
          {/* progress */}
          <div style={{ height: 4, borderRadius: 2, background: "var(--co-bg-4)", overflow: "hidden", marginBottom: 12 }}>
            <div style={{ width: "71%", height: "100%", background: "var(--co-grad-crust)" }} />
          </div>
          {/* summary digest */}
          <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
            <Stat status="passed" n={4} label="passed" />
            <Stat status="failed" n={1} label="failed" />
            <Stat status="running" n={2} label="active" pulse />
          </div>
        </div>
      </CapsuleShell>
      <Handle cx={inlet.x} cy={cy} icon="forEach" active />
      <Handle cx={outlet.x} cy={cy} icon="merge" active />
    </Stage>
  );
}

// ════════════════════════════════════════════════════════════════════════
// Concept E — Group frame
// A translucent tinted frame around a REAL multi-node sub-graph. Collapses to
// one node. Shows the container can wrap arbitrary internal workflows.
// ════════════════════════════════════════════════════════════════════════
function ConceptE({ initial = "collapsed" }) {
  const [open, setOpen] = useStateC2(initial === "expanded");
  const W_ART = 760, H_ART = 384, cy = H_ART / 2;
  const W = open ? 392 : 206;
  const H = open ? 150 : 66;
  const top = cy - H / 2;
  const inlet = { x: LX, y: cy };
  const outlet = { x: LX + W, y: cy };
  const [hov, hb] = useHover();

  return (
    <Stage w={W_ART} h={H_ART} inlet={inlet} outlet={outlet} downstream="gather">
      {/* corner tab — overhangs the frame top-left */}
      <div style={{
        position: "absolute", left: LX + 10, top: top - 13, zIndex: 4,
        display: "flex", alignItems: "center", gap: 6, height: 22, padding: "0 9px",
        borderRadius: "7px 7px 7px 0",
        background: "color-mix(in oklab, var(--co-accent) 88%, #000)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <Icon name="forEach" size={12} color="var(--co-accent-ink)" />
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 700, color: "var(--co-accent-ink)" }}>for-each · ingest.files</span>
      </div>

      <div {...hb} onClick={() => setOpen(o => !o)} style={{
        position: "absolute", left: LX, top, width: W, height: H, zIndex: 2,
        borderRadius: 13,
        background: open ? "color-mix(in oklab, var(--co-accent) 7%, var(--co-bg-1))" : "var(--co-grad-loaf)",
        border: `1.5px ${open ? "dashed" : "solid"} ${open || hov ? "var(--co-accent)" : "var(--co-border-2)"}`,
        boxShadow: `${hov ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 14%, transparent), " : ""}${open ? "" : "inset 3px 0 0 var(--co-accent), "}var(--co-shadow-2)`,
        cursor: "pointer", overflow: "hidden",
        transition: "width 300ms var(--co-ease-out), height 300ms var(--co-ease-out), top 300ms var(--co-ease-out), border-color 160ms, box-shadow 160ms",
      }}>
        {/* top-right controls */}
        <div style={{ position: "absolute", top: 7, right: 9, display: "flex", alignItems: "center", gap: 6, zIndex: 3 }}>
          <Chip tone="accent">×7</Chip>
          <Chevron open={open} color="var(--co-text-muted)" />
        </div>

        {!open ? (
          <div style={{ padding: "0 14px", height: H, display: "flex", flexDirection: "column", justifyContent: "center" }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-pipeline</span>
            <span style={{ display: "flex", alignItems: "center", gap: 5, fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", marginTop: 2 }}>
              <Icon name="layout" size={11} color="var(--co-text-subtle)" /> 3 stages · collapsed
            </span>
          </div>
        ) : (
          <div style={{ height: H, display: "flex", alignItems: "center", justifyContent: "center", gap: 6, paddingTop: 8, animation: "fanFade 320ms var(--co-ease-out) both" }}>
            <MiniInline label="comment-file" />
            <Icon name="chevRight" size={13} color="var(--co-text-subtle)" />
            <MiniInline label="lint-fix" />
            <Icon name="chevRight" size={13} color="var(--co-text-subtle)" />
            <MiniInline label="format" />
          </div>
        )}
      </div>

      {/* fan-out / fan-in edge badges */}
      <div style={{ position: "absolute", left: inlet.x - 13, top: cy - 11, width: 26, height: 22, display: "flex", alignItems: "center", justifyContent: "center", borderRadius: 7, background: "var(--co-bg-3)", border: "1px solid var(--co-accent)", color: "var(--co-accent)", boxShadow: "var(--co-shadow-1)", zIndex: 3 }}>
        <Icon name="forEach" size={13} />
      </div>
      <div style={{ position: "absolute", left: outlet.x - 13, top: cy - 11, width: 26, height: 22, display: "flex", alignItems: "center", justifyContent: "center", borderRadius: 7, background: "var(--co-bg-3)", border: "1px solid var(--co-accent)", color: "var(--co-accent)", boxShadow: "var(--co-shadow-1)", zIndex: 3 }}>
        <Icon name="merge" size={13} />
      </div>
    </Stage>
  );
}

Object.assign(window, { ConceptD, ConceptDRun, ConceptE });
