/* global React, Card, Stage, StatesGrid, TokensList, StageSplit, SubBlock, H3, AnatomyLegend */

// ──────────────────────────────────────────────────────────────────────────
// Tokens section — colors, typography, spacing, radii, shadows, motion.
// Every value here mirrors what's in handoff/tokens.json.
// ──────────────────────────────────────────────────────────────────────────

const PALETTE_SLATE = {
  bg: { "0":"#0c0d10","1":"#14161b","2":"#1a1d23","3":"#22262d","4":"#2b303a","5":"#353b46" },
  fg: { "0":"#f3f4f6","1":"#d8dade","2":"#a5a9b1","3":"#777b84","4":"#565a62","5":"#3d4148" },
  border: { "1":"#21242a","2":"#2e323a","3":"#40454f" },
  semantic: { success:"#6fbf73", warning:"#e6b341", danger:"#e26464", info:"#6ea8d9" },
};
const PALETTE_PAPER = {
  bg: { "0":"#f5f2ec","1":"#fdfbf6","2":"#f3efe6","3":"#e8e3d6","4":"#dcd6c4","5":"#c9c2ad" },
  fg: { "0":"#1a1814","1":"#3a352d","2":"#5d564a","3":"#837b6c","4":"#a8a193","5":"#c9c2ad" },
  border: { "1":"#ebe6d8","2":"#d8d2c0","3":"#b5ad96" },
  semantic: { success:"#5e8a3f", warning:"#b8780f", danger:"#b8331f", info:"#325f8a" },
};
const ACCENT_ORANGE_DARK = { "200":"#fac788","300":"#f4a955","400":"#e8923a","500":"#c66e1f","600":"#9c4f0e", accent:"#e8923a", ink:"#2d1810" };
const ACCENT_ORANGE_LIGHT = { "200":"#f0bd80","300":"#d68c3d","400":"#b86a1a","500":"#944f0c","600":"#6b3a08", accent:"#b86a1a", ink:"#ffffff" };
const ACCENT_GREEN_DARK = { "200":"#c4d49a","300":"#a4b475","400":"#7a8d4a","500":"#5e7340","600":"#455429", accent:"#7a8d4a", ink:"#fbf3e6" };
const ACCENT_GREEN_LIGHT = { "200":"#a4b475","300":"#7a8d4a","400":"#455429","500":"#34401e","600":"#253017", accent:"#455429", ink:"#ffffff" };

function Swatch({ name, value, dart, large }) {
  const ink = isLight(value) ? "#1a1814" : "#f3f4f6";
  return (
    <div style={{
      background: value,
      borderRadius: 8,
      border: "1px solid var(--co-border-1)",
      overflow: "hidden",
      minHeight: large ? 80 : 56,
      display: "flex", flexDirection: "column",
      justifyContent: "space-between",
      padding: 8,
      fontFamily: "var(--co-font-mono)",
      color: ink,
    }}>
      <div style={{ fontSize: 11, fontWeight: 600, opacity: 0.9 }}>{name}</div>
      <div style={{ display: "flex", justifyContent: "space-between", alignItems: "flex-end", gap: 8, fontSize: 10 }}>
        <span style={{ opacity: 0.85 }}>{value}</span>
        {dart && <span style={{ opacity: 0.65 }}>{dart}</span>}
      </div>
    </div>
  );
}

function isLight(hex) {
  // Naive — sums RGB and compares.
  const m = hex.match(/#?([0-9a-f]{2})([0-9a-f]{2})([0-9a-f]{2})/i);
  if (!m) return false;
  const [r, g, b] = [parseInt(m[1],16), parseInt(m[2],16), parseInt(m[3],16)];
  return (r * 0.299 + g * 0.587 + b * 0.114) > 165;
}

function SwatchGrid({ palette, prefix, dartPrefix }) {
  const entries = Object.entries(palette);
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: `repeat(${entries.length}, 1fr)`,
      gap: 8,
    }}>
      {entries.map(([k, v]) => (
        <Swatch
          key={k}
          name={`${prefix}.${k}`}
          value={v}
          dart={dartPrefix ? `${dartPrefix}${k}` : null}
        />
      ))}
    </div>
  );
}

