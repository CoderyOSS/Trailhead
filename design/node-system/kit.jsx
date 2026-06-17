/* global React, Icon */
// ──────────────────────────────────────────────────────────────────────────
// Node-consistency exploration — shared kit + 5 direction renderers.
// Each direction proposes ONE visual grammar that the three node types
// (worker · branch operator · map) all obey, so they read as a family.
// Renders static specimens only; no interaction beyond the canvas wrapper.
// ──────────────────────────────────────────────────────────────────────────

const NS_MONO = "var(--co-font-mono)";
const NS_RAIL = "var(--co-success)";   // a "passed" rail, just to show the status-rail slot

// Small caption under each specimen.
function NSCaption({ children }) {
  return (
    <div style={{
      marginTop: 9, textAlign: "center",
      fontFamily: NS_MONO, fontSize: 10, letterSpacing: "0.05em",
      color: "var(--co-text-subtle)",
    }}>{children}</div>
  );
}

// A node + its caption, stacked.
function Spec({ caption, children }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", flex: "0 0 auto" }}>
      <div style={{ display: "flex", alignItems: "center", minHeight: 72 }}>{children}</div>
      <NSCaption>{caption}</NSCaption>
    </div>
  );
}

// The dark "canvas" panel the three specimens sit on.
function NSStage({ children }) {
  return (
    <div style={{
      position: "relative",
      display: "flex", alignItems: "center", justifyContent: "center", gap: 30,
      padding: "26px 18px",
      flexShrink: 0,
      borderRadius: 14,
      background: "var(--co-grad-hearth)",
      backgroundColor: "var(--co-bg-0)",
      border: "1px solid var(--co-border-1)",
      backgroundImage: "radial-gradient(circle, color-mix(in oklab, var(--co-border-2) 70%, transparent) 1px, transparent 1px)",
      backgroundSize: "26px 26px",
      backgroundPosition: "center",
      overflow: "hidden",
    }}>{children}</div>
  );
}

