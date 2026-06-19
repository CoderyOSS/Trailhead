/* global React, Icon, IconButton */
const { useState: useStateSM, useEffect: useEffectSM, useRef: useRefSM } = React;

// Hide the compact tab-strip's scrollbar (it stays scrollable for long labels).
if (typeof document !== "undefined" && !document.getElementById("sm-tabstrip-style")) {
  const _smStyle = document.createElement("style");
  _smStyle.id = "sm-tabstrip-style";
  _smStyle.textContent = ".sm-tabstrip::-webkit-scrollbar{display:none}";
  document.head.appendChild(_smStyle);
}

// ──────────────────────────────────────────────────────────────────────────
// SettingsModal — app-level preferences, opened by the gear in the mode rail.
//
// It writes straight into the same tweak store the rest of the app reads from
// (theme / accent / canvasStyle / …), so a change here persists and is
// reflected everywhere immediately. The Tweaks panel and this modal are two
// front-doors onto one source of truth.
//
// THEMES is a registry, not a hardcoded switch. Adding a palette = one entry
// here + one block in themes.css. The chooser, swatches and dark/light
// derivation all read from this array, so the picker scales with no new UI.
// ──────────────────────────────────────────────────────────────────────────

const THEMES = [
  { value: "hearth",    name: "Hearth",    desc: "Warm cocoa — the original.", mode: "dark",
    swatch: ["#160d07", "#281a10", "#422c1a", "#e8923a"] },
  { value: "slate",     name: "Slate",     desc: "Neutral, near-black greys.",  mode: "dark",
    swatch: ["#0c0d10", "#1a1d23", "#2b303a", "#6ea8d9"] },
  { value: "trailhead", name: "Trailhead", desc: "Deep forest, mossy canvas.",  mode: "dark",
    swatch: ["#0a120c", "#142319", "#253a2c", "#a4c97a"] },
  { value: "paper",     name: "Paper",     desc: "Light mode, ink on cream.",   mode: "light",
    swatch: ["#f5f2ec", "#e8e3d6", "#c9c2ad", "#b86a1a"] },
];

const ACCENTS = [
  { value: "orange", name: "Orange", grad: "linear-gradient(135deg,#f4a955 0%,#e8923a 50%,#c66e1f 100%)" },
  { value: "green",  name: "Green",  grad: "linear-gradient(135deg,#c4d49a 0%,#7a8d4a 55%,#5e7340 100%)" },
];

// Layout glyphs for the default-view chooser.
function LayoutGlyph({ kind, color }) {
  const c = color, s = { fill: "none", stroke: c, strokeWidth: 1.6, strokeLinecap: "round", strokeLinejoin: "round" };
  if (kind === "graph") return (
    <svg width="22" height="22" viewBox="0 0 24 24">
      <circle cx="5" cy="12" r="2.2" {...s} />
      <circle cx="13" cy="6" r="2.2" {...s} />
      <circle cx="13" cy="18" r="2.2" {...s} />
      <circle cx="20" cy="12" r="2.2" {...s} />
      <path d="M7 11 11 7M7 13l4 4M15 7l4 4M15 17l4-4" {...s} />
    </svg>
  );
  if (kind === "tree") return (
    <svg width="22" height="22" viewBox="0 0 24 24">
      <rect x="9" y="3" width="6" height="4" rx="1" {...s} />
      <rect x="3" y="17" width="6" height="4" rx="1" {...s} />
      <rect x="15" y="17" width="6" height="4" rx="1" {...s} />
      <path d="M12 7v4M6 17v-3h12v3M12 11v3" {...s} />
    </svg>
  );
  return ( // lanes
    <svg width="22" height="22" viewBox="0 0 24 24">
      <rect x="3" y="4" width="18" height="4.5" rx="1.2" {...s} />
      <rect x="3" y="13" width="11" height="4.5" rx="1.2" {...s} />
      <path d="M3 21h18" {...s} opacity="0.5" />
    </svg>
  );
}

