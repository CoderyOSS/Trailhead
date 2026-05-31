/* global React, Icon, IconButton, Button, StatusTag, Tag */
const { useState: useStateSD, useEffect: useEffectSD } = React;

// ──────────────────────────────────────────────────────────────────────────
// Stage drawer — right slide-over. Tabs: settings, prompt, schema, runtime.
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
        marginBottom: 6,
      }}>
        <label style={{
          fontFamily: "var(--co-font-mono)", fontSize: 10,
          letterSpacing: "0.06em", textTransform: "uppercase",
          color: "var(--co-text-subtle)", fontWeight: 500,
        }}>{label}</label>
        {hint && <span style={{ fontSize: 11, color: "var(--co-text-subtle)" }}>{hint}</span>}
      </div>
      {children}
    </div>
  );
}

function SkillChip({ skill, onRemove }) {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 11,
      padding: "3px 4px 3px 8px", borderRadius: 4,
      background: "var(--co-bg-3)", color: "var(--co-text)",
      border: "1px solid var(--co-border-2)",
    }}>
      {skill}
      {onRemove && (
        <button type="button" onClick={onRemove} style={{
          width: 14, height: 14, padding: 0,
          background: "transparent", border: "none",
          color: "var(--co-text-subtle)", cursor: "pointer",
          display: "inline-flex", alignItems: "center", justifyContent: "center",
        }}><Icon name="x" size={9} /></button>
      )}
    </span>
  );
}

// Syntax-highlighted prompt — picks out {{var.ref}} tokens.
function PromptPreview({ value }) {
  // Split on {{...}} keeping the matched groups.
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
          const inner = p.slice(2, -2).trim();
          return (
            <span key={i} style={{
              fontFamily: "var(--co-font-mono)", fontSize: 11.5,
              padding: "1px 6px",
              borderRadius: 4,
              background: "var(--co-accent-soft)",
              color: "var(--co-accent)",
              border: "1px solid color-mix(in oklab, var(--co-accent) 35%, transparent)",
              margin: "0 1px",
            }}>{`{{${inner}}}`}</span>
          );
        }
        return <span key={i}>{p}</span>;
      })}
    </div>
  );
}