function ThemeSwatches({ theme }) {
  const p = theme === "paper" ? PALETTE_PAPER : PALETTE_SLATE;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <SubBlock label="background — surface elevation (lightest → boldest)">
        <SwatchGrid palette={p.bg} prefix="bg" dartPrefix="palette.bg" />
      </SubBlock>
      <SubBlock label="foreground — text + icon strength (strongest → faintest)">
        <SwatchGrid palette={p.fg} prefix="fg" dartPrefix="palette.fg" />
      </SubBlock>
      <SubBlock label="border — divider, default, strong">
        <SwatchGrid palette={p.border} prefix="border" dartPrefix="palette.border" />
      </SubBlock>
      <SubBlock label="semantic">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(4, 1fr)", gap: 8 }}>
          {Object.entries(p.semantic).map(([k, v]) => (
            <Swatch key={k} name={`semantic.${k}`} value={v} dart={`palette.${k}`} />
          ))}
        </div>
      </SubBlock>
    </div>
  );
}

function AccentSwatches({ theme }) {
  const isDark = theme !== "paper";
  const orange = isDark ? ACCENT_ORANGE_DARK : ACCENT_ORANGE_LIGHT;
  const green  = isDark ? ACCENT_GREEN_DARK  : ACCENT_GREEN_LIGHT;
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 16 }}>
      <SubBlock label={`orange · ${isDark ? "on slate" : "on paper"} · AppAccents.orangeOn${isDark ? "Slate" : "Paper"}`}>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8 }}>
          {Object.entries(orange).filter(([k]) => k !== "ink").map(([k, v]) => (
            <Swatch key={k} name={`accent.${k}`} value={v} large />
          ))}
        </div>
      </SubBlock>
      <SubBlock label={`green · ${isDark ? "on slate" : "on paper"} · AppAccents.greenOn${isDark ? "Slate" : "Paper"}`} last>
        <div style={{ display: "grid", gridTemplateColumns: "repeat(5, 1fr)", gap: 8 }}>
          {Object.entries(green).filter(([k]) => k !== "ink").map(([k, v]) => (
            <Swatch key={k} name={`accent.${k}`} value={v} large />
          ))}
        </div>
      </SubBlock>
    </div>
  );
}

// ── Type scale ───────────────────────────────────────────────────────────

const TYPE_SCALE = [
  { name: "5xl", px: 52, role: "displayLarge",  family: "display", weight: 700 },
  { name: "4xl", px: 38, role: "—",             family: "display", weight: 700 },
  { name: "3xl", px: 30, role: "displayMedium", family: "display", weight: 600 },
  { name: "2xl", px: 24, role: "displaySmall",  family: "display", weight: 600 },
  { name: "xl",  px: 20, role: "headlineMedium", family: "display", weight: 600 },
  { name: "lg",  px: 17, role: "titleLarge",    family: "sans",    weight: 600 },
  { name: "md",  px: 15, role: "titleMedium",   family: "sans",    weight: 600 },
  { name: "base",px: 14, role: "bodyLarge",     family: "sans",    weight: 400 },
  { name: "sm",  px: 13, role: "bodyMedium / labelLarge", family: "sans", weight: 400 },
  { name: "xs",  px: 12, role: "bodySmall / labelMedium", family: "sans", weight: 400 },
  { name: "2xs", px: 11, role: "—",             family: "mono",    weight: 500 },
  { name: "3xs", px: 10, role: "labelSmall (caps)", family: "mono", weight: 500 },
];

