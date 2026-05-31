/* global React, Icon, StatusDot */
const { useState: useStateCV, useRef: useRefCV, useEffect: useEffectCV, useMemo: useMemoCV } = React;

// ──────────────────────────────────────────────────────────────────────────
// Node visuals — worker stage card + routing operator diamond.
// ──────────────────────────────────────────────────────────────────────────

const ROUTING_KIND_META = {
  switch: { label: "switch", icon: "gitBranch" },
  branch: { label: "branch", icon: "gitBranch" },
  map:    { label: "for-each", icon: "refresh" },
  loop:   { label: "loop", icon: "refresh" },
  join:   { label: "join", icon: "workflow" },
};

function NodeShell({ status, selected, glow, density, children, onClick, style }) {
  const compact = density === "compact";
  const statusColor = status && status !== "queued" && status !== "skipped"
    ? `var(--co-${status === "passed" ? "success" : status === "failed" ? "danger" : status === "running" ? "accent" : status === "retrying" ? "warning" : "info"})`
    : "var(--co-border-2)";
  const railShadow = (status === "queued" || status === "skipped")
    ? `inset 3px 0 0 color-mix(in oklab, ${statusColor} 40%, transparent)`
    : `inset 3px 0 0 ${statusColor}`;
  const outlineShadow = selected
    ? "0 0 0 1px var(--co-accent), 0 0 0 4px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 6px 16px rgba(0,0,0,0.4)"
    : status === "running" ? `0 0 18px color-mix(in oklab, var(--co-accent) 30%, transparent), 0 4px 12px rgba(0,0,0,0.4)`
    : "var(--co-shadow-1)";
  return (
    <div
      onClick={onClick}
      style={{
        position: "absolute",
        background: glow
          ? `linear-gradient(180deg, color-mix(in oklab, var(--co-accent) 12%, var(--co-bg-2)) 0%, var(--co-bg-2) 70%)`
          : "var(--co-grad-loaf)",
        border: `1px solid ${selected ? "var(--co-accent)" : status === "running" ? statusColor : "var(--co-border-2)"}`,
        borderRadius: 10,
        boxShadow: `${railShadow}, ${outlineShadow}`,
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
  const w = compact ? 168 : 192;
  const h = compact ? 60 : 80;
  const running = status?.status === "running";
  return (
    <NodeShell
      status={status?.status}
      selected={selected}
      glow={running}
      density={density}
      onClick={onClick}
      style={{
        left: info.x, top: info.y,
        width: w, height: h,
        padding: compact ? "8px 10px 8px 12px" : "10px 12px 10px 14px",
      }}
    >
      <div style={{ display: "flex", flexDirection: "column", height: "100%", gap: compact ? 1 : 2 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          {running && <StatusDot status="running" pulse size={6} />}
          <span style={{
            fontFamily: "var(--co-font-mono)",
            fontSize: compact ? 12 : 13,
            fontWeight: 600,
            color: "var(--co-text-strong)",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            flex: 1,
          }}>{stage.label}</span>
          {stage.model && !compact && (
            <span style={{
              fontFamily: "var(--co-font-mono)", fontSize: 9,
              padding: "1px 5px", borderRadius: 3,
              background: "var(--co-bg-4)", color: "var(--co-text-muted)",
              letterSpacing: "0.02em",
            }}>{stage.model}</span>
          )}
        </div>
        <div style={{
          fontSize: compact ? 10.5 : 11.5,
          color: "var(--co-text-subtle)",
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        }}>
          {stage.sub}
        </div>
        {!compact && (
          <div style={{ marginTop: "auto", display: "flex", alignItems: "center", gap: 5, flexWrap: "nowrap", overflow: "hidden" }}>
            {(stage.skills || []).slice(0, 3).map(sk => (
              <span key={sk} style={{
                fontFamily: "var(--co-font-mono)", fontSize: 9,
                padding: "1px 5px", borderRadius: 3,
                background: "var(--co-bg-3)", color: "var(--co-fg-2)",
                border: "1px solid var(--co-border-1)",
              }}>{sk}</span>
            ))}
            {(stage.skills || []).length > 3 && (
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, color: "var(--co-text-subtle)" }}>
                +{stage.skills.length - 3}
              </span>
            )}
          </div>
        )}
      </div>

      {/* in-flight progress bar */}
      {running && status.progress != null && (
        <div style={{
          position: "absolute", left: 6, right: 6, bottom: 3,
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

      {/* status badge - top right */}
      {status && status.status !== "queued" && !running && (
        <div style={{
          position: "absolute", top: -7, right: 8,
          fontFamily: "var(--co-font-mono)", fontSize: 9,
          padding: "1px 6px", borderRadius: 999,
          background: status.status === "passed" ? "var(--co-success)" :
                      status.status === "failed" ? "var(--co-danger)" :
                      status.status === "skipped" ? "var(--co-bg-4)" :
                      "var(--co-bg-4)",
          color: status.status === "skipped" ? "var(--co-text-subtle)" :
                 status.status === "passed"  ? "color-mix(in oklab, var(--co-success) 30%, #000)" :
                 status.status === "failed"  ? "color-mix(in oklab, var(--co-danger) 30%, #000)" :
                 "var(--co-text-strong)",
          fontWeight: 600,
        }}>{status.status === "skipped" ? "skipped" : status.status}</div>
      )}
    </NodeShell>
  );
}

function RoutingNode({ stage, status, info, selected, density, onClick }) {
  const compact = density === "compact";
  const w = compact ? 110 : 124;
  const h = compact ? 44 : 50;
  const meta = ROUTING_KIND_META[stage.kind] || ROUTING_KIND_META.switch;
  const running = status?.status === "running";
  // Routing operators use diamond-cut corners via a clip-path on a layered box.
  return (
    <div
      onClick={onClick}
      onMouseDown={e => e.stopPropagation()}
      style={{
        position: "absolute",
        left: info.x + ((WORKER_DEFAULT_W - w) / 2), // align center with worker
        top: info.y + ((WORKER_DEFAULT_H - h) / 2),
        width: w, height: h,
        cursor: "pointer",
        userSelect: "none",
      }}
    >
      <div style={{
        position: "absolute", inset: 0,
        background: running ? `linear-gradient(180deg, color-mix(in oklab, var(--co-accent) 14%, var(--co-bg-3)) 0%, var(--co-bg-3) 100%)` : "var(--co-bg-3)",
        border: `1px solid ${selected ? "var(--co-accent)" : running ? "var(--co-accent)" : "var(--co-border-3)"}`,
        borderRadius: 999,
        boxShadow: selected ? `0 0 0 3px color-mix(in oklab, var(--co-accent) 22%, transparent), 0 4px 10px rgba(0,0,0,0.4)`
                  : running ? `0 0 14px color-mix(in oklab, var(--co-accent) 30%, transparent)` : "var(--co-shadow-1)",
        transition: "border-color 140ms, box-shadow 200ms",
      }} />
      <div style={{
        position: "absolute", inset: 0,
        display: "flex", alignItems: "center", justifyContent: "center", gap: 5,
        fontFamily: "var(--co-font-mono)",
        fontSize: compact ? 11 : 12,
        fontWeight: 600,
        color: running ? "var(--co-accent)" : "var(--co-text-strong)",
      }}>
        <Icon name={meta.icon} size={compact ? 11 : 12} />
        <span>{meta.label}</span>
      </div>
      {/* sub label below */}
      <div style={{
        position: "absolute", left: 0, right: 0, top: "100%",
        textAlign: "center", marginTop: 4,
        fontFamily: "var(--co-font-mono)",
        fontSize: 9.5,
        color: "var(--co-text-subtle)",
        letterSpacing: "0.02em",
      }}>{stage.sub}</div>
    </div>
  );
}

const WORKER_DEFAULT_W = 192;
const WORKER_DEFAULT_H = 80;

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
    // left → right: column = x-step (260px), lane = y-step (130px from center)
    const colW = 260;
    const laneH = 130;
    const baseY = 320;
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
    // top → down: column → row (depth), lane → x.
    const rowH = 130;
    const laneW = 240;
    const baseX = 700;
    for (const s of stages) {
      out[s.id] = {
        x: baseX + s.lane * laneW,
        y: 60 + s.column * rowH,
      };
    }
    const maxCol = Math.max(...stages.map(s => s.column));
    return { positions: out, width: 1700, height: 60 + (maxCol + 1) * rowH + 60 };
  }

  return { positions: out, width: 1800, height: 700 };
}

// ──────────────────────────────────────────────────────────────────────────
// Edge geometry. Returns an SVG <path d=...> string + a midpoint for labels.
// ──────────────────────────────────────────────────────────────────────────

function edgeAnchor(stage, layoutPos, side, style, isRouting) {
  // returns the (x,y) at which an edge connects to a stage's node
  const w = isRouting ? 124 : WORKER_DEFAULT_W;
  const h = isRouting ? 50  : WORKER_DEFAULT_H;
  const cx = layoutPos.x + (isRouting ? (WORKER_DEFAULT_W / 2) : WORKER_DEFAULT_W / 2);
  const cy = layoutPos.y + (isRouting ? (WORKER_DEFAULT_H / 2) : WORKER_DEFAULT_H / 2);
  // For tree (top-down), use top/bottom; for swimlane/graph use left/right
  const flow = style === "tree" ? "vertical" : "horizontal";
  if (flow === "horizontal") {
    if (side === "out") return { x: layoutPos.x + (isRouting ? (WORKER_DEFAULT_W + w) / 2 : w), y: cy };
    return                 { x: layoutPos.x + (isRouting ? (WORKER_DEFAULT_W - w) / 2 : 0),    y: cy };
  } else {
    if (side === "out") return { x: cx, y: layoutPos.y + (isRouting ? (WORKER_DEFAULT_H + h) / 2 : h) };
    return                 { x: cx, y: layoutPos.y + (isRouting ? (WORKER_DEFAULT_H - h) / 2 : 0) };
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
  workflow, job, view, selectedId, onSelect,
  canvasStyle, edgeStyle, density, inflightAnim,
  drawerOpen,
}) {
  const wrapRef = useRefCV(null);
  const [pan, setPan] = useStateCV({ x: 0, y: 0 });
  const [zoom, setZoom] = useStateCV(0.7);
  const dragRef = useRefCV(null);

  // Builder-mode hover/selection state.
  const [hoveredNodeId, setHoveredNodeId] = useStateCV(null);
  const [hoveredEdgeKey, setHoveredEdgeKey] = useStateCV(null);
  const [selectedEdgeKey, setSelectedEdgeKey] = useStateCV(null);
  const [picker, setPicker] = useStateCV(null);

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
  const isRouting = (s) => s && s.kind !== "worker";

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
      {/* dot grid */}
      <div style={{
        position: "absolute", inset: 0,
        backgroundImage: `radial-gradient(circle, var(--co-border-2) 1px, transparent 1px)`,
        backgroundSize: `${24 * zoom}px ${24 * zoom}px`,
        backgroundPosition: `${pan.x}px ${pan.y}px`,
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
                  style={{ transition: "stroke 240ms" }}
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

                {/* flowing tokens for active edges */}
                {eStatus === "active" && inflightAnim !== "off" && (
                  <FlowTokens d={d} mode={inflightAnim} />
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
          const node = s.kind === "worker"
            ? <WorkerNode  key={s.id} stage={s} status={status} info={p} selected={selectedId === s.id} density={density} onClick={() => onSelect(s.id)} />
            : <RoutingNode key={s.id} stage={s} status={status} info={p} selected={selectedId === s.id} density={density} onClick={() => onSelect(s.id)} />;
          return (
            <div
              key={s.id}
              data-node
              onMouseEnter={() => isBuilder && setHoveredNodeId(s.id)}
              onMouseLeave={() => isBuilder && setHoveredNodeId(id => id === s.id ? null : id)}
            >
              {node}
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

function FlowTokens({ d, mode }) {
  // Three dots along the path at staggered times.
  const dur = mode === "pulse" ? 2.8 : 1.6;
  const dots = mode === "tokens" ? 3 : 2;
  const offsets = [0, 0.33, 0.66].slice(0, dots);
  return (
    <>
      {offsets.map((o, i) => (
        <circle key={i} r={3.2} fill="var(--co-accent)">
          <animateMotion dur={`${dur}s`} repeatCount="indefinite" begin={`${-o * dur}s`} path={d} />
        </circle>
      ))}
    </>
  );
}

Object.assign(window, { Canvas });
