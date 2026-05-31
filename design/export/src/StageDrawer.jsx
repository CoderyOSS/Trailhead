/* global React, Icon, IconButton, Button, StatusTag, Tag,
   CONNECTIONS, ATTACHED_CONFIGS, STAGE_EXECUTIONS */
const { useState: useStateSD, useEffect: useEffectSD, useMemo: useMemoSD } = React;

// ──────────────────────────────────────────────────────────────────────────
// StageDrawer — the right slide-over for a selected stage.
//
//   view = "builder"  → editable stage editor (settings · prompt · result)
//   view = "job"      → read-only log viewer (executions list + details)
//
// The two are completely different — one is for authoring the plan, the
// other is for inspecting a job that's running or has run. We keep them in
// one file because they share the shell (header, close, tabs container).
// ──────────────────────────────────────────────────────────────────────────

function Tabs({ value, onChange, tabs }) {
  return (
    <div style={{
      display: "flex", borderBottom: "1px solid var(--co-border-1)",
      paddingLeft: 16, gap: 0,
      background: "var(--co-bg-2)",
    }}>
      {tabs.map(t => {
        const active = t.value === value;
        return (
          <button
            key={t.value}
            type="button"
            onClick={() => onChange(t.value)}
            style={{
              padding: "10px 14px",
              fontSize: 12.5, fontWeight: 500,
              fontFamily: "var(--co-font-sans)",
              border: "none",
              background: "transparent",
              color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
              cursor: "pointer",
              position: "relative",
            }}
          >
            {t.label}
            {t.count != null && (
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, marginLeft: 4, color: "var(--co-text-subtle)" }}>{t.count}</span>
            )}
            {active && (
              <span style={{
                position: "absolute", left: 8, right: 8, bottom: -1, height: 2,
                background: "var(--co-accent)", borderRadius: 1,
              }} />
            )}
          </button>
        );
      })}
    </div>
  );
}

function Field({ label, children, hint }) {
  return (
    <div style={{ marginBottom: 16 }}>
      <div style={{
        display: "flex", justifyContent: "space-between", alignItems: "baseline",
        marginBottom: 6, gap: 8,
      }}>
        <label style={{
          fontFamily: "var(--co-font-mono)", fontSize: 10,
          letterSpacing: "0.06em", textTransform: "uppercase",
          color: "var(--co-text-subtle)", fontWeight: 500,
        }}>{label}</label>
        {hint && <span style={{
          fontSize: 11, color: "var(--co-text-subtle)",
          overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap", minWidth: 0,
        }}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

// ── shared atoms ──────────────────────────────────────────────────────────

const inputStyle = {
  width: "100%",
  padding: "8px 10px",
  fontFamily: "var(--co-font-mono)", fontSize: 12,
  background: "var(--co-bg-1)",
  border: "1px solid var(--co-border-2)",
  borderRadius: 8,
  color: "var(--co-text)",
  outline: "none",
};

const preStyle = {
  fontFamily: "var(--co-font-mono)", fontSize: 12,
  padding: "8px 10px",
  background: "var(--co-bg-1)",
  border: "1px solid var(--co-border-2)",
  borderRadius: 8,
  color: "var(--co-accent)",
};

function SelectField({ defaultValue, options, disabled }) {
  return (
    <select disabled={disabled} style={{
      width: "100%",
      padding: "8px 10px",
      fontFamily: "var(--co-font-mono)", fontSize: 12,
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-2)",
      borderRadius: 8,
      color: "var(--co-text)",
      appearance: "none",
      cursor: disabled ? "default" : "pointer",
      opacity: disabled ? 0.85 : 1,
      backgroundImage: disabled ? "none"
        : `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='%23c9aa84' d='M0 0h10L5 6z'/></svg>")`,
      backgroundRepeat: "no-repeat",
      backgroundPosition: "right 10px center",
    }} defaultValue={defaultValue}>
      {options.map(o => <option key={o.v} value={o.v}>{o.l}</option>)}
    </select>
  );
}

function PromptTokens({ value }) {
  // Highlights {{...}} interpolation tokens with an accent pill.
  const parts = value.split(/(\{\{[^}]+\}\})/g);
  return (
    <div style={{
      fontFamily: "var(--co-font-mono)", fontSize: 12.5,
      lineHeight: 1.55,
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-2)",
      borderRadius: 8,
      padding: "10px 12px",
      whiteSpace: "pre-wrap",
      color: "var(--co-text)",
      minHeight: 100,
    }}>
      {parts.map((p, i) => {
        if (p.startsWith("{{") && p.endsWith("}}")) {
          return <span key={i} style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            padding: "1px 6px",
            borderRadius: 4,
            background: "var(--co-accent-soft)",
            color: "var(--co-accent)",
            border: "1px solid color-mix(in oklab, var(--co-accent) 35%, transparent)",
            margin: "0 1px",
          }}>{p}</span>;
        }
        return <span key={i}>{p}</span>;
      })}
    </div>
  );
}

