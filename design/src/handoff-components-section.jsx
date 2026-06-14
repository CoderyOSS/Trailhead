/* global React, Card, Stage, StatesGrid, TokensList, StageSplit, SubBlock, H3, AnatomyLegend,
   Button, IconButton, Icon, StatusDot, StatusTag, Tag, Eyebrow,
   ModeRail, WorkflowsSidebar, JobsSidebar, TopBar, StageDrawer, Filmstrip, RunsView,
   Canvas, WorkerNode, BuilderTips, OperatorPicker,
   WORKFLOW, JOB, JOBS_LOG, SNAPSHOTS, STAGE_EXECUTIONS */

// ──────────────────────────────────────────────────────────────────────────
// Component catalog cards — each component rendered in isolation, with
// anatomy callouts, all states, and the tokens the Flutter agent should
// use to build it.
// ──────────────────────────────────────────────────────────────────────────

// Helper: render a real component inside a constrained box so the layout
// computations behave the same as in the live app.
function Constrained({ width, height, children, allowScroll }) {
  return (
    <div style={{
      width, height,
      position: "relative",
      background: "var(--co-bg-1)",
      borderRadius: 8,
      border: "1px solid var(--co-border-1)",
      overflow: allowScroll ? "auto" : "hidden",
      flex: "0 0 auto",
    }}>{children}</div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Buttons & form controls
// ════════════════════════════════════════════════════════════════════════

function ButtonsCard() {
  return (
    <Card
      title="Buttons"
      description='Five variants: primary (accent CTA), trail (gradient — used for "launch"), secondary (filled neutral), ghost (text-style), danger. Three sizes — sm / md / lg. Always pair label with leading icon when one is meaningful.'
      dartImport="ElevatedButton · FilledButton · TextButton"
    >
      <StagesRow>
        <Stage label="primary · trail · secondary · ghost · danger" padding={28}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10, justifyContent: "center" }}>
            <Button variant="primary"   size="md" icon="play">launch</Button>
            <Button variant="trail"     size="md" icon="play">launch</Button>
            <Button variant="secondary" size="md">save draft</Button>
            <Button variant="ghost"     size="md" icon="file">YAML</Button>
            <Button variant="danger"    size="md">delete</Button>
          </div>
        </Stage>
      </StagesRow>

      <SubBlock label="sizes">
        <StatesGrid columns={3} items={[
          { label: "sm · 26px · CompButton.smMin",      children: <Button variant="primary" size="sm" icon="play">launch</Button> },
          { label: "md · 32px · CompButton.mdMin",      children: <Button variant="primary" size="md" icon="play">launch</Button> },
          { label: "lg · 40px · CompButton.lgMin",      children: <Button variant="primary" size="lg" icon="play">launch</Button> },
        ]} />
      </SubBlock>

      <SubBlock label="states (md · primary)">
        <StatesGrid items={[
          { label: "default", children: <Button variant="primary" size="md">save draft</Button> },
          { label: "hover",   children: <Button variant="primary" size="md" style={{ filter: "brightness(1.06)" }}>save draft</Button> },
          { label: "disabled",children: <span style={{ opacity: 0.4, pointerEvents: "none" }}><Button variant="primary" size="md">save draft</Button></span> },
          { label: "loading", children: (
            <Button variant="primary" size="md">
              <span style={{ display: "inline-flex", alignItems: "center", gap: 5 }}>
                <span style={{
                  width: 11, height: 11, border: "2px solid currentColor", borderRightColor: "transparent",
                  borderRadius: 999, animation: "co-spin 0.8s linear infinite",
                }} />
                saving
              </span>
            </Button>
          )},
        ]} />
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "color.bg (primary)", value: "accent.accent" },
          { name: "color.fg (primary)", value: "accent.accentInk" },
          { name: "color.bg (secondary)", value: "palette.surfaceRaised + 1px palette.border" },
          { name: "color.bg (ghost)",   value: "transparent · hover: palette.surfaceHover" },
          { name: "color.bg (danger)",  value: "palette.dangerSoft · fg: palette.danger" },
          { name: "shape", value: "RoundedRectangleBorder(radius: AppRadius.sm)" },
          { name: "font",  value: "AppType.sans · medium · CompButton.{sm|md|lg}FontSize" },
        ]} />
      </SubBlock>
    </Card>
  );
}

function FormControlsCard() {
  return (
    <Card
      title="Form controls"
      description="Text inputs, selects (dropdowns), and segmented toggles. Padding + height are component-token constants. Focus ring uses the active accent."
      dartImport="TextField · DropdownButtonFormField · custom SegmentedToggle"
    >
      <SubBlock label="text input · 32px tall · monospace · accent focus ring">
        <StatesGrid items={[
          { label: "default", children: <FormInput defaultValue="120s" /> },
          { label: "filled",  children: <FormInput defaultValue="webhook.invoke" /> },
          { label: "focus",   children: <FormInput defaultValue="acme/ledger" focused /> },
          { label: "error",   children: <FormInput defaultValue="—" error /> },
        ]} />
      </SubBlock>

      <SubBlock label="select / dropdown">
        <StatesGrid columns={2} items={[
          { label: "closed", children: <FormSelect value="Anthropic · sonnet-4.5  ·  balanced" /> },
          { label: "open",   children: <FormSelect value="Anthropic · sonnet-4.5  ·  balanced" open /> },
        ]} />
      </SubBlock>

      <SubBlock label="segmented · 2-3 options" last>
        <StatesGrid items={[
          { label: "2 options",     children: <Segmented value="json" options={[{v:"json",l:"JSON"},{v:"text",l:"Plain text"}]} /> },
          { label: "3 options",     children: <Segmented value="curved" options={[{v:"curved",l:"curved"},{v:"orthogonal",l:"ortho"},{v:"straight",l:"straight"}]} /> },
          { label: "with icon",     children: <Segmented value="active" options={[
            {v:"active",l:"active",icon:"stopwatch"},{v:"history",l:"history",icon:"list"},
          ]} /> },
          { label: "with description", children: <Segmented value="json" twoLine options={[
            {v:"json",l:"JSON schema",d:"strict"},{v:"text",l:"Plain text",d:"freeform"},
          ]} /> },
        ]} />
      </SubBlock>
    </Card>
  );
}

// inline mock inputs — they exist purely for the catalog, the real ones
// are <input style={inputStyle} /> inside StageDrawer.
function FormInput({ defaultValue, focused, error }) {
  return (
    <input defaultValue={defaultValue} style={{
      width: 200,
      padding: "8px 10px",
      fontFamily: "var(--co-font-mono)", fontSize: 12,
      background: "var(--co-bg-1)",
      border: `1px solid ${error ? "var(--co-danger)" : focused ? "var(--co-accent)" : "var(--co-border-2)"}`,
      borderRadius: 8,
      color: error ? "var(--co-danger)" : "var(--co-text)",
      outline: "none",
      boxShadow: focused ? "var(--co-shadow-focus)" : "none",
    }} />
  );
}

function FormSelect({ value, open }) {
  return (
    <div style={{ position: "relative", width: 240 }}>
      <div style={{
        padding: "8px 10px",
        fontFamily: "var(--co-font-mono)", fontSize: 12,
        background: "var(--co-bg-1)",
        border: `1px solid ${open ? "var(--co-accent)" : "var(--co-border-2)"}`,
        borderRadius: 8,
        color: "var(--co-text)",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <span style={{
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
        }}>{value}</span>
        <span style={{
          width: 0, height: 0,
          borderLeft: "4px solid transparent",
          borderRight: "4px solid transparent",
          borderTop: "4px solid var(--co-text-muted)",
          transform: open ? "rotate(180deg)" : "rotate(0)",
        }} />
      </div>
      {open && (
        <div style={{
          position: "absolute", top: "100%", left: 0, right: 0, marginTop: 4,
          background: "var(--co-bg-2)",
          border: "1px solid var(--co-border-2)",
          borderRadius: 8,
          boxShadow: "var(--co-shadow-2)",
          padding: 4,
          fontFamily: "var(--co-font-mono)", fontSize: 11.5,
          zIndex: 5,
        }}>
          {[
            "Anthropic · haiku-4.5  ·  fast",
            "Anthropic · sonnet-4.5  ·  balanced",
            "Anthropic · opus-4.1  ·  best",
            "OpenAI · gpt-5",
          ].map((item, i) => (
            <div key={i} style={{
              padding: "5px 8px",
              borderRadius: 4,
              background: i === 1 ? "var(--co-bg-3)" : "transparent",
              color: i === 1 ? "var(--co-text-strong)" : "var(--co-text)",
            }}>{item}</div>
          ))}
        </div>
      )}
    </div>
  );
}

function Segmented({ value, options, twoLine }) {
  return (
    <div style={{
      display: "inline-flex", padding: 2,
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
    }}>
      {options.map(o => {
        const active = o.v === value;
        return (
          <div key={o.v} style={{
            padding: twoLine ? "5px 10px" : "4px 11px",
            background: active ? "var(--co-bg-4)" : "transparent",
            color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
            borderRadius: 6,
            fontSize: 12, fontWeight: 500,
            display: "flex", flexDirection: twoLine ? "column" : "row",
            alignItems: twoLine ? "flex-start" : "center", gap: twoLine ? 1 : 5,
            lineHeight: 1.2,
          }}>
            {o.icon && !twoLine && <Icon name={o.icon} size={12} color={active ? "var(--co-accent)" : "currentColor"} />}
            <span>{o.l}</span>
            {twoLine && o.d && <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>{o.d}</span>}
          </div>
        );
      })}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Status pips, tags, chips
// ════════════════════════════════════════════════════════════════════════

function StatusCard() {
  return (
    <Card
      title="Status pips, tags & chips"
      description="The smallest atoms in the system — they show up everywhere: nodes, log rows, table cells, snapshots, filmstrip headers. Each row pairs a colored dot with a label; the label may be ALL CAPS (pip), label-case (tag), or sentence-case (chip)."
      dartImport="StatusPip · StatusTag · Tag · Chip"
    >
      <SubBlock label="status pip — colored dot + uppercase label, used in lists & cards">
        <Stage label="all statuses" padding={20}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 8 }}>
            {["passed","failed","running","retrying","paused","queued","skipped","cancelled"].map(s => (
              <MiniPip key={s} status={s} />
            ))}
          </div>
        </Stage>
      </SubBlock>

      <SubBlock label="status tag — pip-style tag used in tables, top bar, drawer header">
        <Stage padding={20}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
            <StatusTag status="passed" />
            <StatusTag status="failed" />
            <StatusTag status="running" />
            <StatusTag status="retrying" />
            <StatusTag status="cancelled" />
          </div>
        </Stage>
      </SubBlock>

      <SubBlock label="status dot — bare colored dot, used in lists & node nibs">
        <Stage padding={20}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 18, alignItems: "center" }}>
            <StatusDot status="passed"  size={6} />
            <StatusDot status="failed"  size={6} />
            <StatusDot status="running" pulse size={6} />
            <StatusDot status="retrying" size={6} />
            <StatusDot status="cancelled" size={6} />
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-subtle)" }}>
              · "running" pulses · default 6px · "small" 5px
            </span>
          </div>
        </Stage>
      </SubBlock>

      <SubBlock label="workflow tag — chip used to identify the parent workflow in flat job lists">
        <Stage padding={20}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 10 }}>
            <WorkflowTag name="pr-reviewer" />
            <WorkflowTag name="eval-harness" />
            <WorkflowTag name="flake-tracker" />
            <WorkflowTag name="changelog-summary" />
          </div>
        </Stage>
      </SubBlock>

      <SubBlock label="skill / tool chip — fixed-width pill used in node body & log calls">
        <Stage padding={20}>
          <div style={{ display: "flex", flexWrap: "wrap", gap: 6 }}>
            {["git.fetch_pr","git.diff","file.read","code.review.semantic","sec.semgrep","sec.dep_audit"].map(s => (
              <span key={s} style={{
                fontFamily: "var(--co-font-mono)", fontSize: 10.5,
                padding: "2px 6px", borderRadius: 4,
                background: "var(--co-bg-3)", color: "var(--co-text)",
                border: "1px solid var(--co-border-1)",
              }}>{s}</span>
            ))}
          </div>
        </Stage>
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "pip.color · pip.bg", value: "AppTokens.statusColor(status).base / .soft" },
          { name: "pip.font",  value: "AppType.mono · 10px · semibold · letterSpacing 0.04em · UPPERCASE" },
          { name: "pip.shape", value: "RoundedRectangleBorder(radius: AppRadius.xs)" },
          { name: "dot.size",  value: "6px default · 5px small · pulse animation when status=running" },
          { name: "tag.bg",    value: "palette.surfaceRaised (border-1)" },
          { name: "chip.bg (skill/tool)", value: "palette.surfaceRaised (border-1) · mono · 10.5px" },
        ]} />
      </SubBlock>
    </Card>
  );
}