// Mock JSON-schema editor — highlights keys, types, enum values.
function SchemaEditor({ schema }) {
  // Render-only, looks like a code editor.
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
  // Highlight keys ("foo":), strings ("bar"), numbers, and known types.
  // Simple regex-based; not a real parser.
  const KEYWORDS = new Set(["true", "false", "null"]);
  const TYPES = new Set(["object", "string", "integer", "boolean", "array", "number"]);

  // Tokenize
  const out = [];
  let i = 0;
  while (i < line.length) {
    const ch = line[i];
    if (ch === '"') {
      // string literal
      let j = i + 1;
      while (j < line.length && line[j] !== '"') j++;
      const s = line.slice(i, j + 1);
      // is this a key?
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

// ──────────────────────────────────────────────────────────────────────────

function SettingsTab({ stage }) {
  return (
    <div style={{ padding: 16 }}>
      <Field label="stage id">
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 13,
          padding: "8px 10px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-2)",
          borderRadius: 8,
          color: "var(--co-text-strong)",
        }}>{stage.id}</div>
      </Field>

      <Field label="kind">
        <div style={{ display: "flex", gap: 6 }}>
          {["worker", "switch", "branch", "map", "join"].map(k => (
            <button key={k} type="button" style={{
              flex: 1,
              padding: "6px 10px",
              fontSize: 11.5,
              fontFamily: "var(--co-font-mono)",
              background: k === stage.kind ? "var(--co-bg-4)" : "var(--co-bg-2)",
              color: k === stage.kind ? "var(--co-accent)" : "var(--co-text-muted)",
              border: `1px solid ${k === stage.kind ? "var(--co-accent)" : "var(--co-border-1)"}`,
              borderRadius: 6,
              cursor: "pointer",
            }}>{k}</button>
          ))}
        </div>
      </Field>

      {stage.kind === "worker" && (
        <>
          <Field label="skills" hint={`${(stage.skills || []).length} attached`}>
            <div style={{
              padding: "8px 10px",
              background: "var(--co-bg-1)",
              border: "1px solid var(--co-border-2)",
              borderRadius: 8,
              display: "flex", flexWrap: "wrap", gap: 6,
              minHeight: 36,
            }}>
              {(stage.skills || []).map(sk => (
                <SkillChip key={sk} skill={sk} onRemove={() => {}} />
              ))}
              <button type="button" style={{
                display: "inline-flex", alignItems: "center", gap: 4,
                padding: "3px 8px",
                background: "transparent",
                color: "var(--co-text-muted)",
                border: "1px dashed var(--co-border-2)",
                borderRadius: 4,
                cursor: "pointer",
                fontFamily: "var(--co-font-mono)", fontSize: 11,
              }}>
                <Icon name="plus" size={10} /> add skill
              </button>
            </div>
          </Field>

          <Field label="model">
            <select style={{
              width: "100%",
              padding: "8px 10px",
              fontFamily: "var(--co-font-mono)", fontSize: 12,
              background: "var(--co-bg-1)",
              border: "1px solid var(--co-border-2)",
              borderRadius: 8,
              color: "var(--co-text)",
              appearance: "none",
              backgroundImage: `url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='10' height='6' viewBox='0 0 10 6'><path fill='%23c9aa84' d='M0 0h10L5 6z'/></svg>")`,
              backgroundRepeat: "no-repeat",
              backgroundPosition: "right 10px center",
            }} defaultValue={stage.model || "haiku-4.5"}>
              <option value="haiku-4.5">haiku-4.5  ·  fast</option>
              <option value="sonnet-4.5">sonnet-4.5  ·  balanced</option>
              <option value="opus-4.1">opus-4.1  ·  best</option>
            </select>
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
              <div key={i} style={{
                display: "grid", gridTemplateColumns: "70px 1fr",
                gap: 8, alignItems: "center",
                padding: "6px 8px",
                background: "var(--co-bg-1)",
                border: "1px solid var(--co-border-1)",
                borderRadius: 6,
              }}>
                <span style={{
                  fontFamily: "var(--co-font-mono)", fontSize: 11.5,
                  color: "var(--co-accent)", fontWeight: 600,
                }}>{c.match}</span>
                <span style={{
                  fontFamily: "var(--co-font-mono)", fontSize: 11,
                  color: "var(--co-text-muted)",
                }}>→ {c.to.join(", ")}</span>
              </div>
            ))}
          </div>
        </Field>
      )}

      {stage.kind === "map" && (
        <>
          <Field label="iterate over"><div style={pre()}>{stage.over}</div></Field>
          <Field label="body stage"><div style={pre()}>{stage.body}</div></Field>
          <Field label="max parallel"><input defaultValue="8" style={inputStyle} /></Field>
        </>
      )}

      {stage.kind === "join" && (
        <>
          <Field label="waits for">
            <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
              {stage.waits_for.map(w => (
                <div key={w} style={{
                  fontFamily: "var(--co-font-mono)", fontSize: 12,
                  padding: "6px 10px",
                  background: "var(--co-bg-1)",
                  border: "1px solid var(--co-border-1)",
                  borderRadius: 6,
                  color: "var(--co-text)",
                }}>{w}</div>
              ))}
            </div>
          </Field>
          <Field label="mode" hint="any-N · all · first">
            <div style={pre()}>{stage.mode}</div>
          </Field>
        </>
      )}

      {stage.kind === "branch" && (
        <Field label="branches" hint={`on ${stage.cond}`}>
          <div style={{ display: "flex", flexDirection: "column", gap: 6 }}>
            {stage.branches.map((b, i) => (
              <div key={i} style={{
                display: "grid", gridTemplateColumns: "60px 1fr 60px",
                gap: 8, alignItems: "center",
                padding: "6px 8px",
                background: "var(--co-bg-1)",
                border: "1px solid var(--co-border-1)",
                borderRadius: 6,
              }}>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11.5, color: "var(--co-accent)", fontWeight: 600 }}>
                  if {b.match}
                </span>
                <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, color: "var(--co-text-muted)" }}>→ {b.to.join(", ")}</span>
                {b.loop && <span style={{ fontSize: 10, color: "var(--co-warning)", fontFamily: "var(--co-font-mono)" }}>loop</span>}
              </div>
            ))}
          </div>
        </Field>
      )}
    </div>
  );
}

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
const pre = () => ({
  fontFamily: "var(--co-font-mono)", fontSize: 12,
  padding: "8px 10px",
  background: "var(--co-bg-1)",
  border: "1px solid var(--co-border-2)",
  borderRadius: 8,
  color: "var(--co-accent)",
});