function PlainTextBlock({ value, monoSize = 12.5, accent }) {
  return (
    <div style={{
      fontFamily: "var(--co-font-mono)", fontSize: monoSize,
      lineHeight: 1.55,
      background: "var(--co-bg-1)",
      border: `1px solid ${accent ? "var(--co-accent)" : "var(--co-border-2)"}`,
      borderRadius: 8,
      padding: "10px 12px",
      whiteSpace: "pre-wrap",
      color: "var(--co-text)",
      minHeight: 60,
      wordBreak: "break-word",
    }}>
      {value}
    </div>
  );
}

function SchemaEditor({ schema }) {
  const text = JSON.stringify(schema, null, 2);
  const lines = text.split("\n");
  return (
    <div style={{
      fontFamily: "var(--co-font-mono)", fontSize: 12,
      lineHeight: 1.55,
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-2)",
      borderRadius: 8,
      padding: "10px 0 10px 0",
      overflow: "hidden",
    }}>
      <div style={{ display: "grid", gridTemplateColumns: "auto 1fr" }}>
        {lines.map((ln, i) => (
          <React.Fragment key={i}>
            <span style={{
              padding: "0 8px 0 10px",
              color: "var(--co-text-subtle)",
              textAlign: "right",
              userSelect: "none",
              fontVariantNumeric: "tabular-nums",
            }}>{i + 1}</span>
            <span style={{ paddingRight: 14, whiteSpace: "pre" }}><SyntaxLine line={ln} /></span>
          </React.Fragment>
        ))}
      </div>
    </div>
  );
}

function SyntaxLine({ line }) {
  const KEYWORDS = new Set(["true", "false", "null"]);
  const TYPES = new Set(["object", "string", "integer", "boolean", "array", "number"]);
  const out = [];
  let i = 0;
  while (i < line.length) {
    const ch = line[i];
    if (ch === '"') {
      let j = i + 1;
      while (j < line.length && line[j] !== '"') j++;
      const s = line.slice(i, j + 1);
      const after = line.slice(j + 1).match(/^\s*:/);
      const inner = s.slice(1, -1);
      let color = "var(--co-syn-string)";
      if (after) color = "var(--co-syn-function)";
      else if (TYPES.has(inner)) color = "var(--co-syn-keyword)";
      out.push(<span key={i} style={{ color }}>{s}</span>);
      i = j + 1;
    } else if (/[0-9]/.test(ch)) {
      let j = i;
      while (j < line.length && /[0-9.]/.test(line[j])) j++;
      out.push(<span key={i} style={{ color: "var(--co-syn-number)" }}>{line.slice(i, j)}</span>);
      i = j;
    } else if (/[a-z]/i.test(ch)) {
      let j = i;
      while (j < line.length && /[a-z0-9_]/i.test(line[j])) j++;
      const word = line.slice(i, j);
      const color = KEYWORDS.has(word) ? "var(--co-syn-keyword)"
                  : TYPES.has(word) ? "var(--co-syn-type)"
                  : "var(--co-text)";
      out.push(<span key={i} style={{ color }}>{word}</span>);
      i = j;
    } else {
      out.push(<span key={i} style={{ color: "var(--co-syn-punct)" }}>{ch}</span>);
      i++;
    }
  }
  return <>{out}</>;
}