function MiniPip({ status }) {
  // Mirrors the Filmstrip.StatusPip exactly.
  const meta = STATUS_META[status];
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 600,
      padding: "2px 6px", borderRadius: 3,
      background: meta.bg,
      color: meta.color,
      letterSpacing: "0.04em", textTransform: "uppercase",
    }}>
      <span style={{
        width: 5, height: 5, borderRadius: 999,
        background: meta.color,
        animation: status === "running" ? "co-pulse 1.4s ease-in-out infinite" : "none",
      }} />
      {status}
    </span>
  );
}

const STATUS_META = {
  passed:    { color: "var(--co-success)", bg: "var(--co-success-soft)" },
  failed:    { color: "var(--co-danger)",  bg: "var(--co-danger-soft)" },
  running:   { color: "var(--co-accent)",  bg: "var(--co-accent-soft)" },
  retrying:  { color: "var(--co-warning)", bg: "var(--co-warning-soft)" },
  paused:    { color: "var(--co-warning)", bg: "var(--co-warning-soft)" },
  queued:    { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)" },
  skipped:   { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)" },
  cancelled: { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)" },
};

function WorkflowTag({ name }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 3,
      fontFamily: "var(--co-font-mono)", fontSize: 9.5,
      padding: "1px 5px",
      background: "var(--co-bg-3)",
      color: "var(--co-text-muted)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 3,
    }}>
      <span style={{ width: 3, height: 3, background: "var(--co-fg-3)", borderRadius: 999 }} />
      {name}
    </span>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Mode rail
// ════════════════════════════════════════════════════════════════════════

function ModeRailCard() {
  return (
    <Card
      title="Mode rail"
      description="The leftmost column. Three icon buttons — Build (pencil) / Active (stopwatch) / History (bullet list) — gate the whole app's mode. The active icon count appears as a small badge in its top-right corner. Brand glyph sits in the header slot."
      dartImport="lib/widgets/mode_rail.dart"
    >
      <StageSplit
        leftFlex={1.1}
        left={(
          <div style={{ position: "relative", display: "inline-block" }}>
            <Constrained width={52} height={520}>
              <ModeRail mode="active" onMode={() => {}} activeCount={3} />
            </Constrained>
            <RailAnnotations />
          </div>
        )}
        right={(
          <>
            <AnatomyLegend items={[
              { label: "brand glyph",  desc: "32px square, top of the rail, no click action" },
              { label: "mode button",  desc: "40×40px, 16px icon, hover flyout shows the mode label" },
              { label: "active rail",  desc: "2px accent pill on the left edge of the active item" },
              { label: "badge",        desc: "shows the active job count when > 0, accent fill" },
              { label: "tool slot",    desc: "secondary actions (cli, settings) pushed to bottom" },
              { label: "avatar",       desc: "user identity, single-user for now" },
            ]} />

            <div style={{ height: 16 }} />
            <H3>tokens</H3>
            <TokensList tokens={[
              { name: "width",       value: "CompModeRail.width · 52" },
              { name: "item",        value: "CompModeRail.itemSize · 40" },
              { name: "icon",        value: "AppIconSize.lg · 16" },
              { name: "active.color",value: "accent.accent + 2px left rail" },
              { name: "bg.idle",     value: "palette.pageBg" },
              { name: "bg.hover",    value: "palette.bg3" },
              { name: "bg.active",   value: "palette.bg4" },
            ]} />
          </>
        )}
      />
    </Card>
  );
}