// ── Primitive controls (design-system styled, not the glass Tweak* set) ────

function SettingRow({ title, desc, children, stacked = false, last = false }) {
  return (
    <div style={{
      display: "flex",
      flexDirection: stacked ? "column" : "row",
      alignItems: stacked ? "stretch" : "center",
      justifyContent: "space-between",
      gap: stacked ? 12 : 20,
      padding: "16px 0",
      borderBottom: last ? "none" : "1px solid var(--co-border-1)",
    }}>
      <div style={{ maxWidth: stacked ? "none" : 340 }}>
        <div style={{ fontSize: 13.5, fontWeight: 600, color: "var(--co-fg-0)" }}>{title}</div>
        {desc && (
          <div style={{ fontSize: 12, color: "var(--co-text-subtle)", marginTop: 3, lineHeight: 1.5 }}>{desc}</div>
        )}
      </div>
      <div style={{ flexShrink: 0 }}>{children}</div>
    </div>
  );
}

function Seg({ value, options, onChange }) {
  return (
    <div style={{
      display: "inline-flex", padding: 2, gap: 2,
      background: "var(--co-bg-3)", border: "1px solid var(--co-border-2)",
      borderRadius: 9,
    }}>
      {options.map((o) => {
        const on = o.value === value;
        return (
          <button
            key={o.value}
            type="button"
            onClick={() => onChange(o.value)}
            style={{
              display: "inline-flex", alignItems: "center", gap: 6,
              padding: "6px 12px", border: "none", borderRadius: 7, cursor: "pointer",
              fontFamily: "var(--co-font-sans)", fontSize: 12.5, fontWeight: 600,
              background: on ? "var(--co-accent)" : "transparent",
              color: on ? "var(--co-accent-ink)" : "var(--co-text-muted)",
              boxShadow: on ? "var(--co-shadow-1)" : "none",
              transition: "background 140ms var(--co-ease-out), color 140ms var(--co-ease-out)",
            }}
            onMouseEnter={(e) => { if (!on) e.currentTarget.style.color = "var(--co-text-strong)"; }}
            onMouseLeave={(e) => { if (!on) e.currentTarget.style.color = "var(--co-text-muted)"; }}
          >
            {o.glyph}{o.label}
          </button>
        );
      })}
    </div>
  );
}

function Toggle({ on, onChange }) {
  return (
    <button
      type="button"
      role="switch"
      aria-checked={!!on}
      onClick={() => onChange(!on)}
      style={{
        position: "relative", width: 40, height: 23, padding: 0,
        border: "1px solid " + (on ? "transparent" : "var(--co-border-2)"),
        borderRadius: 999, cursor: "pointer",
        background: on ? "var(--co-accent)" : "var(--co-bg-4)",
        transition: "background 160ms var(--co-ease-out)",
      }}
    >
      <span style={{
        position: "absolute", top: 2, left: on ? 19 : 2,
        width: 17, height: 17, borderRadius: 999,
        background: on ? "var(--co-accent-ink)" : "var(--co-fg-2)",
        boxShadow: "0 1px 2px rgba(0,0,0,0.35)",
        transition: "left 160ms var(--co-ease-soft)",
      }} />
    </button>
  );
}

function TextField({ value, onChange, placeholder, mono = false }) {
  return (
    <input
      type="text"
      value={value || ""}
      placeholder={placeholder}
      onChange={(e) => onChange(e.target.value)}
      style={{
        width: "100%", boxSizing: "border-box",
        padding: "8px 11px", borderRadius: 9,
        background: "var(--co-bg-3)", border: "1px solid var(--co-border-2)",
        color: "var(--co-fg-0)", fontSize: 12.5,
        fontFamily: mono ? "var(--co-font-mono)" : "var(--co-font-sans)",
        outline: "none", transition: "border-color 140ms var(--co-ease-out), box-shadow 140ms var(--co-ease-out)",
      }}
      onFocus={(e) => {
        e.target.style.borderColor = "var(--co-accent)";
        e.target.style.boxShadow = "0 0 0 3px color-mix(in oklab, var(--co-accent) 28%, transparent)";
      }}
      onBlur={(e) => {
        e.target.style.borderColor = "var(--co-border-2)";
        e.target.style.boxShadow = "none";
      }}
    />
  );
}