function Empty({ label }) {
  return (
    <div style={{
      padding: 32, textAlign: "center",
      color: "var(--co-text-subtle)", fontSize: 12,
      fontFamily: "var(--co-font-mono)",
    }}>{label}</div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  WORKFLOW EDITOR MODE
// ════════════════════════════════════════════════════════════════════════

function EditorSettingsTab({ stage }) {
  const isWorker = stage.kind === "worker";
  return (
    <div style={{ padding: 16 }}>
      <Field label="stage id">
        <div style={{ ...preStyle, color: "var(--co-text-strong)" }}>{stage.id}</div>
      </Field>

      {isWorker && (
        <>
          <Field label="model config" hint="provider · model">
            <SelectField
              defaultValue={stage.connection || "anthropic-haiku-4.5"}
              options={CONNECTIONS.map(c => ({ v: c.id, l: `${c.label}  ·  ${c.hint}` }))}
            />
          </Field>

          <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10 }}>
            <Field label="timeout">
              <input defaultValue="120s" style={inputStyle} />
            </Field>
            <Field label="retries">
              <input defaultValue="2" style={inputStyle} />
            </Field>
            <Field label="parallelism">
              <input defaultValue="4" style={inputStyle} />
            </Field>
          </div>
        </>
      )}

      {stage.kind === "switch" && (
        <Field label="cases" hint={`switch on ${stage.on}`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {stage.cases.map((c, i) => (
              <div key={i} style={routingRowStyle}>
                <span style={routingMatchStyle}>{c.match}</span>
                <span style={routingArrowStyle}>→ {c.to.join(", ")}</span>
              </div>
            ))}
          </div>
        </Field>
      )}

      {stage.kind === "branch" && (
        <Field label="branches" hint={`on ${stage.cond}`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {stage.branches.map((b, i) => (
              <div key={i} style={{ ...routingRowStyle, gridTemplateColumns: "60px 1fr 50px" }}>
                <span style={routingMatchStyle}>if {b.match}</span>
                <span style={routingArrowStyle}>→ {b.to.join(", ")}</span>
                {b.loop && <span style={{ fontSize: 10, color: "var(--co-warning)", fontFamily: "var(--co-font-mono)" }}>loop</span>}
              </div>
            ))}
          </div>
        </Field>
      )}

      {stage.kind === "map" && (
        <>
          <Field label="iterate over"><div style={preStyle}>{stage.over}</div></Field>
          <Field label="body stage"><div style={preStyle}>{stage.body}</div></Field>
          <Field label="max parallel"><input defaultValue="8" style={inputStyle} /></Field>
        </>
      )}

      {stage.kind === "join" && (
        <>
          <Field label="waits for">
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              {stage.waits_for.map(w => (
                <div key={w} style={{ ...preStyle, color: "var(--co-text)" }}>{w}</div>
              ))}
            </div>
          </Field>
          <Field label="mode" hint="any-N · all · first">
            <div style={preStyle}>{stage.mode}</div>
          </Field>
        </>
      )}
    </div>
  );
}

const routingRowStyle = {
  display: "grid",
  gridTemplateColumns: "70px 1fr",
  gap: 8, alignItems: "center",
  padding: "6px 8px",
  background: "var(--co-bg-1)",
  border: "1px solid var(--co-border-1)",
  borderRadius: 6,
};
const routingMatchStyle = {
  fontFamily: "var(--co-font-mono)", fontSize: 11.5,
  color: "var(--co-accent)", fontWeight: 600,
};
const routingArrowStyle = {
  fontFamily: "var(--co-font-mono)", fontSize: 11,
  color: "var(--co-text-muted)",
};

function ConfigList({ stageId, editable, readOnly }) {
  const items = ATTACHED_CONFIGS[stageId] || [];
  return (
    <div style={{
      padding: 8,
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-2)",
      borderRadius: 8,
      display: "flex", flexDirection: "column", gap: 5,
      minHeight: 60,
    }}>
      {items.length === 0 && (
        <div style={{
          padding: "8px 4px",
          fontSize: 11,
          color: "var(--co-text-subtle)",
          fontFamily: "var(--co-font-mono)",
        }}>no configs attached</div>
      )}
      {items.map(c => (
        <div key={c.id} style={{
          display: "grid",
          gridTemplateColumns: "16px 1fr auto auto",
          alignItems: "center",
          gap: 8,
          padding: "5px 8px",
          background: "var(--co-bg-2)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 5,
        }}>
          <Icon name="file" size={11} color="var(--co-text-subtle)" />
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            color: "var(--co-text)",
            overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
          }}>{c.name}</span>
          <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10, color: "var(--co-text-subtle)" }}>
            {c.size}
          </span>
          {editable && (
            <button type="button" title="detach" style={iconBtn}>
              <Icon name="x" size={9} color="currentColor" />
            </button>
          )}
        </div>
      ))}
      {editable && (
        <button type="button" style={{
          display: "inline-flex", alignItems: "center", justifyContent: "center", gap: 4,
          padding: "5px 8px",
          background: "transparent",
          color: "var(--co-text-muted)",
          border: "1px dashed var(--co-border-2)",
          borderRadius: 4,
          cursor: "pointer",
          fontFamily: "var(--co-font-mono)", fontSize: 11,
        }}>
          <Icon name="plus" size={10} />
          attach config
        </button>
      )}
    </div>
  );
}
const iconBtn = {
  width: 16, height: 16, padding: 0,
  background: "transparent",
  border: "none",
  color: "var(--co-text-subtle)",
  cursor: "pointer",
  display: "inline-flex", alignItems: "center", justifyContent: "center",
};