function RailAnnotations() {
  return (
    <div style={{
      position: "absolute", inset: 0, pointerEvents: "none",
    }}>
      {[
        { n: 1, top: 26 },
        { n: 2, top: 92 },
        { n: 3, top: 144 },
        { n: 4, top: 102, right: -2 }, // badge — pulled right to the corner of stopwatch
        { n: 5, top: 380 },
        { n: 6, top: 470 },
      ].map((m, i) => (
        <div key={i} style={{
          position: "absolute",
          top: m.top, right: m.right ?? -10,
          width: 18, height: 18, borderRadius: 999,
          background: "var(--co-accent)",
          color: "var(--co-accent-ink)",
          display: "flex", alignItems: "center", justifyContent: "center",
          fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 700,
          boxShadow: "0 0 0 2px var(--co-bg-1)",
        }}>{m.n}</div>
      ))}
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Sidebars
// ════════════════════════════════════════════════════════════════════════

function SidebarsCard() {
  return (
    <Card
      title="Sidebars"
      description="Two sidebar variants — Workflows (Build mode) and Jobs (Active + History modes). The Jobs sidebar is shared across both modes: Active shows live jobs (running/paused/queued/retrying) with a live badge in the footer; History shows completed jobs (passed/failed/cancelled) with a filter button and 'no search yet' footer. Both support grouped/flat view toggle. Note: in History the sidebar is hidden until a run is selected — with no selection the runs table fills the width on its own, so the sidebar acts purely as a job-to-job navigator once you drill in."
      dartImport="lib/widgets/sidebars/{workflows,jobs}_sidebar.dart"
    >
      <SubBlock label="workflows sidebar · Build mode · 240px">
        <StageSplit
          leftFlex={1.2}
          left={(
            <Constrained width={240} height={460}>
              <WorkflowsSidebar activeId="wf_pr_reviewer" onPick={() => {}} />
            </Constrained>
          )}
          right={(
            <AnatomyLegend items={[
              { label: "title block", desc: "Workflows · subtitle 'edit plans · N total'" },
              { label: "new workflow", desc: "secondary button, full-width" },
              { label: "section header", desc: "mono caps 9.5px, 'all'" },
              { label: "workflow row",   desc: "name + run count, accent rail when active, live-job pip when running" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="jobs sidebar · Active mode · 260px · grouped view">
        <StageSplit
          leftFlex={1.2}
          left={(
            <Constrained width={260} height={460}>
              <JobsSidebar
                kind="active" jobs={JOBS_LOG}
                viewMode="grouped" onViewMode={() => {}}
                activeId="r_8f2a91c" onPick={() => {}}
              />
            </Constrained>
          )}
          right={(
            <AnatomyLegend items={[
              { label: "title block", desc: "Active jobs · subtitle 'N running · paused · queued'" },
              { label: "view toggle", desc: "grouped (workflow → jobs) ↔ flat (jobs + workflow tag)" },
              { label: "group header", desc: "workflow name · chevron · count · collapses on click" },
              { label: "job row · grouped", desc: "status dot · input string · run id suffix · timestamp · accent left rail when selected" },
              { label: "footer · Active", desc: "'showing N' on left · pulsing live badge on right" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="jobs sidebar · History mode · 260px · grouped view">
        <StageSplit
          leftFlex={1.2}
          left={(
            <Constrained width={260} height={460}>
              <JobsSidebar
                kind="history" jobs={JOBS_LOG}
                viewMode="grouped" onViewMode={() => {}}
                activeId="r_8f29442" onPick={() => {}}
              />
            </Constrained>
          )}
          right={(
            <AnatomyLegend items={[
              { label: "title block", desc: "History · subtitle 'N completed · last 24h'" },
              { label: "filter button", desc: "gear icon + 'filter' label · 1px border-1 · sits beside the view toggle · no search implemented yet" },
              { label: "group header", desc: "workflow name · count · same structure as Active" },
              { label: "job row", desc: "passed/failed/cancelled status dot · input string · run id suffix · timestamp" },
              { label: "footer · History", desc: "'showing N' on left · 'no search yet' on right (no live badge)" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="jobs sidebar · History mode · flat view · workflow shown as tag chip per row">
        <Stage padding={18} height={300}>
          <Constrained width={260} height={260}>
            <JobsSidebar
              kind="history" jobs={JOBS_LOG}
              viewMode="flat" onViewMode={() => {}}
              activeId="r_8f29442" onPick={() => {}}
            />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "width",          value: "CompSidebar.workflowWidth · 240 · jobsWidth · 260" },
          { name: "header.font",    value: "AppType.display · 15px · weight 600 for title" },
          { name: "subtitle.font",  value: "AppType.mono · 10.5px · palette.textSubtle" },
          { name: "viewToggle.bg",  value: "palette.bg3 + 1px border1 · active item: palette.bg4" },
          { name: "filterBtn.bg",   value: "transparent · 1px palette.border1 · radius 5 · History only" },
          { name: "groupHeader",    value: "AppType.mono · 11px · weight 600 · chevron 9px" },
          { name: "row.active.bg",  value: "palette.bg3 · 2px accent left rail at absolute left" },
          { name: "footer.font",    value: "AppType.mono · 10px · palette.textSubtle" },
          { name: "footer.live",    value: "StatusDot running + pulse · Active mode only" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Top bar
// ════════════════════════════════════════════════════════════════════════

function TopBarCard() {
  return (
    <Card
      title="Top bar"
      description="Adapts to the active mode. Build shows workflow identity + save/launch. Active and History (with a selected job) show a two-row job header: identity + status + controls on row 1, input + elapsed/tokens/cost on row 2."
      dartImport="lib/widgets/top_bar/{build,job,history_list}_bar.dart"
    >
      <SubBlock label="Build mode · workflow + save/launch">
        <Stage padding={0} height={56}>
          <Constrained width={1080} height={56}>
            <TopBar mode="build" workflow={WORKFLOW} job={null} jobState="running"
              onPlay={()=>{}} onPause={()=>{}} onStop={()=>{}} onRestart={()=>{}} onSnapshot={()=>{}}
              onClearJob={()=>{}} historyCount={JOBS_LOG.length} />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="Active mode · two-row job header · live controls">
        <Stage padding={0} height={70}>
          <Constrained width={1080} height={70}>
            <TopBar mode="active" workflow={WORKFLOW}
              job={{ ...JOB, workflow: "pr-reviewer", input: "PR #1428" }}
              jobState="running"
              onPlay={()=>{}} onPause={()=>{}} onStop={()=>{}} onRestart={()=>{}} onSnapshot={()=>{}}
              onClearJob={()=>{}} historyCount={JOBS_LOG.length} />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="History list · no job selected">
        <Stage padding={0} height={56}>
          <Constrained width={1080} height={56}>
            <TopBar mode="history" workflow={WORKFLOW} job={null} jobState="passed"
              onPlay={()=>{}} onPause={()=>{}} onStop={()=>{}} onRestart={()=>{}} onSnapshot={()=>{}}
              onClearJob={()=>{}} historyCount={JOBS_LOG.length} />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="History job · two-row · YAML + rerun actions" last>
        <Stage padding={0} height={70}>
          <Constrained width={1080} height={70}>
            <TopBar mode="history" workflow={WORKFLOW}
              job={{ ...JOB, status: "failed", workflow: "eval-harness", input: "suite/regress" }}
              jobState="failed"
              onPlay={()=>{}} onPause={()=>{}} onStop={()=>{}} onRestart={()=>{}} onSnapshot={()=>{}}
              onClearJob={()=>{}} historyCount={JOBS_LOG.length} />
          </Constrained>
        </Stage>

        <div style={{ height: 18 }} />
        <H3>tokens</H3>
        <TokensList tokens={[
          { name: "minHeight",  value: "CompTopBar.minHeight · 56" },
          { name: "bg",         value: "color-mix(palette.appShell 92%, transparent) · backdrop-blur" },
          { name: "border",     value: "bottom: 1px palette.divider" },
          { name: "mode badge", value: "uppercase mono 9.5px · soft color background, full color text" },
          { name: "controls",   value: "play (primary accent gradient) · pause/stop/refresh/bookmark (ghost)" },
          { name: "stats row",  value: "AppType.mono · 11px · palette.textSubtle labels · palette.text values" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Stage drawer (editor mode + log viewer mode)
// ════════════════════════════════════════════════════════════════════════

function StageDrawerCard() {
  const workerStage = WORKFLOW.stages.find(s => s.id === "full_review");
  return (
    <Card
      title="Stage drawer"
      description="Right slide-over panel. Two completely different shapes depending on mode. In Build mode it's an editor with tabs (stage / prompt / result). In Active or History it's a read-only log viewer — header with connection + configs, then an executions list (attempts, retries, map iterations)."
      dartImport="lib/widgets/stage_drawer/{editor,job_log}_view.dart"
    >
      <SubBlock label="Build mode · editor · stage tab">
        <Stage padding={0} height={580}>
          <Constrained width={460} height={580} allowScroll>
            <StageDrawer stage={workerStage} status={null} view="builder" onClose={() => {}} />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="Active mode · log viewer · execution expanded · failed attempt + running attempt">
        <Stage padding={0} height={620}>
          <Constrained width={460} height={620} allowScroll>
            <StageDrawer stage={workerStage} status={{ status: "running", progress: 0.62, tokens: 38402, durMs: 0 }} view="job" onClose={() => {}} />
          </Constrained>
        </Stage>

        <div style={{ height: 18 }} />
        <H3>tokens</H3>
        <TokensList tokens={[
          { name: "width",         value: "CompDrawer.width · 460" },
          { name: "header.height", value: "CompDrawer.headerHeight · 56" },
          { name: "tabs.height",   value: "CompDrawer.tabsHeight · 38 (editor only)" },
          { name: "footer.height", value: "CompDrawer.footerHeight · 48 (editor only)" },
          { name: "bg",            value: "palette.appShell · 1px left border · shadow-3 to the left" },
          { name: "field.gap",     value: "CompDrawer.fieldGap · 16" },
          { name: "execution row", value: "border palette.border1 · accent border when expanded" },
          { name: "rendered prompt", value: "AppType.mono · 12.5px · palette.bg1 · 1px palette.border2" },
        ]} />
      </SubBlock>

      <SubBlock label="behavior" last>
        <ul style={listStyle}>
          <li>Opens with a 240ms slide-in from the right (translateX + opacity).</li>
          <li>Sits as a flex sibling of the canvas+filmstrip column — opening it pushes those inward, never overlays.</li>
          <li>Vertical extent: below the header to the bottom of the viewport.</li>
          <li>Footer (Build mode only): duplicate / delete on the left, save on the right.</li>
          <li>Log viewer is fully read-only — no save/delete buttons exist in this mode.</li>
        </ul>
      </SubBlock>
    </Card>
  );
}

const listStyle = {
  margin: 0, paddingLeft: 18,
  fontSize: 12.5, lineHeight: 1.6,
  color: "var(--co-text-muted)",
};

// ════════════════════════════════════════════════════════════════════════
//  Snapshot filmstrip card
// ════════════════════════════════════════════════════════════════════════

function FilmstripCard() {
  return (
    <Card
      title="Snapshot filmstrip"
      description="Bottom strip in Active and History views. One card per stage execution. Each card shows status pip, kind badge (live/manual), duration + tokens + tool chips, and a body that varies by status: result preview (passed), error block (failed), or streaming + progress (running). Manual snapshots show their pinned note in italic accent text."
      dartImport="lib/widgets/filmstrip/snapshot_card.dart"
    >
      <SubBlock label="full strip — passed, failed, running, manual">
        <Stage padding={0} height={210}>
          <Constrained width={1080} height={208}>
            <Filmstrip snapshots={SNAPSHOTS} activeId="s5" onPick={() => {}} />
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="individual card states">
        <StatesGrid columns={2} items={[
          { label: "PASSED · result preview", children: <SingleSnap id="s0" /> },
          { label: "FAILED · error block",    children: <SingleSnap id="s3" /> },
          { label: "MANUAL · pinned + note",  children: <SingleSnap id="s4" /> },
          { label: "RUNNING · streaming + progress + live badge", children: <SingleSnap id="s5" /> },
        ]} />
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "width",       value: "CompFilmstrip.cardWidth · 268" },
          { name: "padding",     value: "CompFilmstrip.padding (14, 8, 14, 10)" },
          { name: "gap",         value: "CompFilmstrip.gap · 8" },
          { name: "bg",          value: "palette.surface · accent border + accent-soft glow when active" },
          { name: "result block",value: "palette.bg1 + 1px palette.border1 · clamp 3 lines" },
          { name: "error block", value: "palette.dangerSoft + 1px palette.danger 30% · code uppercase 10px" },
          { name: "streaming",   value: "palette.bg1 + 1px palette.accent · ▸ blink + progress bar" },
        ]} />
      </SubBlock>
    </Card>
  );
}

function SingleSnap({ id }) {
  const snap = SNAPSHOTS.find(s => s.id === id);
  if (!snap) return null;
  return (
    <Constrained width={268} height={185}>
      <div style={{ padding: 8 }}>
        <Filmstrip snapshots={[snap]} activeId={null} onPick={() => {}} />
      </div>
    </Constrained>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Runs table
// ════════════════════════════════════════════════════════════════════════

function RunsTableCard() {
  const [view, setView] = React.useState("grouped");
  return (
    <Card
      title="Runs table (History)"
      description="The default History surface — shown full-width with NO jobs sidebar when nothing is selected (the sidebar only appears once you drill into a run, as a job-to-job navigator). Mode badge in the header, status filter pills, a grouped/flat view toggle (same control as the jobs sidebar), then a 9-column table: status dot, run id, input, status tag, started, duration, tokens, cost, by. Grouped inserts a workflow header row before each group; flat is a plain list. No search yet."
      dartImport="lib/widgets/runs_table.dart"
      fullBleed
    >
      <Constrained width="100%" height={500} allowScroll>
        <RunsView
          jobs={JOBS_LOG.filter(j => ["passed","failed","cancelled"].includes(j.status))}
          onPick={() => {}} activeId={null}
          viewMode={view} onViewMode={setView}
        />
      </Constrained>
      <div style={{ padding: 18 }}>
        <H3>tokens</H3>
        <TokensList tokens={[
          { name: "row.padding",  value: "10px vertical · 14px horizontal" },
          { name: "header.font",  value: "AppType.mono · 10px · UPPERCASE · letterSpacing 0.06em" },
          { name: "header.color", value: "palette.textSubtle" },
          { name: "body.font",    value: "AppType.sans 12.5px · ids in mono" },
          { name: "view toggle",  value: "grouped ↔ flat · shared ViewToggle · sits after the filter pills, divider before" },
          { name: "group header", value: "colSpan 9 · bg-1 · workflow name · dot · count · grouped mode only" },
          { name: "row.hover",    value: "palette.surface" },
          { name: "row.active",   value: "palette.surface (sticky)" },
          { name: "filter pill",  value: "border-1 / surfaceRaised when active · counts in subtle text" },
        ]} />
      </div>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Graph nodes
// ════════════════════════════════════════════════════════════════════════

const DEMO_WORKER = {
  id: "demo_w", kind: "worker",
  label: "full_review",
  sub: "code quality · security",
  model: "sonnet",
  skills: ["git.diff", "code.review.semantic", "sec.semgrep"],
};

// A dot-grid background anchored so a grid dot lands exactly on (ax, ay) in the
// element's own coordinate space — used to show the node sitting on the canvas
// grid no matter how the scene is centered.
function dotField(ax, ay, size = 32) {
  return {
    backgroundImage: "radial-gradient(circle, var(--co-border-1) 1px, transparent 1.5px)",
    backgroundSize: `${size}px ${size}px`,
    backgroundPosition: `${ax - size / 2}px ${ay - size / 2}px`,
  };
}

function WNodeWrap({ stage, status, selected, density, grid }) {
  // 160×64 footprint = 5×2 grid cells. The worker body is one grid gap tall and
  // centered on the mid row, so its center line + both ends sit on grid dots.
  return (
    <div style={{ position: "relative", width: 160, height: 64, flexShrink: 0,
      ...(grid ? dotField(0, 32) : null) }}>
      <WorkerNode stage={stage} status={status || null} info={{ x: 0, y: 0 }}
        selected={!!selected} density={density || "default"} onClick={() => {}} />
    </div>
  );
}

function MiniNode({ x, y, w, h = 24, label }) {
  return (
    <g>
      <rect x={x} y={y} width={w} height={h} rx={7}
        fill="var(--co-bg-2)" stroke="var(--co-border-2)" strokeWidth={1} />
      <text x={x + w / 2} y={y + h / 2 + 3.5} textAnchor="middle"
        style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 600, fill: "var(--co-text-strong)" }}>
        {label}
      </text>
    </g>
  );
}

function MiniOpNode({ cx, cy, kind }) {
  const size = 24; // same height as the worker MiniNode body (h=24)
  const icon = kind === "join" ? "merge" : "forEach";
  return (
    <g>
      <rect x={cx - size / 2} y={cy - size / 2} width={size} height={size} rx={7}
        fill="var(--co-bg-3)" stroke="var(--co-border-3)" strokeWidth={1} />
      <g transform={`translate(${cx - 9}, ${cy - 9})`}>
        <Icon name={icon} size={18} color="var(--co-text-strong)" strokeWidth={1.8} />
      </g>
    </g>
  );
}

function ModifierDotPreview({ kind }) {
  const isForEach = kind === "forEach";
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 8 }}>
      {isForEach ? (
        <svg width={320} height={48} style={{ overflow: "visible" }}>
          <defs>
            <marker id="opArrowFe" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-3)" />
            </marker>
          </defs>
          <MiniNode x={4} y={12} w={88} label="full-review" />
          <line x1={92} y1={24} x2={123} y2={24} stroke="var(--co-fg-3)" strokeWidth={1.5} markerEnd="url(#opArrowFe)" />
          <MiniOpNode cx={140} cy={24} kind="map" />
          <line x1={157} y1={24} x2={214} y2={24} stroke="var(--co-fg-3)" strokeWidth={1.5} markerEnd="url(#opArrowFe)" />
          <MiniNode x={218} y={12} w={96} label="comment-file" />
        </svg>
      ) : (
        <svg width={320} height={96} style={{ overflow: "visible" }}>
          <defs>
            <marker id="opArrowJn" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
              <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-fg-3)" />
            </marker>
          </defs>
          <MiniNode x={4} y={2}  w={92} label="quick-review" />
          <MiniNode x={4} y={33} w={92} label="security-scan" />
          <MiniNode x={4} y={64} w={92} label="comment-file" />
          <line x1={96} y1={14} x2={158} y2={45} stroke="var(--co-fg-3)" strokeWidth={1.5} />
          <line x1={96} y1={45} x2={158} y2={45} stroke="var(--co-fg-3)" strokeWidth={1.5} />
          <line x1={96} y1={76} x2={158} y2={45} stroke="var(--co-fg-3)" strokeWidth={1.5} />
          <MiniOpNode cx={172} cy={45} kind="join" />
          <line x1={189} y1={45} x2={232} y2={45} stroke="var(--co-fg-3)" strokeWidth={1.5} markerEnd="url(#opArrowJn)" />
          <MiniNode x={236} y={33} w={72} label="critic" />
        </svg>
      )}
      <div style={{ textAlign: "center" }}>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 600, color: "var(--co-text-strong)" }}>
          {isForEach ? "for-each node" : "join node"}
        </div>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)", marginTop: 2 }}>
          {isForEach ? "fans the source's output over a list" : "waits for N upstreams to converge"}
        </div>
      </div>
    </div>
  );
}

function FanContainerPreview({ open }) {
  const stage = {
    kind: "fan", label: "comment-files", over: "ingest.files",
    count: 7, concurrency: 8, joinMode: "all",
    body: { label: "comment-file", model: "haiku-4.5", skills: ["code.review.inline"] },
  };
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
      <div style={{ position: "relative", width: 184, height: 172 }}>
        <FanNode stage={stage} status={null} info={{ x: 12, y: 54 }} selected={false} view="builder" defaultOpen={open} onClick={() => {}} />
      </div>
      <div style={{ textAlign: "center" }}>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 600, color: "var(--co-text-strong)" }}>
          {open ? "expanded" : "collapsed"}
        </div>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)", marginTop: 2 }}>
          {open ? "reveals the per-item body" : "one node · ×7 over the list"}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Fan container — the expanded form is a modal workflow editor
//  Collapsed it is a single capsule node; expanding opens a centered modal
//  that hosts an editable internal-workflow canvas + a save / cancel /
//  undo-redo / settings toolbar.
// ════════════════════════════════════════════════════════════════════════

const FAN_EDITOR_STAGE = {
  kind: "fan", label: "comment-files", over: "ingest.files",
  count: 7, concurrency: 8, joinMode: "all", timeout: 600,
  body: { label: "comment-file", model: "haiku-4.5", skills: ["code.review.inline"] },
};

// The per-item body is a real worker node — identical component + geometry to
// the worker states above (160×32, 1 grid gap tall).
const FAN_BODY_STAGE = { id: "fan_body", kind: "worker", label: "comment-file" };

// File path the linked-file variant points at.
const FAN_FILE_REF = { path: "flows/comment-file.flow.yaml" };

const fanEditorChip = {
  display: "inline-flex", alignItems: "center", height: 19, padding: "0 7px",
  borderRadius: 999, fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 600,
  whiteSpace: "nowrap", letterSpacing: "0.01em",
};

// Square chrome button used in the modal toolbar (undo / redo / settings / close).
function FanToolBtn({ children, title, onClick, disabled, active }) {
  const [hov, setHov] = React.useState(false);
  return (
    <button type="button" title={title} onClick={onClick} disabled={disabled}
      onMouseEnter={() => setHov(true)} onMouseLeave={() => setHov(false)}
      style={{
        width: 30, height: 30, display: "inline-flex", alignItems: "center", justifyContent: "center",
        borderRadius: 8, padding: 0,
        background: active ? "var(--co-bg-4)" : (hov && !disabled) ? "var(--co-bg-3)" : "transparent",
        color: disabled ? "var(--co-text-disabled)" : active ? "var(--co-accent)" : "var(--co-text-muted)",
        border: "1px solid " + (active ? "color-mix(in oklab, var(--co-accent) 40%, transparent)" : "transparent"),
        cursor: disabled ? "not-allowed" : "pointer",
        transition: "background 140ms var(--co-ease-out), color 140ms, border-color 140ms",
      }}>{children}</button>
  );
}

const UndoSvg = () => (
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="M9 14 4 9l5-5" /><path d="M4 9h10.5a5.5 5.5 0 0 1 0 11H11" />
  </svg>
);
const RedoSvg = () => (
  <svg width="15" height="15" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
    <path d="m15 14 5-5-5-5" /><path d="M20 9H9.5a5.5 5.5 0 0 0 0 11H13" />
  </svg>
);

// One endpoint of the internal lane (fan-out source / fan-in sink).
function LaneEndpoint({ icon, label, sub }) {
  return (
    <div style={{ position: "relative", width: 36, flex: "0 0 auto" }}>
      <div style={{
        width: 36, height: 36, borderRadius: 10, display: "flex", alignItems: "center", justifyContent: "center",
        background: "var(--co-bg-3)", border: "1px solid var(--co-accent)", color: "var(--co-accent)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <Icon name={icon} size={18} />
      </div>
      <div style={{ position: "absolute", top: "calc(100% + 7px)", left: "50%", transform: "translateX(-50%)", textAlign: "center", whiteSpace: "nowrap" }}>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--co-text-subtle)" }}>{label}</div>
        <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-muted)", marginTop: 1 }}>{sub}</div>
      </div>
    </div>
  );
}

// The connector edge between lane items.
function LaneEdge() {
  return (
    <div style={{ flex: 1, minWidth: 26, height: 2, position: "relative", borderRadius: 2,
      background: "color-mix(in oklab, var(--co-accent) 50%, transparent)" }}>
      <span style={{ position: "absolute", left: -1, top: "50%", transform: "translateY(-50%)", width: 5, height: 5, borderRadius: 999, background: "var(--co-accent)" }} />
      <span style={{ position: "absolute", right: -7, top: "50%", transform: "translateY(-50%)", display: "flex", color: "var(--co-accent)" }}>
        <Icon name="chevRight" size={13} strokeWidth={2.4} />
      </span>
    </div>
  );
}

// The per-item body — the real worker node (160×32, 1 grid gap tall), so the
// body reads identically to every other worker node in the spec.
function EditorBodyNode() {
  return (
    <div style={{ position: "relative", width: 160, height: 64, flexShrink: 0 }}>
      <WorkerNode stage={FAN_BODY_STAGE} status={null} info={{ x: 0, y: 0 }} selected={false} density="default" onClick={() => {}} />
    </div>
  );
}

function FanSettingsField({ label, value }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 5 }}>
      <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--co-text-subtle)" }}>{label}</span>
      <div style={{ display: "flex", alignItems: "center", height: 30, padding: "0 10px", borderRadius: 8, background: "var(--co-bg-0)", border: "1px solid var(--co-border-2)",
        fontFamily: "var(--co-font-mono)", fontSize: 12, color: "var(--co-text-strong)" }}>{value}</div>
    </div>
  );
}

// The editor region: an internal-workflow canvas (hearth + dot grid) hosting
// the fan-out → body → fan-in lane, a zoom indicator, and an optional
// settings panel that slides in from the right.
function FanEditorRegion({ settingsOpen }) {
  return (
    <div style={{ display: "flex", minHeight: 256, borderTop: "1px solid var(--co-border-1)", borderBottom: "1px solid var(--co-border-1)" }}>
      <div style={{
        position: "relative", flex: 1, overflow: "hidden",
        background: "var(--co-grad-hearth)",
        backgroundColor: "var(--co-bg-0)",
        backgroundImage: "radial-gradient(circle, var(--co-border-1) 1px, transparent 1px)",
        backgroundSize: "32px 32px",
        backgroundPosition: "center",
      }}>
        <span style={{ position: "absolute", top: 10, left: 12, fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--co-text-subtle)" }}>internal workflow</span>

        <div style={{ display: "flex", alignItems: "center", gap: 0, padding: "0 26px", height: "100%" }}>
          <LaneEndpoint icon="forEach" label="fan-out" sub="ingest.files" />
          <LaneEdge />
          <EditorBodyNode />
          <LaneEdge />
          <LaneEndpoint icon="merge" label="fan-in" sub="→ results" />
        </div>

        {/* editor floating toolbar */}
        <div style={{ position: "absolute", left: "50%", bottom: 12, transform: "translateX(-50%)",
          display: "flex", alignItems: "center", gap: 4, padding: 4, borderRadius: 10,
          background: "color-mix(in oklab, var(--co-bg-1) 88%, transparent)", border: "1px solid var(--co-border-2)",
          backdropFilter: "blur(8px)", WebkitBackdropFilter: "blur(8px)", boxShadow: "var(--co-shadow-2)" }}>
          <span style={{ display: "inline-flex", alignItems: "center", height: 26, padding: "0 8px", fontFamily: "var(--co-font-mono)", fontSize: 11, color: "var(--co-text-subtle)" }}>100%</span>
        </div>
      </div>

      {settingsOpen && (
        <div style={{ width: 224, flex: "0 0 auto", borderLeft: "1px solid var(--co-border-1)", background: "var(--co-bg-1)", padding: 16, display: "flex", flexDirection: "column", gap: 14 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
            <Icon name="settings" size={14} color="var(--co-accent)" />
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, letterSpacing: "0.06em", textTransform: "uppercase", color: "var(--co-text-muted)", fontWeight: 600 }}>fan settings</span>
          </div>
          <FanSettingsField label="concurrency" value="8 parallel" />
          <FanSettingsField label="join mode" value="all" />
          <FanSettingsField label="per-item timeout" value="600s" />
          <FanSettingsField label="on item error" value="continue" />
        </div>
      )}
    </div>
  );
}

// File-linkage bar — the subworkflow can live in an external file or be a
// local-only graph. Linked → shows the path + an "open file" button;
// local-only → shows a "save to file" option.
function FanFileBar({ fileRef }) {
  const linked = !!fileRef;
  return (
    <div style={{ display: "flex", alignItems: "center", gap: 9, padding: "0 14px", height: 42,
      borderTop: "1px solid var(--co-border-1)",
      background: linked ? "color-mix(in oklab, var(--co-accent) 7%, var(--co-bg-2))" : "var(--co-bg-2)" }}>
      <Icon name="file" size={15} color={linked ? "var(--co-accent)" : "var(--co-text-subtle)"} />
      {linked ? (
        <>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-text-strong)", whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{fileRef.path}</span>
          <span style={{ ...fanEditorChip, height: 16, fontSize: 8.5, letterSpacing: "0.06em", textTransform: "uppercase",
            background: "color-mix(in oklab, var(--co-accent) 14%, transparent)", color: "var(--co-accent)", border: "1px solid color-mix(in oklab, var(--co-accent) 32%, transparent)" }}>linked file</span>
        </>
      ) : (
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-text-muted)", whiteSpace: "nowrap" }}>
          local subworkflow&nbsp;·&nbsp;<span style={{ color: "var(--co-text-subtle)" }}>not saved to a file</span>
        </span>
      )}
      <span style={{ flex: 1 }} />
      {linked
        ? <Button size="sm" variant="secondary" icon="fileOpen">open file</Button>
        : <Button size="sm" variant="secondary" icon="save">save to file</Button>}
    </div>
  );
}

// The modal panel itself — toolbar header, file bar, editor region, action footer.
function FanEditorPanel({ onClose, fileRef }) {
  const [hist, setHist] = React.useState(2);   // 0..2 — start at latest edit
  const [dirty, setDirty] = React.useState(false);
  const [settingsOpen, setSettingsOpen] = React.useState(false);
  const canUndo = hist > 0, canRedo = hist < 2;
  const onCancel = () => { if (onClose) onClose(); };
  return (
    <div style={{
      width: "100%", background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-2)", borderRadius: 18,
      boxShadow: "0 24px 64px rgba(0,0,0,0.55), inset 0 1px 0 color-mix(in oklab, var(--co-parchment) 14%, transparent)",
      overflow: "hidden", display: "flex", flexDirection: "column",
    }}>
      {/* toolbar header */}
      <div style={{ display: "flex", alignItems: "center", gap: 12, padding: "13px 14px", height: 60 }}>
        <div style={{ width: 32, height: 32, borderRadius: 9, flex: "0 0 auto", display: "flex", alignItems: "center", justifyContent: "center", background: "var(--co-grad-crust)", boxShadow: "0 3px 10px color-mix(in oklab, var(--co-accent) 32%, transparent)" }}>
          <Icon name="forEach" size={17} color="var(--co-accent-ink)" />
        </div>
        <div style={{ minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 7 }}>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 700, color: "var(--co-text-strong)", letterSpacing: "-0.01em", whiteSpace: "nowrap" }}>comment-files</span>
            <span style={{ ...fanEditorChip, height: 17, background: "color-mix(in oklab, var(--co-accent) 15%, transparent)", color: "var(--co-accent)", border: "1px solid color-mix(in oklab, var(--co-accent) 32%, transparent)" }}>×7</span>
          </div>
          <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text-subtle)", marginTop: 2, whiteSpace: "nowrap" }}>fan-out / fan-in · capsule reactor</div>
        </div>
        <span style={{ flex: 1 }} />
        <div style={{ display: "flex", alignItems: "center", gap: 2 }}>
          <FanToolBtn title="undo" disabled={!canUndo} onClick={() => { setHist(h => Math.max(0, h - 1)); setDirty(true); }}><UndoSvg /></FanToolBtn>
          <FanToolBtn title="redo" disabled={!canRedo} onClick={() => { setHist(h => Math.min(2, h + 1)); setDirty(true); }}><RedoSvg /></FanToolBtn>
          <span style={{ width: 1, height: 18, background: "var(--co-border-2)", margin: "0 5px" }} />
          <FanToolBtn title="settings" active={settingsOpen} onClick={() => setSettingsOpen(o => !o)}><Icon name="settings" size={16} /></FanToolBtn>
          <FanToolBtn title="close" onClick={onCancel}><Icon name="x" size={16} /></FanToolBtn>
        </div>
      </div>

      <FanFileBar fileRef={fileRef} />

      <FanEditorRegion settingsOpen={settingsOpen} />

      {/* action footer */}
      <div style={{ display: "flex", alignItems: "center", gap: 10, padding: "11px 14px", height: 58 }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, minWidth: 0, flexWrap: "wrap" }}>
          <span style={{ ...fanEditorChip, background: "var(--co-bg-3)", color: "var(--co-text-muted)", border: "1px solid var(--co-border-2)" }}>over ingest.files</span>
          <span style={{ ...fanEditorChip, background: "var(--co-bg-3)", color: "var(--co-text-muted)", border: "1px solid var(--co-border-2)" }}>8 parallel</span>
          <span style={{ ...fanEditorChip, background: "var(--co-bg-3)", color: "var(--co-text-muted)", border: "1px solid var(--co-border-2)" }}>join · all</span>
          {dirty && (
            <span style={{ display: "inline-flex", alignItems: "center", gap: 5, fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-warning)" }}>
              <span style={{ width: 6, height: 6, borderRadius: 999, background: "var(--co-warning)" }} /> edited
            </span>
          )}
        </div>
        <span style={{ flex: 1 }} />
        <Button variant="ghost" onClick={onCancel}>cancel</Button>
        <Button variant="primary" icon="check" onClick={() => setDirty(false)}>save changes</Button>
      </div>
    </div>
  );
}

// Collapsed capsule — the single canvas node, shown deselected. 160×64 =
// exactly 2 grid gaps tall (the worker is 1 gap; the fan capsule is double),
// sitting on the 32px grid. Toasted header: deselected it bakes down to a
// muted cocoa-orange over a neutral shell; the full crust gradient + accent
// outline appear only on selection (or while running). Connectors are the
// standard worker affordances — arrow in at the left border, dot output
// handle on the right. Its chevron opens the modal.
function FanCollapsedTrigger({ onExpand }) {
  return (
    <div style={{ position: "relative", width: 224, height: 128, ...dotField(32, 64) }}>
      <div style={{
        position: "absolute", left: 32, top: 32, width: 160, height: 64, borderRadius: 13, overflow: "hidden",
        background: "var(--co-bg-2)", border: "1px solid var(--co-border-2)",
        boxShadow: "var(--co-shadow-1)",
      }}>
        <div style={{ display: "flex", alignItems: "center", gap: 6, padding: "0 9px", height: 26, background: "linear-gradient(135deg, color-mix(in oklab, var(--co-accent) 32%, var(--co-bg-4)) 0%, color-mix(in oklab, var(--co-accent) 18%, var(--co-bg-3)) 100%)" }}>
          <Icon name="forEach" size={13} color="var(--co-accent-200)" />
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, fontWeight: 700, color: "var(--co-accent-200)", letterSpacing: "0.02em" }}>map</span>
          <span style={{ flex: 1 }} />
          <span style={{ display: "inline-flex", alignItems: "center", height: 16, padding: "0 6px", borderRadius: 999, background: "rgba(0,0,0,0.22)", color: "var(--co-accent-200)", fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 700 }}>×7</span>
          <button type="button" onClick={onExpand} title="expand to editor"
            style={{ display: "flex", alignItems: "center", justifyContent: "center", width: 16, height: 16, border: "none", background: "transparent", color: "var(--co-accent-200)", cursor: "pointer", padding: 0 }}>
            <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.6" strokeLinecap="round" strokeLinejoin="round"><polyline points="9,6 15,12 9,18" /></svg>
          </button>
        </div>
        <div style={{ padding: "0 11px", height: 38, display: "flex", flexDirection: "column", justifyContent: "center", gap: 1 }}>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 13, fontWeight: 600, color: "var(--co-text-strong)" }}>comment-file</span>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>over ingest.files</span>
        </div>
      </div>
    </div>
  );
}

