# Flutter handoff — Trailhead workflow manager

This folder is the design-handoff package for the workflow + job UI.
Everything here is generated from one source of truth: `tokens.json`.

## What's in here

| File | Purpose |
|---|---|
| `tokens.json` | Source of truth. Every color, spacing, radius, type, motion value. Both themes (slate, paper) × both accents (orange, green) live here. |
| `lib/theme/tokens.dart` | Typed Dart mirror of `tokens.json`. Compile-time constants for every primitive + theme palettes + accents. |
| `lib/theme/app_theme.dart` | Material 3 `ThemeData` builder + custom `AppTokens` `ThemeExtension`. Call `appTheme(palette:, accent:)` from `MaterialApp`. |
| `Flutter Handoff.html` | Scrollable design doc. Components rendered in isolation with anatomy + states + token references. Open this when building. |
| `Component Catalog.html` | The same components as a deck — one component per slide. Better for "pull up the spec for the top bar" lookups. |

## How to use

```dart
import 'lib/theme/app_theme.dart';
import 'lib/theme/tokens.dart';

MaterialApp(
  theme: defaultDarkTheme(),  // Slate + Orange
  darkTheme: defaultDarkTheme(),
  // …
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

## Implementation guidance for an AI agent

1. **Never invent values.** If a number isn't in `tokens.json` or `tokens.dart`, ask before adding it.
2. **Reference semantic aliases** (`palette.surface`, not `palette.bg2`) wherever possible. They're aliased to the right `bg/fg` index in `ThemePalette`.
3. **Sizes for canvas nodes, drawer, rail, etc. live in component-specific classes** (`CompNode`, `CompDrawer`, `CompModeRail`, etc) in `tokens.dart`. Use them.
4. **Read `Flutter Handoff.html`** in your browser when implementing a component for the first time — the anatomy callouts show you how to compose it.
5. **The two handoff docs share state**; the catalog deck is a reorganization of the doc, not different content.

## Theme switching

The Slate ↔ Paper and Orange ↔ Green axes are orthogonal — any combination is valid:

| | Slate | Paper |
|---|---|---|
| **Orange** | `appTheme(palette: AppPalettes.slate, accent: AppAccents.orangeOnSlate)` | `appTheme(palette: AppPalettes.paper, accent: AppAccents.orangeOnPaper)` |
| **Green** | `appTheme(palette: AppPalettes.slate, accent: AppAccents.greenOnSlate)` | `appTheme(palette: AppPalettes.paper, accent: AppAccents.greenOnPaper)` |

Or call `AppAccents.resolve(brightness: ..., isGreen: ...)` to pick the right one.