function TypeScale() {
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: "auto auto auto 1fr",
      gap: "0 18px",
      alignItems: "baseline",
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
      padding: "12px 18px",
    }}>
      {TYPE_SCALE.map(t => (
        <React.Fragment key={t.name}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11,
            color: "var(--co-accent)", paddingTop: 6,
          }}>{t.name}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11,
            color: "var(--co-text-muted)",
            fontVariantNumeric: "tabular-nums", paddingTop: 6,
          }}>{t.px}px</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)", paddingTop: 7,
          }}>{t.role}</span>
          <span style={{
            fontFamily: t.family === "display" ? "var(--co-font-display)" : t.family === "mono" ? "var(--co-font-mono)" : "var(--co-font-sans)",
            fontSize: t.px,
            fontWeight: t.weight,
            color: "var(--co-text-strong)",
            letterSpacing: t.px > 26 ? "-0.02em" : t.px > 18 ? "-0.01em" : "0",
            lineHeight: 1.1,
            paddingTop: 8, paddingBottom: 8,
          }}>The quick brown fox</span>
        </React.Fragment>
      ))}
    </div>
  );
}

function TypeFamilies() {
  const rows = [
    { label: "display", value: "Bricolage Grotesque", use: "headers, hero copy", css: "var(--co-font-display)" },
    { label: "sans",    value: "Plus Jakarta Sans",   use: "body, labels, buttons", css: "var(--co-font-sans)" },
    { label: "mono",    value: "JetBrains Mono",      use: "ids, code, eyebrows, stats", css: "var(--co-font-mono)" },
  ];
  return (
    <div style={{
      display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 12,
    }}>
      {rows.map(r => (
        <div key={r.label} style={{
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          padding: "14px 14px 16px",
        }}>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 9.5,
            letterSpacing: "0.08em", textTransform: "uppercase",
            color: "var(--co-text-subtle)", fontWeight: 500,
          }}>{r.label}</div>
          <div style={{
            fontFamily: r.css, fontSize: 22,
            color: "var(--co-text-strong)",
            margin: "6px 0 6px",
            lineHeight: 1.1,
          }}>{r.value}</div>
          <div style={{ fontSize: 11.5, color: "var(--co-text-muted)" }}>{r.use}</div>
        </div>
      ))}
    </div>
  );
}

// ── Spacing ──────────────────────────────────────────────────────────────

const SPACING = [
  { name: "s1",  px: 2 },
  { name: "s2",  px: 4 },
  { name: "s3",  px: 6 },
  { name: "s4",  px: 8 },
  { name: "s5",  px: 12 },
  { name: "s6",  px: 16 },
  { name: "s7",  px: 20 },
  { name: "s8",  px: 24 },
  { name: "s9",  px: 32 },
  { name: "s10", px: 40 },
  { name: "s11", px: 48 },
  { name: "s12", px: 64 },
];

