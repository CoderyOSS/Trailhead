/* global React, Icon, StatusDot */
const { useState: useStateFS, useRef: useRefFS, useEffect: useEffectFS } = React;

// ──────────────────────────────────────────────────────────────────────────
// Snapshot filmstrip — bottom panel during a job view.
//
// Each snapshot is one stage's execution: what came in, what came out,
// duration, tokens, tools called, and the error if it failed. The card
// shows those directly — no abstract pipeline thumbnails.
// ──────────────────────────────────────────────────────────────────────────

const CARD_W = 268;

function pretty(value) {
  if (value == null) return "—";
  if (typeof value === "string") return value;
  if (typeof value === "number") return value.toLocaleString();
  if (typeof value === "boolean") return value ? "true" : "false";
  if (Array.isArray(value)) return value.join(", ");
  // object
  return Object.entries(value)
    .map(([k, v]) => {
      const sv = Array.isArray(v) ? `[${v.length}]` : typeof v === "object" ? "{…}" : pretty(v);
      return `${k}: ${sv}`;
    })
    .join("  ·  ");
}

function fmtDur(ms) {
  if (ms == null) return "—";
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60_000) return `${(ms / 1000).toFixed(ms < 10_000 ? 2 : 1)}s`;
  const m = Math.floor(ms / 60_000);
  const s = Math.floor((ms % 60_000) / 1000);
  return `${m}m${String(s).padStart(2, "0")}s`;
}

function fmtTokens(n) {
  if (!n) return "0";
  if (n < 1000) return String(n);
  return `${(n / 1000).toFixed(n < 10_000 ? 2 : 1)}k`;
}

const STATUS_META = {
  passed:    { color: "var(--co-success)", bg: "var(--co-success-soft)", label: "passed" },
  failed:    { color: "var(--co-danger)",  bg: "var(--co-danger-soft)",  label: "failed" },
  running:   { color: "var(--co-accent)",  bg: "var(--co-accent-soft)",  label: "running" },
  retrying:  { color: "var(--co-warning)", bg: "var(--co-warning-soft)", label: "retrying" },
  cancelled: { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)",         label: "cancelled" },
};

function StatusPip({ status }) {
  const m = STATUS_META[status] || STATUS_META.cancelled;
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 600,
      padding: "1px 6px",
      borderRadius: 3,
      background: m.bg,
      color: m.color,
      letterSpacing: "0.04em",
      textTransform: "uppercase",
    }}>
      <span style={{
        width: 5, height: 5, borderRadius: 999,
        background: m.color,
        animation: status === "running" ? "co-pulse 1.4s ease-in-out infinite" : "none",
      }} />
      {m.label}
    </span>
  );
}

function KindBadge({ kind }) {
  if (kind === "live") {
    return (
      <span style={{
        display: "inline-flex", alignItems: "center", gap: 3,
        fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600,
        padding: "1px 5px",
        borderRadius: 3,
        border: "1px solid var(--co-accent)",
        color: "var(--co-accent)",
        letterSpacing: "0.06em", textTransform: "uppercase",
      }}>live</span>
    );
  }
  if (kind === "manual") {
    return (
      <span title="manual snapshot" style={{ color: "var(--co-accent)", display: "inline-flex", alignItems: "center" }}>
        <Icon name="bookmark" size={11} color="currentColor" />
      </span>
    );
  }
  return null;
}

// ──────────────────────────────────────────────────────────────────────────

function ToolList({ tools }) {
  if (!tools?.length) {
    return <span style={{ color: "var(--co-text-subtle)", fontFamily: "var(--co-font-mono)", fontSize: 10 }}>no tools</span>;
  }
  return (
    <div style={{ display: "flex", flexWrap: "wrap", gap: 3 }}>
      {tools.slice(0, 3).map(tool => (
        <span key={tool} style={{
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          padding: "1px 5px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 3,
          color: "var(--co-text-muted)",
          whiteSpace: "nowrap",
        }}>{tool}</span>
      ))}
      {tools.length > 3 && (
        <span style={{
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          color: "var(--co-text-subtle)",
          padding: "1px 2px",
        }}>+{tools.length - 3}</span>
      )}
    </div>
  );
}