function EditorPromptTab({ stage }) {
  if (!stage.prompt) return <Empty label="no prompt for this routing operator" />;
  const refs = [...new Set([...stage.prompt.matchAll(/\{\{([^}]+)\}\}/g)].map(m => m[1].trim()))];
  return (
    <div style={{ padding: 16 }}>
      <Field label="prompt template" hint={`${refs.length} dynamic refs`}>
        <PromptTokens value={stage.prompt} />
      </Field>

      <Field label="syntax">
        <div style={{
          fontSize: 12, lineHeight: 1.55,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          color: "var(--co-text-muted)",
        }}>
          Reference values from previous stages with <code style={inlineCodeStyle}>{"{{stage_id.field}}"}</code>.
          Use <code style={inlineCodeStyle}>{"{{inputs.x}}"}</code> for workflow inputs,
          {" "}<code style={inlineCodeStyle}>{"{{skills.<name>}}"}</code> to inject a skill file,
          and <code style={inlineCodeStyle}>{"{{item}}"}</code> inside a map body.
        </div>
      </Field>
    </div>
  );
}
const inlineCodeStyle = { fontFamily: "var(--co-font-mono)", color: "var(--co-accent)" };

function EditorResultTab({ stage }) {
  const [format, setFormat] = useStateSD(stage.resultFormat || "json");
  if (stage.kind !== "worker") return <Empty label="routing operators don't define a result schema" />;
  const downstream = format === "json"
    ? <>Fields autocomplete in any downstream prompt as <code style={inlineCodeStyle}>{`{{${stage.id}.<field>}}`}</code>.</>
    : <>Reference the full text in downstream prompts as <code style={inlineCodeStyle}>{`{{${stage.id}.text}}`}</code>.</>;
  return (
    <div style={{ padding: 16 }}>
      <Field label="result format" hint="how this stage's output is interpreted">
        <div style={{
          display: "inline-flex", padding: 2,
          background: "var(--co-bg-2)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 6,
          width: "100%",
        }}>
          {[
            { v: "json", l: "JSON schema", sub: "structured · strict" },
            { v: "text", l: "Plain text",  sub: "freeform blob" },
          ].map(o => {
            const active = format === o.v;
            return (
              <button key={o.v} type="button" onClick={() => setFormat(o.v)} style={{
                flex: 1, padding: "6px 10px",
                background: active ? "var(--co-bg-4)" : "transparent",
                color: active ? "var(--co-text-strong)" : "var(--co-text-muted)",
                border: "none",
                borderRadius: 4,
                cursor: "pointer",
                display: "flex", flexDirection: "column", alignItems: "flex-start",
                gap: 1,
              }}>
                <span style={{ fontFamily: "var(--co-font-sans)", fontSize: 12, fontWeight: 500 }}>{o.l}</span>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 9.5, color: "var(--co-text-subtle)" }}>{o.sub}</span>
              </button>
            );
          })}
        </div>
      </Field>

      {format === "json" && (
        <Field label="result schema  ·  JSON" hint="strict — workers fail-soft on mismatch">
          <SchemaEditor schema={stage.schema} />
        </Field>
      )}

      <Field label="downstream usage">
        <div style={{
          fontSize: 12, lineHeight: 1.55,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          color: "var(--co-text-muted)",
        }}>{downstream}</div>
      </Field>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  JOB LOG VIEWER MODE  (read-only)
