/* global React, Icon, StatusDot, StatusTag, Spinner */
const { useState: useStateCV, useRef: useRefCV, useEffect: useEffectCV, useMemo: useMemoCV } = React;

// ──────────────────────────────────────────────────────────────────────────
// Node visuals — worker stage card + routing operator diamond.
// ──────────────────────────────────────────────────────────────────────────



// ── Node geometry ──────────────────────────────────────────────────────────
// Every node — worker OR operator — is the same height. The operator node is
// exactly 2 grid cells tall, so the dot-grid spacing is half the node height
// and the horizontal edge (which exits at the vertical center) runs straight
// along a row of grid dots.
const NODE_H   = 64;          // layout cell height — the shared vertical center every node hangs off of
const GRID     = NODE_H / 2;  // 32 — dot spacing = half the cell height
const WORKER_W = 160;         // worker width = 5 grid gaps → both ends land on a column of grid dots
const WORKER_H = GRID;        // 32 — worker body is exactly one grid gap tall
const WORKER_TOP = (NODE_H - WORKER_H) / 2; // 16 — centers the body on the cell's mid row (a grid row), so the
                                            // body's center line + its left/right ends + the output dot all sit on grid dots
const OP_W     = 32;          // operator node — rounded square, same height as the worker body, centered in the worker column

function NodeShell({ status, selected, glow, density, children, onClick, style, suppressRail }) {
  const compact = density === "compact";
  const running = status === "running";
  const statusColor = status && status !== "queued" && status !== "skipped"
    ? `var(--co-${status === "passed" ? "success" : status === "failed" ? "danger" : status === "running" ? "accent" : status === "retrying" ? "warning" : "info"})`
    : "var(--co-border-2)";
  const railShadow = (status === "queued" || status === "skipped")
    ? `inset 3px 0 0 color-mix(in oklab, ${statusColor} 40%, transparent)`
    : `inset 3px 0 0 ${statusColor}`;
  // Running gets an animated, breathing accent halo so it can never be
  // mistaken for the static crisp ring of a selected node. Selection always
  // wins when both are true (a deliberate user state).
  const breathing = running && !selected;
  const outlineShadow = selected
    ? "0 0 0 1px var(--co-accent), 0 0 0 4px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)"
    : "var(--co-shadow-1)";
  return (
    <div
      onClick={onClick}
      style={{
        position: "absolute",
        background: glow
          ? `linear-gradient(180deg, color-mix(in oklab, var(--co-accent) 12%, var(--co-bg-2)) 0%, var(--co-bg-2) 70%)`
          : "var(--co-grad-loaf)",
        border: `1px solid ${selected ? "var(--co-accent)" : running ? statusColor : "var(--co-border-2)"}`,
        borderRadius: 10,
        boxShadow: breathing ? undefined : (suppressRail ? outlineShadow : `${railShadow}, ${outlineShadow}`),
        animation: breathing ? "co-node-running-glow 1.7s var(--co-ease-in-out) infinite" : undefined,
        cursor: "pointer",
        userSelect: "none",
        transition: "border-color 140ms, box-shadow 200ms, transform 100ms",
        ...style,
      }}
      onMouseDown={e => e.stopPropagation()}
    >
      {children}
    </div>
  );
}