function PromptTab({ stage }) {
  if (!stage.prompt) return <Empty label="no prompt for this routing operator" />;
  // Detect referenced variables
  const refs = [...new Set([...stage.prompt.matchAll(/\{\{([^}]+)\}\}/g)].map(m => m[1].trim()))];
  return (
    <div style={{ padding: 16 }}>
      <Field label="prompt template" hint={`${refs.length} dynamic refs`}>
        <PromptPreview value={stage.prompt} />
      </Field>

      <Field label="resolved references">
        <div style={{
          display: "flex", flexWrap: "wrap", gap: 6,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
        }}>
          {refs.map(r => (
            <span key={r} style={{
              fontFamily: "var(--co-font-mono)", fontSize: 11,
              padding: "2px 7px",
              background: "var(--co-bg-3)",
              border: "1px solid var(--co-border-2)",
              borderRadius: 4,
              color: "var(--co-accent)",
            }}>{r}</span>
          ))}
        </div>
      </Field>

      <Field label="hints">
        <div style={{
          fontSize: 12, lineHeight: 1.55,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          color: "var(--co-text-muted)",
        }}>
          Reference values from previous stages with <code style={{ fontFamily: "var(--co-font-mono)", color: "var(--co-accent)" }}>{"{{stage_id.field}}"}</code>.
          Use <code style={{ fontFamily: "var(--co-font-mono)", color: "var(--co-accent)" }}>{"{{inputs.x}}"}</code> for workflow inputs and
          {" "}<code style={{ fontFamily: "var(--co-font-mono)", color: "var(--co-accent)" }}>{"{{item}}"}</code> inside a map body.
        </div>
      </Field>
    </div>
  );
}

function SchemaTab({ stage }) {
  if (!stage.schema) return <Empty label="this stage does not produce a result schema" />;
  return (
    <div style={{ padding: 16 }}>
      <Field label="result schema  ·  JSON" hint="strict — workers fail-soft on schema mismatch">
        <SchemaEditor schema={stage.schema} />
      </Field>
      <Field label="downstream consumers">
        <div style={{
          fontSize: 12, lineHeight: 1.55,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-1)",
          borderRadius: 8,
          color: "var(--co-text-muted)",
        }}>
          Fields surface as autocompletes in any downstream prompt as <code style={{ fontFamily: "var(--co-font-mono)", color: "var(--co-accent)" }}>{`{{${stage.id}.<field>}}`}</code>.
        </div>
      </Field>
    </div>
  );
}

function RuntimeTab({ stage, status }) {
  if (!status) return <Empty label="no runtime data — start a job to see live output" />;
  return (
    <div style={{ padding: 16 }}>
      <div style={{
        display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 10,
        marginBottom: 16,
      }}>
        <Stat label="status" value={<StatusTag status={status.status === "skipped" ? "cancelled" : status.status} />} />
        <Stat label="duration"  value={status.durMs > 0 ? `${(status.durMs/1000).toFixed(2)}s` : "—"} mono />
        <Stat label="tokens"    value={status.tokens > 0 ? status.tokens.toLocaleString() : "—"} mono />
      </div>

      {status.progress != null && (
        <Field label="progress">
          <div style={{ display: "flex", alignItems: "center", gap: 10 }}>
            <div style={{ flex: 1, height: 6, background: "var(--co-bg-3)", borderRadius: 3, overflow: "hidden" }}>
              <div style={{ width: `${status.progress * 100}%`, height: "100%", background: "var(--co-grad-crust)" }} />
            </div>
            <span style={{ fontFamily: "var(--co-font-mono)", fontSize: 11, color: "var(--co-text)", fontVariantNumeric: "tabular-nums" }}>
              {Math.round(status.progress * 100)}%
            </span>
          </div>
        </Field>
      )}

      <Field label="result so far" hint="streaming">
        <div style={{
          fontFamily: "var(--co-font-mono)", fontSize: 12,
          lineHeight: 1.55,
          padding: "10px 12px",
          background: "var(--co-bg-1)",
          border: "1px solid var(--co-border-2)",
          borderRadius: 8,
          color: "var(--co-text)",
          maxHeight: 200,
          overflowY: "auto",
        }}>
          {status.status === "passed" && stage.id === "classify" ? (
            <>
              {`{`}<br/>
              &nbsp;&nbsp;<span style={{ color: "var(--co-syn-function)" }}>"risk"</span>: <span style={{ color: "var(--co-syn-string)" }}>"high"</span>,<br/>
              &nbsp;&nbsp;<span style={{ color: "var(--co-syn-function)" }}>"reasons"</span>: [<span style={{ color: "var(--co-syn-string)" }}>"db migration"</span>, <span style={{ color: "var(--co-syn-string)" }}>"auth touched"</span>],<br/>
              &nbsp;&nbsp;<span style={{ color: "var(--co-syn-function)" }}>"security_relevant"</span>: <span style={{ color: "var(--co-syn-keyword)" }}>true</span><br/>
              {`}`}
            </>
          ) : status.status === "running" ? (
            <span style={{ color: "var(--co-text-muted)" }}>
              <span style={{ animation: "co-blink 1.2s linear infinite" }}>▸</span> tool: <span style={{ color: "var(--co-accent)" }}>code.search</span> · query="auth check"<br/>
              <span style={{ animation: "co-blink 1.2s linear infinite" }}>▸</span> reading <span style={{ color: "var(--co-accent)" }}>src/auth/middleware.ts</span> · 142 lines<br/>
              <span style={{ animation: "co-blink 1.2s linear infinite" }}>▸</span> drafting comment on line 47…
            </span>
          ) : status.status === "passed" ? (
            <span style={{ color: "var(--co-success)" }}>✓ stage passed — see runs log for full output.</span>
          ) : status.status === "queued" ? (
            <span style={{ color: "var(--co-text-subtle)" }}>queued — waiting on upstream dependencies.</span>
          ) : status.status === "skipped" ? (
            <span style={{ color: "var(--co-text-subtle)" }}>skipped — switch chose another branch.</span>
          ) : <span style={{ color: "var(--co-text-subtle)" }}>—</span>}
        </div>
      </Field>
    </div>
  );
}