// Full-screen overlay version (the live, interactive modal).
function FanEditorOverlay({ onClose, fileRef }) {
  React.useEffect(() => {
    const h = (e) => { if (e.key === "Escape") onClose(); };
    window.addEventListener("keydown", h);
    return () => window.removeEventListener("keydown", h);
  }, [onClose]);
  return (
    <div onClick={onClose} style={{
      position: "fixed", inset: 0, zIndex: 9000, display: "flex", alignItems: "center", justifyContent: "center", padding: 24,
      background: "rgba(10,6,3,0.62)", backdropFilter: "blur(6px)", WebkitBackdropFilter: "blur(6px)",
      animation: "co-slide-in 180ms var(--co-ease-out)",
    }}>
      <div onClick={(e) => e.stopPropagation()} style={{ width: 760, maxWidth: "94vw" }}>
        <FanEditorPanel onClose={onClose} fileRef={fileRef} />
      </div>
    </div>
  );
}

// A static specimen of the modal as it sits over the dimmed canvas.
function FanModalSpecimen({ fileRef, label }) {
  return (
    <div style={{ position: "relative", marginTop: 14, borderRadius: 12, overflow: "hidden", border: "1px solid var(--co-border-1)" }}>
      <div style={{ position: "absolute", inset: 0, background: "var(--co-grad-hearth)", backgroundColor: "var(--co-bg-0)" }} />
      <div style={{ position: "absolute", inset: 0, background: "rgba(8,5,3,0.5)" }} />
      <div style={{ position: "relative", padding: "34px 22px 30px", display: "flex", justifyContent: "center" }}>
        <div style={{ width: "100%", maxWidth: 740 }}>
          <FanEditorPanel onClose={() => {}} fileRef={fileRef} />
        </div>
      </div>
      <span style={{ position: "absolute", top: 10, left: 12, fontFamily: "var(--co-font-mono)", fontSize: 9, letterSpacing: "0.08em", textTransform: "uppercase", color: "var(--co-text-subtle)" }}>{label}</span>
    </div>
  );
}