// ════════════════════════════════════════════════════════════════════════

const EX_STATUS_META = {
  passed:    { color: "var(--co-success)", bg: "var(--co-success-soft)", label: "passed" },
  failed:    { color: "var(--co-danger)",  bg: "var(--co-danger-soft)",  label: "failed" },
  running:   { color: "var(--co-accent)",  bg: "var(--co-accent-soft)",  label: "running" },
  retrying:  { color: "var(--co-warning)", bg: "var(--co-warning-soft)", label: "retrying" },
  queued:    { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)",         label: "queued" },
  skipped:   { color: "var(--co-fg-3)",    bg: "var(--co-bg-3)",         label: "skipped" },
};

function ExStatusPip({ status }) {
  const m = EX_STATUS_META[status] || EX_STATUS_META.queued;
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 10, fontWeight: 600,
      padding: "2px 6px",
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

function fmtDur(ms) {
  if (ms == null || ms === 0) return "—";
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

function ExecutionRow({ exec, expanded, onToggle }) {
  return (
    <div style={{
      border: `1px solid ${expanded ? "var(--co-accent)" : "var(--co-border-1)"}`,
      background: expanded ? "var(--co-bg-1)" : "var(--co-bg-2)",
      borderRadius: 8,
      overflow: "hidden",
      transition: "border-color 140ms",
    }}>
      <button
        type="button"
        onClick={onToggle}
        style={{
          width: "100%",
          display: "grid",
          gridTemplateColumns: "16px 1fr auto",
          alignItems: "center",
          gap: 10,
          padding: "9px 12px",
          background: "transparent",
          border: "none",
          cursor: "pointer",
          textAlign: "left",
        }}
      >
        <span style={{
          display: "inline-block",
          transform: expanded ? "rotate(90deg)" : "rotate(0deg)",
          transition: "transform 120ms",
          color: "var(--co-text-subtle)",
          lineHeight: 0,
        }}>
          <Icon name="chevRight" size={11} color="currentColor" />
        </span>
        <div style={{ display: "flex", flexDirection: "column", gap: 3, minWidth: 0 }}>
          <div style={{ display: "flex", alignItems: "center", gap: 8, minWidth: 0 }}>
            <span style={{
              fontFamily: "var(--co-font-mono)", fontSize: 12,
              color: "var(--co-text-strong)", fontWeight: 500,
              overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            }}>{exec.label}</span>
            <ExStatusPip status={exec.status} />
          </div>
          <div style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)",
            display: "flex", alignItems: "center", gap: 8,
            fontVariantNumeric: "tabular-nums",
          }}>
            <span>{exec.startedAt}</span>
            <span style={{ color: "var(--co-border-2)" }}>·</span>
            <span>{fmtDur(exec.durMs)}</span>
            <span style={{ color: "var(--co-border-2)" }}>·</span>
            <span>{fmtTokens(exec.tokens)} tok</span>
            {exec.tools?.length > 0 && (
              <>
                <span style={{ color: "var(--co-border-2)" }}>·</span>
                <span>{exec.tools.length} tool{exec.tools.length === 1 ? "" : "s"}</span>
              </>
            )}
          </div>
        </div>
        {exec.status === "running" && exec.progress != null && (
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-accent)",
            fontVariantNumeric: "tabular-nums",
          }}>{Math.round(exec.progress * 100)}%</span>
        )}
      </button>

      {expanded && <ExecutionDetail exec={exec} />}
    </div>
  );
}