function WorkerNode({ stage, status, info, selected, density, onClick }) {
  const compact = density === "compact";
  const st = status?.status;
  const running = st === "running";
  return (
    <NodeShell
      status={st}
      selected={selected}
      glow={running}
      density={density}
      suppressRail
      onClick={onClick}
      style={{
        left: info.x, top: info.y + WORKER_TOP,
        width: WORKER_W, height: WORKER_H,
        padding: 0,
        display: "flex", alignItems: "center",
      }}
    >
      {/* leading golden role-tile — the shared identity anchor on every node. */}
      <span style={{
        width: 26, height: "100%", flexShrink: 0,
        display: "flex", alignItems: "center", justifyContent: "center",
        background: "var(--co-grad-crust)", color: "var(--co-accent-ink)",
        borderTopLeftRadius: 9, borderBottomLeftRadius: 9,
        borderRight: "1px solid var(--co-border-2)",
      }}>
        <Icon name={stage.icon || "bot"} size={14} color="currentColor" />
      </span>

      {/* title — left-aligned beside the role-tile */}
      <span style={{
        fontFamily: "var(--co-font-mono)",
        fontSize: compact ? 12.5 : 13.5,
        fontWeight: 600,
        color: "var(--co-text-strong)",
        textAlign: "left",
        overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        flex: 1, padding: "0 10px",
      }}>{stage.label}</span>

      {/* in-flight progress bar */}
      {running && status.progress != null && (
        <div style={{
          position: "absolute", left: 34, right: 12, bottom: 6,
          height: 2, background: "var(--co-bg-4)", borderRadius: 1, overflow: "hidden",
        }}>
          <div style={{
            width: `${status.progress * 100}%`,
            height: "100%",
            background: "var(--co-grad-crust)",
            transition: "width 600ms var(--co-ease-out)",
          }} />
        </div>
      )}

      {/* status badge — solid pill straddling the top border, label centered on the border line */}
      {status && status.status !== "queued" && (() => {
        const st = status.status;
        const solid = {
          passed:    { bg: "var(--co-success)", fg: "color-mix(in oklab, var(--co-success) 32%, #000)" },
          failed:    { bg: "var(--co-danger)",  fg: "color-mix(in oklab, var(--co-danger) 34%, #000)" },
          running:   { bg: "var(--co-accent)",  fg: "color-mix(in oklab, var(--co-accent) 38%, #000)" },
          retrying:  { bg: "var(--co-warning)", fg: "color-mix(in oklab, var(--co-warning) 36%, #000)" },
          skipped:   { bg: "var(--co-bg-4)",    fg: "var(--co-text-subtle)" },
          cancelled: { bg: "var(--co-bg-4)",    fg: "var(--co-text-subtle)" },
        }[st] || { bg: "var(--co-bg-4)", fg: "var(--co-text-strong)" };
        return (
          <div style={{
            position: "absolute", top: -8, right: 8,
            display: "inline-flex", alignItems: "center", gap: 4,
            height: 16, padding: "0 7px", borderRadius: 999,
            fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600,
            letterSpacing: "0.02em", lineHeight: 1, whiteSpace: "nowrap",
            background: solid.bg, color: solid.fg,
          }}>
            {st === "running" && (
              <span style={{
                width: 10, height: 10, borderRadius: "50%",
                background: `radial-gradient(farthest-side, ${solid.fg} 94%, transparent) top/2px 2px no-repeat, conic-gradient(transparent 30%, ${solid.fg})`,
                WebkitMask: "radial-gradient(farthest-side, transparent calc(100% - 2px), #000 0)",
                mask: "radial-gradient(farthest-side, transparent calc(100% - 2px), #000 0)",
                animation: "co-spin 0.8s infinite linear",
                flexShrink: 0,
              }} />
            )}
            {st}
          </div>
        );
      })()}
    </NodeShell>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Operator node — for-each / join. A small rounded-square icon node the same
// height as a worker body, centered in the worker column. Icon-only (no text).
// ──────────────────────────────────────────────────────────────────────────

function OperatorNode({ stage, status, info, selected, onClick, onContextMenu }) {
  const running = status?.status === "running";
  const icon = stage.kind === "join" ? "merge" : "gitBranch";
  return (
    <div
      onClick={onClick}
      onContextMenu={onContextMenu}
      onMouseDown={e => e.stopPropagation()}
      title={`${stage.kind} · right-click to remove`}
      style={{
        position: "absolute",
        left: info.x + (WORKER_W - OP_W) / 2,
        top: info.y + WORKER_TOP,
        width: OP_W, height: OP_W,
        display: "flex", alignItems: "center", justifyContent: "center",
        background: running
          ? "linear-gradient(180deg, color-mix(in oklab, var(--co-accent) 16%, var(--co-bg-3)) 0%, var(--co-bg-3) 100%)"
          : "var(--co-bg-3)",
        border: `1px solid ${selected ? "var(--co-accent)" : running ? "var(--co-accent)" : "var(--co-border-3)"}`,
        borderRadius: 9,
        boxShadow: selected
          ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 4px 10px rgba(0,0,0,0.4)"
          : running ? "0 0 14px color-mix(in oklab, var(--co-accent) 30%, transparent)" : "var(--co-shadow-1)",
        color: running ? "var(--co-accent)" : "var(--co-text-strong)",
        cursor: "pointer", userSelect: "none",
        transition: "border-color 140ms, box-shadow 200ms",
      }}
    >
      <Icon name={icon} size={18} />
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Context menu — right-click an arrow to insert an operator, or right-click an
// operator node to remove it (reconnecting the arrow it sat on).
// ──────────────────────────────────────────────────────────────────────────

function ContextMenu({ menu, onInsert, onRemove, onDuplicate, onRemoveCollapse, onDelete, onClose }) {
  let items;
  if (menu.kind === "edge") {
    items = [
      { icon: "merge",   label: "insert join",     onClick: () => onInsert(menu.edgeKey, "join") },
    ];
  } else if (menu.kind === "operator") {
    items = [
      { icon: "collapseLink", label: "remove · keep arrow", onClick: () => onRemove(menu.nodeId) },
    ];
  } else {
    // worker node
    items = [
      { icon: "copy",         label: "duplicate",         desc: "clone this node downstream",     onClick: () => onDuplicate(menu.nodeId) },
      { icon: "collapseLink", label: "remove + collapse", desc: "delete & rewire parent → child", onClick: () => onRemoveCollapse(menu.nodeId) },
      { divider: true },
      { icon: "x",            label: "delete node",       desc: "removes its connections too",    danger: true, onClick: () => onDelete(menu.nodeId) },
    ];
  }
  return (
    <>
      <div
        onClick={onClose}
        onContextMenu={(e) => { e.preventDefault(); onClose(); }}
        style={{ position: "fixed", inset: 0, zIndex: 60 }}
      />
      <div style={{
        position: "fixed", left: menu.x, top: menu.y, zIndex: 65,
        minWidth: 196,
        background: "var(--co-bg-1)",
        border: "1px solid var(--co-border-2)",
        borderRadius: 8,
        boxShadow: "var(--co-shadow-3)",
        padding: 4,
        transform: "translate(2px, 2px)",
      }}>
        {items.map((it, i) => it.divider
          ? <span key={i} style={{ display: "block", height: 1, margin: "4px 6px", background: "var(--co-border-1)" }} />
          : (
          <button
            key={i}
            type="button"
            onClick={(e) => { e.stopPropagation(); it.onClick(); }}
            style={{
              width: "100%",
              display: "grid", gridTemplateColumns: it.desc ? "20px 1fr" : "18px 1fr", alignItems: "center", gap: 9,
              padding: it.desc ? "6px 8px" : "7px 9px",
              background: "transparent", border: "none", borderRadius: 5,
              cursor: "pointer", textAlign: "left",
              color: it.danger ? "var(--co-danger)" : "var(--co-text)",
            }}
            onMouseEnter={(e) => { e.currentTarget.style.background = it.danger ? "var(--co-danger-soft)" : "var(--co-bg-3)"; }}
            onMouseLeave={(e) => { e.currentTarget.style.background = "transparent"; }}
          >
            <span style={{ display: "flex", alignItems: "center", justifyContent: "center", color: it.danger ? "currentColor" : "var(--co-accent)" }}>
              <Icon name={it.icon} size={14} color="currentColor" />
            </span>
            {it.desc ? (
              <span style={{ display: "flex", flexDirection: "column", lineHeight: 1.25 }}>
                <span style={{ fontFamily: "var(--co-font-sans)", fontSize: 12, fontWeight: 500 }}>{it.label}</span>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: it.danger ? "color-mix(in oklab, var(--co-danger) 70%, var(--co-text-subtle))" : "var(--co-text-subtle)" }}>{it.desc}</span>
              </span>
            ) : (
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 12, fontWeight: 500 }}>{it.label}</span>
            )}
          </button>
          )
        )}
      </div>
    </>
  );
}

