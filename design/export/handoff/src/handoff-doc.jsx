/* global React, ReactDOM, Section, H1, TOC, ThemeSwitcher, TokensSection, ComponentsSection, LayoutsSection */

const { useState: useStateDoc, useEffect: useEffectDoc } = React;

// ──────────────────────────────────────────────────────────────────────────
// Handoff doc root — the scrollable HTML reference. Mounts the tokens,
// components, and layouts sections inside a fixed-width container, with
// a sticky table of contents on the left and a theme/accent switcher in
// the page header.
// ──────────────────────────────────────────────────────────────────────────

const SECTIONS = [
  { id: "intro",      label: "Introduction" },
  { id: "tokens",     label: "Design tokens" },
  { id: "components", label: "Components" },
  { id: "layouts",    label: "Layouts" },
  { id: "delivery",   label: "Delivery files" },
];

function HandoffDoc() {
  const [theme, setTheme]   = useStateDoc("slate");
  const [accent, setAccent] = useStateDoc("orange");

  useEffectDoc(() => {
    document.documentElement.dataset.themeVariant = theme;
    document.documentElement.dataset.theme  = theme === "paper" ? "light" : "dark";
    document.documentElement.dataset.accent = accent;
  }, [theme, accent]);

  return (
    <div style={{
      background: "var(--co-bg-0)",
      color: "var(--co-text)",
      fontFamily: "var(--co-font-sans)",
      minHeight: "100vh",
    }}>
      {/* page header */}
      <header style={{
        position: "sticky", top: 0, zIndex: 50,
        background: "color-mix(in oklab, var(--co-bg-0) 90%, transparent)",
        backdropFilter: "blur(10px)",
        borderBottom: "1px solid var(--co-border-1)",
      }}>
        <div style={{
          maxWidth: 1400, margin: "0 auto",
          padding: "14px 32px",
          display: "flex", alignItems: "center", justifyContent: "space-between", gap: 24,
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
            <img src="assets/trailhead-logo.svg" alt="" width="32" height="32" />
            <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.15 }}>
              <span style={{
                fontFamily: "var(--co-font-display)", fontSize: 16, fontWeight: 700,
                letterSpacing: "-0.01em",
                color: "var(--co-text-strong)",
              }}>Trailhead · Flutter handoff</span>
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 10.5,
                color: "var(--co-text-subtle)",
              }}>workflow manager · v0.42</span>
            </div>
          </div>
          <ThemeSwitcher
            theme={theme} accent={accent}
            onTheme={setTheme} onAccent={setAccent}
          />
        </div>
      </header>

      {/* body */}
      <div style={{
        maxWidth: 1400, margin: "0 auto",
        display: "flex", alignItems: "flex-start",
      }}>
        <TOC sections={SECTIONS} />

        <div style={{ flex: 1, minWidth: 0 }}>
          {/* Intro */}
          <Section
            id="intro"
            eyebrow="overview"
            title="Implementation reference for the workflow manager UI"
            description="This document is the source for building the workflow + job UI in Flutter. Read the tokens first, then the components in any order. Each component card shows the rendered visual, an anatomy legend, all states, and the design tokens it consumes. Layouts at the bottom show the full-screen compositions."
          >
            <div style={{ display: "flex", flexWrap: "wrap", gap: 12 }}>
              <DeliveryPill icon="file" name="tokens.json"   note="source of truth" />
              <DeliveryPill icon="file" name="tokens.dart"   note="typed Dart mirror — constants" />
              <DeliveryPill icon="file" name="app_theme.dart" note="M3 ThemeData + AppTokens extension" />
              <DeliveryPill icon="file" name="README.md"     note="how to wire it up" />
            </div>
          </Section>

          {/* Tokens */}
          <Section
            id="tokens"
            eyebrow="01 · foundation"
            title="Design tokens"
            description="The atomic system the UI is built from. Theme palette + accent palette + primitives. Slate is the default surface; Paper is the light alternate. Orange is the default accent; Green is the secondary brand option. The Flutter constants are in lib/theme/tokens.dart."
          >
            <TokensSection theme={theme} />
          </Section>

          {/* Components */}
          <Section
            id="components"
            eyebrow="02 · catalog"
            title="Components"
            description="Each card is one component, rendered in isolation. Anatomy lists name each part the agent needs to build; tokens list the values consumed. Sizes are component-level tokens (CompButton.smMin, CompDrawer.width, etc) — not pixel values."
          >
            <ComponentsSection />
          </Section>

          {/* Layouts */}
          <Section
            id="layouts"
            eyebrow="03 · compositions"
            title="Layouts"
            description="Four full-screen layouts the components compose into. Each one includes the widget-tree hint so the Flutter agent doesn't have to derive the Row/Column structure from screenshots."
          >
            <LayoutsSection />
          </Section>

          {/* Delivery */}
          <Section
            id="delivery"
            eyebrow="04 · files"
            title="Delivery files"
            description="The four files below are everything you need to begin. See README.md for wiring instructions."
          >
            <DeliveryList />
          </Section>

          <footer style={{
            maxWidth: 1180, margin: "0 auto",
            padding: "48px 32px 96px",
            color: "var(--co-text-subtle)",
            fontFamily: "var(--co-font-mono)", fontSize: 11,
            textAlign: "center",
          }}>
            end of handoff · Trailhead workflow manager · v0.42
          </footer>
        </div>
      </div>
    </div>
  );
}

function DeliveryPill({ icon, name, note }) {
  return (
    <div style={{
      display: "flex", alignItems: "center", gap: 8,
      padding: "8px 12px",
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
    }}>
      <window.Icon name={icon} size={12} color="var(--co-accent)" />
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text-strong)" }}>{name}</span>
      <span style={{ fontSize: 11, color: "var(--co-text-subtle)" }}>· {note}</span>
    </div>
  );
}

function DeliveryList() {
  const rows = [
    { name: "handoff/tokens.json",       desc: "Source of truth. Themes (slate, paper) × accents (orange, green) + primitives + component tokens.", lang: "JSON" },
    { name: "handoff/lib/theme/tokens.dart",   desc: "Typed Dart constants — AppSpacing, AppRadius, AppType, AppMotion, AppPalettes, AppAccents, plus per-component sizes (CompButton, CompDrawer, etc).", lang: "Dart" },
    { name: "handoff/lib/theme/app_theme.dart", desc: "Material 3 ThemeData builder + AppTokens ThemeExtension. Call appTheme(palette:, accent:) from MaterialApp.theme.", lang: "Dart" },
    { name: "handoff/README.md",         desc: "Wiring instructions, theme combinations table, agent guidance.", lang: "Markdown" },
  ];
  return (
    <div style={{
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 10,
      overflow: "hidden",
    }}>
      {rows.map((r, i) => (
        <div key={i} style={{
          padding: "14px 18px",
          borderBottom: i === rows.length - 1 ? "none" : "1px solid var(--co-border-1)",
          display: "grid",
          gridTemplateColumns: "auto 1fr auto",
          alignItems: "center", gap: 14,
        }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 12.5,
            color: "var(--co-text-strong)", fontWeight: 500,
          }}>{r.name}</span>
          <span style={{ fontSize: 12.5, color: "var(--co-text-muted)" }}>{r.desc}</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            padding: "2px 7px",
            background: "var(--co-bg-3)",
            border: "1px solid var(--co-border-1)",
            borderRadius: 3,
            color: "var(--co-text-subtle)",
          }}>{r.lang}</span>
        </div>
      ))}
    </div>
  );
}

ReactDOM.createRoot(document.getElementById("root")).render(<HandoffDoc />);