// The SubBlock body: collapsed trigger (opens the live overlay) + two static
// specimens of the modal — one linked to an external file, one local-only.
function FanContainerBlock() {
  const [open, setOpen] = React.useState(false);
  return (
    <SubBlock label="fan container · expand → workflow editor modal">
      <Stage padding={24} height={224} bg="var(--co-bg-0)">
        <div style={{ display: "flex", flexDirection: "column", alignItems: "center", gap: 10 }}>
          <FanCollapsedTrigger onExpand={() => setOpen(true)} />
          <div style={{ textAlign: "center" }}>
            <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, fontWeight: 600, color: "var(--co-text-strong)" }}>collapsed · one node · 160×64 (2 grid gaps)</div>
            <div style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)", marginTop: 2 }}>deselected · toasted header · click the chevron to open the editor</div>
          </div>
        </div>
      </Stage>
      {open && <FanEditorOverlay onClose={() => setOpen(false)} fileRef={FAN_FILE_REF} />}

      <FanModalSpecimen fileRef={FAN_FILE_REF} label="expanded · modal editor — linked to an external file" />
      <FanModalSpecimen fileRef={null} label="expanded · modal editor — local-only subworkflow" />

      <p style={{ margin: "12px 2px 0", fontSize: 11.5, lineHeight: 1.5, color: "var(--co-text-subtle)" }}>
        The <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>fan container</strong> collapses to a single capsule node — <span style={{ fontFamily: "var(--co-font-mono)" }}>160×64</span>, exactly two grid gaps tall (the worker is one), sitting on the 32px grid with the standard worker connectors — arrow in at the left border, dot output handle on the right. Deselected it wears a <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>toasted header</strong> (muted cocoa-orange) over a neutral shell; selection re-ignites the full crust gradient and adds the accent outline + halo, so accent chrome stays a selection-only signal. Expanding opens a <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>centered modal</strong> over the dimmed canvas. Its <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>internal-workflow region</strong> hosts the fan-out source, the per-item body, and the fan-in sink; the body is the <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>same worker node</strong> used everywhere else (160×32). The contained subworkflow can live in its own file: a <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>file bar</strong> shows the linked path with an <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>open file</strong> button, or — for a <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>local-only</strong> graph — offers <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>save to file</strong>. The toolbar carries <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>undo / redo</strong> and <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>settings</strong> (concurrency, join mode, timeouts slide in from the right); the footer has <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>cancel</strong> and a primary <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>save changes</strong>. Edits are staged and only committed on save; cancel or <span style={{ fontFamily: "var(--co-font-mono)" }}>Esc</span> discards them.
      </p>
    </SubBlock>
  );
}