// ──────────────────────────────────────────────────────────────────────────
// Layout — computes (x, y) per stage based on canvas style.
// ──────────────────────────────────────────────────────────────────────────

function computeLayout(workflow, style) {
  const out = {};
  const stages = workflow.stages;

  if (style === "graph") {
    // n8n style: use authored positions.
    for (const s of stages) {
      out[s.id] = { x: s.pos.x, y: s.pos.y };
    }
    return { positions: out, width: 2080, height: 700 };
  }

  if (style === "swimlane") {
    // left → right: column = x-step, lane = y-step. Lane spacing is a multiple
    // of GRID so every lane's center lands on a row of grid dots.
    const colW = 256;
    const laneH = 4 * GRID;   // 128
    const baseY = 10 * GRID;  // 320
    for (const s of stages) {
      out[s.id] = {
        x: 80 + s.column * colW,
        y: baseY + s.lane * laneH,
      };
    }
    const maxCol = Math.max(...stages.map(s => s.column));
    return { positions: out, width: 80 + (maxCol + 1) * colW + 80, height: 700 };
  }

  if (style === "tree") {
    // top → down: column → row (depth), lane → x. All offsets are GRID
    // multiples so the vertical trunk threads through the dot columns.
    const rowH = 4 * GRID;    // 128
    const laneW = 8 * GRID;   // 256
    const baseX = 22 * GRID;  // 704 → +WORKER_W/2 lands a column of dots
    const baseY = 2 * GRID;   // 64
    for (const s of stages) {
      out[s.id] = {
        x: baseX + s.lane * laneW,
        y: baseY + s.column * rowH,
      };
    }
    const maxCol = Math.max(...stages.map(s => s.column));
    return { positions: out, width: 1700, height: baseY + (maxCol + 1) * rowH + 60 };
  }

  return { positions: out, width: 1800, height: 700 };
}

// ──────────────────────────────────────────────────────────────────────────
// Edge geometry. Returns an SVG <path d=...> string + a midpoint for labels.
// ──────────────────────────────────────────────────────────────────────────

function edgeAnchor(stage, layoutPos, side, style, isRouting) {
  // returns the (x,y) at which an edge connects to a stage's node. Every node
  // shares NODE_H and the same vertical center, so horizontal edges are flat.
  const w = isRouting ? OP_W : WORKER_W;
  const cx = layoutPos.x + WORKER_W / 2;
  const cy = layoutPos.y + NODE_H / 2;
  // For tree (top-down), use top/bottom; for swimlane/graph use left/right
  const flow = style === "tree" ? "vertical" : "horizontal";
  if (flow === "horizontal") {
    if (side === "out") return { x: layoutPos.x + (isRouting ? (WORKER_W + w) / 2 : w), y: cy };
    return                 { x: layoutPos.x + (isRouting ? (WORKER_W - w) / 2 : 0),    y: cy };
  } else {
    // Tree (top-down): edges meet the body's top / bottom edge. The worker body
    // is shorter than the cell, so use its real edges; routing fills the cell.
    const topY = layoutPos.y + WORKER_TOP;
    const botY = layoutPos.y + WORKER_TOP + WORKER_H;
    if (side === "out") return { x: cx, y: botY };
    return                 { x: cx, y: topY };
  }
}

