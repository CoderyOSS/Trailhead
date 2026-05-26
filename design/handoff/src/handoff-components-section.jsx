/* global React, Card, Stage, StatesGrid, TokensList, StageSplit, SubBlock, H3, AnatomyLegend,
   Button, IconButton, Icon, StatusDot, StatusTag, Tag, Eyebrow,
   ModeRail, WorkflowsSidebar, JobsSidebar, TopBar, StageDrawer, Filmstrip, RunsView,
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
          <div style={{ position: "relative" }}>
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
      description="Two sidebar variants — Workflows (Build mode) and Jobs (Active + History modes). Jobs sidebar has a grouped/flat toggle. Both share the same header structure: title, subtitle, optional secondary controls."
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
              { label: "title block", desc: "Active jobs · subtitle counts" },
              { label: "view toggle", desc: "grouped (workflow → jobs) ↔ flat (jobs + workflow tag)" },
              { label: "group header", desc: "workflow name · chevron · count" },
              { label: "job row · grouped", desc: "status dot · input string · timestamp" },
              { label: "footer", desc: "showing N · live badge on Active · 'no search yet' on History" },
            ]} />
          )}
        />
      </SubBlock>

      <SubBlock label="jobs sidebar · flat view (workflow appears as a tag chip on each row)" last>
        <Stage padding={18} height={300}>
          <Constrained width={260} height={260}>
            <JobsSidebar
              kind="active" jobs={JOBS_LOG}
              viewMode="flat" onViewMode={() => {}}
              activeId="r_8f2a91c" onPick={() => {}}
            />
          </Constrained>
        </Stage>
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
  return (
    <Card
      title="Runs table (History)"
      description="Sortable table of past jobs. Mode badge in the header, status filter pills, then a 9-column table: status dot, run id, input, status tag, started, duration, tokens, cost, by. No search yet — sort by clicking column headers."
      dartImport="lib/widgets/runs_table.dart"
      fullBleed
    >
      <Constrained width="100%" height={500} allowScroll>
        <RunsView jobs={JOBS_LOG.filter(j => ["passed","failed","cancelled"].includes(j.status))} onPick={() => {}} activeId={null} />
      </Constrained>
      <div style={{ padding: 18 }}>
        <H3>tokens</H3>
        <TokensList tokens={[
          { name: "row.padding",  value: "10px vertical · 14px horizontal" },
          { name: "header.font",  value: "AppType.mono · 10px · UPPERCASE · letterSpacing 0.06em" },
          { name: "header.color", value: "palette.textSubtle" },
          { name: "body.font",    value: "AppType.sans 12.5px · ids in mono" },
          { name: "row.hover",    value: "palette.surface" },
          { name: "row.active",   value: "palette.surface (sticky)" },
          { name: "filter pill",  value: "border-1 / surfaceRaised when active · counts in subtle text" },
        ]} />
      </div>
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
    </>
  );
}

Object.assign(window, { ComponentsSection });
