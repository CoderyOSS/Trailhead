/* global React, Card, SubBlock, H3, TokensList */

// ──────────────────────────────────────────────────────────────────────────
// Layouts section — schematic mockups of each app mode.
//
// We use stylized rectangles instead of the live components for two reasons:
//  1. The Flutter agent reads layouts as composition diagrams — clearer with
//     labeled regions than with the full live UI.
//  2. Rendering 4 live Canvas instances at once produces ResizeObserver feedback
//     in the browser; the schematic eliminates that.
// Live full-fidelity examples are available by opening Workflow Builder.html
// directly.
// ──────────────────────────────────────────────────────────────────────────

const REGION_BG = {
  rail:      "var(--co-bg-1)",
  sidebar:   "var(--co-bg-1)",
  topbar:    "var(--co-bg-1)",
  canvas:    "var(--co-bg-0)",
  drawer:    "var(--co-bg-1)",
  filmstrip: "var(--co-bg-1)",
  table:     "var(--co-bg-0)",
};

function Label({ children, sub, accent }) {
  return (
    <div style={{
      display: "flex", flexDirection: "column", gap: 2,
      pointerEvents: "none",
    }}>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        letterSpacing: "0.10em", textTransform: "uppercase",
        color: accent ? "var(--co-accent)" : "var(--co-text-muted)",
        fontWeight: 600,
      }}>{children}</span>
      {sub && (
        <span style={{
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          color: "var(--co-text-subtle)",
        }}>{sub}</span>
      )}
    </div>
  );
}

function Region({ children, bg, border, padding = "8px 10px", style }) {
  return (
    <div style={{
      position: "absolute",
      background: bg,
      border: border ? "1px solid var(--co-border-1)" : "none",
      padding,
      display: "flex", flexDirection: "column",
      ...style,
    }}>{children}</div>
  );
}

// Vertical line stack to suggest list rows
function StackLines({ count = 6, height = 8, gap = 6, opacity = 0.5, width = "70%" }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap, opacity, marginTop: 6 }}>
      {Array.from({ length: count }).map((_, i) => (
        <div key={i} style={{
          width, height,
          background: "var(--co-border-2)",
          borderRadius: 3,
        }} />
      ))}
    </div>
  );
}

// Tile representing the active row in a list
function ActiveListRow({ y, label, w = "60%" }) {
  return (
    <>
      <div style={{
        position: "absolute", left: 8, top: y, width: 2, height: 18,
        background: "var(--co-accent)", borderRadius: 2,
      }} />
      <div style={{
        position: "absolute", left: 14, right: 12, top: y - 2, height: 22,
        background: "var(--co-bg-3)",
        borderRadius: 5,
        display: "flex", alignItems: "center", padding: "0 8px",
        fontFamily: "var(--co-font-mono)", fontSize: 10.5,
        color: "var(--co-text)",
      }}>{label}</div>
    </>
  );
}

// Node placeholder used in canvas region
function FakeNode({ x, y, w = 96, h = 30, label = "stage", status = "queued", running, selected }) {
  const statusColor = status === "passed"  ? "var(--co-success)"
                    : status === "running" ? "var(--co-accent)"
                    : status === "failed"  ? "var(--co-danger)"
                    : "var(--co-border-2)";
  return (
    <div style={{
      position: "absolute", left: x, top: y, width: w, height: h,
      background: "var(--co-bg-2)",
      border: `1px solid ${selected ? "var(--co-accent)" : "var(--co-border-2)"}`,
      borderLeft: `3px solid ${statusColor}`,
      borderRadius: 6,
      display: "flex", alignItems: "center",
      padding: "0 8px",
      fontFamily: "var(--co-font-mono)", fontSize: 9.5,
      color: "var(--co-text)",
      boxShadow: selected ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 22%, transparent)" : "none",
    }}>
      {running && (
        <span style={{
          width: 5, height: 5, background: "var(--co-accent)", borderRadius: 999,
          marginRight: 5, animation: "co-pulse 1.4s ease-in-out infinite",
        }} />
      )}
      {label}
    </div>
  );
}