function pathBetween(a, b, edgeStyle, flow, loop) {
  const dx = b.x - a.x;
  const dy = b.y - a.y;

  if (loop) {
    // Loop-back curve: arc out and below (or above) the main flow
    if (flow === "horizontal") {
      const midY = Math.max(a.y, b.y) + 200;
      return `M ${a.x} ${a.y} C ${a.x} ${midY}, ${b.x} ${midY}, ${b.x} ${b.y}`;
    } else {
      const midX = Math.max(a.x, b.x) + 240;
      return `M ${a.x} ${a.y} C ${midX} ${a.y}, ${midX} ${b.y}, ${b.x} ${b.y}`;
    }
  }

  if (edgeStyle === "straight") {
    return `M ${a.x} ${a.y} L ${b.x} ${b.y}`;
  }

  if (edgeStyle === "orthogonal") {
    if (flow === "horizontal") {
      const mx = a.x + dx / 2;
      return `M ${a.x} ${a.y} L ${mx} ${a.y} L ${mx} ${b.y} L ${b.x} ${b.y}`;
    } else {
      const my = a.y + dy / 2;
      return `M ${a.x} ${a.y} L ${a.x} ${my} L ${b.x} ${my} L ${b.x} ${b.y}`;
    }
  }

  // curved (default)
  if (flow === "horizontal") {
    const c = Math.max(40, Math.abs(dx) * 0.5);
    return `M ${a.x} ${a.y} C ${a.x + c} ${a.y}, ${b.x - c} ${b.y}, ${b.x} ${b.y}`;
  } else {
    const c = Math.max(40, Math.abs(dy) * 0.5);
    return `M ${a.x} ${a.y} C ${a.x} ${a.y + c}, ${b.x} ${b.y - c}, ${b.x} ${b.y}`;
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Canvas — main viewport. Pan with drag, zoom with wheel.
// ──────────────────────────────────────────────────────────────────────────

function Canvas({
  workflow: workflowProp, job, view, selectedId, onSelect,
  canvasStyle, edgeStyle, density, inflightAnim,
  drawerOpen,
}) {
  // Local, mutable copy so right-click insert/remove can edit the graph.
  const [workflow, setWorkflow] = useStateCV(workflowProp);
  useEffectCV(() => { setWorkflow(workflowProp); }, [workflowProp]);
  const wrapRef = useRefCV(null);
  const [pan, setPan] = useStateCV({ x: 0, y: 0 });
  const [zoom, setZoom] = useStateCV(0.7);
  const dragRef = useRefCV(null);
  const longPressRef = useRefCV(null);

  // Builder-mode hover/selection state.
  const [hoveredNodeId, setHoveredNodeId] = useStateCV(null);
  const [hoveredEdgeKey, setHoveredEdgeKey] = useStateCV(null);
  const [selectedEdgeKey, setSelectedEdgeKey] = useStateCV(null);
  const [picker, setPicker] = useStateCV(null);
  const [ctxMenu, setCtxMenu] = useStateCV(null);

  // Right-click affordances. Insert an operator into an arrow (splitting it),
  // or remove an operator node and reconnect the arrow it sat on.
  const openEdgeMenu = (e, edgeKey) => {
    e.preventDefault(); e.stopPropagation();
    setCtxMenu({ x: e.clientX, y: e.clientY, kind: "edge", edgeKey });
  };
  const openNodeMenu = (e, nodeId, isOperator) => {
    e.preventDefault(); e.stopPropagation();
    setCtxMenu({ x: e.clientX, y: e.clientY, kind: isOperator ? "operator" : "worker", nodeId });
  };
  // Long-press (touch) opens the same context menu at the touch point.
  const openNodeMenuAt = (clientX, clientY, nodeId, isOperator) => {
    setCtxMenu({ x: clientX, y: clientY, kind: isOperator ? "operator" : "worker", nodeId });
  };
  const insertOperator = (edgeKey, opKind) => {
    setCtxMenu(null);
    setWorkflow(prev => {
      const arrow = prev.edges.find(ed => `${ed.from}→${ed.to}` === edgeKey);
      if (!arrow) return prev;
      const id = `${opKind}_${Math.random().toString(36).slice(2, 6)}`;
      const pf = positions[arrow.from], pt = positions[arrow.to];
      const pos = (pf && pt)
        ? { x: Math.round((pf.x + pt.x) / 2), y: Math.round((pf.y + pt.y) / 2) }
        : { x: 600, y: 320 };
      const src = prev.stages.find(s => s.id === arrow.from) || {};
      const newStage = {
        id, kind: opKind,
        label: opKind === "join" ? "join" : "for-each",
        pos, column: (src.column ?? 0) + 1, lane: src.lane ?? 0,
      };
      const edges = prev.edges.filter(ed => ed !== arrow);
      edges.push({ from: arrow.from, to: id });
      edges.push({ from: id, to: arrow.to, ...(arrow.case ? { case: arrow.case } : {}), ...(arrow.loop ? { loop: arrow.loop } : {}) });
      return { ...prev, stages: [...prev.stages, newStage], edges };
    });
  };
  const removeOperator = (nodeId) => {
    setCtxMenu(null);
    if (selectedId === nodeId) onSelect(null);
    setWorkflow(prev => {
      const incoming = prev.edges.filter(ed => ed.to === nodeId);
      const outgoing = prev.edges.filter(ed => ed.from === nodeId);
      const edges = prev.edges.filter(ed => ed.from !== nodeId && ed.to !== nodeId);
      for (const i of incoming) for (const o of outgoing) {
        edges.push({ from: i.from, to: o.to, ...(o.case ? { case: o.case } : {}), ...(o.loop ? { loop: o.loop } : {}) });
      }
      return { ...prev, stages: prev.stages.filter(s => s.id !== nodeId), edges };
    });
  };

  // Worker node actions (context menu). Duplicate clones the node and wires the
  // original straight into the clone; delete removes the node and its edges.
  const duplicateNode = (nodeId) => {
    setCtxMenu(null);
    setWorkflow(prev => {
      const src = prev.stages.find(s => s.id === nodeId);
      if (!src) return prev;
      const id = `${src.kind}_${Math.random().toString(36).slice(2, 6)}`;
      const pos = src.pos ? { x: src.pos.x, y: src.pos.y + 4 * 32 } : { x: 600, y: 320 };
      const clone = { ...src, id, label: `${src.label}-copy`, pos,
        column: (src.column ?? 0) + 1, lane: (src.lane ?? 0) };
      return { ...prev, stages: [...prev.stages, clone], edges: [...prev.edges, { from: nodeId, to: id }] };
    });
  };
  const deleteNode = (nodeId) => {
    setCtxMenu(null);
    if (selectedId === nodeId) onSelect(null);
    setWorkflow(prev => ({
      ...prev,
      stages: prev.stages.filter(s => s.id !== nodeId),
      edges: prev.edges.filter(ed => ed.from !== nodeId && ed.to !== nodeId),
    }));
  };

  // Selecting a node clears the edge selection (and vice versa).
  useEffectCV(() => { if (selectedId) setSelectedEdgeKey(null); }, [selectedId]);

  const { positions, width: worldW, height: worldH } = useMemoCV(
    () => computeLayout(workflow, canvasStyle),
    [workflow, canvasStyle]
  );

  // Compute bbox of nodes + auto-fit
  const refit = React.useCallback(() => {
    if (!wrapRef.current) return;
    const r = wrapRef.current.getBoundingClientRect();
    const xs = Object.values(positions).map(p => p.x);
    const ys = Object.values(positions).map(p => p.y);
    if (!xs.length) return;
    const minX = Math.min(...xs), maxX = Math.max(...xs);
    const minY = Math.min(...ys), maxY = Math.max(...ys);
    const bw = (maxX - minX) + 220;
    const bh = (maxY - minY) + 140;
    const padX = 40, padY = 60;
    const availW = Math.max(360, r.width - padX * 2);
    const availH = Math.max(280, r.height - padY * 2);
    const fitZoom = Math.min(0.9, Math.min(availW / bw, availH / bh));
    const finalZoom = Math.max(0.35, fitZoom);
    setZoom(finalZoom);
    const bboxCx = ((minX + maxX) / 2 + 100) * finalZoom;
    const bboxCy = ((minY + maxY) / 2 + 40)  * finalZoom;
    const visibleW = r.width - (drawerOpen ? 460 : 0);
    setPan({
      x: Math.max(20, visibleW / 2 - bboxCx),
      y: r.height / 2 - bboxCy - 20,
    });
  }, [positions, drawerOpen]);

  useEffectCV(() => { refit(); }, [refit, canvasStyle]);
  useEffectCV(() => {
    const onResize = () => refit();
    window.addEventListener("resize", onResize);
    return () => window.removeEventListener("resize", onResize);
  }, [refit]);

  // Pan drag
  const onMouseDown = (e) => {
    if (e.target.closest("[data-node]")) return;
    dragRef.current = { x: e.clientX, y: e.clientY, panX: pan.x, panY: pan.y };
  };
  useEffectCV(() => {
    const onMove = (e) => {
      if (!dragRef.current) return;
      setPan({
        x: dragRef.current.panX + (e.clientX - dragRef.current.x),
        y: dragRef.current.panY + (e.clientY - dragRef.current.y),
      });
    };
    const onUp = () => { dragRef.current = null; };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => { window.removeEventListener("mousemove", onMove); window.removeEventListener("mouseup", onUp); };
  }, []);

  // Wheel zoom
  const onWheel = (e) => {
    if (e.ctrlKey || e.metaKey) {
      e.preventDefault();
      const next = Math.max(0.4, Math.min(2.0, zoom * (1 - e.deltaY * 0.002)));
      setZoom(next);
    } else {
      // pan
      setPan(p => ({ x: p.x - e.deltaX, y: p.y - e.deltaY }));
      e.preventDefault();
    }
  };

  const showInflight = view === "job";
  const isBuilder = view === "builder";

  // Edge map: { "from→to:case": status }
  const stageById = useMemoCV(() => Object.fromEntries(workflow.stages.map(s => [s.id, s])), [workflow]);
  const isRouting = (s) => s && s.kind !== "worker" && s.kind !== "map";

  const flow = canvasStyle === "tree" ? "vertical" : "horizontal";

  // Pre-compute edge paths so the overlay can reuse them for affordance
  // positioning without re-deriving anchor + curve geometry.
  const edgePaths = useMemoCV(() => {
    const m = {};
    for (const edge of workflow.edges) {
      const from = stageById[edge.from];
      const to = stageById[edge.to];
      if (!from || !to || !positions[edge.from] || !positions[edge.to]) continue;
      const a = edgeAnchor(from, positions[edge.from], "out", canvasStyle, isRouting(from));
      const b = edgeAnchor(to,   positions[edge.to],   "in",  canvasStyle, isRouting(to));
      m[`${edge.from}→${edge.to}`] = pathBetween(a, b, edgeStyle, flow, edge.loop);
    }
    return m;
  }, [workflow, positions, canvasStyle, edgeStyle, flow]);

  return (
    <div
      ref={wrapRef}
      onMouseDown={onMouseDown}
      onWheel={onWheel}
      style={{
        position: "relative",
        flex: 1,
        overflow: "hidden",
        background: "var(--co-grad-hearth)",
        cursor: dragRef.current ? "grabbing" : "grab",
      }}
    >
      {/* dot grid — spacing is half the node height (a node spans exactly 2
          cells); offset by half a cell so the dots land on node tops, centers
          and bottoms, and horizontal edges thread straight through a dot row. */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `radial-gradient(circle, var(--co-border-2) 1px, transparent 1px)`,
        backgroundSize: `${GRID * zoom}px ${GRID * zoom}px`,
        backgroundPosition: `${pan.x - (GRID / 2) * zoom}px ${pan.y - (GRID / 2) * zoom}px`,
        opacity: 0.35,
        pointerEvents: "none",
      }} />

      <div style={{
        position: "absolute",
        left: pan.x, top: pan.y,
        width: worldW, height: worldH,
        transform: `scale(${zoom})`,
        transformOrigin: "0 0",
      }}>
        {/* Edges — SVG layer */}
        <svg
          width={worldW} height={worldH}
          style={{ position: "absolute", left: 0, top: 0, overflow: "visible", pointerEvents: "none" }}
        >
          <defs>
            <marker id="arrowDone" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-3)" />
            </marker>
            <marker id="arrowActive" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-accent)" />
            </marker>
            <marker id="arrowPending" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-4)" />
            </marker>
            <marker id="arrowSkipped" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-4)" />
            </marker>
          </defs>

          {workflow.edges.map((edge, i) => {
            const from = stageById[edge.from];
            const to = stageById[edge.to];
            if (!from || !to || !positions[edge.from] || !positions[edge.to]) return null;
            const edgeKey = `${edge.from}→${edge.to}`;
            const d = edgePaths[edgeKey];
            if (!d) return null;
            const a = edgeAnchor(from, positions[edge.from], "out", canvasStyle, isRouting(from));
            const b = edgeAnchor(to,   positions[edge.to],   "in",  canvasStyle, isRouting(to));

            const eStatus = showInflight ? (job.edgeStatus[edgeKey] || "pending") : "design";
            const isEdgeHovered  = hoveredEdgeKey === edgeKey;
            const isEdgeSelected = selectedEdgeKey === edgeKey;
            const highlight = isBuilder && (isEdgeHovered || isEdgeSelected);
            const stroke = highlight ? "var(--co-accent)" :
              eStatus === "done"    ? "var(--co-fg-3)" :
              eStatus === "active"  ? "var(--co-accent)" :
              eStatus === "skipped" ? "var(--co-fg-4)" :
              eStatus === "design"  ? "var(--co-fg-3)" : "var(--co-fg-4)";
            const dash =
              eStatus === "pending" ? "4 4" :
              eStatus === "skipped" ? "2 5" : "0";
            const arrow =
              eStatus === "done" ? "url(#arrowDone)" :
              eStatus === "active" ? "url(#arrowActive)" :
              eStatus === "skipped" ? "url(#arrowSkipped)" :
              eStatus === "design" ? "url(#arrowDone)" :
              "url(#arrowPending)";
            const opacity = eStatus === "skipped" ? 0.35 : eStatus === "pending" ? 0.6 : 1;

            return (
              <g key={i}>
                {/* Wide invisible hit area for hover/click */}
                {isBuilder && (
                  <path
                    d={d}
                    fill="none"
                    stroke="transparent"
                    strokeWidth={18}
                    style={{ pointerEvents: "stroke", cursor: "pointer" }}
                    onMouseEnter={() => setHoveredEdgeKey(edgeKey)}
                    onMouseLeave={() => setHoveredEdgeKey(k => k === edgeKey ? null : k)}
                    onClick={(e) => {
                      e.stopPropagation();
                      setSelectedEdgeKey(k => k === edgeKey ? null : edgeKey);
                      onSelect(null);
                    }}
                    onContextMenu={(e) => openEdgeMenu(e, edgeKey)}
                  />
                )}

                <path
                  d={d}
                  fill="none"
                  stroke={stroke}
                  strokeWidth={(eStatus === "active" || highlight) ? 2 : 1.5}
                  strokeDasharray={dash}
                  markerEnd={arrow}
                  opacity={opacity}
                  style={{
                    transition: "stroke 240ms",
                    animation: (eStatus === "active" && inflightAnim === "pulse")
                      ? "co-pulse 1.8s var(--co-ease-in-out) infinite" : undefined,
                  }}
                  pointerEvents="none"
                />

                {/* case / label on the edge */}
                {edge.case && (
                  <CaseLabel
                    a={a} b={b} flow={flow}
                    label={edge.case}
                    status={eStatus}
                  />
                )}
              </g>
            );
          })}
        </svg>

        {/* Nodes */}
        {workflow.stages.map(s => {
          const p = positions[s.id];
          if (!p) return null;
          const status = showInflight ? job.stageStatus[s.id] : null;
          const isOp = s.kind !== "worker" && s.kind !== "map";
          return (
            <div
              key={s.id}
              data-node
              onMouseEnter={() => isBuilder && setHoveredNodeId(s.id)}
              onMouseLeave={() => isBuilder && setHoveredNodeId(id => id === s.id ? null : id)}
              onContextMenu={isBuilder ? (e) => openNodeMenu(e, s.id, isOp) : undefined}
              onTouchStart={isBuilder ? (e) => {
                const t = e.touches[0];
                const cx = t.clientX, cy = t.clientY;
                if (longPressRef.current) clearTimeout(longPressRef.current);
                longPressRef.current = setTimeout(() => {
                  longPressRef.current = null;
                  openNodeMenuAt(cx, cy, s.id, isOp);
                }, 480);
              } : undefined}
              onTouchMove={isBuilder ? () => { if (longPressRef.current) { clearTimeout(longPressRef.current); longPressRef.current = null; } } : undefined}
              onTouchEnd={isBuilder ? () => { if (longPressRef.current) { clearTimeout(longPressRef.current); longPressRef.current = null; } } : undefined}
            >
              {s.kind === "map"
                ? <MapNode stage={s} status={status} info={p} selected={selectedId === s.id} view={view} onClick={() => onSelect(s.id)} />
                : isOp
                ? <OperatorNode stage={s} status={status} info={p} selected={selectedId === s.id} onClick={() => onSelect(s.id)} />
                : <WorkerNode stage={s} status={status} info={p} selected={selectedId === s.id} density={density} onClick={() => onSelect(s.id)} />}
            </div>
          );
        })}

        {/* Builder-mode in-world affordances (counter-scaled to keep
            visual size constant) — output handles, edge pins, node toolbar. */}
        {isBuilder && (
          <BuilderOverlay
            workflow={workflow}
            positions={positions}
            flow={flow}
            edgePaths={edgePaths}
            zoom={zoom}
            hoveredNodeId={hoveredNodeId}
            hoveredEdgeKey={hoveredEdgeKey}
            selectedNodeId={selectedId}
            selectedEdgeKey={selectedEdgeKey}
            setPicker={(p) => {
              // Convert world coords → screen coords for the picker.
              const screen = {
                x: p.anchor.x * zoom + pan.x,
                y: p.anchor.y * zoom + pan.y,
              };
              setPicker({ ...p, anchor: screen });
            }}
            onDeleteEdge={() => setSelectedEdgeKey(null)}
          />
        )}
      </div>

      {/* Operator picker — screen-space, rendered outside the world transform
          so it's never affected by zoom. */}
      {isBuilder && picker && (
        <OperatorPicker
          anchor={picker.anchor}
          context={picker.kind === "insert-edge" ? "insert" : "after"}
          onClose={() => setPicker(null)}
        />
      )}

      {/* Right-click context menu — screen-space, outside the world transform. */}
      {isBuilder && ctxMenu && (
        <ContextMenu
          menu={ctxMenu}
          onInsert={insertOperator}
          onRemove={removeOperator}
          onDuplicate={duplicateNode}
          onRemoveCollapse={removeOperator}
          onDelete={deleteNode}
          onClose={() => setCtxMenu(null)}
        />
      )}

      {/* Zoom controls */}
      <div style={{
        position: "absolute", left: 16, bottom: 16,
        display: "flex", alignItems: "center", gap: 4,
        padding: 4, background: "var(--co-bg-2)",
        border: "1px solid var(--co-border-1)",
        borderRadius: 8,
        fontFamily: "var(--co-font-mono)", fontSize: 11,
        boxShadow: "var(--co-shadow-2)",
        zIndex: 5,
      }}>
        <button type="button" onClick={() => setZoom(z => Math.max(0.4, z - 0.1))} style={zoomBtn}>−</button>
        <span style={{ minWidth: 38, textAlign: "center", color: "var(--co-text-muted)" }}>{Math.round(zoom * 100)}%</span>
        <button type="button" onClick={() => setZoom(z => Math.min(2, z + 0.1))} style={zoomBtn}>+</button>
        <span style={{ width: 1, height: 16, background: "var(--co-border-1)", margin: "0 2px" }} />
        <button type="button" onClick={refit} style={{ ...zoomBtn, width: "auto", padding: "0 8px" }}>fit</button>
      </div>

      {/* Mode indicator */}
      <div style={{
        position: "absolute", right: 16, bottom: 16,
        padding: "5px 10px",
        background: "var(--co-bg-2)",
        border: "1px solid var(--co-border-1)",
        borderRadius: 8,
        fontFamily: "var(--co-font-mono)", fontSize: 10,
        color: "var(--co-text-subtle)",
        boxShadow: "var(--co-shadow-2)",
        letterSpacing: "0.04em",
        zIndex: 5,
      }}>
        layout · {canvasStyle}
      </div>

      {/* Builder how-to tips panel */}
      {isBuilder && <BuilderTips />}
    </div>
  );
}
const zoomBtn = {
  width: 22, height: 22,
  border: "none", background: "transparent",
  color: "var(--co-text-strong)",
  fontFamily: "var(--co-font-mono)", fontSize: 13,
  cursor: "pointer", borderRadius: 4,
};