function Stat({ label, value, mono }) {
  return (
    <div style={{
      padding: "8px 10px",
      background: "var(--co-bg-1)",
      border: "1px solid var(--co-border-1)",
      borderRadius: 8,
    }}>
      <div style={{
        fontFamily: "var(--co-font-mono)", fontSize: 9.5,
        letterSpacing: "0.06em", textTransform: "uppercase",
        color: "var(--co-text-subtle)", fontWeight: 500,
        marginBottom: 3,
      }}>{label}</div>
      <div style={{
        fontFamily: mono ? "var(--co-font-mono)" : "var(--co-font-sans)",
        fontSize: 13, color: "var(--co-text-strong)",
        fontVariantNumeric: "tabular-nums",
      }}>{value}</div>
    </div>
  );
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

// ──────────────────────────────────────────────────────────────────────────

function StageDrawer({ stage, status, onClose, view }) {
  const [tab, setTab] = useStateSD("settings");
  useEffectSD(() => { setTab("settings"); }, [stage?.id]);

  if (!stage) return null;

  const meta = stage.kind === "worker" ? "worker stage" :
    stage.kind === "switch" ? "switch — n-way router" :
    stage.kind === "branch" ? "branch — if/else router" :
    stage.kind === "map"    ? "map — fan-out iterator" :
    stage.kind === "join"   ? "join — wait for upstreams" :
    "routing operator";

  const tabs = stage.kind === "worker"
    ? [
        { value: "settings", label: "stage" },
        { value: "prompt",   label: "prompt" },
        { value: "schema",   label: "schema" },
        { value: "runtime",  label: view === "job" ? "runtime" : "preview" },
      ]
    : [
        { value: "settings", label: "routing" },
        { value: "runtime",  label: view === "job" ? "runtime" : "preview" },
      ];

  return (
    <aside style={{
      width: 460,
      position: "absolute", top: 0, right: 0, bottom: 0,
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
            fontFamily: "var(--co-font-mono)", fontSize: 12, fontWeight: 700,
            color: stage.kind === "worker" ? "var(--co-accent-ink)" : "var(--co-accent)",
          }}>
            <Icon name={stage.kind === "worker" ? "zap" : "gitBranch"} size={14} color={stage.kind === "worker" ? "var(--co-accent-ink)" : "var(--co-accent)"} />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, lineHeight: 1.2 }}>
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 14,
                color: "var(--co-text-strong)", fontWeight: 600,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>{stage.label}</span>
              {status && <span style={{ flex: "0 0 auto" }}><StatusTag status={status.status === "skipped" ? "cancelled" : status.status} /></span>}
            </div>
            <div style={{
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
              color: "var(--co-text-subtle)", marginTop: 2,
            }}>{stage.id} · {meta}</div>
          </div>
          <IconButton icon="x" onClick={onClose} title="Close" />
        </div>
      </div>

      <Tabs value={tab} onChange={setTab} tabs={tabs} />

      <div style={{ flex: 1, overflowY: "auto" }}>
        {tab === "settings" && <SettingsTab stage={stage} />}
        {tab === "prompt"   && <PromptTab stage={stage} />}
        {tab === "schema"   && <SchemaTab stage={stage} />}
        {tab === "runtime"  && <RuntimeTab stage={stage} status={status} />}
      </div>

      {/* footer */}
      <div style={{
        padding: "10px 14px",
        borderTop: "1px solid var(--co-border-1)",
        background: "var(--co-bg-2)",
        display: "flex", alignItems: "center", gap: 8,
      }}>
        {view === "builder" ? (
          <>
            <Button variant="ghost" size="sm" icon="copy">duplicate</Button>
            <Button variant="danger" size="sm">delete</Button>
            <div style={{ flex: 1 }} />
            <Button variant="primary" size="sm" icon="check">save</Button>
          </>
        ) : (
          <>
            <Button variant="ghost" size="sm" icon="refresh">retry stage</Button>
            <div style={{ flex: 1 }} />
            <Button variant="secondary" size="sm" icon="bookmark">snapshot here</Button>
          </>
        )}
      </div>
    </aside>
  );
}

Object.assign(window, { StageDrawer });