function GraphNodesCard() {
  return (
    <Card
      title="Graph nodes"
      description="Two node shapes live on the canvas. Worker nodes are compact rounded rectangles holding a prompt, skills, and config. The fan container is a toasted-header capsule that fans a list out over its body and fans every result back in — replacing the old for-each and join operators with a single node that collapses to one node and expands into a modal workflow editor. It wires in and out with the same arrow-input and dot-output connectors as a worker."
      dartImport="lib/widgets/canvas/worker_node.dart · fan_node.dart"
    >
      <SubBlock label="worker node · all states · 160×32px (1 grid gap tall)">
        <StatesGrid columns={4} items={[
          { label: "default",                 children: <WNodeWrap stage={DEMO_WORKER} grid /> },
          { label: "selected",                children: <WNodeWrap stage={DEMO_WORKER} selected grid /> },
          { label: "running · progress",      children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "running", progress: 0.55 }} grid /> },
          { label: "running · spinner",       children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "running" }} grid /> },
          { label: "queued",                  children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "queued" }} grid /> },
          { label: "passed",                  children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "passed" }} grid /> },
          { label: "failed",                  children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "failed" }} grid /> },
          { label: "selected · passed",       children: <WNodeWrap stage={DEMO_WORKER} status={{ status: "passed" }} selected grid /> },
        ]} />
        <p style={{ margin: "12px 2px 0", fontSize: 11.5, lineHeight: 1.5, color: "var(--co-text-subtle)" }}>
          <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>Compact + grid-locked.</strong> The worker body is a rounded rectangle one grid gap tall (32px), centered on a grid row — so its center line, both ends, and the output dot on its right edge all sit on grid dots. It shows only its title; run status lives in the solid pill straddling the top border (passed / failed / running / skipped), the colored 3px left rail, and (when determinate) a 2px progress strip. <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>Running vs selected</strong> never read alike: selected is a static crisp accent ring; running is a breathing accent halo plus the running pill with a rotating ring spinner. A selected node also surfaces the output-handle dot, and a long-press / right-click opens its context menu. See <strong style={{ color: "var(--co-text-muted)", fontWeight: 600 }}>Builder affordances</strong> below.
        </p>
      </SubBlock>

      <FanContainerBlock />

      <SubBlock label="anatomy · worker node">
        <StageSplit
          left={<WNodeWrap stage={DEMO_WORKER} status={{ status: "running", progress: 0.62 }} />}
          right={(
            <AnatomyLegend items={[
              { label: "status rail",   desc: "3px left edge · colored by run status · full height · follows the rounded-rect corners" },
              { label: "status tag",    desc: "top-right · solid-fill pill straddling the top border · passed / failed / running / skipped · label centered on the border line" },
              { label: "label",         desc: "mono 14px · weight 600 · centered · truncated with ellipsis" },
              { label: "progress bar",  desc: "2px bottom strip · accent gradient · determinate running only" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "node.cell",         value: "64px tall layout cell · shared vertical center for all nodes" },
          { name: "worker.size",       value: "160 × 32px body · rounded rectangle (1 grid gap tall, centered on the cell)" },
          { name: "worker.shape",      value: "borderRadius: 10 · rounded rectangle" },
          { name: "grid.lock",         value: "body center line + both ends + output dot all land on 32px grid dots" },
          { name: "fan.size",          value: "160 × 64px collapsed · exactly 2 grid gaps tall (worker is 1) · sits on the 32px grid · no edge connectors" },
          { name: "fan.header",        value: "26px · crustGradient · forEach icon + 'map' + count chip + expand chevron (opens modal)" },
          { name: "fan.expand",        value: "chevron opens a centered modal editor — no longer grows the node in place" },
          { name: "modal.panel",       value: "760px max · bg1 · 1px border2 · radius 18 · shadow 0 24 64 / 0.55 + 1px parchment inner highlight" },
          { name: "modal.scrim",       value: "rgba(10,6,3,0.62) + 6px backdrop blur · co-slide-in 180ms entry · Esc / scrim-click = cancel" },
          { name: "modal.toolbar",     value: "60px header · crustGradient icon tile + title + ×count chip · right: undo / redo · divider · settings · close (30px square btns)" },
          { name: "modal.fileBar",     value: "42px · linked → file icon + path + 'linked file' chip + open-file btn (accent-tinted bg) · local-only → muted 'not saved to a file' + save-to-file btn" },
          { name: "modal.editor",      value: "internal-workflow canvas · hearth + 32px dot grid · fan-out → body → fan-in lane · floating add-stage / 100% bar" },
          { name: "modal.body",        value: "the per-item body is the same WorkerNode (160 × 32px) used in the worker states — identical component + geometry" },
          { name: "modal.settings",    value: "224px right panel · slides in on settings toggle · concurrency / join mode / per-item timeout / on-error" },
          { name: "modal.footer",      value: "58px · context chips (over <list> · N parallel · join · mode) + 'edited' dot · ghost cancel + primary save changes" },
          { name: "label.padding",     value: "0 10px horizontal · text centered" },
          { name: "bg.default",        value: "palette.loafGradient" },
          { name: "bg.running",        value: "accent 12% mix into bg2 → bg2 at 70%" },
          { name: "border.default",    value: "1px palette.border2" },
          { name: "border.selected",   value: "1px accent · outer: 1px accent + 4px accent 22% + shadow-1" },
          { name: "halo.running",      value: "breathing glow · co-node-running-glow 1.7s ease-in-out · NOT the static selected ring" },
          { name: "statusTag",        value: "solid pill in top-right slot · h 16px · top -8 (centered on border) · mono 9px/600 · running adds a co-spin 0.8s ring · same solid treatment for passed / failed / skipped" },
          { name: "statusRail.width",  value: "3px · colorKeyed to run status" },
          { name: "label.font",        value: "AppType.mono · 14px · weight 600" },
          { name: "progressBar",       value: "h 2px · bottom 6px · l/r 12px · palette.crustGradient · determinate running only" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Graph edges
// ════════════════════════════════════════════════════════════════════════

function EdgeSvg({ id, d, stroke, strokeWidth, strokeDasharray, opacity, label }) {
  const markerId = `ea-${id}`;
  const mx = 190, my = 50;
  return (
    <svg width={380} height={100} style={{ overflow: "visible", display: "block" }}>
      <defs>
        <marker id={markerId} viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
          <path d="M 0 0 L 10 5 L 0 10 z" fill={stroke || "var(--co-fg-3)"} />
        </marker>
      </defs>
      <path d={d} fill="none" stroke={stroke || "var(--co-fg-3)"}
        strokeWidth={strokeWidth || 1.5} strokeDasharray={strokeDasharray || "0"}
        markerEnd={`url(#${markerId})`} opacity={opacity || 1} />
      {label && (
        <g transform={`translate(${mx} ${my})`}>
          <rect x={-label.length * 3.6 - 6} y={-9} width={label.length * 7.2 + 12} height={18} rx={9}
            fill="var(--co-bg-3)" stroke="var(--co-border-2)" strokeWidth={1} />
          <text x={0} y={4} textAnchor="middle"
            style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, fill: "var(--co-fg-2)", fontWeight: 500 }}>
            {label}
          </text>
        </g>
      )}
    </svg>
  );
}

function GraphEdgesCard() {
  const a = { x: 20, y: 30 }, b = { x: 360, y: 70 };
  const curvedD   = `M ${a.x} ${a.y} C ${a.x+120} ${a.y}, ${b.x-120} ${b.y}, ${b.x} ${b.y}`;
  const orthoD    = `M ${a.x} ${a.y} L ${a.x} 50 L ${b.x} 50 L ${b.x} ${b.y}`;
  const straightD = `M ${a.x} ${a.y} L ${b.x} ${b.y}`;

  return (
    <Card
      title="Graph edges"
      description="SVG cubic beziers connect nodes. Three curve styles, four run-state appearances, optional case labels on routing branches, and animated flow tokens on active edges."
      dartImport="lib/widgets/canvas/edge_painter.dart"
    >
      <SubBlock label="edge styles">
        <StatesGrid columns={1} items={[
          { label: "curved (default) · c = max(40, |dx| × 0.5)", children: <EdgeSvg id="c0" d={curvedD} /> },
          { label: "orthogonal · 3-segment L-routed",             children: <EdgeSvg id="c1" d={orthoD} /> },
          { label: "straight · direct line",                       children: <EdgeSvg id="c2" d={straightD} /> },
        ]} />
      </SubBlock>

      <SubBlock label="edge states (curved style)">
        <StatesGrid columns={2} items={[
          { label: "design / done · solid fg3 · 1.5px",          children: <EdgeSvg id="s0" d={curvedD} /> },
          { label: "active · accent · 2px",                       children: <EdgeSvg id="s1" d={curvedD} stroke="var(--co-accent)" strokeWidth={2} /> },
          { label: "pending · dashed 4 4 · fg4 · opacity 0.6",    children: <EdgeSvg id="s2" d={curvedD} strokeDasharray="4 4" stroke="var(--co-fg-4)" opacity={0.6} /> },
          { label: "skipped · dashed 2 5 · fg4 · opacity 0.35",   children: <EdgeSvg id="s3" d={curvedD} strokeDasharray="2 5" stroke="var(--co-fg-4)" opacity={0.35} /> },
        ]} />
      </SubBlock>

      <SubBlock label="case label · routing branch identifier · midpoint pill">
        <Stage padding={20} height={120}>
          <EdgeSvg id="lbl" d={curvedD} label="passed" />
        </Stage>
      </SubBlock>

      <SubBlock label="flow tokens · 3 accent dots animated along active edge">
        <Stage padding={20} height={120}>
          <svg width={380} height={100} style={{ overflow: "visible", display: "block" }}>
            <defs>
              <marker id="ea-flow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
                <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-accent)" />
              </marker>
            </defs>
            <path d={curvedD} fill="none" stroke="var(--co-accent)" strokeWidth={2} markerEnd="url(#ea-flow)" />
            {[0, 0.33, 0.66].map((o, i) => (
              <circle key={i} r={3.2} fill="var(--co-accent)">
                <animateMotion dur="2s" repeatCount="indefinite" begin={`${-o * 2}s`} path={curvedD} />
              </circle>
            ))}
          </svg>
        </Stage>
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "strokeWidth.default",  value: "1.5px" },
          { name: "strokeWidth.active",   value: "2px" },
          { name: "color.design/done",    value: "palette.fg3" },
          { name: "color.active",         value: "accent.accent" },
          { name: "color.pending",        value: "palette.fg4 · opacity 0.6 · dash 4 4" },
          { name: "color.skipped",        value: "palette.fg4 · opacity 0.35 · dash 2 5" },
          { name: "arrow",                value: "SVG marker · viewBox 10×10 · 6×6 rendered" },
          { name: "caseLabel.bg",         value: "palette.bg3 + 1px border2 · radius 9" },
          { name: "caseLabel.font",       value: "AppType.mono · 10px · weight 500" },
          { name: "flowToken.r",          value: "3.2px · accent fill · 3 dots · staggered 0.33s apart" },
          { name: "controlPoint",         value: "c = max(40, |dx| × 0.5) horizontal · |dy| × 0.5 vertical" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Graph canvas viewport
// ════════════════════════════════════════════════════════════════════════

function GraphCanvasCard() {
  return (
    <Card
      title="Graph canvas"
      description="Infinite pan + pinch-zoom viewport. Holds nodes, SVG edges, and builder overlays. Three layout algorithms: graph (authored positions), swimlane (column/lane grid), tree (depth/breadth grid). Zoom range 0.35×–2.0× with fit-to-nodes."
      dartImport="lib/widgets/canvas/graph_canvas.dart"
    >
      <SubBlock label="canvas · builder mode · graph layout · dot grid · zoom controls">
        <Stage padding={0} height={440}>
          <Constrained width="100%" height={440}>
            <div style={{ display: "flex", flexDirection: "column", width: "100%", height: "100%" }}>
              <Canvas workflow={WORKFLOW} job={null} view="builder"
                selectedId={null} onSelect={() => {}}
                canvasStyle="graph" edgeStyle="curved" density="default"
                inflightAnim="tokens" drawerOpen={false} />
            </div>
          </Constrained>
        </Stage>
      </SubBlock>

      <SubBlock label="layout modes">
        <StatesGrid columns={2} items={[
          { label: "swimlane · left→right columns + lanes", children: (
            <Constrained width={320} height={260}>
              <div style={{ display: "flex", flexDirection: "column", width: "100%", height: "100%" }}>
                <Canvas workflow={WORKFLOW} job={null} view="builder"
                  selectedId={null} onSelect={() => {}}
                  canvasStyle="swimlane" edgeStyle="curved" density="compact"
                  inflightAnim="off" drawerOpen={false} />
              </div>
            </Constrained>
          )},
          { label: "tree · top→down depth rows", children: (
            <Constrained width={320} height={260}>
              <div style={{ display: "flex", flexDirection: "column", width: "100%", height: "100%" }}>
                <Canvas workflow={WORKFLOW} job={null} view="builder"
                  selectedId={null} onSelect={() => {}}
                  canvasStyle="tree" edgeStyle="curved" density="compact"
                  inflightAnim="off" drawerOpen={false} />
              </div>
            </Constrained>
          )},
        ]} />
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "bg",                value: "palette.hearthGradient (canvas fill)" },
          { name: "dotGrid.size",      value: "32 × zoom px · half the node height · dots align to node tops & centers · border2 · opacity 0.35" },
          { name: "zoom.range",        value: "0.35× – 2.0× · default: auto-fit to node bounding box" },
          { name: "zoomControl.bg",    value: "palette.bg2 · 1px border1 · radius 8 · shadow-2 · bottom-left" },
          { name: "zoomControl.btn",   value: "22×22px · mono 13px · transparent bg · hover bg3" },
          { name: "layoutBadge",       value: "mono 10px · palette.textSubtle · bottom-right · radius 8" },
          { name: "pan",               value: "drag on canvas background · mousedown away from nodes" },
          { name: "zoom.gesture",      value: "ctrl/cmd+wheel → scale · plain wheel → pan x/y" },
          { name: "refit",             value: "bbox of all node positions · padding 40px · max zoom 0.9" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Builder affordances
// ════════════════════════════════════════════════════════════════════════

const PICKER_TYPES = [
  { kind: "worker", label: "worker",   icon: "zap",       desc: "skills · prompt · result" },
  { kind: "branch", label: "branch",   icon: "gitBranch", desc: "conditional routing" },
  { kind: "fan",    label: "fan",      icon: "forEach",   desc: "fan-out a list, fan-in results" },
];

function OperatorPickerMock() {
  const [hovered, setHovered] = React.useState(null);
  return (
    <div style={{
      width: 240,
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-2)",
      borderRadius: 8,
      boxShadow: "var(--co-shadow-3)",
      overflow: "hidden",
    }}>
      <div style={{
        padding: "8px 10px 6px",
        borderBottom: "1px solid var(--co-border-1)",
        display: "flex", alignItems: "center", justifyContent: "space-between",
      }}>
        <span style={{
          fontFamily: "var(--co-font-mono)", fontSize: 10,
          letterSpacing: "0.08em", textTransform: "uppercase",
          color: "var(--co-text-subtle)", fontWeight: 500,
        }}>add next stage</span>
        <Icon name="x" size={10} color="var(--co-text-subtle)" />
      </div>
      <div style={{ padding: 4 }}>
        {PICKER_TYPES.map(t => (
          <div key={t.kind}
            onMouseEnter={() => setHovered(t.kind)}
            onMouseLeave={() => setHovered(null)}
            style={{
              display: "grid", gridTemplateColumns: "22px 1fr",
              alignItems: "center", gap: 8,
              padding: "6px 8px", borderRadius: 5, cursor: "pointer",
              background: hovered === t.kind ? "var(--co-bg-3)" : "transparent",
            }}>
            <span style={{
              width: 22, height: 22, borderRadius: 5,
              background: t.kind === "worker" ? "color-mix(in oklab, var(--co-accent) 14%, var(--co-bg-3))" : "var(--co-bg-3)",
              border: "1px solid var(--co-border-2)",
              display: "flex", alignItems: "center", justifyContent: "center",
              color: t.kind === "worker" ? "var(--co-accent)" : "var(--co-fg-2)",
            }}>
              <Icon name={t.icon} size={11} color="currentColor" />
            </span>
            <span style={{ display: "flex", flexDirection: "column", lineHeight: 1.2 }}>
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-text-strong)", fontWeight: 500 }}>{t.label}</span>
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>{t.desc}</span>
            </span>
          </div>
        ))}
      </div>
    </div>
  );
}

// ── in-situ affordance scenes ───────────────────────────────────────────
// Each affordance is shown positioned on a real node / edge exactly where it
// renders in the live BuilderOverlay, so the "where" is unambiguous.

const AFF_NODE_W = 160;
const AFF_NODE_H = 64;

const DEMO_WORKER2 = {
  id: "demo_w2", kind: "worker",
  label: "post_review",
  sub: "summarize · comment",
  model: "haiku",
  skills: ["pr.summarize", "git.comment"],
};

// reusable affordance visuals (shared by every scene) ----------------------
function HandleDot() {
  return (
    <div style={{
      width: 12, height: 12, borderRadius: 999,
      background: "var(--co-accent)",
      border: "2px solid var(--co-bg-1)",
      boxShadow: "0 0 0 1px var(--co-accent), 0 0 8px color-mix(in oklab, var(--co-accent) 50%, transparent)",
      flexShrink: 0,
    }} />
  );
}

function EdgeInsertBtn() {
  return (
    <button type="button" style={{
      width: 24, height: 24, padding: 0, borderRadius: 999,
      background: "var(--co-accent)", border: "2px solid var(--co-bg-1)",
      boxShadow: "0 0 0 1px var(--co-accent), 0 2px 8px rgba(0,0,0,0.4)",
      color: "var(--co-accent-ink)", display: "flex", alignItems: "center", justifyContent: "center",
      fontFamily: "var(--co-font-mono)", fontSize: 14, fontWeight: 700, cursor: "pointer", lineHeight: 1,
    }}>+</button>
  );
}

function EdgeDeleteBtn() {
  return (
    <button type="button" style={{
      width: 20, height: 20, padding: 0, borderRadius: 999,
      background: "var(--co-bg-1)", border: "1px solid var(--co-danger)",
      color: "var(--co-danger)", display: "flex", alignItems: "center", justifyContent: "center", cursor: "pointer",
    }}><Icon name="x" size={10} color="currentColor" /></button>
  );
}

// Output handle — a SINGLE solid dot centered on the node's border. On an
// iPad-first / touch UI a single target is more reliable than two adjacent
// hit areas, so the one dot carries both gestures: tap = add downstream,
// drag = wire a connection.
function HandleOnBorder({ borderX, cy }) {
  return (
    <div style={{ position: "absolute", left: borderX, top: cy, transform: "translate(-50%, -50%)" }}>
      <HandleDot />
    </div>
  );
}

// Context menu — invoked by long-press (touch) or right-click (mouse) on a
// selected node. No floating button: the menu opens at the press point.
function MiniContextMenu() {
  return (
    <div style={{
      minWidth: 196,
      background: "var(--co-bg-1)", border: "1px solid var(--co-border-2)",
      borderRadius: 8, boxShadow: "var(--co-shadow-3)", padding: 4,
      whiteSpace: "nowrap",
    }}>
      <MiniMenuItem icon="copy" label="duplicate" desc="clone this node downstream" />
      <MiniMenuItem icon="collapseLink" label="remove + collapse" desc="delete & rewire parent → child" />
      <span style={{ display: "block", height: 1, margin: "4px 6px", background: "var(--co-border-1)" }} />
      <MiniMenuItem icon="x" label="delete node" desc="removes its connections too" danger />
    </div>
  );
}

// The point a long-press / right-click landed on — a small accent dot with a
// soft halo ring, sitting at the menu's anchor corner.
function PressPoint() {
  return (
    <>
      <div style={{
        position: "absolute", left: 0, top: 0, transform: "translate(-50%, -50%)",
        width: 32, height: 32, borderRadius: 999,
        border: "1.5px solid var(--co-accent)", opacity: 0.32,
      }} />
      <div style={{
        position: "absolute", left: 0, top: 0, transform: "translate(-50%, -50%)",
        width: 11, height: 11, borderRadius: 999,
        background: "var(--co-accent)",
        boxShadow: "0 0 0 4px color-mix(in oklab, var(--co-accent) 22%, transparent)",
      }} />
    </>
  );
}

function MiniMenuItem({ icon, label, desc, danger }) {
  return (
    <div style={{
      width: "100%",
      display: "grid", gridTemplateColumns: "20px 1fr", alignItems: "center", gap: 9,
      padding: "6px 8px", borderRadius: 5,
      color: danger ? "var(--co-danger)" : "var(--co-text)",
    }}>
      <span style={{ display: "flex", alignItems: "center", justifyContent: "center" }}>
        <Icon name={icon} size={14} color="currentColor" />
      </span>
      <span style={{ display: "flex", flexDirection: "column", lineHeight: 1.25 }}>
        <span style={{ fontFamily: "var(--co-font-sans)", fontSize: 12, fontWeight: 500 }}>{label}</span>
        <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: danger ? "color-mix(in oklab, var(--co-danger) 70%, var(--co-text-subtle))" : "var(--co-text-subtle)" }}>{desc}</span>
      </span>
    </div>
  );
}

// "when / where / action" descriptor shown beside each scene ---------------
function WhenWhere({ rows }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 11 }}>
      {rows.map((r, i) => (
        <div key={i} style={{ display: "grid", gridTemplateColumns: "58px 1fr", gap: 10, alignItems: "baseline" }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 9.5, fontWeight: 600,
            letterSpacing: "0.08em", textTransform: "uppercase",
            color: "var(--co-accent)", paddingTop: 1,
          }}>{r.k}</span>
          <span style={{ fontSize: 12.5, lineHeight: 1.45, color: "var(--co-text-muted)" }}>{r.v}</span>
        </div>
      ))}
    </div>
  );
}