function ExecutionDetail({ exec }) {
  return (
    <div style={{
      padding: "4px 12px 12px",
      borderTop: "1px solid var(--co-border-1)",
      display: "flex", flexDirection: "column", gap: 12,
    }}>
      {/* Streaming live output */}
      {exec.status === "running" && exec.streaming && (
        <LogSection label="streaming" accent>
          <PlainTextBlock value={`▸ ${exec.streaming}`} accent />
          {exec.progress != null && (
            <div style={{ marginTop: 6, display: "flex", alignItems: "center", gap: 8 }}>
              <div style={{ flex: 1, height: 4, background: "var(--co-bg-3)", borderRadius: 2, overflow: "hidden" }}>
                <div style={{ width: `${exec.progress * 100}%`, height: "100%", background: "var(--co-accent)" }} />
              </div>
              <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 10.5, color: "var(--co-text)" }}>
                {Math.round(exec.progress * 100)}%
              </span>
            </div>
          )}
        </LogSection>
      )}

      {/* Rendered prompt (no template vars) */}
      {exec.renderedPrompt && (
        <LogSection label="rendered prompt" hint="full string sent to the model">
          <PlainTextBlock value={exec.renderedPrompt} />
        </LogSection>
      )}

      {/* Tool calls */}
      {exec.tools?.length > 0 && (
        <LogSection label="tool calls" hint={`${exec.tools.length} call${exec.tools.length === 1 ? "" : "s"}`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 4 }}>
            {exec.tools.map((t, i) => <ToolCallRow key={i} call={t} />)}
          </div>
        </LogSection>
      )}

      {/* Result */}
      {exec.status === "passed" && exec.result && (
        <LogSection label="result">
          <SchemaEditor schema={exec.result} />
        </LogSection>
      )}

      {/* Error */}
      {exec.status === "failed" && exec.error && (
        <LogSection label="error">
          <div style={{
            padding: "8px 10px",
            background: "var(--co-danger-soft)",
            border: "1px solid color-mix(in oklab, var(--co-danger) 30%, transparent)",
            borderRadius: 6,
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            lineHeight: 1.5,
            color: "var(--co-text)",
          }}>
            <div style={{
              fontWeight: 600, color: "var(--co-danger)",
              letterSpacing: "0.04em", textTransform: "uppercase", fontSize: 10,
              marginBottom: 4,
            }}>{exec.error.code}</div>
            {exec.error.message}
          </div>
        </LogSection>
      )}

      {/* Skipped reason */}
      {exec.status === "skipped" && exec.skipReason && (
        <LogSection label="skipped">
          <div style={{
            padding: "8px 10px",
            background: "var(--co-bg-2)",
            border: "1px solid var(--co-border-1)",
            borderRadius: 6,
            fontFamily: "var(--co-font-mono)", fontSize: 11.5,
            color: "var(--co-text-muted)",
          }}>{exec.skipReason}</div>
        </LogSection>
      )}

      {/* Queued waits-for */}
      {exec.status === "queued" && exec.waitsFor && (
        <LogSection label="waiting for">
          <div style={{ display: "flex", flexWrap: "wrap", gap: 4 }}>
            {exec.waitsFor.map(w => (
              <span key={w} style={{
                fontFamily: "var(--co-font-mono)", fontSize: 11,
                padding: "2px 7px",
                background: "var(--co-bg-2)",
                border: "1px solid var(--co-border-1)",
                borderRadius: 4,
                color: "var(--co-text-muted)",
              }}>{w}</span>
            ))}
          </div>
        </LogSection>
      )}
    </div>
  );
}

