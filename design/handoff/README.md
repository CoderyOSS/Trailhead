# Flutter handoff — Trailhead workflow manager

Design-to-Flutter handoff package for the workflow + job UI.

---

## Archive structure

The zip extracts to a **flat folder**. Every path in `Flutter Handoff.html` is relative to the folder root — no subdirectory nesting. Extracting and overwriting your local copy is the full update procedure.

```
Flutter Handoff.html          ← open this in your browser
README.md                     ← you are here
tokens.json                   ← source of truth (all themes × accents × primitives)
colors_and_type.css           ← CSS custom-property tokens (consumed by the HTML doc)
themes.css                    ← dark/light theme overrides
assets/
  codery-glyph.svg
  trailhead-logo.png
  trailhead-logo.svg
  trailhead-square.png
lib/
  theme/
    tokens.dart               ← typed Dart constants (AppSpacing, AppRadius, AppType, etc.)
    app_theme.dart            ← Material 3 ThemeData builder + AppTokens ThemeExtension
src/
  ── live app components ──────────────────────────────────────────────
  Common.jsx                  ← shared primitives: Button, Icon, StatusDot, Tag, …
  data.js                     ← sample data (WORKFLOW, JOB, JOBS_LOG, SNAPSHOTS)
  Rail.jsx                    ← mode rail (left strip)
  WorkflowsSidebar.jsx
  JobsSidebar.jsx
  TopBar.jsx
  Canvas.jsx                  ← node graph: WorkerNode, FanNode, OperatorNode, edges
  BuilderOverlay.jsx          ← operator picker + builder tips overlay
  StageDrawer.jsx             ← right slide-over (editor + log viewer)
  Filmstrip.jsx               ← snapshot strip (bottom bar)
  RunsView.jsx                ← history runs table
  ── handoff doc sections ─────────────────────────────────────────────
  handoff-shell.jsx           ← Card, Stage, StatesGrid, TokensList, AnatomyLegend, TOC
  handoff-tokens-section.jsx  ← §01 Design tokens
  handoff-components-section.jsx ← §02 Component catalog
  handoff-layouts-section.jsx ← §03 Full-screen layouts
  handoff-doc.jsx             ← root — mounts all sections, theme switcher
```

> **Why everything lives in `src/`:** `Flutter Handoff.html` only resolves paths relative to its own location. Keeping all JSX in one flat `src/` directory means you can extract the zip anywhere and open the HTML without a local server or path fixups.

---

## How to update your local copy

1. Download the new zip.
2. Extract into a **temp folder**.
3. Copy-paste (overwrite) the temp folder contents over your existing copy.
   - Same filenames → clean overwrite.
   - New files (e.g. a new `src/` component) appear automatically.
   - Deleted files are not removed — delete manually if needed.

---

## Opening the doc

Open `Flutter Handoff.html` directly in **Chrome or Safari** — no build step, no server needed. Babel transpiles the JSX in-browser on first load (~1 s).

> Firefox blocks local `file://` cross-origin script loads for Babel. Use Chrome or `python3 -m http.server` if on Firefox.

---

## Using the tokens in Flutter

```dart
import 'lib/theme/app_theme.dart';
import 'lib/theme/tokens.dart';

MaterialApp(
  theme: defaultDarkTheme(),  // Slate + Orange (default)
  darkTheme: defaultDarkTheme(),
);
```

Inside any widget:

```dart
final t = Theme.of(context).extension<AppTokens>()!;
Container(
  color: t.palette.surface,
  padding: const EdgeInsets.all(AppSpacing.s6),
  child: Text('Hello', style: TextStyle(color: t.palette.textStrong)),
);
```

For status colors:

```dart
final pip = t.statusColor(WorkflowStatus.running);
Container(
  color: pip.soft,
  child: Text('RUNNING', style: TextStyle(color: pip.base)),
);
```

---

## Theme combinations

The Slate ↔ Paper and Orange ↔ Green axes are orthogonal:

|             | Slate | Paper |
|-------------|-------|-------|
| **Orange**  | `appTheme(palette: AppPalettes.slate, accent: AppAccents.orangeOnSlate)` | `appTheme(palette: AppPalettes.paper, accent: AppAccents.orangeOnPaper)` |
| **Green**   | `appTheme(palette: AppPalettes.slate, accent: AppAccents.greenOnSlate)`  | `appTheme(palette: AppPalettes.paper, accent: AppAccents.greenOnPaper)`  |

Or call `AppAccents.resolve(brightness: ..., isGreen: ...)` to pick the right one automatically.

---

## Guidance for the implementing agent

1. **Never invent values.** If a number isn't in `tokens.json` or `tokens.dart`, ask before adding it.
2. **Reference semantic aliases** (`palette.surface`, not `palette.bg2`) wherever possible.
3. **Component-specific sizes** live in `CompNode`, `CompDrawer`, `CompModeRail`, etc. in `tokens.dart`. Use them.
4. **Read `Flutter Handoff.html`** in your browser when implementing a component — the anatomy callouts show composition details.
5. **`Flutter Handoff.html` loads the live component tree** — rendered specimens match production exactly.
