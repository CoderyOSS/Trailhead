/* global React, Icon, IconButton, Button, StatusTag, workflowToYaml */
const { useState: useStateYD, useMemo: useMemoYD, useEffect: useEffectYD } = React;

// ──────────────────────────────────────────────────────────────────────────
// YamlDrawer — the alternative right slide-over.
//
// Where StageDrawer inspects ONE stage, this shows the WHOLE workflow (or a
// job's resolved spec) as YAML. It is strictly read-only: the visual builder
// is the source of truth and compiles the YAML, so there's nothing to edit
// here. The header makes that contract explicit with a "read-only" lock.
//
//   view = "workflow" → the draft workflow spec (build mode)
//   view = "job"      → the exact spec a job ran, with a run-metadata preface
// ──────────────────────────────────────────────────────────────────────────

// One-line YAML tokenizer. Deliberately small — it only needs to look right
// for the spec workflowToYaml() emits, not parse arbitrary YAML.
function YamlLine({ raw }) {
  const indentMatch = raw.match(/^(\s*)(.*)$/);
  const indent = indentMatch[1];
  let rest = indentMatch[2];

  const out = [];
  let key = 0;
  const push = (text, color, extra) => {
    if (text === "") return;
    out.push(<span key={key++} style={{ color, ...extra }}>{text}</span>);
  };

  // Full-line comment.
  if (rest.startsWith("#")) {
    return (
      <>
        {indent}
        <span style={{ color: "var(--co-syn-comment)", fontStyle: "italic" }}>{rest}</span>
      </>
    );
  }

  // Split off a trailing inline comment ( … # foo) — but never inside quotes.
  let trailing = null;
  const hashIdx = rest.search(/\s#/);
  if (hashIdx !== -1 && (rest.slice(0, hashIdx).split('"').length % 2 === 1)) {
    trailing = rest.slice(hashIdx);
    rest = rest.slice(0, hashIdx);
  }

  // Leading list marker.
  let listMarker = "";
  const lm = rest.match(/^(-\s+)(.*)$/);
  if (lm) { listMarker = lm[1]; rest = lm[2]; }

  // key: value
  const kv = rest.match(/^([A-Za-z0-9_.\-]+)(:)(\s*)(.*)$/);
  if (kv) {
    push(kv[1], "var(--co-syn-function)");          // key
    push(kv[2], "var(--co-syn-punct)");              // colon
    push(kv[3], "var(--co-text)");                   // gap
    pushValue(kv[4], push);                          // value
  } else if (rest.length) {
    pushValue(rest, push);
  }

  return (
    <>
      {indent}
      {listMarker && <span style={{ color: "var(--co-syn-punct)" }}>{listMarker}</span>}
      {out}
      {trailing && <span style={{ color: "var(--co-syn-comment)", fontStyle: "italic" }}>{trailing}</span>}
    </>
  );
}

function pushValue(val, push) {
  if (val === "") return;
  // Block scalar indicators.
  if (val === "|" || val === ">" || val === "|-" || val === ">-") {
    push(val, "var(--co-syn-keyword)");
    return;
  }
  // Quoted string.
  if (/^".*"$/.test(val)) { push(val, "var(--co-syn-string)"); return; }
  // Inline array  [a, b, c]
  if (/^\[.*\]$/.test(val)) {
    const inner = val.slice(1, -1);
    push("[", "var(--co-syn-punct)");
    inner.split(/(,\s*)/).forEach(tok => {
      if (/^,\s*$/.test(tok)) push(tok, "var(--co-syn-punct)");
      else push(tok, "var(--co-text)");
    });
    push("]", "var(--co-syn-punct)");
    return;
  }
  // Number.
  if (/^-?\d+(\.\d+)?$/.test(val)) { push(val, "var(--co-syn-number)"); return; }
  // Keyword literals + scalar types.
  if (["true", "false", "null"].includes(val)) { push(val, "var(--co-syn-keyword)"); return; }
  if (["int", "string", "boolean", "object", "array", "integer", "number"].includes(val)) {
    push(val, "var(--co-syn-type)"); return;
  }
  // enum[…] shorthand we emit for schema props.
  if (/^enum\[/.test(val)) { push(val, "var(--co-syn-type)"); return; }
  // Bare scalar.
  push(val, "var(--co-text)");
}

function YamlBody({ text, search }) {
  const lines = text.split("\n");
  const q = search.trim().toLowerCase();
  return (
    <div style={{
      flex: 1, overflow: "auto",
      background: "var(--co-code-bg, var(--co-bg-1))",
    }}>
      <div style={{
        display: "grid", gridTemplateColumns: "auto 1fr",
        fontFamily: "var(--co-font-mono)", fontSize: 12.5, lineHeight: 1.65,
        padding: "12px 0 24px",
        minWidth: "min-content",
      }}>
        {lines.map((ln, i) => {
          const hit = q && ln.toLowerCase().includes(q);
          return (
            <React.Fragment key={i}>
              <span style={{
                padding: "0 12px 0 16px",
                color: "var(--co-text-subtle)",
                textAlign: "right",
                userSelect: "none",
                fontVariantNumeric: "tabular-nums",
                opacity: 0.55,
                background: hit ? "color-mix(in oklab, var(--co-accent) 14%, transparent)" : "transparent",
              }}>{i + 1}</span>
              <span style={{
                paddingRight: 20, whiteSpace: "pre", tabSize: 2,
                background: hit ? "color-mix(in oklab, var(--co-accent) 14%, transparent)" : "transparent",
              }}>
                <YamlLine raw={ln} />
              </span>
            </React.Fragment>
          );
        })}
      </div>
    </div>
  );
}

// Build a run-metadata comment preface for the job view.
function jobPreface(job) {
  const status = job.status || job.state || "running";
  return [
    `# ─── resolved run spec ───────────────────────────────`,
    `# run:       ${job.id}`,
    `# workflow:  ${job.workflow || "pr-reviewer"} · v${job.workflowVersion || 14}`,
    `# input:     ${job.input || "—"}`,
    `# status:    ${status}`,
    `# this is the exact, pinned spec the run executed — read-only.`,
    `# ─────────────────────────────────────────────────────`,
    ``,
  ].join("\n");
}

function YamlDrawer({ workflow, job, view = "workflow", onClose, interactive = true }) {
  const [copied, setCopied]   = useStateYD(false);
  const [search, setSearch]   = useStateYD("");
  const [showFind, setShowFind] = useStateYD(false);

  const isJob = view === "job" && job;

  const fileName = isJob
    ? `${job.id}.resolved.yaml`
    : `${workflow.name}.yaml`;

  const yamlText = useMemoYD(() => {
    const spec = workflowToYaml(workflow);
    return isJob ? jobPreface(job) + spec : spec;
  }, [workflow, job, isJob]);

  const lineCount = useMemoYD(() => yamlText.split("\n").length, [yamlText]);
  const byteSize  = useMemoYD(() => {
    const b = new Blob([yamlText]).size;
    return b < 1024 ? `${b} B` : `${(b / 1024).toFixed(1)} kB`;
  }, [yamlText]);

  function copyAll() {
    const done = () => { setCopied(true); setTimeout(() => setCopied(false), 1600); };
    if (navigator.clipboard && navigator.clipboard.writeText) {
      navigator.clipboard.writeText(yamlText).then(done).catch(done);
    } else {
      const ta = document.createElement("textarea");
      ta.value = yamlText; document.body.appendChild(ta); ta.select();
      try { document.execCommand("copy"); } catch (e) {}
      document.body.removeChild(ta); done();
    }
  }

  function download() {
    const blob = new Blob([yamlText], { type: "text/yaml" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url; a.download = fileName; document.body.appendChild(a);
    a.click(); document.body.removeChild(a);
    setTimeout(() => URL.revokeObjectURL(url), 1000);
  }

  // Esc closes; ⌘/Ctrl-F toggles the in-drawer find. Skipped in static
  // contexts (e.g. the handoff catalog) so it doesn't hijack browser find.
  useEffectYD(() => {
    if (!interactive) return;
    const onKey = (e) => {
      if (e.key === "Escape") { if (showFind) { setShowFind(false); setSearch(""); } else onClose(); }
      if ((e.metaKey || e.ctrlKey) && e.key.toLowerCase() === "f") { e.preventDefault(); setShowFind(s => !s); }
    };
    window.addEventListener("keydown", onKey);
    return () => window.removeEventListener("keydown", onKey);
  }, [onClose, showFind, interactive]);

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
            background: "var(--co-bg-3)",
            border: "1px solid var(--co-border-3)",
            display: "flex", alignItems: "center", justifyContent: "center",
          }}>
            <Icon name="file" size={14} color="var(--co-accent)" />
          </div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ display: "flex", alignItems: "center", gap: 8, lineHeight: 1.2 }}>
              <span style={{
                fontFamily: "var(--co-font-mono)", fontSize: 14,
                color: "var(--co-text-strong)", fontWeight: 600,
                whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis",
              }}>{fileName}</span>
              <ReadOnlyPill />
            </div>
            <div style={{
              fontFamily: "var(--co-font-mono)", fontSize: 10.5,
              color: "var(--co-text-subtle)", marginTop: 2,
              fontVariantNumeric: "tabular-nums",
            }}>{lineCount} lines · {byteSize} · {isJob ? "pinned to run" : `compiled from v${workflow.draft || workflow.version} draft`}</div>
          </div>
          <IconButton icon="x" onClick={onClose} title="Close" />
        </div>

        {/* toolbar */}
        <div style={{ display: "flex", alignItems: "center", gap: 6, marginTop: 12 }}>
          <Button variant="secondary" size="sm" icon={copied ? "check" : "copy"} onClick={copyAll}>
            {copied ? "copied" : "copy"}
          </Button>
          <Button variant="ghost" size="sm" icon="save" onClick={download}>download</Button>
          <div style={{ flex: 1 }} />
          <IconButton icon="search" title="Find (⌘F)" active={showFind} onClick={() => setShowFind(s => !s)} size={26} />
        </div>

        {showFind && (
          <div style={{ marginTop: 8 }}>
            <input
              autoFocus
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="find in spec…"
              style={{
                width: "100%",
                padding: "6px 10px",
                fontFamily: "var(--co-font-mono)", fontSize: 12,
                background: "var(--co-bg-0)",
                border: "1px solid var(--co-border-2)",
                borderRadius: 8,
                color: "var(--co-text)",
                outline: "none",
              }}
            />
          </div>
        )}
      </div>

      {/* body */}
      <YamlBody text={yamlText} search={search} />

      {/* footer — reinforces the read-only contract */}
      <div style={{
        padding: "9px 14px",
        borderTop: "1px solid var(--co-border-1)",
        background: "var(--co-bg-2)",
        display: "flex", alignItems: "center", gap: 8,
        fontFamily: "var(--co-font-mono)", fontSize: 10.5,
        color: "var(--co-text-subtle)",
      }}>
        <Icon name="lock" size={11} color="var(--co-text-subtle)" />
        <span>
          {isJob
            ? "the canvas compiled this — rerun to change it"
            : "the canvas compiles this — edit stages to change it"}
        </span>
      </div>
    </aside>
  );
}

function ReadOnlyPill() {
  return (
    <span style={{
      display: "inline-flex", alignItems: "center", gap: 4,
      fontFamily: "var(--co-font-mono)", fontSize: 9, fontWeight: 700,
      letterSpacing: "0.08em", textTransform: "uppercase",
      padding: "2px 6px", borderRadius: 4,
      background: "var(--co-bg-3)",
      color: "var(--co-text-muted)",
      border: "1px solid var(--co-border-1)",
      flex: "0 0 auto",
    }}>
      <Icon name="lock" size={9} color="currentColor" />
      read-only
    </span>
  );
}

Object.assign(window, { YamlDrawer });
