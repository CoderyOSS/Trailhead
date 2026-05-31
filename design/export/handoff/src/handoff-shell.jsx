/* global React, Icon */
const { useState: useStateHO } = React;

// ──────────────────────────────────────────────────────────────────────────
// Handoff doc shell — primitives shared between the scrollable doc and the
// component catalog deck. Both consume the same tokens.json values.
// ──────────────────────────────────────────────────────────────────────────

function H1({ children, eyebrow }) {
  return (
    <div style={{ marginBottom: 8 }}>
      {eyebrow && <div style={eyebrowStyle}>{eyebrow}</div>}
      <h1 style={{
        fontFamily: "var(--co-font-display)",
        fontSize: 32, fontWeight: 700,
        letterSpacing: "-0.02em",
        color: "var(--co-text-strong)",
        margin: 0, lineHeight: 1.1,
      }}>{children}</h1>
    </div>
  );
}

function H2({ children, id }) {
  return (
    <h2 id={id} style={{
      fontFamily: "var(--co-font-display)",
      fontSize: 24, fontWeight: 600,
      letterSpacing: "-0.015em",
      color: "var(--co-text-strong)",
      margin: "0 0 12px",
      lineHeight: 1.2,
      scrollMarginTop: 24,
    }}>{children}</h2>
  );
}

function H3({ children }) {
  return (
    <h3 style={{
      fontFamily: "var(--co-font-mono)",
      fontSize: 11, fontWeight: 600,
      letterSpacing: "0.08em", textTransform: "uppercase",
      color: "var(--co-accent)",
      margin: "0 0 10px",
    }}>{children}</h3>
  );
}

const eyebrowStyle = {
  fontFamily: "var(--co-font-mono)",
  fontSize: 11, fontWeight: 500,
  letterSpacing: "0.10em", textTransform: "uppercase",
  color: "var(--co-text-subtle)",
  marginBottom: 4,
};

function Section({ id, eyebrow, title, description, children }) {
  return (
    <section id={id} style={{
      maxWidth: 1180,
      margin: "0 auto",
      padding: "64px 32px 32px",
      scrollMarginTop: 0,
    }}>
      <div style={{ marginBottom: 28 }}>
        {eyebrow && <div style={eyebrowStyle}>{eyebrow}</div>}
        <h2 style={{
          fontFamily: "var(--co-font-display)",
          fontSize: 28, fontWeight: 600,
          letterSpacing: "-0.02em",
          color: "var(--co-text-strong)",
          margin: "0 0 8px",
          lineHeight: 1.1,
        }}>{title}</h2>
        {description && (
          <p style={{
            fontSize: 14, lineHeight: 1.55,
            color: "var(--co-text-muted)",
            maxWidth: 720,
            margin: 0,
          }}>{description}</p>
        )}
      </div>
      {children}
    </section>
  );
}

function Card({ title, description, dartImport, children, fullBleed, minHeight }) {
  const ref = useStateHO ? null : null;
  // Lazy-mount: only render the body once the card scrolls into view.
  // Prevents many heavy components from rendering on first paint, which can
  // create ResizeObserver feedback loops the browser flags.
  const [mounted, setMounted] = useStateHO(false);
  const wrapRef = React.useRef(null);
  React.useEffect(() => {
    if (mounted) return;
    if (!('IntersectionObserver' in window)) { setMounted(true); return; }
    const el = wrapRef.current;
    if (!el) return;
    const io = new IntersectionObserver((entries) => {
      for (const e of entries) {
        if (e.isIntersecting) { setMounted(true); io.disconnect(); break; }
      }
    }, { rootMargin: "200px 0px 200px 0px" });
    io.observe(el);
    return () => io.disconnect();
  }, [mounted]);

  return (
    <div ref={wrapRef} style={{
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 12,
      overflow: "hidden",
      marginBottom: 28,
      minHeight: minHeight ?? 220,
    }}>
      {(title || description) && (
        <div style={{
          padding: "14px 18px 12px",
          borderBottom: "1px solid var(--co-border-1)",
          background: "var(--co-bg-2)",
          display: "flex", alignItems: "flex-start", justifyContent: "space-between", gap: 16,
        }}>
          <div style={{ flex: 1, minWidth: 0 }}>
            {title && (
              <h3 style={{
                fontFamily: "var(--co-font-display)",
                fontSize: 17, fontWeight: 600,
                color: "var(--co-text-strong)",
                margin: 0, lineHeight: 1.2,
              }}>{title}</h3>
            )}
            {description && (
              <p style={{
                fontSize: 12.5, lineHeight: 1.5,
                color: "var(--co-text-muted)",
                margin: "4px 0 0",
              }}>{description}</p>
            )}
          </div>
          {dartImport && (
            <span style={{
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
              padding: "3px 7px",
              background: "var(--co-bg-3)",
              color: "var(--co-text-muted)",
              border: "1px solid var(--co-border-1)",
              borderRadius: 4,
              whiteSpace: "nowrap",
              flex: "0 0 auto",
            }}>{dartImport}</span>
          )}
        </div>
      )}
      <div style={{ padding: fullBleed ? 0 : 18 }}>
        {mounted ? children : (
          <div style={{
            padding: 32, textAlign: "center",
            color: "var(--co-text-subtle)", fontSize: 11,
            fontFamily: "var(--co-font-mono)",
          }}>loading…</div>
        )}
      </div>
    </div>
  );
}