// ── Sections ───────────────────────────────────────────────────────────────

function AppearanceSection({ t, setTweak }) {
  return (
    <div>
      <SettingRow
        title="Color theme"
        desc="Applies across the whole app. More palettes can be added to the theme registry."
        stacked
      >
        <div style={{ display: "grid", gridTemplateColumns: "repeat(2, 1fr)", gap: 10 }}>
          {THEMES.map((th) => {
            const on = t.theme === th.value;
            return (
              <button
                key={th.value}
                type="button"
                onClick={() => setTweak("theme", th.value)}
                style={{
                  position: "relative", textAlign: "left", cursor: "pointer",
                  padding: 11, borderRadius: 12,
                  background: "var(--co-bg-2)",
                  border: "1px solid " + (on ? "var(--co-accent)" : "var(--co-border-1)"),
                  boxShadow: on ? "0 0 0 1px var(--co-accent), var(--co-shadow-1)" : "none",
                  transition: "border-color 140ms var(--co-ease-out), box-shadow 140ms var(--co-ease-out)",
                }}
                onMouseEnter={(e) => { if (!on) e.currentTarget.style.borderColor = "var(--co-border-3)"; }}
                onMouseLeave={(e) => { if (!on) e.currentTarget.style.borderColor = "var(--co-border-1)"; }}
              >
                <div style={{ display: "flex", gap: 0, borderRadius: 7, overflow: "hidden", height: 34, border: "1px solid var(--co-border-1)" }}>
                  {th.swatch.map((c, i) => (
                    <span key={i} style={{ flex: i === th.swatch.length - 1 ? "0 0 26px" : 1, background: c }} />
                  ))}
                </div>
                <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginTop: 9 }}>
                  <div>
                    <div style={{ display: "flex", alignItems: "center", gap: 6 }}>
                      <span style={{ fontSize: 13, fontWeight: 600, color: "var(--co-fg-0)" }}>{th.name}</span>
                      <span style={{
                        fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.04em",
                        textTransform: "uppercase", color: "var(--co-text-subtle)",
                        padding: "1px 5px", borderRadius: 4, background: "var(--co-bg-3)",
                      }}>{th.mode}</span>
                    </div>
                    <div style={{ fontSize: 11, color: "var(--co-text-subtle)", marginTop: 2 }}>{th.desc}</div>
                  </div>
                  {on && (
                    <span style={{
                      width: 18, height: 18, borderRadius: 999, flexShrink: 0,
                      background: "var(--co-accent)", color: "var(--co-accent-ink)",
                      display: "flex", alignItems: "center", justifyContent: "center",
                    }}>
                      <Icon name="check" size={11} color="currentColor" strokeWidth={2.5} />
                    </span>
                  )}
                </div>
              </button>
            );
          })}
        </div>
      </SettingRow>

      <SettingRow title="Accent color" desc="The active / selected highlight used throughout the UI.">
        <div style={{ display: "flex", gap: 10 }}>
          {ACCENTS.map((a) => {
            const on = t.accent === a.value;
            return (
              <button
                key={a.value}
                type="button"
                onClick={() => setTweak("accent", a.value)}
                title={a.name}
                style={{
                  display: "flex", alignItems: "center", gap: 8,
                  padding: "7px 12px 7px 8px", cursor: "pointer",
                  borderRadius: 9, background: "var(--co-bg-2)",
                  border: "1px solid " + (on ? "var(--co-accent)" : "var(--co-border-1)"),
                  boxShadow: on ? "0 0 0 1px var(--co-accent)" : "none",
                  transition: "border-color 140ms var(--co-ease-out)",
                }}
                onMouseEnter={(e) => { if (!on) e.currentTarget.style.borderColor = "var(--co-border-3)"; }}
                onMouseLeave={(e) => { if (!on) e.currentTarget.style.borderColor = "var(--co-border-1)"; }}
              >
                <span style={{
                  width: 22, height: 22, borderRadius: 7, background: a.grad,
                  boxShadow: "inset 0 0 0 1px rgba(255,255,255,0.12)",
                }} />
                <span style={{ fontSize: 12.5, fontWeight: 600, color: on ? "var(--co-fg-0)" : "var(--co-text-muted)" }}>{a.name}</span>
              </button>
            );
          })}
        </div>
      </SettingRow>

      <SettingRow title="Interface density" desc="Spacing and node size on the canvas." last>
        <Seg
          value={t.density}
          options={[
            { value: "comfortable", label: "Comfortable" },
            { value: "compact",     label: "Compact" },
          ]}
          onChange={(v) => setTweak("density", v)}
        />
      </SettingRow>
    </div>
  );
}