function SpacingScale() {
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: "1fr 1fr",
      gap: 24,
    }}>
      <div>
        <H3>scale · 4px base</H3>
        <div style={{
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          padding: 14,
          display: "flex", flexDirection: "column", gap: 6,
        }}>
          {SPACING.map(s => (
            <div key={s.name} style={{
              display: "grid",
              gridTemplateColumns: "60px 50px 1fr",
              alignItems: "center",
              gap: 10,
              fontFamily: "var(--co-font-mono)", fontSize: 11,
            }}>
              <span style={{ color: "var(--co-accent)" }}>AppSpacing.{s.name}</span>
              <span style={{ color: "var(--co-text-muted)", fontVariantNumeric: "tabular-nums" }}>{s.px}px</span>
              <span style={{
                display: "inline-block",
                width: s.px, height: 10,
                background: "var(--co-accent)",
                borderRadius: 2,
              }} />
            </div>
          ))}
        </div>
      </div>
      <div>
        <H3>radii</H3>
        <div style={{
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          padding: 14,
          display: "grid",
          gridTemplateColumns: "repeat(4, 1fr)",
          gap: 12,
        }}>
          {[
            { name: "xs", px: 4 },
            { name: "sm", px: 6 },
            { name: "md", px: 10 },
            { name: "lg", px: 14 },
            { name: "xl", px: 20 },
            { name: "2xl",px: 28 },
            { name: "pill",px: 999 },
          ].map(r => (
            <div key={r.name} style={{ display: "flex", flexDirection: "column", gap: 4, alignItems: "center" }}>
              <div style={{
                width: 56, height: 36,
                background: "var(--co-bg-3)",
                border: "1px solid var(--co-border-2)",
                borderRadius: r.px,
              }} />
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-accent)" }}>{r.name}</span>
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>{r.px}px</span>
            </div>
          ))}
        </div>

        <H3>elevation · shadow</H3>
        <div style={{
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          padding: 24,
          display: "grid",
          gridTemplateColumns: "repeat(3, 1fr)",
          gap: 18,
        }}>
          {["1", "2", "3"].map(n => (
            <div key={n} style={{
              height: 60,
              background: "var(--co-bg-3)",
              borderRadius: 8,
              boxShadow: n === "1" ? "var(--co-shadow-1)" : n === "2" ? "var(--co-shadow-2)" : "var(--co-shadow-3)",
              display: "flex", alignItems: "center", justifyContent: "center",
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
              color: "var(--co-text-muted)",
            }}>shadow.{n}</div>
          ))}
        </div>
      </div>
    </div>
  );
}

// ── Motion ───────────────────────────────────────────────────────────────

function MotionTokens() {
  return (
    <div style={{
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
      padding: 16,
    }}>
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 24,
      }}>
        <div>
          <H3>duration</H3>
          <TokensList tokens={[
            { name: "instant", value: "80ms · AppMotion.instant" },
            { name: "fast",    value: "160ms · AppMotion.fast" },
            { name: "base",    value: "240ms · AppMotion.base — default for drawers, dropdowns" },
            { name: "slow",    value: "380ms · AppMotion.slow — page transitions" },
          ]} />
        </div>
        <div>
          <H3>easing</H3>
          <TokensList tokens={[
            { name: "easeOut",   value: "cubic(0.2, 0.8, 0.2, 1) · default" },
            { name: "easeInOut", value: "cubic(0.4, 0, 0.2, 1) · symmetric" },
            { name: "easeSnap",  value: "cubic(0.32, 0.72, 0, 1) · controls / clicks" },
            { name: "easeSoft",  value: "cubic(0.34, 1.1, 0.64, 1) · soft overshoot" },
          ]} />
        </div>
      </div>
    </div>
  );
}

// ──────────────────────────────────────────────────────────────────────────

function TokensSection({ theme }) {
  return (
    <>
      <Card title="Theme palette" description={`The active surface set. ${theme === "paper" ? "Paper" : "Slate"} is shown — toggle in the header.`} dartImport="AppPalettes.slate · AppPalettes.paper">
        <ThemeSwatches theme={theme} />
      </Card>

      <Card title="Accent palette" description="Orthogonal axis. Both accents work in both themes — orange is the default; green is the secondary brand option.">
        <AccentSwatches theme={theme} />
      </Card>

      <Card title="Typography" description="Three families. The display face only appears on H1-H3; everything else is sans or mono.">
        <SubBlock label="families">
          <TypeFamilies />
        </SubBlock>
        <SubBlock label="scale" last>
          <TypeScale />
        </SubBlock>
      </Card>

      <Card title="Spacing, radii, elevation" description="4px-based scale. Component cards reference these by name (s4, md, etc) — don't hand-pick pixel values.">
        <SpacingScale />
      </Card>

      <Card title="Motion" description="Durations + easings shared across the system. Drawer slides use base/easeOut; status pulse uses fast/easeInOut.">
        <MotionTokens />
      </Card>
    </>
  );
}

Object.assign(window, { TokensSection });