// scenes -------------------------------------------------------------------
function OutputHandleScene() {
  const nx = 22, ny = 22;
  const rightX = nx + AFF_NODE_W;
  const cy = ny + AFF_NODE_H / 2;
  // Grid anchored to the node so the dots fall on the body's center line and
  // both ends — the output dot (right-edge midpoint) lands on a grid dot.
  return (
    <div style={{ position: "relative", width: 300, height: 124, ...dotField(nx, cy) }}>
      <WorkerNode stage={DEMO_WORKER} status={null} info={{ x: nx, y: ny }} selected density="default" onClick={() => {}} />
      <HandleOnBorder borderX={rightX} cy={cy} />
    </div>
  );
}

function ToolbarScene() {
  const nx = 28, ny = 22;
  const cx = nx + AFF_NODE_W / 2;       // node center x
  const bodyCy = ny + AFF_NODE_H / 2;   // worker body center y
  // The press lands on the node body; the menu opens from that point, flowing
  // down and to the right — exactly where a right-click / long-press would.
  const pressX = cx;
  const pressY = bodyCy;
  return (
    <div style={{ position: "relative", width: 320, height: 200 }}>
      <WorkerNode stage={DEMO_WORKER} status={null} info={{ x: nx, y: ny }} selected density="default" onClick={() => {}} />
      {/* context menu emanates from the press point */}
      <div style={{ position: "absolute", left: pressX + 6, top: pressY + 6 }}>
        <MiniContextMenu />
      </div>
      {/* the long-press / right-click point, drawn on top at the anchor corner */}
      <div style={{ position: "absolute", left: pressX, top: pressY }}>
        <PressPoint />
      </div>
    </div>
  );
}