function CanvasSection({ t, setTweak }) {
  const glyphColor = "currentColor";
  return (
    <div>
      <SettingRow
        title="Default canvas layout"
        desc="How workflows are arranged when you open them. Graph routes freely; tree stacks top-down by dependency."
        stacked
      >
        <Seg
          value={t.canvasStyle}
          options={[
            { value: "graph", label: "Graph", glyph: <LayoutGlyph kind="graph" color={glyphColor} /> },
            { value: "tree",  label: "Tree",  glyph: <LayoutGlyph kind="tree"  color={glyphColor} /> },
          ]}
          onChange={(v) => setTweak("canvasStyle", v)}
        />
      </SettingRow>

      <SettingRow title="Edge style" desc="How connections are drawn between stages." last>
        <Seg
          value={t.edgeStyle}
          options={[
            { value: "curved",     label: "Curved" },
            { value: "orthogonal", label: "Ortho" },
            { value: "straight",   label: "Straight" },
          ]}
          onChange={(v) => setTweak("edgeStyle", v)}
        />
      </SettingRow>
    </div>
  );
}

function WorkflowSection({ t, setTweak }) {
  return (
    <div>
      <SettingRow
        title="Worker runner"
        desc="Where agent jobs execute. Localhost runs in-process; the others schedule containers on a backend."
        stacked
      >
        <Seg
          value={t.workerRunner}
          options={[
            { value: "localhost", label: "Localhost" },
            { value: "docker",    label: "Docker" },
            { value: "swarm",     label: "Docker Swarm" },
            { value: "k3s",       label: "K3s" },
          ]}
          onChange={(v) => setTweak("workerRunner", v)}
        />
      </SettingRow>

      <SettingRow title="Open on launch" desc="Which mode the app starts in. Takes effect next time you load.">
        <Seg
          value={t.defaultMode}
          options={[
            { value: "build",   label: "Build" },
            { value: "active",  label: "Active" },
            { value: "history", label: "History" },
          ]}
          onChange={(v) => setTweak("defaultMode", v)}
        />
      </SettingRow>

      <SettingRow title="Confirm before stopping a run" desc="Ask for confirmation before cancelling an in-flight job.">
        <Toggle on={t.confirmStop} onChange={(v) => setTweak("confirmStop", v)} />
      </SettingRow>

      <SettingRow title="Notify when a run finishes" desc="Post a toast when a job lands as passed or failed." last>
        <Toggle on={t.notifyFinish} onChange={(v) => setTweak("notifyFinish", v)} />
      </SettingRow>
    </div>
  );
}

