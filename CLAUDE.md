# tebru/elm-design — Overlap design system (single package)

One Elm package (`elm.json` name: `tebru/elm-design`), all modules namespaced `Tebru.*`. Vendored into the app as
`frontend/packages/elm-design` (a symlink to this directory — edits through either path hit the same files). Four layers:

1. **Theme** — the styling engine `Tebru.Theme.Config` (opaque builder) plus token modules. Hand-written: `Config.elm`,
   `Spacing.elm` (geometry combinators). Generated from `tokens.js`: the 9 token modules `Border`, `Elevation`, `MaxWidth`,
   `Radius`, `Space`, `Surface`, `Text`, `Transition`, `Typography`, plus `Structure.elm` (structural enums — spec data in
   `codegen/structure-def.js`, referenced from `tokens.js` via `structure:`; literal-class-per-variant + verbatim leftovers).
2. **`Tebru.Box`** — layout primitives (`row`/`stack`/`box`/`grid`), semantic tags via `withElement` (`Ul`/`Li`/`Nav`/`Section`/`Header`).
   Its responsive grid-cols matrix is the generated `Tebru.Box.GridCols` (spec in `codegen/structure-def.js`).
3. **`Tebru.Component.*`** — 27 headless components (Button, Input, Text, Link, Card, Modal, Dropdown, Notification, Skeleton, Tabs, …
   — see `exposed-modules` in `elm.json`). No variant enums: app variants are `withStyle` presets.
4. **`Tebru.Icon`** + **`Tebru.Icon.Geometry`** — Lucide icons; Geometry is generated, one top-level value per icon (tree-shakeable).

## Hard rules

1. **Generated files are never hand-edited** (each carries a generated-header comment; all listed in `.gitattributes` as
   linguist-generated): the 10 modules under `src/Tebru/Theme/` (9 token modules + `Structure.elm`), `src/Tebru/Box/GridCols.elm`,
   `src/Tebru/Icon/Geometry.elm`, `generated.css`, `palette.template.css`, `utilities.css`. To change a token: edit `tokens.js`
   (structural enums / grid matrix: `codegen/structure-def.js`) and regenerate. To change emitted shapes/headers/docs: edit
   `codegen/*.js` and regenerate. (`preflight.css` is vendored, not generated — never edit; re-vendor to upgrade.)
2. **No raw utility classes** outside generated resolvers, except deliberate bespoke styling kept behind named,
   in-code-documented module constants (`Config.addRaw` — pseudo-selectors, arbitrary px, keyframe animation hooks). The
   class vocabulary is CLOSED: `codegen/emit-css.js` fails the CSS build on any class it cannot compile.