// ── Stage — the canvas a component sits in for isolation viewing ─────────

function Stage({ children, label, bg, height, padding = 24 }) {
  return (
    <div style={{
      position: "relative",
      background: bg ?? "var(--co-bg-0)",
      backgroundImage: !bg ? `radial-gradient(circle, var(--co-border-1) 1px, transparent 1px)` : "none",
      backgroundSize: "16px 16px",
      border: "1px solid var(--co-border-1)",
      borderRadius: 10,
      padding,
      minHeight: height ?? 180,
      display: "flex", alignItems: "center", justifyContent: "center",
      overflow: "hidden",
    }}>
      {label && (
        <span style={{
          position: "absolute", top: 8, left: 10,
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          letterSpacing: "0.08em", textTransform: "uppercase",
          color: "var(--co-text-subtle)",
        }}>{label}</span>
      )}
      {children}
    </div>
  );
}

// ── Anatomy callouts ─────────────────────────────────────────────────────
// Wrap a Stage with <AnatomyOverlay items=[{x,y,label,desc,side}]>

function AnatomyOverlay({ items = [] }) {
  return (
    <>
      {items.map((it, i) => (
        <AnatomyMarker key={i} {...it} index={i + 1} />
      ))}
    </>
  );
}

function AnatomyMarker({ x, y, label, desc, side = "right", index }) {
  // x/y are percentages (0-100) of the stage area.
  // side: "right" | "left" | "top" | "bottom"
  const dist = 60;
  const lineLen = 24;
  const offsets = {
    right:  { lx: x + 0.2, ly: y, tx: x + dist/4, ty: y, tw: 200, align: "left" },
    left:   { lx: x - 0.2, ly: y, tx: x - dist/4, ty: y, tw: 200, align: "right" },
    top:    { lx: x, ly: y - 0.2, tx: x, ty: y - dist/3, tw: 160, align: "center" },
    bottom: { lx: x, ly: y + 0.2, tx: x, ty: y + dist/3, tw: 160, align: "center" },
  };
  const o = offsets[side] || offsets.right;
  return (
    <>
      {/* anchor dot */}
      <div style={{
        position: "absolute",
        left: `${x}%`, top: `${y}%`,
        transform: "translate(-50%, -50%)",
        width: 18, height: 18,
        borderRadius: 999,
        background: "var(--co-accent)",
        color: "var(--co-accent-ink)",
        display: "flex", alignItems: "center", justifyContent: "center",
        fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 700,
        boxShadow: "0 0 0 2px var(--co-bg-1), 0 0 0 3px var(--co-accent)",
        pointerEvents: "none",
        zIndex: 4,
      }}>{index}</div>
    </>
  );
}

// Legend list shown beside the stage; matches the index numbers.
function AnatomyLegend({ items }) {
  return (
    <ol style={{
      listStyle: "none", padding: 0, margin: 0,
      display: "flex", flexDirection: "column", gap: 10,
    }}>
      {items.map((it, i) => (
        <li key={i} style={{
          display: "grid",
          gridTemplateColumns: "20px 1fr",
          gap: 10,
          alignItems: "flex-start",
        }}>
          <span style={{
            width: 18, height: 18, borderRadius: 999,
            background: "var(--co-accent-soft)",
            color: "var(--co-accent)",
            border: "1px solid color-mix(in oklab, var(--co-accent) 35%, transparent)",
            display: "flex", alignItems: "center", justifyContent: "center",
            fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 600,
            marginTop: 1,
          }}>{i + 1}</span>
          <div style={{ lineHeight: 1.4 }}>
            <div style={{
              fontFamily: "var(--co-font-mono)", fontSize: 12,
              color: "var(--co-text-strong)", fontWeight: 500,
            }}>{it.label}</div>
            {it.desc && (
              <div style={{ fontSize: 11.5, color: "var(--co-text-muted)" }}>{it.desc}</div>
            )}
          </div>
        </li>
      ))}
    </ol>
  );
}