// CHANNELS is a registry like THEMES — add a messaging app here (icon, copy,
// connection fields) and a card renders for it with no other UI changes.
// Each channel's on/off lives at `<value>Enabled`; field values at their keys.
const CHANNELS = [
  {
    value: "telegram",
    name: "Telegram",
    icon: "send",
    desc: "Send run notifications to a Telegram chat through a bot.",
    fields: [
      { key: "telegramToken", label: "Bot token", placeholder: "123456789:ABCdef…", mono: true },
      { key: "telegramChat",  label: "Chat ID",   placeholder: "@your_channel or -100…", mono: true },
    ],
  },
];

function MessagingSection({ t, setTweak }) {
  return (
    <div>
      {CHANNELS.map((ch, idx) => {
        const on = !!t[ch.value + "Enabled"];
        return (
          <div
            key={ch.value}
            style={{ padding: "16px 0", borderBottom: idx === CHANNELS.length - 1 ? "none" : "1px solid var(--co-border-1)" }}
          >
            <div style={{ display: "flex", alignItems: "center", gap: 12 }}>
              <span style={{
                width: 34, height: 34, borderRadius: 9, flexShrink: 0,
                background: "var(--co-bg-3)", border: "1px solid var(--co-border-2)",
                display: "flex", alignItems: "center", justifyContent: "center",
                color: on ? "var(--co-accent)" : "var(--co-text-muted)",
              }}>
                <Icon name={ch.icon} size={17} color="currentColor" />
              </span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ display: "flex", alignItems: "center", gap: 8 }}>
                  <span style={{ fontSize: 13.5, fontWeight: 600, color: "var(--co-fg-0)" }}>{ch.name}</span>
                  <span style={{
                    fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.04em",
                    textTransform: "uppercase", padding: "1px 6px", borderRadius: 4,
                    color: on ? "var(--co-accent)" : "var(--co-text-subtle)",
                    background: on ? "color-mix(in oklab, var(--co-accent) 18%, transparent)" : "var(--co-bg-3)",
                  }}>{on ? "connected" : "off"}</span>
                </div>
                <div style={{ fontSize: 12, color: "var(--co-text-subtle)", marginTop: 3, lineHeight: 1.5 }}>{ch.desc}</div>
              </div>
              <div style={{ flexShrink: 0 }}>
                <Toggle on={on} onChange={(v) => setTweak(ch.value + "Enabled", v)} />
              </div>
            </div>

            {on && (
              <div style={{ display: "grid", gap: 10, marginTop: 14, paddingLeft: 46 }}>
                {ch.fields.map((f) => (
                  <label key={f.key} style={{ display: "block" }}>
                    <span style={{ display: "block", fontSize: 11.5, fontWeight: 600, color: "var(--co-text-muted)", marginBottom: 5 }}>{f.label}</span>
                    <TextField
                      value={t[f.key]}
                      placeholder={f.placeholder}
                      mono={f.mono}
                      onChange={(v) => setTweak(f.key, v)}
                    />
                  </label>
                ))}
              </div>
            )}
          </div>
        );
      })}

      <p style={{ fontSize: 11.5, color: "var(--co-text-subtle)", lineHeight: 1.5, margin: "16px 0 0" }}>
        More channels can be added to the messaging registry as they ship.
      </p>
    </div>
  );
}

function PluginsSection() {
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", textAlign: "center", padding: "44px 16px 36px" }}>
      <span style={{
        width: 46, height: 46, borderRadius: 12, marginBottom: 16,
        background: "var(--co-bg-3)", border: "1px solid var(--co-border-2)",
        display: "flex", alignItems: "center", justifyContent: "center",
        color: "var(--co-text-muted)",
      }}>
        <Icon name="plug" size={22} color="currentColor" />
      </span>
      <div style={{ fontSize: 14, fontWeight: 600, color: "var(--co-fg-0)" }}>No plugins installed</div>
      <div style={{ fontSize: 12.5, color: "var(--co-text-subtle)", marginTop: 6, maxWidth: 320, lineHeight: 1.55 }}>
        Extend Trailhead with custom stages, reviewers, and integrations.
      </div>
      <code style={{
        marginTop: 16, padding: "8px 12px", borderRadius: 8,
        background: "var(--co-code-bg)", border: "1px solid var(--co-border-1)",
        fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-code-fg)",
      }}>trailhead plugin add &lt;name&gt;</code>
    </div>
  );
}