function CaseLabel({ a, b, flow, label, status }) {
  // Midpoint, slightly biased toward source
  const mx = (a.x + b.x) / 2;
  const my = (a.y + b.y) / 2;
  const fg = status === "active" ? "var(--co-accent)" : status === "skipped" ? "var(--co-fg-4)" : "var(--co-fg-2)";
  return (
    <g transform={`translate(${mx} ${my})`}>
      <rect x={-label.length * 3.6 - 6} y={-9} width={label.length * 7.2 + 12} height={18} rx={9}
        fill="var(--co-bg-3)" stroke="var(--co-border-2)" strokeWidth={1} />
      <text x={0} y={4} textAnchor="middle"
        style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, fill: fg, fontWeight: 500 }}>
        {label}
      </text>
    </g>
  );
}

// FlowTokens removed — work happens inside workers, not on the wires. Active
// edges read by accent color (and an optional co-pulse breathe), never by
// traveling dots.

// ──────────────────────────────────────────────────────────────────────────
// Map node — the map container (concept "capsule reactor").
// Replaces the standalone for-each + join operators. A capsule that occupies
// the worker column (WORKER_W wide, centered on the cell midline so edges
// stay flat). Collapses to one node; the header chevron expands it in place
// to reveal the per-item body.
//
// Header is the state indicator ("toasted header"): deselected it bakes down
// to a muted cocoa-orange; the full crust gradient re-ignites on selection or
// while running. The shell stays neutral so the accent outline + halo remain
// selection-only signals, exactly like a worker node.
//
// Connectors are completely standard: edges hit the left border with the
// usual arrowhead, and build mode renders the same dot output handle on the
// right border as any worker — no special inlet/outlet badges.
// ──────────────────────────────────────────────────────────────────────────
const mapChipStyle = {
  display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px",
  borderRadius: 999,
  background: "color-mix(in oklab, var(--co-accent) 14%, transparent)",
  color: "var(--co-accent)",
  border: "1px solid color-mix(in oklab, var(--co-accent) 34%, transparent)",
  fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600, whiteSpace: "nowrap",
};