// ── States grid ──────────────────────────────────────────────────────────

function StatesGrid({ items, columns = 4 }) {
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: `repeat(${columns}, 1fr)`,
      gap: 1,
      background: "var(--co-border-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
      overflow: "hidden",
    }}>
      {items.map((it, i) => (
        <div key={i} style={{
          background: "var(--co-bg-1)",
          padding: 14,
          display: "flex", flexDirection: "column", gap: 10, alignItems: "flex-start",
          minHeight: 84,
        }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 9.5,
            letterSpacing: "0.08em", textTransform: "uppercase",
            color: "var(--co-text-subtle)", fontWeight: 500,
          }}>{it.label}</span>
          <div style={{ alignSelf: it.center ? "center" : "flex-start" }}>
            {it.children}
          </div>
        </div>
      ))}
    </div>
  );
}

// ── Tokens table — list of token-name + value used by a component ────────

function TokensList({ tokens }) {
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: "auto 1fr",
      gap: "0 12px",
      fontFamily: "var(--co-font-mono)", fontSize: 11.5,
      lineHeight: 1.8,
    }}>
      {tokens.map((t, i) => (
        <React.Fragment key={i}>
          <span style={{ color: "var(--co-accent)" }}>{t.name}</span>
          <span style={{ color: "var(--co-text-muted)" }}>{t.value}</span>
        </React.Fragment>
      ))}
    </div>
  );
}

// Two-column layout used inside cards: stage on the left, legend/tokens on right
function StageSplit({ left, right, leftFlex = 1.6 }) {
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: `${leftFlex}fr 1fr`,
      gap: 18,
      alignItems: "flex-start",
    }}>
      <div>{left}</div>
      <div style={{ paddingTop: 4 }}>{right}</div>
    </div>
  );
}

// Lists of subsections inside the same card body — keeps the visual rhythm tight.
function SubBlock({ label, children, last }) {
  return (
    <div style={{ marginBottom: last ? 0 : 22 }}>
      <H3>{label}</H3>
      {children}
    </div>
  );
}

// ── Layouts — table of contents + jump links ─────────────────────────────

function TOC({ sections, accentColor }) {
  return (
    <nav style={{
      position: "sticky", top: 16, alignSelf: "flex-start",
      width: 220, flex: "0 0 220px",
      display: "flex", flexDirection: "column", gap: 2,
      padding: "16px 0",
      fontFamily: "var(--co-font-sans)",
    }}>
      <div style={{ ...eyebrowStyle, marginBottom: 8, paddingLeft: 12 }}>contents</div>
      {sections.map(s => (
        <a key={s.id} href={`#${s.id}`} style={{
          fontFamily: "var(--co-font-mono)", fontSize: 12,
          padding: "5px 12px",
          color: "var(--co-text-muted)",
          textDecoration: "none",
          borderLeft: "2px solid transparent",
        }}
        onMouseEnter={(e) => { e.currentTarget.style.color = "var(--co-text-strong)"; e.currentTarget.style.borderLeftColor = "var(--co-border-3)"; }}
        onMouseLeave={(e) => { e.currentTarget.style.color = "var(--co-text-muted)"; e.currentTarget.style.borderLeftColor = "transparent"; }}
        >{s.label}</a>
      ))}
    </nav>
  );
}

// Theme switcher in the page header
function ThemeSwitcher({ theme, accent, onTheme, onAccent }) {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
      <Pills label="theme" value={theme} onChange={onTheme} options={[
        { v: "slate", l: "Slate" },
        { v: "paper", l: "Paper" },
      ]} />
      <Pills label="accent" value={accent} onChange={onAccent} options={[
        { v: "orange", l: "Orange" },
        { v: "green",  l: "Green" },
      ]} />
    </div>
  );
}

function Pills({ label, value, onChange, options }) {
  return (
    <div style={{
      display: "inline-flex", alignItems: "center",
      padding: 2,
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 6,
      gap: 0,
    }}>
      {options.map(o => {
        const active = o.v === value;
        return (
          <button key={o.v} type="button" onClick={() => onChange(o.v)} style={{
            padding: "4px 10px",
            fontSize: 11.5, fontWeight: 500, fontFamily: "var(--co-font-sans)",
            background: active ? "var(--co-bg-4)" : "transparent",
            color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
            border: "none", borderRadius: 4,
            cursor: "pointer",
          }}>{o.l}</button>
        );
      })}
    </div>
  );
}

Object.assign(window, {
  H1, H2, H3, Section, Card, Stage, AnatomyOverlay, AnatomyMarker, AnatomyLegend,
  StatesGrid, TokensList, StageSplit, SubBlock, TOC, ThemeSwitcher, Pills, eyebrowStyle,
});