// ── Shell ────────────────────────────────────────────────────────────────

const SM_SECTIONS = [
  { value: "appearance", label: "Appearance", icon: "sun",      Comp: AppearanceSection },
  { value: "canvas",     label: "Canvas",     icon: "layout",   Comp: CanvasSection },
  { value: "workflow",   label: "Workflow",   icon: "workflow", Comp: WorkflowSection },
  { value: "messaging",  label: "Messaging",  icon: "send",     Comp: MessagingSection },
  { value: "plugins",    label: "Plugins",    icon: "plug",     Comp: PluginsSection },
];

function SettingsModal({ t, setTweak, onClose, embedded = false, initialSection = "appearance" }) {
  const [section, setSection] = useStateSM(initialSection);
  const dialogRef = useRefSM(null);
  const [compact, setCompact] = useStateSM(false);

  // In embedded mode (handoff catalog) there's no overlay to dismiss, so Esc
  // shouldn't be bound — it would steal the key from the host doc.
  useEffectSM(() => {
    if (embedded) return;
    const onKey = (e) => { if (e.key === "Escape") onClose && onClose(); };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose, embedded]);

  // Below ~600px the left sidebar would crowd the content, so the nav collapses
  // to a horizontal tab strip instead of disappearing — every section stays reachable.
  useEffectSM(() => {
    const el = dialogRef.current;
    if (!el || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver((entries) => {
      setCompact(entries[0].contentRect.width < 600);
    });
    ro.observe(el);
    return () => ro.disconnect();
  }, []);

  const Active = SM_SECTIONS.find((s) => s.value === section).Comp;

  const dialog = (
      <div
        ref={dialogRef}
        onMouseDown={(e) => e.stopPropagation()}
        role="dialog"
        aria-label="Settings"
        style={{
          width: embedded ? "100%" : 720, maxWidth: "100%",
          height: embedded ? "100%" : undefined,
          maxHeight: embedded ? "100%" : "86vh",
          display: "flex", flexDirection: "column",
          background: "var(--co-bg-1)",
          border: embedded ? "none" : "1px solid var(--co-border-2)",
          borderRadius: embedded ? 0 : 18,
          boxShadow: embedded ? "none" : "var(--co-shadow-3)",
          overflow: "hidden",
        }}
      >
        {/* Header */}
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          padding: "16px 16px 16px 22px",
          borderBottom: "1px solid var(--co-border-1)",
        }}>
          <div style={{ display: "flex", alignItems: "center", gap: 11 }}>
            <span style={{
              width: 30, height: 30, borderRadius: 8, flexShrink: 0,
              background: "var(--co-bg-3)", border: "1px solid var(--co-border-2)",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: "var(--co-accent)",
            }}>
              <Icon name="settings" size={16} color="currentColor" />
            </span>
            <div>
              <div style={{ fontFamily: "var(--co-font-display)", fontSize: 17, fontWeight: 600, color: "var(--co-fg-0)", letterSpacing: "-0.01em" }}>Settings</div>
              <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-subtle)", marginTop: 1 }}>preferences · saved locally</div>
            </div>
          </div>
          <IconButton icon="x" onClick={onClose} title="Close" />
        </div>

        {/* Compact: horizontal tab strip replaces the sidebar */}
        {compact && (
          <div role="tablist" className="sm-tabstrip" style={{
            display: "flex", gap: 4, padding: "4px 10px 0",
            overflowX: "auto", overflowY: "hidden", flexShrink: 0,
            scrollbarWidth: "none", msOverflowStyle: "none",
            borderBottom: "1px solid var(--co-border-1)",
            background: "var(--co-bg-0)",
          }}>
            {SM_SECTIONS.map((s) => {
              const on = s.value === section;
              return (
                <button
                  key={s.value}
                  type="button"
                  role="tab"
                  aria-selected={on}
                  onClick={() => setSection(s.value)}
                  style={{
                    display: "inline-flex", alignItems: "center", gap: 7, flexShrink: 0,
                    padding: "9px 11px", border: "none", background: "transparent", cursor: "pointer",
                    fontFamily: "var(--co-font-sans)", fontSize: 12.5, fontWeight: on ? 600 : 500,
                    color: on ? "var(--co-fg-0)" : "var(--co-text-muted)",
                    borderBottom: "2px solid " + (on ? "var(--co-accent)" : "transparent"),
                    marginBottom: -1,
                    transition: "color 140ms var(--co-ease-out)",
                  }}
                  onMouseEnter={(e) => { if (!on) e.currentTarget.style.color = "var(--co-text-strong)"; }}
                  onMouseLeave={(e) => { if (!on) e.currentTarget.style.color = "var(--co-text-muted)"; }}
                >
                  <Icon name={s.icon} size={14} color={on ? "var(--co-accent)" : "currentColor"} />
                  {s.label}
                </button>
              );
            })}
          </div>
        )}

        {/* Body: nav + content */}
        <div style={{ display: "flex", minHeight: 0, flex: 1 }}>
          {/* Section nav — hidden in compact, replaced by the tab strip above.
              Uses a div (not <nav>) so host pages that globally hide <nav>
              (e.g. the handoff doc) don't blank the sidebar. */}
          {!compact && (
          <div role="navigation" aria-label="Settings sections" style={{
            flex: "0 0 178px", padding: 12,
            borderRight: "1px solid var(--co-border-1)",
            background: "var(--co-bg-0)",
            display: "flex", flexDirection: "column", gap: 2,
          }}>
            {SM_SECTIONS.map((s) => {
              const on = s.value === section;
              return (
                <button
                  key={s.value}
                  type="button"
                  onClick={() => setSection(s.value)}
                  style={{
                    display: "flex", alignItems: "center", gap: 10,
                    padding: "9px 11px", border: "none", borderRadius: 8, cursor: "pointer",
                    textAlign: "left", width: "100%",
                    fontFamily: "var(--co-font-sans)", fontSize: 13, fontWeight: on ? 600 : 500,
                    background: on ? "var(--co-bg-3)" : "transparent",
                    color: on ? "var(--co-fg-0)" : "var(--co-text-muted)",
                    transition: "background 140ms var(--co-ease-out), color 140ms var(--co-ease-out)",
                  }}
                  onMouseEnter={(e) => { if (!on) e.currentTarget.style.background = "var(--co-bg-2)"; }}
                  onMouseLeave={(e) => { if (!on) e.currentTarget.style.background = "transparent"; }}
                >
                  <Icon name={s.icon} size={15} color={on ? "var(--co-accent)" : "currentColor"} />
                  {s.label}
                </button>
              );
            })}
          </div>
          )}

          {/* Content */}
          <div style={{ flex: 1, minWidth: 0, overflowY: "auto", padding: "6px 24px 20px" }}>
            <Active t={t} setTweak={setTweak} />
          </div>
        </div>
      </div>
  );

  if (embedded) return dialog;

  return (
    <div
      onMouseDown={onClose}
      style={{
        position: "fixed", inset: 0, zIndex: 200,
        display: "flex", alignItems: "center", justifyContent: "center",
        padding: 24,
        background: "color-mix(in oklab, var(--co-bg-0) 62%, transparent)",
        backdropFilter: "blur(6px)", WebkitBackdropFilter: "blur(6px)",
        animation: "co-slide-in 240ms var(--co-ease-out)",
      }}
    >
      {dialog}
    </div>
  );
}

Object.assign(window, {
  SettingsModal,
  SM_SECTIONS,
  AppearanceSection, CanvasSection, WorkflowSection, MessagingSection, PluginsSection,
});