function LogSection({ label, hint, accent, children }) {
  return (
    <div>
      <div style={{
        display: "flex", justifyContent: "space-between", alignItems: "baseline",
        marginBottom: 5, gap: 8,
      }}>
        <span style={{
          fontFamily: "var(--co-font-mono)", fontSize: 9.5,
          letterSpacing: "0.06em", textTransform: "uppercase",
          color: accent ? "var(--co-accent)" : "var(--co-text-subtle)", fontWeight: 500,
        }}>{label}</span>
        {hint && <span style={{ fontSize: 10.5, color: "var(--co-text-subtle)" }}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

function ToolCallRow({ call }) {
  const running = call.running === true || call.ok == null;
  const tone = call.ok === true  ? "var(--co-success)"
            : call.ok === false ? "var(--co-danger)"
            :                      "var(--co-accent)";
  return (
    <div style={{
      display: "grid",
      gridTemplateColumns: "8px 1fr auto",
      alignItems: "center",
      gap: 8,
      padding: "5px 8px",
      background: "var(--co-bg-2)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 5,
      fontFamily: "var(--co-font-mono)", fontSize: 11,
    }}>
      <span style={{
        width: 6, height: 6, borderRadius: 999,
        background: tone,
        animation: running ? "co-pulse 1.4s ease-in-out infinite" : "none",
      }} />
      <span style={{ minWidth: 0, overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap" }}>
        <span style={{ color: "var(--co-text-strong)" }}>{call.name}</span>
        {call.args && <span style={{ color: "var(--co-text-subtle)", marginLeft: 6 }}>· {call.args}</span>}
      </span>
      <span style={{
        color: "var(--co-text-muted)",
        fontVariantNumeric: "tabular-nums",
      }}>{running ? "…" : `${call.ms}ms`}</span>
    </div>
  );
}

function JobStageHeaderInfo({ stage }) {
  const isWorker = stage.kind === "worker";
  if (!isWorker) {
    return (
      <div style={{ padding: 16, paddingBottom: 0 }}>
        <Field label="kind">
          <div style={preStyle}>{stage.kind} operator</div>
        </Field>
        {stage.kind === "switch" && <Field label="on"><div style={preStyle}>{stage.on}</div></Field>}
        {stage.kind === "branch" && <Field label="cond"><div style={preStyle}>{stage.cond}</div></Field>}
        {stage.kind === "map"    && <Field label="over"><div style={preStyle}>{stage.over}</div></Field>}
        {stage.kind === "join"   && <Field label="waits for"><div style={preStyle}>{stage.waits_for.join(", ")}</div></Field>}
      </div>
    );
  }
  const connection = CONNECTIONS.find(c => c.id === (stage.connection || "anthropic-haiku-4.5"))
                  ?? CONNECTIONS[0];
  const configs = ATTACHED_CONFIGS[stage.id] || [];
  return (
    <div style={{ padding: "12px 16px 0", borderBottom: "1px solid var(--co-border-1)" }}>
      <div style={{
        display: "grid",
        gridTemplateColumns: "1fr 1fr",
        gap: 8, marginBottom: 12,
      }}>
        <Field label="connection">
          <div style={{
            ...preStyle,
            color: "var(--co-text-strong)",
            display: "flex", alignItems: "center", gap: 6,
          }}>
            <Icon name="zap" size={11} color="var(--co-text-subtle)" />
            <span style={{
              overflow: "hidden", textOverflow: "ellipsis", whiteSpace: "nowrap",
            }}>{connection.label}</span>
          </div>
        </Field>
        <Field label="configs" hint={`${configs.length}`}>
          <div style={{ ...preStyle, color: "var(--co-text)", display: "flex", flexWrap: "wrap", gap: 4 }}>
            {configs.length === 0 && <span style={{ color: "var(--co-text-subtle)" }}>—</span>}
            {configs.map(c => (
              <span key={c.id} style={{
                fontSize: 10.5,
                padding: "1px 6px",
                background: "var(--co-bg-3)",
                border: "1px solid var(--co-border-1)",
                borderRadius: 3,
                color: "var(--co-text-muted)",
              }}>{c.name}</span>
            ))}
          </div>
        </Field>
      </div>
    </div>
  );
}

function JobLogView({ stage }) {
  const executions = STAGE_EXECUTIONS[stage.id] || [];
  // Auto-expand the most "interesting" execution (running > failed > last passed).
  const initialOpen = useMemoSD(() => {
    const running = executions.find(e => e.status === "running");
    if (running) return running.id;
    const failed = executions.find(e => e.status === "failed");
    if (failed) return failed.id;
    return executions[0]?.id ?? null;
  }, [executions]);
  const [openId, setOpenId] = useStateSD(initialOpen);
  useEffectSD(() => { setOpenId(initialOpen); }, [stage.id, initialOpen]);

  return (
    <div style={{ display: "flex", flexDirection: "column", height: "100%" }}>
      <JobStageHeaderInfo stage={stage} />

      <div style={{ flex: 1, overflowY: "auto", padding: 16 }}>
        <div style={{
          display: "flex", alignItems: "center", justifyContent: "space-between",
          marginBottom: 8,
        }}>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            letterSpacing: "0.06em", textTransform: "uppercase",
            color: "var(--co-text-subtle)", fontWeight: 500,
          }}>executions</span>
          <span style={{
            fontFamily: "var(--co-font-mono)", fontSize: 10,
            color: "var(--co-text-subtle)",
          }}>{executions.length} · this job</span>
        </div>

        <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
          {executions.map(ex => (
            <ExecutionRow
              key={ex.id}
              exec={ex}
              expanded={openId === ex.id}
              onToggle={() => setOpenId(id => id === ex.id ? null : ex.id)}
            />
          ))}
          {executions.length === 0 && (
            <div style={{
              padding: 20, textAlign: "center",
              color: "var(--co-text-subtle)", fontSize: 12,
              fontFamily: "var(--co-font-mono)",
            }}>no executions yet for this stage</div>
          )}
        </div>
      </div>
    </div>
  );
}

// ════════════════════════════════════════════════════════════════════════
//  Drawer shell
// ════════════════════════════════════════════════════════════════════════

function StageDrawer({ stage, status, onClose, view }) {
  const [tab, setTab] = useStateSD("settings");
  useEffectSD(() => { setTab("settings"); }, [stage?.id, view]);

  if (!stage) return null;

  const meta = stage.kind === "worker" ? "worker stage" :
    stage.kind === "switch" ? "switch — n-way router" :
    stage.kind === "branch" ? "branch — if/else router" :
    stage.kind === "map"    ? "map — fan-out iterator" :
    stage.kind === "join"   ? "join — wait for upstreams" :
    "routing operator";

  const isBuilder = view === "builder";

  const editorTabs = stage.kind === "worker"
    ? [
        { value: "settings", label: "stage" },
        { value: "prompt",   label: "prompt" },
        { value: "result",   label: "result" },
      ]
    : [
        { value: "settings", label: "routing" },
      ];

  return (
    <aside style={{
      width: 460, flex: "0 0 460px",
      minHeight: 0,
      background: "var(--co-bg-1)",
      borderLeft: "1px solid var(--co-border-1)",
      display: "flex", flexDirection: "column",
      animation: "co-slide-in 240ms var(--co-ease-out)",
      boxShadow: "-12px 0 32px rgba(0,0,0,0.45)",
      zIndex: 20,
    }}>
      {/* header */}
      <div style={{ padding: "14px 16px 12px", borderBottom: "1px solid var(--co-border-1)" }}>
        <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
          <div style={{
            width: 28, height: 28, borderRadius: 6,
            background: stage.kind === "worker" ? "var(--co-grad-crust)" : "var(--co-bg-3)",
            border: stage.kind === "worker" ? "none" : "1px solid var(--co-border-3)",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name={stage.kind === "worker" ? "zap" : "gitBranch"} size={14}
                  color={stage.kind === "worker" ? "var(--co-accent-ink)" : "var(--co-accent)"} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, lineHeight: 1.2 }}>
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 14,
                color: "var(--co-text-strong)", fontWeight: 600,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>{stage.label}</span>
              {!isBuilder && status && <span style={{ flex: "0 0 auto" }}><StatusTag status={status.status === "skipped" ? "cancelled" : status.status} /></span>}
            </div>
            <div style={{
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
              color: "var(--co-text-subtle)", marginTop: 2,
            }}>{stage.id} · {meta}{!isBuilder ? " · log" : ""}</div>
          </div>
          <IconButton icon="x" onClick={onClose} title="Close" />
        </div>
      </div>

      {/* body — completely different shape in builder vs. job */}
      {isBuilder ? (
        <>
          <Tabs value={tab} onChange={setTab} tabs={editorTabs} />
          <div style={{ flex: 1, overflowY: "auto" }}>
            {tab === "settings" && <EditorSettingsTab stage={stage} />}
            {tab === "prompt"   && <EditorPromptTab   stage={stage} />}
            {tab === "result"   && <EditorResultTab   stage={stage} />}
          </div>
          <div style={{
            padding: "10px 14px",
            borderTop: "1px solid var(--co-border-1)",
            background: "var(--co-bg-2)",
            display: "flex", alignItems: "center", gap: 8,
          }}>
            <Button variant="ghost" size="sm" icon="copy">duplicate</Button>
            <Button variant="danger" size="sm">delete</Button>
            <div style={{ flex: 1 }} />
            <Button variant="primary" size="sm" icon="check">save</Button>
          </div>
        </>
      ) : (
        <JobLogView stage={stage} />
      )}
    </aside>
  );
}

Object.assign(window, { StageDrawer });
