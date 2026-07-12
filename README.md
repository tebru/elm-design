# tebru/elm-design

Overlap's design system as one Elm package: a typed utility-class styling engine and token vocabulary (`Tebru.Theme.*`, with
its own CSS emitter — no Tailwind dependency), layout
primitives (`Tebru.Box`), 27 headless UI components (`Tebru.Component.*`), and Lucide icons (`Tebru.Icon` +
`Tebru.Icon.Geometry`, one generated value per icon so dead-code elimination ships only the icons you use).

## What's inside

- `Tebru.Theme.Config` — opaque style builder; components and layouts take `Config -> Config` modifier functions via `withStyle`.
- `Tebru.Theme.{Surface,Text,Border,Space,Spacing,Radius,Elevation,Typography,Structure,MaxWidth,Transition}` — typed tokens.
  Most are generated from `tokens.js`; `Structure` (structural enums) is generated too, from spec data in
  `codegen/structure-def.js`; only `Spacing` (geometry combinators) is hand-written.
- `Tebru.Box` — `row`/`stack`/`box`/`grid` flex/grid primitives; semantic elements (`ul`/`li`/`nav`/`section`/`header`) via `withElement`.
- `Tebru.Component.*` — headless components (Button, Input, Text, Link, Card, Modal, Overlay, Dropdown, Notification, Skeleton,
  Tabs, Tooltip, …). No variant enums: they bake structure plus neutral defaults, and apps define variants as `withStyle` presets
  (e.g. the Overlap app's `Style.Kit`).

## Consuming

**Elm** — add this package's `src/` to your `source-directories` (vendored or symlinked; Elm has no path dependencies), or depend
on the published package.

**CSS** — ONE plain-CSS bundle plus your palette. No Tailwind, no build integration:

```css
@import "path/to/elm-design/theme.css"; /* preflight + token vars + emitted utilities + component CSS */
@import "./palette.css";                /* your copy of palette.template.css, with real values */
```

Any bundler that flattens `@import` works; with none, pre-flatten once via `node codegen/bundle-css.js theme.css out.css`.
The utility classes are emitted by the package's OWN codegen (`codegen/emit-css.js`) from the closed class inventory
(`codegen/generate-inventory.js`: tokens + structural vocabulary + bespoke literals + the policy-bounded `hover:` enumeration
for the `withHoverStyle` channel) — no class scanning of Elm source, and a class outside the inventory fails the build.
An app with its own extension tokens does NOT import `theme.css`: it runs the emitter with its app tokens file
(`node codegen/emit-css.js app-theme/app-tokens.js` — see the Overlap app's `npm run css:build`), which produces one MERGED
utilities file (compiled with the app's own `breakpoints` config), and assembles preflight + `generated.css` +
`components.css` + that file + its palette in its entry stylesheet.

## Theming — the value-free brand contract

The engine ships **no brand values**. Every `--color-<role>` registered in `generated.css` delegates to a contract variable
(`--surface-*`, `--fg-*`, `--border-*`) that the consumer must define in a `:root` block, and the brand font follows the same
mechanism: `--font-sans` delegates to `--font-family-sans` (a `cssOnly` group in `tokens.js` with an explicit `contract:` var —
no Elm module, since Elm code never sets font-family). Overriding `--font-family-sans` re-fonts the whole app: the vendored
preflight body font and the emitted utilities both resolve through `--font-sans` (load the font files yourself — the contract
var is only the stack). Copy `palette.template.css` into your app, replace the placeholder values, and `@import` your copy.
`codegen/check-palette.js` (run it in your CSS build) fails the build if your palette misses any contract var.
Re-theming by **values** is pure CSS — no Elm change, no rebuild. Re-theming by **vocabulary** (different roles/steps) means
editing `tokens.js` and rerunning the generators. Non-brand scales (`--spacing-*`, `--radius-*`, `--text-*`, `--shadow-*`,
`--font-weight-*`) ship engine-owned defaults in `generated.css` (registered in cascade layer `theme`), so a consumer may
override any of them in a later unlayered `:root` block, but they are convention, not identity — they carry no contract.

## Generated vs hand-written

Never hand-edit (regenerate instead): the token modules in `src/Tebru/Theme/` that carry a generated header,
`src/Tebru/Icon/Geometry.elm`, `generated.css`, `palette.template.css`, `utilities.css`. Generators live in `codegen/`
(`generate.js` from `tokens.js`; `generate-inventory.js` — the total class inventory; `emit-css.js` — the utility-CSS
emitter over that inventory, with its hand mapping table in `utility-css.js`; `bundle-css.js` — the plain-CSS `@import`
flattener; `generate-icons.js` from `lucide-static`); the Overlap app runs them as `npm run theme:gen` / `npm run css:build` /
`npm run icons:gen`. `preflight.css` is VENDORED (Tailwind v4 preflight, MIT, compiled form) — re-vendor to upgrade, never edit.

## Development

- `npx elm-test` — the suite in `tests/`.
- `npx elm-review` — design-system rules in `review/`, fully armed (no allow-lists).
