/* global React, Icon, IconButton, Eyebrow, StatusDot, WORKFLOWS_LIST */
const { useState: useStateSB } = React;

function SidebarBrand() {
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "12px 14px 10px", borderBottom: "1px solid var(--co-border-1)" }}>
      <img src="assets/trailhead-logo.png" alt="Trailhead" width="36" height="36" style={{ display: "block", flex: "0 0 36px" }} />
      <div style={{ display: "flex", flexDirection: "column", lineHeight: 1.15, flex: 1 }}>
        <span style={{ fontFamily: "var(--co-font-display)", fontSize: 15, fontWeight: 700, color: "var(--co-text-strong)", letterSpacing: "-0.02em" }}>
          Trailhead
        </span>
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>workflows · acme</span>
      </div>
      <span style={{
        fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600,
        padding: "2px 5px", borderRadius: 3,
        background: "var(--co-trail-soft)", color: "var(--co-trail-400)",
        letterSpacing: "0.04em",
      }}>v0.42</span>
    </div>
  );
}

function NavRow({ icon, label, count, active, onClick, accent = "accent", children }) {
  const [hover, setHover] = useStateSB(false);
  return (
    <button
      type="button"
      onClick={onClick}
      onMouseEnter={() => setHover(true)}
      onMouseLeave={() => setHover(false)}
      style={{
        display: "flex", alignItems: "center", gap: 9,
        width: "calc(100% - 12px)",
        margin: "0 6px",
        padding: "5px 8px",
        background: active ? "var(--co-bg-3)" : hover ? "var(--co-bg-2)" : "transparent",
        border: "none",
        borderRadius: 6,
        fontSize: 12.5, fontFamily: "var(--co-font-sans)",
        color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
        cursor: "pointer",
        textAlign: "left",
        position: "relative",
        transition: "background 140ms var(--co-ease-out), color 140ms var(--co-ease-out)",
      }}
    >
      {active && (
        <span style={{ position: "absolute", left: -6, top: 6, bottom: 6, width: 2, borderRadius: 2, background: `var(--co-${accent})` }} />
      )}
      {icon && <Icon name={icon} size={13} color={active ? `var(--co-${accent})` : "currentColor"} />}
      <span style={{ flex: 1, fontWeight: active ? 500 : 400 }}>{label}</span>
      {children}
      {count != null && (
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)", fontVariantNumeric: "tabular-nums" }}>{count}</span>
      )}
    </button>
  );
}

function WorkflowsList({ activeId, onPick }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
      {WORKFLOWS_LIST.map(wf => (
        <NavRow
          key={wf.id}
          icon="workflow"
          label={wf.name}
          active={wf.id === activeId}
          onClick={() => onPick(wf.id)}
          accent="trail-400"
        >
          {wf.active > 0 && (
            <span style={{
              display: "inline-flex", alignItems: "center", gap: 4,
              fontFamily: "var(--co-font-mono)", fontSize: 10,
              color: "var(--co-accent)",
            }}>
              <StatusDot status="running" pulse size={5} />
              {wf.active}
            </span>
          )}
        </NavRow>
      ))}
    </div>
  );
}

function RecentRuns({ jobs, activeId, onPick }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 1 }}>
      {jobs.slice(0, 6).map(j => (
        <button
          key={j.id}
          type="button"
          onClick={() => onPick(j.id)}
          style={{
            display: "grid",
            gridTemplateColumns: "10px 1fr auto",
            alignItems: "center",
            gap: 8,
            width: "calc(100% - 12px)",
            margin: "0 6px",
            padding: "5px 8px",
            background: j.id === activeId ? "var(--co-bg-3)" : "transparent",
            border: "none",
            borderRadius: 6,
            color: "var(--co-text-muted)",
            cursor: "pointer",
            textAlign: "left",
            fontFamily: "var(--co-font-mono)",
            fontSize: 11,
          }}
          onMouseEnter={e => { if (j.id !== activeId) e.currentTarget.style.background = "var(--co-bg-2)"; }}
          onMouseLeave={e => { if (j.id !== activeId) e.currentTarget.style.background = "transparent"; }}
        >
          <StatusDot status={j.status} pulse={j.status === "running"} size={6} />
          <span style={{ overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", color: j.id === activeId ? "var(--co-text-strong)" : "var(--co-text)" }}>
            {j.id.replace(/^r_/, "r_")}
          </span>
          <span style={{ color: "var(--co-text-subtle)" }}>{j.started}</span>
        </button>
      ))}
    </div>
  );
}

function SectionTitle({ children, right }) {
  return (
    <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", padding: "12px 14px 4px" }}>
      <Eyebrow>{children}</Eyebrow>
      {right}
    </div>
  );
}

function Sidebar({ activeWorkflow, onWorkflow, activeJob, onJob, jobs }) {
  return (
    <aside style={{
      width: 220, flex: "0 0 220px",
      height: "100vh",
      background: "var(--co-bg-1)",
      borderRight: "1px solid var(--co-border-1)",
      display: "flex", flexDirection: "column",
      fontFamily: "var(--co-font-sans)",
    }}>
      <SidebarBrand />

      <div style={{ flex: 1, overflowY: "auto", paddingBottom: 12 }}>
        <SectionTitle right={
          <button type="button" title="New workflow" style={{
            background: "transparent", border: "none", color: "var(--co-text-subtle)",
            cursor: "pointer", padding: 2,
          }}><Icon name="plus" size={12} /></button>
        }>workflows · {WORKFLOWS_LIST.length}</SectionTitle>
        <WorkflowsList activeId={activeWorkflow} onPick={onWorkflow} />

        <SectionTitle>recent jobs</SectionTitle>
        <RecentRuns jobs={jobs} activeId={activeJob} onPick={onJob} />

        <SectionTitle>tools</SectionTitle>
        <NavRow icon="bar"       label="evals" />
        <NavRow icon="terminal"  label="cli · tokens" />
        <NavRow icon="settings"  label="settings" />
      </div>

      <div style={{
        padding: "10px 12px",
        borderTop: "1px solid var(--co-border-1)",
        display: "flex", alignItems: "center", gap: 8,
      }}>
        <div style={{
          width: 24, height: 24, borderRadius: 999, background: "var(--co-grad-trail)",
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: "var(--co-font-mono)", fontSize: 10, color: "#fbf3e6", fontWeight: 700,
        }}>jb</div>
        <div style={{ flex: 1, minWidth: 0, lineHeight: 1.1 }}>
          <div style={{ fontSize: 12, color: "var(--co-text)" }}>jen.b</div>
          <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>maintainer · local</div>
        </div>
        <IconButton icon="settings" size={24} title="Account" />
      </div>
    </aside>
  );
}

Object.assign(window, { Sidebar });