function MapNode({ stage, status, info, selected, view, onClick, defaultOpen }) {
  const [open, setOpen] = useStateCV(!!defaultOpen);
  const job = view === "job" ? status : null;
  const st = status?.status;
  const cy = info.y + NODE_H / 2;
  const W = WORKER_W;                 // 160 — sits in the worker column
  const H = open ? 152 : 76;
  const top = cy - H / 2;
  const count = stage.count ?? 0;
  const done = job?.done ?? 0;
  const running = st === "running";
  const dim = !!job && st !== "running" && st !== "passed";

  const borderColor = selected || running ? "var(--co-accent)" : "var(--co-border-2)";
  const boxShadow = selected
    ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)"
    : running ? "0 0 18px color-mix(in oklab, var(--co-accent) 30%, transparent), 0 4px 12px rgba(0,0,0,0.4)"
    : "var(--co-shadow-1)";
  // Toasted header — full crust only when lit (selected or running).
  const lit = selected || running;
  const headerBg = lit
    ? "var(--co-grad-crust)"
    : "linear-gradient(135deg, color-mix(in oklab, var(--co-accent) 32%, var(--co-bg-4)) 0%, color-mix(in oklab, var(--co-accent) 18%, var(--co-bg-3)) 100%)";
  const headerFg = lit ? "var(--co-accent-ink)" : "var(--co-accent-200)";
  const chipBg = lit ? "rgba(0,0,0,0.18)" : "rgba(0,0,0,0.22)";

  return (
    <>
      <div
        onClick={onClick}
        onMouseDown={e => e.stopPropagation()}
        style={{
          position: "absolute", left: info.x, top, width: W, height: H,
          borderRadius: 13, overflow: "hidden",
          background: "var(--co-bg-2)",
          border: `1px solid ${borderColor}`,
          boxShadow,
          cursor: "pointer", userSelect: "none",
          transition: "height 260ms var(--co-ease-out), top 260ms var(--co-ease-out), border-color 140ms, box-shadow 200ms",
        }}
      >
        {/* toasted header — muted when idle, crust gradient when lit */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: 26, background: headerBg, filter: dim ? "saturate(0.7) brightness(0.92)" : "none" }}>
          <Icon name="forEach" size={13} color={headerFg} />
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, fontWeight: 700, color: headerFg, letterSpacing: "0.02em" }}>map</span>
          <span style={{ flex: 1 }} />
          {job && (
            <span style={{
              display: "inline-flex", alignItems: "center", gap: 4, height: 16, padding: "0 6px",
              borderRadius: 999, background: chipBg, color: headerFg,
              fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 700, whiteSpace: "nowrap",
            }}>
              {running && <span style={{ width: 5, height: 5, borderRadius: 999, background: headerFg }} />}
              {`${done} / ${count}`}
            </span>
          )}
          <button type="button" onClick={(e) => { e.stopPropagation(); setOpen(o => !o); }}
            title={open ? "collapse" : "expand internal workflow"}
            style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 16, height: 16, border: "none", background: "transparent", color: headerFg, cursor: "pointer", padding: 0 }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round" style={{ transform: open ? "rotate(90deg)" : "none", transition: "transform 240ms var(--co-ease-out)" }}><polyline points="9,6 15,12 9,18" /></svg>
          </button>
        </div>

        {/* body */}
        {!open ? (
          <div style={{ padding: "0 11px", height: 50, display: "flex", flexDirection: "column", justifyContent: "center", gap: 2 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{stage.body.label}</span>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>over {stage.over}</span>
          </div>
        ) : (
          <div style={{ padding: "8px 10px", display: "flex", flexDirection: "column", gap: 7 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--co-text-subtle)" }}>runs per item</span>
            <div style={{ display: "flex", alignItems: "center", justifyContent: "center", height: 30, borderRadius: 8, background: "var(--co-bg-0)", border: "1px solid var(--co-border-2)" }}>
              <span style={{ display: "inline-flex", alignItems: "center", height: 24, padding: "0 10px", borderRadius: 7, background: "var(--co-grad-loaf)", border: "1px solid var(--co-border-2)", boxShadow: "inset 3px 0 0 var(--co-accent)", fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap" }}>{stage.body.label}</span>
            </div>
            <div style={{ display: "flex", gap: 5 }}>
              <span style={mapChipStyle}>{stage.concurrency} parallel</span>
              <span style={mapChipStyle}>collect · {stage.joinMode}</span>
            </div>
          </div>
        )}
      </div>
    </>
  );
}

Object.assign(window, { Canvas, WorkerNode, MapNode });