// One full board: heading + stage + rationale. Fixed height for the canvas.
function Board({ tag, name, tagline, rationale, move, render, h = 396 }) {
  return (
    <div style={{
      width: 700, height: h, boxSizing: "border-box",
      display: "flex", flexDirection: "column",
      padding: "20px 22px 22px",
      background: "var(--co-bg-1)",
      fontFamily: "var(--co-font-sans)",
    }}>
      <div style={{ display: "flex", alignItems: "baseline", gap: 10, marginBottom: 3 }}>
        <span style={{
          fontFamily: NS_MONO, fontSize: 11, fontWeight: 700,
          color: "var(--co-accent)", letterSpacing: "0.04em",
        }}>{tag}</span>
        <span style={{
          fontFamily: "var(--co-font-display)", fontSize: 21, fontWeight: 600,
          color: "var(--co-text-strong)", letterSpacing: "-0.02em",
        }}>{name}</span>
      </div>
      <div style={{ fontSize: 12.5, color: "var(--co-text-muted)", marginBottom: 14, lineHeight: 1.4 }}>{tagline}</div>

      <NSStage>{(render || boardNodes[tag])()}</NSStage>

      <div style={{ display: "flex", gap: 16, marginTop: 16, alignItems: "flex-start" }}>
        <div style={{ flex: 1, fontSize: 12, lineHeight: 1.55, color: "var(--co-text-muted)" }}>{rationale}</div>
        <div style={{
          flex: "0 0 188px",
          padding: "9px 11px", borderRadius: 9,
          background: "color-mix(in oklab, var(--co-accent) 9%, var(--co-bg-2))",
          border: "1px solid color-mix(in oklab, var(--co-accent) 26%, transparent)",
        }}>
          <div style={{ fontFamily: NS_MONO, fontSize: 8.5, letterSpacing: "0.1em", textTransform: "uppercase", color: "var(--co-accent)", marginBottom: 4, fontWeight: 600 }}>consistency move</div>
          <div style={{ fontSize: 11, lineHeight: 1.45, color: "var(--co-text)" }}>{move}</div>
        </div>
      </div>
    </div>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION A — Unified chassis
//  One shell, one header grammar (icon tile + kind label). All equal height.
// ══════════════════════════════════════════════════════════════════════════
function ChassisNode({ icon, kind, tile, rail, children }) {
  const tileBg = tile === "crust" ? "var(--co-grad-crust)" : "var(--co-bg-3)";
  const tileFg = tile === "crust" ? "var(--co-accent-ink)" : "var(--co-accent)";
  const tileBd = tile === "outline" ? "1px solid color-mix(in oklab, var(--co-accent) 45%, transparent)" : "1px solid transparent";
  return (
    <div style={{
      width: 178, height: 88, boxSizing: "border-box",
      borderRadius: 12, overflow: "hidden",
      background: "var(--co-grad-loaf)",
      border: "1px solid var(--co-border-2)",
      boxShadow: `inset 3px 0 0 ${rail}, var(--co-shadow-1)`,
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 8, padding: "10px 12px 0" }}>
        <span style={{ width: 22, height: 22, borderRadius: 6, display: "flex", alignItems: "center", justifyContent: "center", background: tileBg, border: tileBd, color: tileFg, flexShrink: 0 }}>
          <Icon name={icon} size={13} color="currentColor" />
        </span>
        <span style={{ fontFamily: NS_MONO, fontSize: 9, letterSpacing: "0.12em", textTransform: "uppercase", color: "var(--co-text-subtle)", fontWeight: 600 }}>{kind}</span>
      </div>
      <div style={{ padding: "7px 14px 14px" }}>{children}</div>
    </div>
  );
}
const nsBigLabel = { fontFamily: NS_MONO, fontSize: 14.5, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" };
const nsSubLabel = { fontFamily: NS_MONO, fontSize: 10, color: "var(--co-text-subtle)", marginTop: 2 };

function ChassisChip({ children, tone }) {
  return <span style={{
    display: "inline-flex", alignItems: "center", height: 16, padding: "0 7px", borderRadius: 999,
    background: tone === "accent" ? "color-mix(in oklab, var(--co-accent) 16%, transparent)" : "var(--co-bg-3)",
    border: "1px solid " + (tone === "accent" ? "color-mix(in oklab, var(--co-accent) 34%, transparent)" : "var(--co-border-2)"),
    color: tone === "accent" ? "var(--co-accent)" : "var(--co-text-muted)",
    fontFamily: NS_MONO, fontSize: 9, fontWeight: 600,
  }}>{children}</span>;
}

function DirA() {
  return (
    <>
      <Spec caption="worker">
        <ChassisNode icon="zap" kind="worker" tile="crust" rail={NS_RAIL}>
          <div style={nsBigLabel}>full-review</div>
          <div style={nsSubLabel}>sonnet-4.5 · 3 skills</div>
        </ChassisNode>
      </Spec>
      <Spec caption="branch">
        <ChassisNode icon="gitBranch" kind="branch" tile="outline" rail="var(--co-border-2)">
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ ...nsBigLabel, fontSize: 13 }}>risk == high</div>
          </div>
          <div style={{ marginTop: 5 }}><ChassisChip tone="accent">3 cases</ChassisChip></div>
        </ChassisNode>
      </Spec>
      <Spec caption="map">
        <ChassisNode icon="forEach" kind="map" tile="crust" rail="var(--co-border-2)">
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ ...nsBigLabel, flex: 1 }}>comment-file</div>
            <ChassisChip tone="accent">×7</ChassisChip>
          </div>
          <div style={nsSubLabel}>maps ingest.files</div>
        </ChassisNode>
      </Spec>
    </>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION B — Worker-card language (everyone is the flat pill)
// ══════════════════════════════════════════════════════════════════════════
function PillNode({ glyph, label, rail, badge }) {
  return (
    <div style={{
      width: 178, height: 34, boxSizing: "border-box",
      borderRadius: 9, display: "flex", alignItems: "center", gap: 8, padding: "0 10px",
      background: "var(--co-grad-loaf)",
      border: "1px solid var(--co-border-2)",
      boxShadow: `inset 3px 0 0 ${rail}, var(--co-shadow-1)`,
    }}>
      <Icon name={glyph} size={13} color="var(--co-accent)" />
      <span style={{ flex: 1, fontFamily: NS_MONO, fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{label}</span>
      {badge}
    </div>
  );
}
function PillBadge({ icon, children }) {
  return (
    <span style={{ display: "inline-flex", alignItems: "center", gap: 3, height: 17, padding: "0 6px", borderRadius: 999, background: "color-mix(in oklab, var(--co-accent) 15%, transparent)", border: "1px solid color-mix(in oklab, var(--co-accent) 32%, transparent)", color: "var(--co-accent)", fontFamily: NS_MONO, fontSize: 9, fontWeight: 700 }}>
      {icon && <Icon name={icon} size={9} color="currentColor" />}{children}
    </span>
  );
}
function DirB() {
  return (
    <>
      <Spec caption="worker">
        <PillNode glyph="zap" label="full-review" rail={NS_RAIL}
          badge={<span style={{ width: 7, height: 7, borderRadius: 999, background: "var(--co-accent)", boxShadow: "0 0 0 3px color-mix(in oklab, var(--co-accent) 20%, transparent)" }} />} />
      </Spec>
      <Spec caption="branch">
        <PillNode glyph="gitBranch" label="branch" rail="var(--co-border-2)" badge={<PillBadge>3</PillBadge>} />
      </Spec>
      <Spec caption="map">
        <PillNode glyph="forEach" label="comment-file" rail="var(--co-border-2)" badge={<PillBadge>×7</PillBadge>} />
      </Spec>
    </>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION C — Leading icon-tile rail (one recurring motif, varied heights)
// ══════════════════════════════════════════════════════════════════════════
function TileRailNode({ icon, tile, height, children }) {
  const tileBg = tile === "crust" ? "var(--co-grad-crust)" : "var(--co-bg-3)";
  const tileFg = tile === "crust" ? "var(--co-accent-ink)" : tile === "outline" ? "var(--co-accent)" : "var(--co-text-muted)";
  const tileBd = tile === "outline" ? "color-mix(in oklab, var(--co-accent) 45%, transparent)" : "var(--co-border-2)";
  return (
    <div style={{
      width: 184, height, boxSizing: "border-box",
      borderRadius: 12, overflow: "hidden", display: "flex",
      background: "var(--co-grad-loaf)",
      border: "1px solid var(--co-border-2)",
      boxShadow: "var(--co-shadow-1)",
    }}>
      <div style={{ width: 30, flexShrink: 0, display: "flex", alignItems: "center", justifyContent: "center", background: tileBg, borderRight: `1px solid ${tileBd}`, color: tileFg }}>
        <Icon name={icon} size={15} color="currentColor" />
      </div>
      <div style={{ flex: 1, minWidth: 0, padding: "0 11px", display: "flex", flexDirection: "column", justifyContent: "center" }}>{children}</div>
    </div>
  );
}
function DirC() {
  return (
    <>
      <Spec caption="worker">
        <TileRailNode icon="zap" tile="neutral" height={34}>
          <div style={nsBigLabel}>full-review</div>
        </TileRailNode>
      </Spec>
      <Spec caption="branch">
        <TileRailNode icon="gitBranch" tile="outline" height={34}>
          <div style={{ ...nsBigLabel, fontSize: 13 }}>branch</div>
          <div style={nsSubLabel}>risk == high · 3</div>
        </TileRailNode>
      </Spec>
      <Spec caption="map">
        <TileRailNode icon="forEach" tile="crust" height={60}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ ...nsBigLabel, flex: 1, fontSize: 13.5 }}>comment-file</div>
            <ChassisChip tone="accent">×7</ChassisChip>
          </div>
          <div style={nsSubLabel}>maps ingest.files · collect all</div>
        </TileRailNode>
      </Spec>
    </>
  );
}

// ══════════════════════════════════════════════════════════════════════════
//  DIRECTION D — Header strip for all (every node rhymes with the map)
// ══════════════════════════════════════════════════════════════════════════
function HeaderNode({ icon, kind, variant, height, children }) {
  // One neutral header for every role — golden/crust is reserved for the
  // selected state, so a resting node's header never reads as selected. Role
  // is carried by the icon + kind label, not the header color.
  const hdr = { bg: "var(--co-bg-3)", fg: "var(--co-text-muted)" };
  return (
    <div style={{
      width: 178, height, boxSizing: "border-box",
      borderRadius: 12, overflow: "hidden",
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-2)",
      boxShadow: "var(--co-shadow-1)",
    }}>
      <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: 24, background: hdr.bg, color: hdr.fg }}>
        <Icon name={icon} size={12} color="currentColor" />
        <span style={{ fontFamily: NS_MONO, fontSize: 10, fontWeight: 700, letterSpacing: "0.06em", textTransform: "uppercase" }}>{kind}</span>
      </div>
      <div style={{ padding: "8px 11px 10px" }}>{children}</div>
    </div>
  );
}
function DirD() {
  return (
    <>
      <Spec caption="worker">
        <HeaderNode icon="zap" kind="worker" variant="neutral" height={78}>
          <div style={nsBigLabel}>full-review</div>
          <div style={nsSubLabel}>sonnet-4.5</div>
        </HeaderNode>
      </Spec>
      <Spec caption="branch">
        <HeaderNode icon="gitBranch" kind="branch" variant="routing" height={78}>
          <div style={{ ...nsBigLabel, fontSize: 13 }}>risk == high</div>
          <div style={nsSubLabel}>3 cases · 1 default</div>
        </HeaderNode>
      </Spec>
      <Spec caption="map">
        <HeaderNode icon="forEach" kind="map" variant="crust" height={78}>
          <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
            <div style={{ ...nsBigLabel, flex: 1 }}>comment-file</div>
            <ChassisChip tone="accent">×7</ChassisChip>
          </div>
          <div style={nsSubLabel}>maps ingest.files</div>
        </HeaderNode>
      </Spec>
    </>
  );
}

const boardNodes = { A: DirA, B: DirB, C: DirC, D: DirD };

Object.assign(window, {
  Board, NSStage, Spec, NSCaption,
  // palettes + atoms reused by synthesis directions
  NS_MONO, NS_RAIL, nsBigLabel, nsSubLabel,
  ChassisChip,
  DirA, DirB, DirC, DirD,
});