function ErrorBlock({ error }) {
  return (
    <div style={{
      padding: "6px 8px",
      background: "var(--co-danger-soft)",
      border: "1px solid color-mix(in oklab, var(--co-danger) 30%, transparent)",
      borderRadius: 5,
      fontFamily: "var(--co-font-mono)", fontSize: 10.5,
      lineHeight: 1.4,
      color: "var(--co-text)",
      minHeight: 56,
    }}>
      <div style={{
        color: "var(--co-danger)",
        fontWeight: 600,
        fontSize: 10,
        letterSpacing: "0.04em",
        textTransform: "uppercase",
        marginBottom: 2,
      }}>{error.code}</div>
      <div style={{
        color: "var(--co-text)",
        display: "-webkit-box",
        WebkitLineClamp: 2,
        WebkitBoxOrient: "vertical",
        overflow: "hidden",
      }}>{error.message}</div>
    </div>
  );
}

function StreamingBlock({ streaming, progress }) {
  return (
    <div style={{
      padding: "6px 8px",
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-accent)",
      borderRadius: 5,
      fontFamily: "var(--co-font-mono)", fontSize: 10.5,
      lineHeight: 1.4,
      color: "var(--co-text)",
      minHeight: 56,
      display: "flex", flexDirection: "column", gap: 4,
    }}>
      <div style={{
        display: "-webkit-box",
        WebkitLineClamp: 2,
        WebkitBoxOrient: "vertical",
        overflow: "hidden",
        flex: 1,
      }}>
        <span style={{ animation: "co-blink 1.2s linear infinite", color: "var(--co-accent)", marginRight: 4 }}>▸</span>
        {streaming}
      </div>
      {progress != null && (
        <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
          <div style={{ flex: 1, height: 3, background: "var(--co-bg-3)", borderRadius: 2, overflow: "hidden" }}>
            <div style={{
              width: `${progress * 100}%`, height: "100%",
              background: "var(--co-accent)",
            }} />
          </div>
          <span style={{ fontSize: 9.5, color: "var(--co-text-muted)", fontVariantNumeric: "tabular-nums" }}>
            {Math.round(progress * 100)}%
          </span>
        </div>
      )}
    </div>
  );
}