function EdgeScene() {
  const ay = 22;
  const aR = AFF_NODE_W;       // parent node right edge (node A at x = 0)
  const bX = 300;             // child node left edge — widened so the + (on the
                              // parent border) and the × (edge center) sit well apart
  const cy = ay + AFF_NODE_H / 2;
  const midX = (aR + bX) / 2; // center of the connection
  const W = bX + AFF_NODE_W + 8;
  const d = `M ${aR} ${cy} C ${aR + 28} ${cy}, ${bX - 28} ${cy}, ${bX} ${cy}`;
  return (
    <div style={{ position: "relative", width: W, height: 124 }}>
      <svg width={W} height={124} style={{ position: "absolute", inset: 0, overflow: "visible" }}>
        <defs>
          <marker id="aff-edge-arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
            <path d="M 0 0 L 10 5 L 0 10 z" fill="var(--co-accent)" />
          </marker>
        </defs>
        <path d={d} fill="none" stroke="var(--co-accent)" strokeWidth={2} markerEnd="url(#aff-edge-arrow)" />
      </svg>
      <WorkerNode stage={DEMO_WORKER}  status={null} info={{ x: 0,  y: ay }} selected density="default" onClick={() => {}} />
      <WorkerNode stage={DEMO_WORKER2} status={null} info={{ x: bX, y: ay }} density="default" onClick={() => {}} />
      {/* + insert — centered ON the parent node's output border */}
      <div style={{ position: "absolute", left: aR, top: cy, transform: "translate(-50%, -50%)" }}>
        <EdgeInsertBtn />
      </div>
      {/* × delete — centered on the connection (edge midpoint) */}
      <div style={{ position: "absolute", left: midX, top: cy, transform: "translate(-50%, -50%)" }}>
        <EdgeDeleteBtn />
      </div>
    </div>
  );
}

function PickerScene() {
  const nx = 30, ny = 16;
  const rightX = nx + AFF_NODE_W;
  const cy = ny + AFF_NODE_H / 2;
  // The live overlay centers the picker on the CLICK ANCHOR — for an
  // after-node add that anchor is the node's right-edge midpoint (rightX),
  // not the "+" glyph. Match that exactly.
  const pickerCx = rightX;
  return (
    <div style={{ position: "relative", width: 380, height: 320 }}>
      <WorkerNode stage={DEMO_WORKER} status={null} info={{ x: nx, y: ny }} selected density="default" onClick={() => {}} />
      <HandleOnBorder borderX={rightX} cy={cy} />
      <div style={{
        position: "absolute", left: pickerCx, top: cy + 14,
        transform: "translate(-50%, 0)",
      }}>
        <OperatorPickerMock />
      </div>
    </div>
  );
}

function BuilderAffordancesCard() {
  return (
    <Card
      title="Builder affordances"
      description="Zoom-invariant overlays that only appear in build mode. Each is shown in situ on a real node or edge — with when it appears and where it anchors. All overlays counter-scale (transform: scale(1/zoom)) so they keep a constant pixel size at any zoom."
      dartImport="lib/widgets/canvas/builder_overlay.dart · operator_picker.dart"
    >
      <SubBlock label="output handle · one dot · tap to add · drag to connect">
        <StageSplit
          leftFlex={1.5}
          left={(
            <Stage label="on a selected / hovered node" padding={20} height={150} bg="var(--co-bg-0)">
              <OutputHandleScene />
            </Stage>
          )}
          right={(
            <WhenWhere rows={[
              { k: "when",    v: "the node is hovered or selected" },
              { k: "where",   v: "a single solid dot, centered on the node's right-edge border (bottom edge in tree layout)" },
              { k: "tap",     v: "adds a stage downstream — opens the operator picker" },
              { k: "drag",    v: "drags out a connection to wire this node to another" },
              { k: "touch",   v: "iPad-first — one target, no adjacent + button to mis-hit. Visual dot is 12px; hit area is padded to ≥44px" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="edge affordance · + on parent border · × on connection center">
        <StageSplit
          leftFlex={1.5}
          left={(
            <Stage label="parent node selected → its connections too" padding={20} height={150} gridSize={32}>
              <EdgeScene />
            </Stage>
          )}
          right={(
            <WhenWhere rows={[
              { k: "when",   v: "the parent node is selected — its output connections are selected with it, so there is no thin edge line to tap on its own" },
              { k: "insert", v: "the accent + dot sits centered on the parent node's output border; tap to insert an operator into the connection" },
              { k: "delete", v: "the danger × sits at the center of the connection; tap to remove the edge" },
              { k: "touch",  v: "iPad-first — one selection state (node + its edges) means fewer, larger, well-separated targets" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="node context menu · long-press / right-click">
        <StageSplit
          leftFlex={1.5}
          left={(
            <Stage label="on the selected node" padding={20} height={230} gridSize={32}>
              <ToolbarScene />
            </Stage>
          )}
          right={(
            <WhenWhere rows={[
              { k: "when",    v: "the node is selected (does not show on hover alone)" },
              { k: "trigger", v: "long-press (touch) or right-click (mouse) anywhere on the node — there is no floating button to mis-hit" },
              { k: "where",   v: "opens at the press point, flowing down and to the right; flips to stay on-screen near a canvas edge" },
              { k: "menu",    v: "duplicate — clones the node downstream. remove + collapse — deletes the node and rewires its parent's output straight into the child's input, healing the connection. delete node — removes the node and its connections (danger)." },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="operator picker · screen-space popover · shown on dot tap">
        <StageSplit
          leftFlex={1.5}
          left={(
            <Stage label="opens from a handle tap or edge +" padding={20} height={350} gridSize={32}>
              <PickerScene />
            </Stage>
          )}
          right={(
            <WhenWhere rows={[
              { k: "when",  v: "the output-handle dot is tapped, or an edge insert + is tapped" },
              { k: "where", v: "screen-space, 14px below and horizontally centered on the tapped point — the handle dot (node's right edge) or the edge midpoint" },
              { k: "note",  v: "renders outside the canvas world transform, so it never inherits zoom" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="builder tips · dismissible help panel">
        <StageSplit
          leftFlex={1.5}
          left={(
            <Stage label="pinned to the canvas top-left" padding={16} height={190}>
              <div style={{ position: "relative", width: 280, height: 158 }}>
                <BuilderTips />
              </div>
            </Stage>
          )}
          right={(
            <WhenWhere rows={[
              { k: "when",   v: "present whenever build mode is active" },
              { k: "where",  v: "pinned to the top-left of the canvas, above the nodes" },
              { k: "action", v: "collapses to a ? button; click it to reopen" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="tokens" last>
        <TokensList tokens={[
          { name: "outputHandle.dot",    value: "12px · accent fill · 2px bg1 border · accent glow ring" },
          { name: "outputHandle.gesture",value: "single dot · tap → add downstream · drag → connect" },
          { name: "outputHandle.hitArea",value: "≥44px touch target padded around the 12px visual dot" },
          { name: "edgeInsert.btn",      value: "24px · accent fill · 2px bg1 ring · accent-ink color" },
          { name: "edgeDelete.btn",      value: "20px · bg1 · 1px danger border" },
          { name: "nodeMenu.trigger",   value: "long-press (touch) / right-click (mouse) on a selected node · no floating button" },
          { name: "nodeMenu.menu",       value: "196px menu at the press point · bg1 · border2 · radius 8 · shadow-3 · duplicate / collapse / delete" },
          { name: "menuItem",            value: "icon + label (sans 12) + mono 9.5px desc · danger row tints on hover" },
          { name: "picker.width",        value: "240px · bg2 · border2 · radius 8 · shadow-3" },
          { name: "picker.row",          value: "22px icon square · mono 11.5px label + 10px desc subtitle" },
          { name: "scaleInvariance",     value: "all overlays: transform scale(1/zoom) so px size stays constant" },
        ]} />
      </SubBlock>
    </Card>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Layout helpers
// ════════════════════════════════════════════════════════════════════════

function StagesRow({ children }) {
  return (
    <div style={{ display: "flex", flexDirection: "column", gap: 18, marginBottom: 22 }}>
      {children}
    </div>
  );
}

function ComponentsSection() {
  return (
    <>
      <ButtonsCard />
      <FormControlsCard />
      <StatusCard />
      <ModeRailCard />
      <SidebarsCard />
      <TopBarCard />
      <StageDrawerCard />
      <FilmstripCard />
      <RunsTableCard />
      <GraphNodesCard />
      <GraphEdgesCard />
      <GraphCanvasCard />
      <BuilderAffordancesCard />
    </>
  );
}

Object.assign(window, { ComponentsSection });