// Curved edge between two centers
function FakeEdge({ from, to, status = "design" }) {
  const stroke = status === "active" ? "var(--co-accent)"
              : status === "skipped" ? "var(--co-fg-4)"
              :                        "var(--co-fg-3)";
  const dash = status === "pending" ? "4 4" : status === "skipped" ? "2 5" : "0";
  const opacity = status === "skipped" ? 0.4 : 1;
  const dx = (to.x - from.x);
  const c  = Math.max(20, Math.abs(dx) * 0.5);
  const d  = `M ${from.x} ${from.y} C ${from.x + c} ${from.y}, ${to.x - c} ${to.y}, ${to.x} ${to.y}`;
  return (
    <path d={d} stroke={stroke} strokeWidth="1.5" fill="none" strokeDasharray={dash} opacity={opacity} />
  );
}

// ── Schematic layouts ────────────────────────────────────────────────────

function SchematicLayout({ mode, openDrawer }) {
  const W = 1080;
  const H = mode === "history-list" ? 540 : 620;
  const railW = 52;
  const sbW = mode === "build" ? 240 : mode === "history-list" ? 0 : 260;
  const topH = mode === "build" || mode === "history-list" ? 56 : 64;
  const filmH = mode === "active" || mode === "history" ? 200 : 0;
  const drawerW = openDrawer ? 460 : 0;

  const canvasL = railW + sbW;
  const canvasT = topH;
  const canvasR = W - drawerW;
  const canvasB = H - filmH;

  return (
    <div style={{
      position: "relative",
      width: "100%",
      maxWidth: W,
      height: H,
      background: REGION_BG.canvas,
      border: "1px solid var(--co-border-1)",
      borderRadius: 10,
      overflow: "hidden",
      margin: "0 auto",
    }}>
      {/* Mode rail */}
      <Region bg={REGION_BG.rail} border style={{ left: 0, top: 0, bottom: 0, width: railW, padding: "10px 0", borderRight: "1px solid var(--co-border-1)" }}>
        <div style={{ width: 28, height: 28, background: "var(--co-bg-3)", borderRadius: 6, margin: "0 auto" }} />
        <div style={{ height: 14 }} />
        {[
          { mode: "build",          label: "pencil" },
          { mode: "active",         label: "stopwatch" },
          { mode: "history",        label: "list" },
        ].map(it => {
          const isActive = mode === it.mode || (mode === "history-list" && it.mode === "history");
          return (
            <div key={it.mode} style={{
              position: "relative",
              width: 40, height: 40, margin: "1px auto",
              background: isActive ? "var(--co-bg-4)" : "transparent",
              borderRadius: 8,
              display: "flex", alignItems: "center", justifyContent: "center",
              color: isActive ? "var(--co-accent)" : "var(--co-text-subtle)",
              fontFamily: "var(--co-font-mono)", fontSize: 9.5,
            }}>
              {it.label}
              {isActive && (
                <span style={{
                  position: "absolute", left: -4, top: 8, bottom: 8, width: 2, borderRadius: 2, background: "var(--co-accent)",
                }} />
              )}
            </div>
          );
        })}
      </Region>

      {/* Sidebar — hidden in History list (no selection): the table fills the width */}
      {mode !== "history-list" && (
      <Region bg={REGION_BG.sidebar} border style={{ left: railW, top: 0, bottom: 0, width: sbW, padding: 0, borderRight: "1px solid var(--co-border-1)" }}>
        <div style={{ padding: 14, borderBottom: "1px solid var(--co-border-1)" }}>
          <Label accent>{mode === "build" ? "WORKFLOWS" : mode === "active" ? "ACTIVE JOBS" : "HISTORY"}</Label>
          {mode !== "build" && (
            <div style={{ marginTop: 6, height: 22, background: "var(--co-bg-3)", borderRadius: 5, display: "inline-flex", padding: 2, gap: 1 }}>
              <span style={{ padding: "0 8px", background: "var(--co-bg-4)", borderRadius: 4, fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-strong)", display: "flex", alignItems: "center" }}>grouped</span>
              <span style={{ padding: "0 8px", color: "var(--co-text-subtle)", fontFamily: "var(--co-font-mono)", fontSize: 9.5, display: "flex", alignItems: "center" }}>flat</span>
            </div>
          )}
        </div>
        <div style={{ padding: 12, position: "relative", flex: 1 }}>
          {mode === "build" && (
            <>
              <ActiveListRow y={4} label="pr-reviewer" />
              <StackLines count={5} />
            </>
          )}
          {mode !== "build" && (
            <>
              <ActiveListRow y={4} label={mode === "active" ? "PR #1428 · running" : "PR #1426 · passed"} />
              <StackLines count={mode === "active" ? 4 : 8} />
            </>
          )}
        </div>
      </Region>
      )}

      {/* Top bar */}
      <Region bg={REGION_BG.topbar} border style={{
        left: canvasL, right: 0, top: 0, height: topH,
        padding: "0 14px",
        borderBottom: "1px solid var(--co-border-1)",
        flexDirection: "row", alignItems: "center", gap: 10,
      }}>
        <span style={{
          fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 700,
          padding: "3px 8px", borderRadius: 3,
          background: mode === "active" ? "var(--co-accent-soft)" : "var(--co-bg-3)",
          color: mode === "active" ? "var(--co-accent)" : "var(--co-text-muted)",
          letterSpacing: "0.10em",
        }}>{(mode === "history-list" ? "HISTORY" : mode).toUpperCase()}</span>

        {mode === "build" && (
          <>
            <div style={{ width: 22, height: 22, background: "var(--co-bg-3)", borderRadius: 5 }} />
            <span style={{ fontFamily: "var(--co-font-display)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)" }}>pr-reviewer</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>v14</span>
            <div style={{ flex: 1 }} />
            <ActionPill label="duplicate" ghost />
            <ActionPill label="YAML" ghost />
            <ActionPill label="save draft" />
            <ActionPill label="launch" primary />
          </>
        )}
        {(mode === "active" || mode === "history") && (
          <>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 12, fontWeight: 600, color: "var(--co-text-strong)" }}>r_8f2a91c</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, padding: "1px 5px", borderRadius: 3, background: "var(--co-bg-3)", color: "var(--co-text-muted)" }}>pr-reviewer · v14</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, padding: "1px 5px", borderRadius: 3, background: mode === "active" ? "var(--co-accent-soft)" : "var(--co-success-soft)", color: mode === "active" ? "var(--co-accent)" : "var(--co-success)" }}>{mode === "active" ? "RUNNING" : "PASSED"}</span>
            <div style={{ flex: 1 }} />
            {mode === "active" && (
              <div style={{ display: "inline-flex", gap: 3 }}>
                <ActionPill label="pause" ghost />
                <ActionPill label="stop" ghost />
                <ActionPill label="refresh" ghost />
              </div>
            )}
            {mode === "history" && (
              <>
                <ActionPill label="YAML" ghost />
                <ActionPill label="rerun" />
              </>
            )}
          </>
        )}
        {mode === "history-list" && (
          <>
            <span style={{ fontFamily: "var(--co-font-display)", fontSize: 14, fontWeight: 600, color: "var(--co-text-strong)" }}>Past jobs</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>· 13 runs · last 24h</span>
            <div style={{ flex: 1 }} />
            <ActionPill label="refresh" ghost />
          </>
        )}
      </Region>

      {/* Canvas area or table */}
      {mode !== "history-list" ? (
        <>
          <Region bg={REGION_BG.canvas} style={{
            left: canvasL, top: canvasT,
            width: canvasR - canvasL,
            height: canvasB - canvasT,
            padding: 0,
            backgroundImage: `radial-gradient(circle, var(--co-border-1) 1px, transparent 1px)`,
            backgroundSize: "20px 20px",
          }}>
            <svg viewBox={`0 0 ${canvasR - canvasL} ${canvasB - canvasT}`} width="100%" height="100%" style={{ position: "absolute", inset: 0 }}>
              <FakeEdge from={{ x: 105, y: 110 }} to={{ x: 200, y: 110 }} status={mode === "active" ? "done" : "design"} />
              <FakeEdge from={{ x: 305, y: 110 }} to={{ x: 400, y: 110 }} status={mode === "active" ? "done" : "design"} />
              <FakeEdge from={{ x: 505, y: 110 }} to={{ x: 600, y: 80 }}  status={mode === "active" ? "active" : "design"} />
              <FakeEdge from={{ x: 505, y: 110 }} to={{ x: 600, y: 145 }} status={mode === "active" ? "active" : "design"} />
              <FakeEdge from={{ x: 700, y: 80 }}  to={{ x: 790, y: 110 }} status={mode === "active" ? "pending" : "design"} />
              <FakeEdge from={{ x: 700, y: 145 }} to={{ x: 790, y: 110 }} status={mode === "active" ? "pending" : "design"} />
            </svg>
            <FakeNode x={10}  y={92}  label="ingest"        status={mode === "active" ? "passed" : "queued"} />
            <FakeNode x={105 + 7} y={92}  w={88} label="classify-risk"  status={mode === "active" ? "passed" : "queued"} />
            <FakeNode x={305 + 0} y={95}  w={92} h={24} label="switch"  status="queued" />
            <FakeNode x={400 + 5} y={62}  w={92} label="quick-review"  status={mode === "active" ? "skipped" : "queued"} />
            <FakeNode x={400 + 5} y={130} w={92} label="security-scan" status={mode === "active" ? "running" : "queued"} running={mode === "active"} />
            <FakeNode x={500 + 1} y={92}  w={88} label="full-review"   status={mode === "active" ? "running" : "queued"} running={mode === "active"} selected={openDrawer} />
            <FakeNode x={695 + 0} y={95}  w={88} h={24} label="join"   status="queued" />
            <FakeNode x={790 + 0} y={92}  w={88} label="critic"       status="queued" />
          </Region>

          {/* Filmstrip */}
          {filmH > 0 && (
            <Region bg={REGION_BG.filmstrip} border style={{
              left: canvasL, right: drawerW, bottom: 0, height: filmH,
              padding: "10px 14px",
              borderTop: "1px solid var(--co-border-1)",
            }}>
              <Label>SNAPSHOTS · 6</Label>
              <div style={{
                marginTop: 8,
                display: "flex", gap: 8, overflowX: "hidden",
              }}>
                {[0,1,2,3,4].map(i => (
                  <div key={i} style={{
                    flex: "0 0 200px",
                    height: 130,
                    background: "var(--co-bg-2)",
                    border: `1px solid ${i === 4 ? "var(--co-accent)" : "var(--co-border-1)"}`,
                    borderRadius: 8,
                    padding: 8,
                    display: "flex", flexDirection: "column", gap: 4,
                  }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-strong)" }}>stage-{i+1}</span>
                      <span style={{
                        fontFamily: "var(--co-font-mono)", fontSize: 8,
                        padding: "1px 4px", borderRadius: 2,
                        background: i === 3 ? "var(--co-danger-soft)" : i === 4 ? "var(--co-accent-soft)" : "var(--co-success-soft)",
                        color:      i === 3 ? "var(--co-danger)"      : i === 4 ? "var(--co-accent)"      : "var(--co-success)",
                        textTransform: "uppercase", letterSpacing: "0.04em",
                      }}>{i === 3 ? "failed" : i === 4 ? "live" : "passed"}</span>
                    </div>
                    <div style={{ height: 50, background: "var(--co-bg-1)", border: "1px solid var(--co-border-1)", borderRadius: 4 }} />
                    <div style={{ display: "flex", flexDirection: "column", gap: 3 }}>
                      <div style={{ height: 4, background: "var(--co-border-2)", borderRadius: 2, width: "85%" }} />
                      <div style={{ height: 4, background: "var(--co-border-2)", borderRadius: 2, width: "70%" }} />
                    </div>
                  </div>
                ))}
              </div>
            </Region>
          )}
        </>
      ) : (
        // History list — table
        <Region bg={REGION_BG.table} style={{
          left: canvasL, top: canvasT, right: 0, bottom: 0,
          padding: 18,
        }}>
          <div style={{ display: "flex", alignItems: "flex-end", justifyContent: "space-between", marginBottom: 12 }}>
            <div>
              <span style={{ fontFamily: "var(--co-font-display)", fontSize: 17, color: "var(--co-text-strong)", fontWeight: 600 }}>jobs · pr-reviewer</span>
              <div style={{ marginTop: 2, fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>13 runs · last 24h</div>
            </div>
            <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
              {["all 13","passed 4","failed 1","cancelled 1"].map((p, i) => (
                <span key={i} style={{
                  padding: "3px 8px",
                  fontFamily: "var(--co-font-mono)", fontSize: 10,
                  background: i === 0 ? "var(--co-bg-3)" : "transparent",
                  color: i === 0 ? "var(--co-text-strong)" : "var(--co-text-muted)",
                  border: `1px solid ${i === 0 ? "var(--co-border-3)" : "var(--co-border-1)"}`,
                  borderRadius: 999,
                }}>{p}</span>
              ))}
              <span style={{ width: 1, height: 16, background: "var(--co-border-1)", margin: "0 2px" }} />
              <span style={{ display: "inline-flex", background: "var(--co-bg-3)", border: "1px solid var(--co-border-1)", borderRadius: 5, padding: 2, gap: 1 }}>
                <span style={{ padding: "0 7px", background: "var(--co-bg-4)", borderRadius: 4, fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-strong)", display: "flex", alignItems: "center" }}>grouped</span>
                <span style={{ padding: "0 7px", color: "var(--co-text-subtle)", fontFamily: "var(--co-font-mono)", fontSize: 9.5, display: "flex", alignItems: "center" }}>flat</span>
              </span>
            </div>
          </div>
          <div style={{
            background: "var(--co-bg-1)",
            border: "1px solid var(--co-border-1)",
            borderRadius: 8,
            overflow: "hidden",
          }}>
            <div style={{
              display: "grid",
              gridTemplateColumns: "26px 100px 1fr 80px 70px 70px 60px",
              padding: "8px 14px",
              fontFamily: "var(--co-font-mono)", fontSize: 9.5,
              color: "var(--co-text-subtle)", letterSpacing: "0.06em", textTransform: "uppercase",
              borderBottom: "1px solid var(--co-border-1)",
            }}>
              <span></span><span>run id</span><span>input</span><span>status</span><span>started</span><span>dur</span><span>cost</span>
            </div>
            {[
              { id: "r_8f29442", inp: "PR #1427", status: "passed",    started: "14:12", dur: "3m44s", cost: "$0.31" },
              { id: "r_8f28a01", inp: "suite/all", status: "failed",   started: "14:07", dur: "8m12s", cost: "$1.84" },
              { id: "r_8f27b3d", inp: "ci-main", status: "passed",     started: "14:03", dur: "0m48s", cost: "$0.04" },
              { id: "r_8f26108", inp: "PR #1426", status: "passed",    started: "13:58", dur: "2m18s", cost: "$0.22" },
              { id: "r_8f23911", inp: "PR #1424", status: "cancelled", started: "12:55", dur: "0m22s", cost: "$0.02" },
            ].map((r, i) => {
              const sColor = r.status === "passed" ? "var(--co-success)" : r.status === "failed" ? "var(--co-danger)" : "var(--co-fg-3)";
              const sSoft  = r.status === "passed" ? "var(--co-success-soft)" : r.status === "failed" ? "var(--co-danger-soft)" : "var(--co-bg-3)";
              return (
                <div key={i} style={{
                  display: "grid",
                  gridTemplateColumns: "26px 100px 1fr 80px 70px 70px 60px",
                  padding: "10px 14px",
                  borderBottom: "1px solid var(--co-border-1)",
                  alignItems: "center",
                  fontFamily: "var(--co-font-mono)", fontSize: 11,
                }}>
                  <span><span style={{ display: "inline-block", width: 6, height: 6, background: sColor, borderRadius: 999 }} /></span>
                  <span style={{ color: "var(--co-text-strong)" }}>{r.id}</span>
                  <span style={{ color: "var(--co-text)" }}>{r.inp}</span>
                  <span><span style={{ padding: "1px 6px", background: sSoft, color: sColor, borderRadius: 3, fontSize: 9.5, fontWeight: 600, letterSpacing: "0.04em", textTransform: "uppercase" }}>{r.status}</span></span>
                  <span style={{ color: "var(--co-text)" }}>{r.started}</span>
                  <span style={{ color: "var(--co-text)" }}>{r.dur}</span>
                  <span style={{ color: "var(--co-text)" }}>{r.cost}</span>
                </div>
              );
            })}
          </div>
        </Region>
      )}

      {/* Drawer */}
      {openDrawer && (
        <Region bg={REGION_BG.drawer} border style={{
          right: 0, top: topH, bottom: 0, width: drawerW,
          padding: 0,
          borderLeft: "1px solid var(--co-border-1)",
          boxShadow: "-12px 0 32px rgba(0,0,0,0.3)",
        }}>
          {/* drawer header */}
          <div style={{ padding: "14px 16px 12px", borderBottom: "1px solid var(--co-border-1)" }}>
            <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
              <div style={{ width: 28, height: 28, background: "var(--co-grad-crust)", borderRadius: 6 }} />
              <div style={{ flex: 1 }}>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13, color: "var(--co-text-strong)", fontWeight: 600 }}>full-review</span>
                <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", marginTop: 2 }}>worker stage{mode === "active" ? " · log" : ""}</div>
              </div>
            </div>
          </div>
          {/* drawer tabs (editor only) */}
          {mode === "build" && (
            <div style={{ padding: "0 16px", borderBottom: "1px solid var(--co-border-1)", background: "var(--co-bg-2)", display: "flex", gap: 16 }}>
              {["stage","prompt","result"].map((t, i) => (
                <div key={t} style={{
                  padding: "10px 0",
                  fontSize: 12, color: i === 0 ? "var(--co-text-strong)" : "var(--co-text-muted)",
                  borderBottom: i === 0 ? "2px solid var(--co-accent)" : "2px solid transparent",
                }}>{t}</div>
              ))}
            </div>
          )}
          {/* drawer body */}
          <div style={{ flex: 1, padding: 16, position: "relative" }}>
            {mode === "build" && (
              <>
                <Label>STAGE ID</Label>
                <div style={{ marginTop: 6, height: 32, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                <div style={{ height: 16 }} />
                <Label>MODEL CONFIG</Label>
                <div style={{ marginTop: 6, height: 32, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                <div style={{ height: 16 }} />
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 8 }}>
                  <div style={{ height: 56, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                  <div style={{ height: 56, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                  <div style={{ height: 56, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                </div>
              </>
            )}
            {mode === "active" && (
              <>
                <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 8, marginBottom: 12 }}>
                  <div>
                    <Label>CONNECTION</Label>
                    <div style={{ marginTop: 4, height: 32, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8, display: "flex", alignItems: "center", padding: "0 10px", fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-accent)" }}>Anthropic · sonnet-4.5</div>
                  </div>
                  <div>
                    <Label>CONFIGS · 2</Label>
                    <div style={{ marginTop: 4, height: 32, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 8 }} />
                  </div>
                </div>
                <Label>EXECUTIONS · 2</Label>
                <div style={{ marginTop: 6, display: "flex", flexDirection: "column", gap: 6 }}>
                  <div style={{
                    border: "1px solid var(--co-border-1)",
                    background: "var(--co-bg-2)",
                    borderRadius: 8,
                    padding: "9px 12px",
                  }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-text-strong)" }}>attempt 1</span>
                      <span style={{ padding: "1px 6px", background: "var(--co-danger-soft)", color: "var(--co-danger)", borderRadius: 3, fontSize: 9.5, fontFamily: "var(--co-font-mono)", textTransform: "uppercase", letterSpacing: "0.04em", fontWeight: 600 }}>failed</span>
                    </div>
                    <div style={{ marginTop: 2, fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>+00:35 · 1m13s · 18.0k tok</div>
                  </div>
                  <div style={{
                    border: "1px solid var(--co-accent)",
                    background: "var(--co-bg-1)",
                    borderRadius: 8,
                    padding: "9px 12px",
                  }}>
                    <div style={{ display: "flex", justifyContent: "space-between", alignItems: "center" }}>
                      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-text-strong)" }}>attempt 2</span>
                      <span style={{ padding: "1px 6px", background: "var(--co-accent-soft)", color: "var(--co-accent)", borderRadius: 3, fontSize: 9.5, fontFamily: "var(--co-font-mono)", textTransform: "uppercase", letterSpacing: "0.04em", fontWeight: 600, display: "inline-flex", alignItems: "center", gap: 4 }}>
                        <span style={{ width: 5, height: 5, background: "var(--co-accent)", borderRadius: 999, animation: "co-pulse 1.4s ease-in-out infinite" }} />running
                      </span>
                    </div>
                    <div style={{ marginTop: 2, fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>+02:02 · 38.4k tok · 62%</div>
                    <div style={{ marginTop: 8, height: 60, background: "var(--co-bg-1)", border: "1px solid var(--co-accent)", borderRadius: 5 }} />
                    <div style={{ marginTop: 4, height: 38, background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)", borderRadius: 5 }} />
                  </div>
                </div>
              </>
            )}
          </div>
        </Region>
      )}
    </div>
  );
}

function ActionPill({ label, primary, ghost }) {
  return (
    <span style={{
      padding: "4px 10px",
      fontSize: 11, fontWeight: 500, fontFamily: "var(--co-font-sans)",
      background: primary ? "var(--co-grad-crust)" : "transparent",
      color:      primary ? "var(--co-accent-ink)" : "var(--co-text-muted)",
      borderRadius: 5,
      whiteSpace: "nowrap",
    }}>{label}</span>
  );
}

function WidgetTreeNote({ children }) {
  return (
    <div style={{
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
      padding: 14,
      fontFamily: "var(--co-font-mono)", fontSize: 11.5,
      lineHeight: 1.65,
      color: "var(--co-text-muted)",
      whiteSpace: "pre",
      overflowX: "auto",
    }}>{children}</div>
  );
}

function LayoutCard({ title, description, mode, openDrawer, tree, extra }) {
  return (
    <Card title={title} description={description}>
      <SchematicLayout mode={mode} openDrawer={openDrawer} />
      <div style={{ height: 18 }} />
      <H3>widget tree</H3>
      <WidgetTreeNote>{tree}</WidgetTreeNote>
      {extra}
    </Card>
  );
}

function LayoutsSection() {
  return (
    <>
      <LayoutCard
        title="Build mode · workflow editor"
        description="Mode rail · Workflows sidebar · top bar with save + launch · canvas (graph / lanes / tree). Drawer optional. No filmstrip."
        mode="build"
        tree={`Scaffold
└─ Row
   ├─ ModeRail          (52px, fixed)
   ├─ WorkflowsSidebar  (240px, fixed)
   └─ Expanded
      └─ Column
         ├─ TopBar          (BuildBar variant)
         └─ Expanded
            └─ Row
               ├─ Expanded → Canvas (free-pan graph)
               └─ StageDrawer    (460px when open · editor mode)`}
      />
      <LayoutCard
        title="Active mode · running job"
        description="Two-row JobBar. Active edges flow tokens. Right drawer is read-only log viewer with executions list. Filmstrip beneath the canvas."
        mode="active"
        openDrawer
        tree={`Scaffold
└─ Row
   ├─ ModeRail
   ├─ JobsSidebar (kind: 'active')
   └─ Expanded
      └─ Column
         ├─ TopBar (JobBar — 2 rows)
         └─ Expanded
            └─ Row
               ├─ Expanded
               │  └─ Column
               │     ├─ Expanded → Canvas (status overlay + token flow)
               │     └─ Filmstrip
               └─ StageDrawer (log viewer · 460px)`}
      />
      <LayoutCard
        title="History · list view"
        description="No job selected. The jobs sidebar is hidden — the full RunsView table fills the width (rail → table, no sidebar between). The table carries its own grouped/flat toggle beside the status filter pills. Selecting a run brings the sidebar back as a job-to-job navigator."
        mode="history-list"
        tree={`Scaffold
└─ Row
   ├─ ModeRail
   └─ Expanded            // no sidebar until a run is selected
      └─ Column
         ├─ TopBar (HistoryListBar — 1 row)
         └─ Expanded → RunsView (grouped/flat toggle, no search)`}
      />
      <LayoutCard
        title="History · selected job · review past run"
        description="Same as Active but read-only and animations disabled. TopBar shows YAML + rerun actions. Canvas, filmstrip, and log viewer all reflect the historical job state."
        mode="history"
        openDrawer
        tree={`Same widget tree as Active, but:
 - TopBar (JobBar — history variant, YAML + rerun)
 - Canvas inflightAnim disabled
 - StageDrawer log viewer is fully read-only`}
        extra={(
          <>
            <div style={{ height: 18 }} />
            <H3>tokens shared across layouts</H3>
            <TokensList tokens={[
              { name: "rail width",      value: "CompModeRail.width · 52" },
              { name: "sidebar width",   value: "CompSidebar.{jobsWidth | workflowWidth}" },
              { name: "topbar minHeight",value: "CompTopBar.minHeight · 56" },
              { name: "drawer width",    value: "CompDrawer.width · 460" },
              { name: "filmstrip",       value: "CompFilmstrip — auto height + horizontal scroll" },
              { name: "canvas",          value: "Expanded child · always pannable + zoomable" },
              { name: "layout",          value: "Row(rail, sidebar, Expanded[Column(TopBar, Row[Expanded[canvas+filmstrip], drawer])])" },
            ]} />
          </>
        )}
      />
    </>
  );
}

Object.assign(window, { LayoutsSection });