function ResultBlock({ result }) {
  return (
    <div style={{
      padding: "6px 8px",
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 5,
      fontFamily: "var(--co-font-mono)", fontSize: 10.5,
      lineHeight: 1.45,
      color: "var(--co-text)",
      minHeight: 56,
      display: "-webkit-box",
      WebkitLineClamp: 3,
      WebkitBoxOrient: "vertical",
      overflow: "hidden",
      wordBreak: "break-word",
    }}>
      {pretty(result)}
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────

function SnapshotCard({ snap, active, onClick }) {
  return (
    <button
      type="button"
      onClick={onClick}
      style={{
        flex: `0 0 ${CARD_W}px`,
        display: "flex", flexDirection: "column",
        gap: 6,
        background: active ? "var(--co-bg-3)" : "var(--co-bg-2)",
        border: `1px solid ${active ? "var(--co-accent)" : "var(--co-border-1)"}`,
        borderRadius: 8,
        padding: "8px 10px 10px",
        cursor: "pointer",
        textAlign: "left",
        boxShadow: active ? "0 0 0 3px color-mix(in oklab, var(--co-accent) 18%, transparent)" : "none",
        transition: "border-color 140ms, box-shadow 140ms",
        position: "relative",
      }}
    >
      {/* Header row — stage name + time, then status + kind */}
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 8 }}>
        <div style={{ minWidth: 0, flex: 1, display: "flex", flexDirection: "column", lineHeight: 1.2 }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            color: "var(--co-text-strong)", fontWeight: 600,
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          }}>{snap.stageLabel}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 9.5,
            color: "var(--co-text-subtle)",
            fontVariantNumeric: "tabular-nums",
            marginTop: 1,
          }}>{snap.at}</span>
        </div>
        <div style={{ display: "inline-flex", alignItems: "center", gap: 5, flex: "0 0 auto" }}>
          <KindBadge kind={snap.kind} />
          <StatusPip status={snap.status} />
        </div>
      </div>

      {/* Stats row */}
      <div style={{
        display: "grid",
        gridTemplateColumns: "auto auto 1fr",
        gap: 8,
        alignItems: "center",
        padding: "4px 0",
        borderTop: "1px solid var(--co-border-1)",
        borderBottom: "1px solid var(--co-border-1)",
      }}>
        <StatChip icon="clock" value={fmtDur(snap.durMs)} title="duration" />
        <StatChip value={`${fmtTokens(snap.tokens)} tok`} title="tokens used" />
        <ToolList tools={snap.tools} />
      </div>

      {/* Result / Error / Streaming */}
      {snap.status === "failed" && snap.error
        ? <ErrorBlock error={snap.error} />
        : snap.status === "running"
        ? <StreamingBlock streaming={snap.streaming} progress={snap.progress} />
        : <ResultBlock result={snap.result} />}

      {/* Manual note */}
      {snap.note && (
        <div style={{
          fontSize: 10,
          color: "var(--co-accent)",
          fontStyle: "italic",
          display: "flex", alignItems: "center", gap: 4,
          padding: "2px 0 0",
        }}>
          <Icon name="bookmark" size={9} color="currentColor" />
          <span style={{
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            minWidth: 0, flex: 1,
          }}>{snap.note}</span>
        </div>
      )}
    </button>
  );
}

function StatChip({ icon, value, title }) {
  return (
    <span title={title} style={{
      display: "inline-flex", alignItems: "center", gap: 3,
      fontFamily: "var(--co-font-mono)", fontSize: 10,
      color: "var(--co-text-muted)",
      fontVariantNumeric: "tabular-nums",
      whiteSpace: "nowrap",
    }}>
      {icon && <Icon name={icon} size={10} color="currentColor" />}
      {value}
    </span>
  );
}

// ──────────────────────────────────────────────────────────────────────────

function Filmstrip({ snapshots, activeId, onPick }) {
  const scrollRef = useRefFS(null);

  // Scroll the active card into view when activeId changes
  useEffectFS(() => {
    if (!scrollRef.current) return;
    const el = scrollRef.current.querySelector(`[data-snap-id="${activeId}"]`);
    if (el) el.scrollIntoView({ block: "nearest", inline: "nearest", behavior: "smooth" });
  }, [activeId]);

  return (
    <div style={{
      flex: "0 0 auto",
      borderTop: "1px solid var(--co-border-1)",
      background: "var(--co-bg-1)",
      padding: "8px 14px 10px",
      display: "flex", flexDirection: "column", gap: 6,
      zIndex: 5,
    }}>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", gap: 10 }}>
        <div style={{ display: "flex", alignItems: "baseline", gap: 10, minWidth: 0, overflow: "hidden" }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            letterSpacing: "0.08em", textTransform: "uppercase",
            color: "var(--co-text-subtle)", fontWeight: 500,
            whiteSpace: "nowrap",
            flex: "0 0 auto",
          }}>snapshots · {snapshots.length}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          }}>per-stage · resume or rerun from any point</span>
        </div>
      </div>
      <div ref={scrollRef} style={{
        display: "flex", gap: 8, overflowX: "auto",
        paddingBottom: 2,
        scrollSnapType: "x proximity",
      }}>
        {snapshots.map(s => (
          <div key={s.id} data-snap-id={s.id} style={{ scrollSnapAlign: "start" }}>
            <SnapshotCard snap={s} active={s.id === activeId} onClick={() => onPick(s.id)} />
          </div>
        ))}
      </div>
    </div>
  );
}

Object.assign(window, { Filmstrip });