3. **Value-free brand contract**: the engine ships no brand values. Every `--color-<role>` in `generated.css` — and the brand font
   `--font-sans` (a `cssOnly` group with an explicit `contract:` var, `--font-family-sans`; no Elm module) — delegates to a
   contract var the consumer defines (contract file: `palette.template.css`; the Overlap app's values live in `frontend/static/palette.css`).
4. **The styling model**: design-language value → token + var (`tokens.js`); structural → typed enum (`Structure`);
   spacing geometry → composition (`Spacing`); one-off → component-local named constant (never a global token).
5. **No commits** — the user manages version control. The git repository in this directory is user-managed: never commit, stage, or otherwise write to it.

## Commands (self-contained — this package has its own dev toolchain)

`devbox shell` provides elm/node/watchexec and runs `npm install` (elm-test, elm-format, elm-review,
lucide-static pinned in `package.json`). Then, from this directory:

- `npm run gen` — regenerate everything (Elm token modules + generated.css + palette.template.css + utilities.css)
- `npm test` — elm-test (420) + the codegen node suites (`npm run test:elm` / `test:codegen` individually)
- `npm run lint` — elm-review. GREEN is the contract: the app-side `No*Outside` location rules deliberately do
  NOT run here (see `review/src/ReviewConfig.elm`'s header for why); only `NoComposedAddRaw` + hygiene rules do.
- `npm run format` / `format:fix` — elm-format over the HAND-WRITTEN Elm only (`Component/`, `Box.elm`, `Icon.elm`,
  `Theme/Config.elm`, `Theme/Spacing.elm`, `tests/`). Generated modules are NOT elm-format-clean and must never be
  formatted — the generator is their formatter of record. Add new hand-written modules to both format scripts.
- `npm run watch` — run-pty watchers (format / gen / elm-test / codegen tests / review), see `run-pty-watch.json`.
- `npm run icons:gen` — regenerate `src/Tebru/Icon/Geometry.elm` (`lucide-static` resolves from this package's
  own `node_modules` now; no NODE_PATH needed).

The consuming app additionally drives the same scripts through its own npm aliases (`theme:gen`, `css:build`, …)
via the `packages/elm-design` symlink.

## Codegen (scripts live in `codegen/`)

There is NO Tailwind anywhere: the package emits its utility CSS itself.

- `npm run gen` (app alias: `theme:gen`) — runs `codegen/generate.js tokens.js` then `codegen/emit-css.js`. Output: the 10 modules in
  `src/Tebru/Theme/` (token modules + `Structure.elm`), `src/Tebru/Box/GridCols.elm`, `generated.css`, `palette.template.css`,
  `utilities.css` (CSS at this package's root). Every generated module carries a module doc comment with full `@docs` coverage.
- `codegen/generate-inventory.js` — derives the TOTAL class inventory (the closed vocabulary): the package half from
  `tokens.js` + `structure-def.js` + the package's bespoke literals + the policy-bounded `hover:` channel, and the app half from
  an app tokens file (`app-tokens.js` + its `utilities.bespokeSources` hatch modules). The hover-enumeration policy and the
  watcher retrigger contract are documented in its header. A utility-shaped literal the shape filter does not recognize in a
  bespoke hatch module is a HARD ERROR (never silently dropped) — extend `ROOTS`/`BARE` for real classes, `BLOCKLIST` for
  config keys / attribute names.
- `codegen/check-bespoke-sync.js` — asserts `utilities.bespokeSources` matches the app's `NoAddRawOutside` allow-list plus the
  explicit `utilities.bespokeExtras` list (declared via `utilities.addRawRule`; skipped when absent). Runs inside
  `emit-css.js` writeAppCss, so `npm run css:build` fails on drift.
- `codegen/emit-css.js` — the CSS EMITTER: compiles the inventory directly to utility CSS. Token classes are mechanical
  (prefix+key → `property: var(--…)`); the structural vocabulary uses the one-time hand table in `codegen/utility-css.js`
  (declaration bodies verbatim from the last Tailwind build, `--tw-*` machinery included); spacing geometry, the
  numeric/fraction/keyword/arbitrary-value grammars, and variant wrapping (hover/focus/disabled/placeholder/before/
  group-hover/responsive/`[&…]`) are implemented in the emitter. Breakpoints are a consumer-owned config (`breakpoints` in the
  tokens file; the app overrides in `app-tokens.js`). Unknown classes FAIL the build (`utility-css.js` `NO_CSS` lists the only
  exceptions). Outputs: package `utilities.css`, and with an app tokens arg the MERGED app file (`static/utilities.generated.css`).
- `codegen/bundle-css.js` — plain-CSS `@import` flattener (supports `layer(...)` wrapping); the whole app CSS "build". The
  CLI strips block comments from the bundled output only (source files keep theirs) and fails if any `@import` line survives
  bundling.
- `codegen/check-palette.js` — palette-contract checker: fails the build if the consumer's palette misses any contract var
  from `palette.template.css`. Wired into the app's `npm run css:build`; run it in any consumer's CSS build.
- `npm run icons:gen` — runs `codegen/generate-icons.js` (`lucide-static` from this package's `node_modules`).
  Output: `src/Tebru/Icon/Geometry.elm`.
- Codegen tests: `npm run test:codegen` from this directory. They exercise the app half against the REAL consumer
  config when invoked from an app root (`<cwd>/app-theme/app-tokens.js`), the vendored fixture otherwise
  (`codegen/fixtures/resolve-app-tokens.js`).

## CSS delivery files (package root)

- `theme.css` — the ONE consumer bundle entry (plain CSS, no build integration): layer-order statement + `preflight.css`
  (into layer `base`) + `generated.css` + `utilities.css` + `components.css`. A consumer imports this plus its own palette —
  through any `@import`-flattening bundler, or pre-flattened via `node codegen/bundle-css.js theme.css out.css`. An app with
  its OWN extension tokens (Overlap) does NOT import it: it emits a MERGED utilities file and assembles the same pieces minus
  `utilities.css` (see the app's `static/styles.css`).
- `preflight.css` — Tailwind v4's preflight reset, vendored verbatim in compiled form (MIT, license header in file).
- `generated.css` — token registrations as plain `:root` custom properties in cascade layer `theme`; color + brand-font tokens
  value-free (each delegates to a contract var), scales keep literal defaults.
- `utilities.css` — the emitted package-scope utility classes (layer `utilities` + the `--tw-*` channel machinery).
- `components.css` — hand-written component CSS: modal/dropdown/toast animations + the skeleton shimmer family.
- `palette.template.css` — the brand contract / starter template (loud placeholders). Consumers copy it, fill in real values,
  and `@import` their copy — never this file.

## Verify

- Tests: `npx elm-test` from this directory (`tests/{Theme,Layout,Component,Icon}`).
- Lint: `npx elm-review` from this directory. GREEN is the contract: the app-side `No*Outside` location rules deliberately do
  NOT run here (see `review/src/ReviewConfig.elm`'s header for why); only `NoComposedAddRaw` + hygiene rules do.
