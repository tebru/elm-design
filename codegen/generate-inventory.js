/* generate-inventory.js — derives the TOTAL class inventory: the complete,
   closed set of utility classes the typed vocabulary can emit. The inventory
   is the SOLE input of codegen/emit-css.js (the design system's own CSS
   emitter — no Tailwind, no scanning of Elm source): every scanner failure
   mode (composed classes, literal-arm requirement, incidental doc-comment
   coverage, stale safelists) is dead by construction, and a class outside the
   enumeration simply does not exist.

   Two builders, split by ownership (mirroring the old safelist split):

     1. buildPackageInventory()
        - engine token classes (tokens.js groups incl. radius corners)
        - spacing geometry (edge prefixes x the Space scale)
        - structural enums + verbatim leftovers + the GridCols matrix
          (codegen/structure-def.js)
        - the package's bespoke class literals (string literals extracted from
          the src/ tree, shape-filtered)
        - the package half of the HOVER CHANNEL (policy below)

     2. buildAppInventory(appTokensPath)
        - app extension token classes (host prefix x variant key)
        - the app's bespoke class literals (extracted from the module list in
          <app-tokens>.utilities.bespokeSources — the NoAddRawOutside allow-list
          plus the documented extras; see app-tokens.js)
        - the app half of the hover channel

   HOVER POLICY IS DATA — the hover channel (`withHoverStyle`) is TYPE-CLOSED:
   only setters whose group/type declares `hoverable: true` (tokens.js /
   structure-def.js) accept a Hover-tagged Config (generate.js emits the
   others as `Config Config.Standard -> ...`), and the hover: enumeration
   below is derived FROM THOSE SAME FLAGS, so the CSS half and the Elm-type
   half of the boundary cannot drift apart. What the flags currently express:

     - colors (hoverable groups with cssVar === "color"): the full
       hoverable-color-prefix cross product {bg,text,border}-<key> over every
       engine color token, every CONSUMER_CONTRACT_COLORS key (utility-css.js —
       package bespoke color keys whose var the consumer supplies, e.g.
       surface-hover for the Choice switch hover), AND every app extension
       color (any color key may host any hoverable color facet under hover,
       like the old safelists)
     - border structure (structure-def.js `hoverable: true` types + verbatim
       blocks): BorderWidth/BorderStyle variants + the border-side classes
     - elevation (hoverable, prefixed): every shadow token class, plus every
       extracted bespoke `shadow-[...]` arbitrary value (the arbitrary-value
       extension of the hoverable elevation family)
     - decoration (hoverable, prefix-less): underline / no-underline

   NOT hover-enumerated (and no longer hover-TYPEABLE — those setters accept
   only `Config Config.Standard`): radius, spacing, sizing, typography,
   opacity, … Out-of-policy hover styling is a compile error, not a silent
   no-op. The one deliberately open seam is `Config.addRaw`/`Config.set`
   (bespoke): they stay tag-polymorphic, and a raw class is hover-emitted only
   if it lands in a hover section here (today: bespoke arbitrary shadows).

   BESPOKE EXTRACTION — string literals only (never raw file text, or the
   doc-comment noise the old scanner emitted returns): every "..." literal is
   split on whitespace and shape-filtered by isClassLike. NoComposedAddRaw
   guarantees addRaw arguments concatenate only whole class tokens, so
   literal extraction is complete for the runtime class set. Named-constant
   indirection (tooltipClasses, dividerClass, ...) is covered because we
   extract ALL literals in the scanned modules, not just addRaw arguments.

   RETRIGGER CONTRACT (run-pty-watch.json's "Build CSS" watcher — run-pty's
   strict JSON config allows no comments, so the reasoning lives here): the
   emitted CSS is a pure function of
     - this file + emit-css.js + utility-css.js + tokens.js +
       codegen/structure-def.js                            (package inventory)
     - the package's src/ tree (.elm files)                (package bespoke)
     - the app's app-tokens.js                             (app inventory +
       breakpoints)
     - the app's utilities.bespokeSources modules            (app bespoke; all
       under the app's src/ and app-theme/src/ trees)
   plus the hand-written/imported CSS the bundler assembles (styles.css,
   palette.css, generated.css, app-tokens.generated.css, preflight.css,
   components.css). The watcher must retrigger on all of the above; it
   therefore watches the Elm source trees that can carry bespoke literals
   (src/, app-theme/, packages/elm-design/src/), the token + codegen JS inputs
   (packages/elm-design/{tokens.js,codegen}/, app-theme/app-tokens.js), and
   the static CSS inputs — and nothing it WRITES (utilities.css,
   utilities.generated.css, output.css), so it cannot retrigger itself. It
   must NOT need .elm-land/ or any other source: nothing else can
   contribute classes.

   Consumed by codegen/emit-css.js (run via `npm run theme:gen` and
   `npm run css:build`). Deterministic: sections are sorted and deduped, so
   reruns over unchanged inputs are byte-identical. */

const fs = require("fs");
const path = require("path");

const pkgRoot = path.join(__dirname, "..");
const tokens = require(path.join(pkgRoot, "tokens.js"));
const { CONSUMER_CONTRACT_COLORS } = require("./utility-css");

/* ---------------- class-shape heuristic (bespoke + verbatim extraction) ---------------- */

// Bare utility words the design system genuinely uses as whole classes.
const BARE = new Set([
  "flex", "grid", "block", "hidden", "inline-block", "inline-flex", "inline",
  "absolute", "relative", "fixed", "sticky", "static", "border", "group", "grow", "shrink",
  "underline", "no-underline", "truncate", "uppercase", "rounded", "transition", "italic",
  "skeleton", "skeleton-dark", "lucide-icon", "flex-wrap", "flex-nowrap", "grow-0", "shrink-0",
]);

// Utility roots: `<root>-<something>` is class-shaped.
const ROOTS = [
  "bg", "text", "border", "rounded", "shadow", "p", "pt", "pr", "pb", "pl", "px", "py",
  "m", "mt", "mr", "mb", "ml", "mx", "my", "gap", "gap-x", "gap-y", "w", "h", "min-w", "min-h",
  "max-w", "max-h", "inset", "top", "right", "bottom", "left", "z", "flex", "grid-cols",
  "items", "justify", "self", "opacity", "overflow-x", "overflow-y", "overflow", "pointer-events",
  "cursor", "font", "tracking", "leading", "whitespace", "duration", "ease", "transition",
  "animate", "translate-x", "translate-y", "-translate-x", "-translate-y", "rotate", "scale",
  "aspect", "basis", "list", "ring", "outline", "from", "to", "via", "bg-gradient",
  "content", "col-span", "row-span", "order", "space-x", "space-y", "grid-rows", "skeleton",
];

// Known NON-classes: Config keys, CSS property names, and attribute names that
// would otherwise false-positive against the roots — or trip the utility-shaped
// near-miss guard below. Listing a token here is a deliberate "not a class".
const BLOCKLIST = new Set([
  "border-side", "border-width", "border-style", "border-color", "border-radius",
  "background-color", "gap-x", "gap-y", "overflow-x", "overflow-y", "text-align",
  "font-size", "font-weight", "font-family", "max-width", "min-width", "max-height", "min-height",
  "text-overflow", "letter-spacing", "line-height", "white-space", "text-transform",
  "z-index", "text-decoration", "padding-x", "padding-y", "flex-basis", "flex-grow", "flex-shrink",
  "padding-top", "padding-right", "padding-bottom", "padding-left", // Spacing.withPadding edge slot keys
  "box-shadow", "grid-template-columns", "pointer-events",
  "radius-tl", "radius-tr", "radius-bl", "radius-br", // Radius config keys
  "aria-hidden", // attribute name (Component.Tooltip)
  "aria-checked", // attribute name (Component.Choice)
]);

const VARIANT_RE =
  /^(hover|focus|focus-visible|focus-within|active|disabled|placeholder|before|after|first|last|group-hover|min-\[[^\]]+\]|max-\[[^\]]+\]|sm|md|lg|xl|2xl)$/;

// Split a candidate on ':' outside brackets (arbitrary values/variants contain ':').
function splitVariants(tok) {
  const parts = [];
  let depth = 0;
  let cur = "";
  for (const ch of tok) {
    if (ch === "[") depth++;
    if (ch === "]") depth--;
    if (ch === ":" && depth === 0) {
      parts.push(cur);
      cur = "";
    } else {
      cur += ch;
    }
  }
  parts.push(cur);
  return parts;
}

function isClassLike(tok) {
  if (!tok || tok.length < 2) return false;
  if (!/^[!A-Za-z0-9\[\]&>*:()'\-\/.,%_+#]+$/.test(tok)) return false;
  const parts = splitVariants(tok);
  const base = parts[parts.length - 1];
  const variants = parts.slice(0, -1);
  for (const v of variants) {
    if (!(VARIANT_RE.test(v) || /^\[.*\]$/.test(v))) return false;
  }
  if (BLOCKLIST.has(base)) return false;
  const negBase = base.startsWith("-") ? base.slice(1) : base;
  if (BARE.has(negBase)) return true;
  return ROOTS.some((r) => negBase.startsWith(r + "-") && negBase.length > r.length + 1 && !BLOCKLIST.has(negBase));
}

/* ---------------- near-miss guard (bespoke completeness) ---------------- */

// A token shaped like a utility class: a lowercase root followed by one or
// more hyphen-joined value segments (plain lowercase alphanumerics, fractions,
// percentages, or [arbitrary] values). Deliberately narrow — SVG path data,
// prose, URLs, and Elm identifiers do not match.
const UTILITY_SHAPED_RE = /^-?[a-z][a-z0-9]*(-(\[[^\]]*\]|[a-z0-9./%]+))+$/;

// A token that LOOKS like a utility class (valid variant chain + utility
// shape) but that isClassLike does not recognize and BLOCKLIST does not
// exempt. Such a token in a bespoke hatch module would be silently dropped
// from the inventory — i.e. a class that renders on elements but emits no
// CSS — so extractBespoke fails loudly on it instead (the closed-vocabulary
// contract). The fix is always one of: extend ROOTS/BARE (it IS a class the
// emitter can compile), or add it to BLOCKLIST (it is a config key /
// attribute name / prose, not a class).
function isNearMiss(tok) {
  if (!tok || isClassLike(tok)) return false;
  if (!/^[!A-Za-z0-9\[\]&>*:()'\-\/.,%_+#]+$/.test(tok)) return false;
  const parts = splitVariants(tok);
  const base = parts[parts.length - 1];
  for (const v of parts.slice(0, -1)) {
    if (!(VARIANT_RE.test(v) || /^\[.*\]$/.test(v))) return false;
  }
  if (BLOCKLIST.has(base)) return false;
  return UTILITY_SHAPED_RE.test(base);
}

/* ---------------- bespoke literal extraction ---------------- */

// Class-shaped tokens inside the string LITERALS of Elm source text.
// (Doc comments are not string literals; classes mentioned there in prose are
// never extracted. Quoted examples inside doc comments do match — harmless
// over-inclusion, never under-inclusion of runtime classes.)
function extractClassLiterals(elmSource) {
  const found = new Set();
  for (const m of elmSource.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
    for (const tok of m[1].split(/\s+/)) if (isClassLike(tok)) found.add(tok);
  }
  return found;
}

// Utility-shaped literal tokens isClassLike would silently drop (see isNearMiss).
function findNearMisses(elmSource) {
  const found = new Set();
  for (const m of elmSource.matchAll(/"((?:[^"\\]|\\.)*)"/g)) {
    for (const tok of m[1].split(/\s+/)) if (isNearMiss(tok)) found.add(tok);
  }
  return found;
}

function* elmFiles(dir) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isSymbolicLink()) continue;
    if (e.isDirectory()) yield* elmFiles(p);
    else if (e.name.endsWith(".elm")) yield p;
  }
}

// paths: files or directories (directories are walked for .elm files).
// FAILS LOUDLY when a hatch module carries a utility-shaped literal the shape
// filter does not recognize: silently dropping it would mean a class with no
// emitted CSS (the exact failure mode the closed inventory exists to prevent).
function extractBespoke(paths) {
  const classes = new Set();
  const nearMisses = [];
  for (const p of paths) {
    if (!fs.existsSync(p)) throw new Error(`generate-inventory: bespoke source does not exist: ${p}`);
    const files = fs.statSync(p).isDirectory() ? [...elmFiles(p)] : [p];
    for (const f of files) {
      const src = fs.readFileSync(f, "utf8");
      for (const cls of extractClassLiterals(src)) classes.add(cls);
      for (const tok of findNearMisses(src)) nearMisses.push(`  "${tok}"  (${f})`);
    }
  }
  if (nearMisses.length > 0) {
    throw new Error(
      `generate-inventory: ${nearMisses.length} utility-shaped string literal(s) in bespoke hatch modules ` +
        `have an unrecognized shape and would be SILENTLY DROPPED from the class inventory (class on the ` +
        `element, no CSS emitted):\n${nearMisses.join("\n")}\n` +
        `If a literal IS a real utility class, extend ROOTS/BARE in codegen/generate-inventory.js (and make ` +
        `sure codegen/emit-css.js can compile it); if it is a config key / attribute name / prose, add it to BLOCKLIST.`
    );
  }
  return classes;
}

/* ---------------- package inventory ---------------- */

const EDGE_PREFIXES = ["p", "pt", "pr", "pb", "pl", "px", "py", "gap", "gap-x", "gap-y"];

// Token groups declare their entries as `variants` (roles) or `steps` (scales).
function groupEntries(g) {
  return Object.values(g.variants || g.steps || {});
}

/* ---- hover-family derivation — single-sourced from the `hoverable` flags ----
   The SAME flags type the generated withX signatures (generate.js configTagFor),
   so this enumeration and the compile-time hover boundary cannot drift apart. */

// Hoverable COLOR groups (tokens.js): their keys cross-product with every
// hoverable color prefix — any color key may host any hoverable color facet
// under hover (hover:bg-*/text-*/border-* like the old safelists).
function hoverColorKeys() {
  const keys = [];
  for (const g of Object.values(tokens.groups)) {
    if (g.cssVar !== "color" || !g.hoverable) continue;
    for (const v of groupEntries(g)) keys.push(v.key);
  }
  return keys;
}

function hoverColorPrefixes() {
  const prefixes = new Set();
  for (const g of Object.values(tokens.groups)) {
    if (g.cssVar !== "color" || !g.hoverable) continue;
    prefixes.add(g.class.prefix);
  }
  return [...prefixes];
}

// Hoverable NON-color token groups (tokens.js: elevation, decoration): each
// contributes its full class list, plus — for prefixed groups — the bespoke
// arbitrary-value extension (`<prefix>-[...]`, e.g. the bespoke card-lift
// shadows) drawn from the given bespoke literal set.
function hoverTokenGroupSections(bespoke) {
  const out = [];
  for (const [name, g] of Object.entries(tokens.groups)) {
    if (!g.hoverable || g.cssVar === "color") continue;
    const prefix = g.class.prefix;
    const cls = (key) => (prefix === "" ? key : `${prefix}-${key}`);
    const classes = groupEntries(g).map((v) => `hover:${cls(v.key)}`);
    if (prefix !== "") classes.push(...[...bespoke].filter((c) => c.startsWith(`${prefix}-[`)).map((c) => `hover:${c}`));
    out.push({ name, classes });
  }
  return out;
}

// Hoverable border-structure classes (structure-def.js): every `hoverable: true`
// structural type's variants, plus all class literals of `hoverable: true`
// verbatim blocks (withBorderSide's border/border-t/r/b/l).
function hoverStructureBases(structureDef) {
  const bases = new Set();
  for (const t of structureDef.types) {
    if (!t.hoverable) continue;
    for (const v of Object.values(t.variants)) for (const cls of [].concat(v)) bases.add(cls);
  }
  for (const block of structureDef.verbatim) {
    if (!block.hoverable) continue;
    for (const cls of extractClassLiterals(block.code)) bases.add(cls);
  }
  return [...bases];
}

function buildPackageInventory() {
  const sections = [];
  const add = (comment, classes) => sections.push({ comment, classes: [...new Set(classes)].sort() });

  // 1. Engine token groups (tokens.js).
  for (const [groupName, g] of Object.entries(tokens.groups)) {
    if (g.cssOnly || groupName === "space") continue; // fontFamily: no classes; space: geometry tier below
    const entries = g.variants || g.steps;
    const prefix = g.class && g.class.prefix;
    if (!entries || prefix == null) continue;
    const cls = (key) => (prefix === "" ? key : `${prefix}-${key}`);
    add(`engine tokens: ${groupName}`, Object.values(entries).map((v) => cls(v.key)));
    if (g.corners) {
      add(
        `engine tokens: ${groupName} per-corner`,
        Object.values(entries).flatMap((v) => ["tl", "tr", "bl", "br"].map((c) => `${prefix}-${c}-${v.key}`))
      );
    }
  }

  // 2. Spacing geometry: every edge prefix x the Space scale (Tebru.Theme.Spacing combinators).
  add(
    "spacing geometry: edge prefixes x the Space scale",
    EDGE_PREFIXES.flatMap((edge) => Object.values(tokens.groups.space.steps).map((v) => `${edge}-${v.key}`))
  );

  // 3. Structural enums + verbatim leftovers + GridCols (codegen/structure-def.js).
  const [structureDef, gridColsDef] = tokens.structure.modules;
  add(
    "structure: typed enum variants (structure-def.js)",
    structureDef.types.flatMap((t) => Object.values(t.variants).flatMap((v) => [].concat(v)))
  );
  add(
    "structure: verbatim-block literals (grow/shrink/border sides/control sizing/flex-wrap/mx-auto)",
    structureDef.verbatim.flatMap((b) => [...extractClassLiterals(b.code)])
  );
  add(
    "structure: GridCols breakpoint x columns matrix",
    gridColsDef.breakpoints.flatMap((bp) =>
      Array.from({ length: gridColsDef.maxCols }, (_, i) => `${bp.prefix}grid-cols-${i + 1}`)
    )
  );

  // 4. Package bespoke: class literals in the package's own components/resolvers.
  const pkgBespoke = extractBespoke([path.join(pkgRoot, "src")]);
  add("bespoke: class literals in the package's src tree", [...pkgBespoke]);

  // 5. Hover channel, package half — derived from the SAME `hoverable` flags
  //    that type the withX signatures (policy in the file header).
  const colorPrefixes = hoverColorPrefixes();
  add(
    `hover channel: hoverable color tokens x ${colorPrefixes.join("/")}`,
    hoverColorKeys().flatMap((key) => colorPrefixes.map((p) => `hover:${p}-${key}`))
  );
  // Consumer-contract color keys (utility-css.js CONSUMER_CONTRACT_COLORS) ride
  // the same cross product: their classes are composed by PACKAGE bespoke code
  // (Choice's hover:bg-surface-hover switch fallback), so the PACKAGE half must
  // emit them — a standalone theme.css consumer never merges an app half.
  add(
    `hover channel: consumer-contract color keys x ${colorPrefixes.join("/")}`,
    [...CONSUMER_CONTRACT_COLORS].flatMap((key) => colorPrefixes.map((p) => `hover:${p}-${key}`))
  );
  add("hover channel: hoverable border structure (width/side/style)", hoverStructureBases(structureDef).map((b) => `hover:${b}`));
  for (const { name, classes } of hoverTokenGroupSections(pkgBespoke)) {
    add(`hover channel: hoverable token group '${name}' (+ package bespoke arbitrary values)`, classes);
  }

  return sections;
}

/* ---------------- app inventory ---------------- */

function buildAppInventory(appTokensPath) {
  const appTokens = require(appTokensPath);
  const appDir = path.dirname(appTokensPath);
  const inv = appTokens.utilities || {};
  if (!inv.css || !Array.isArray(inv.bespokeSources)) {
    throw new Error(`generate-inventory: ${appTokensPath} must declare utilities.css and utilities.bespokeSources`);
  }

  const sections = [];
  const add = (comment, classes) => sections.push({ comment, classes: [...new Set(classes)].sort() });

  // ALL facet groups, whatever their names — generate.js emits Elm resolvers and
  // emit-css.js buildContext registers colors for every `facetGroup: true` group,
  // so enumerating only a hardcoded one would silently drop the others' classes
  // (the exact failure mode the closed inventory exists to prevent). Fail loudly
  // on a variant whose facet names no host (mirrors generate.js validateFacetGroup).
  const facetEntries = [];
  for (const [groupName, g] of Object.entries(appTokens.groups || {})) {
    if (!g || !g.facetGroup) continue;
    const hosts = g.hosts || {};
    for (const [ctor, v] of Object.entries(g.variants || {})) {
      if (!hosts[v.facet]) {
        throw new Error(
          `generate-inventory: variant ${ctor} in facet group "${groupName}" (${appTokensPath}) names unknown facet ` +
            `"${v.facet}" (known hosts: ${Object.keys(hosts).join(", ") || "none"})`
        );
      }
      facetEntries.push({ variant: v, prefix: hosts[v.facet].prefix });
    }
  }

  // 1. App extension tokens: facet host prefix x key (what the generated resolvers emit).
  add(
    "app tokens: facet host prefix x variant key (all facet groups in the app tokens file)",
    facetEntries.map((e) => `${e.prefix}-${e.variant.key}`)
  );

  // 2. App bespoke: class literals in the declared hatch modules.
  const bespokePaths = inv.bespokeSources.map((p) => path.resolve(appDir, p));
  const appBespoke = extractBespoke(bespokePaths);
  add("bespoke: class literals in the app's declared hatch modules (utilities.bespokeSources)", [...appBespoke]);

  // 3. Hover channel, app half — same `hoverable`-flag derivation as the
  //    package half: hoverable-color-prefix cross product over every app color
  //    key (keys without a --color-* var emit nothing and are harmless), plus
  //    the bespoke arbitrary-value extensions of the prefixed hoverable groups
  //    (shadows) found in the app's hatch modules.
  const colorPrefixes = hoverColorPrefixes();
  add(
    `hover channel: app color keys x ${colorPrefixes.join("/")}`,
    facetEntries.flatMap((e) => colorPrefixes.map((p) => `hover:${p}-${e.variant.key}`))
  );
  for (const { name, classes } of hoverTokenGroupSections(appBespoke)) {
    add(
      `hover channel: app bespoke arbitrary values for hoverable token group '${name}'`,
      classes.filter((c) => c.includes("["))
    );
  }

  return { sections, outPath: path.resolve(appDir, inv.css), appDir, bespokePaths };
}

// Loud-drift guard: bespoke class literals must stay confined to the declared
// modules. addRaw confinement is lint-enforced (NoAddRawOutside), but
// Config.set is not, so warn when a src module OUTSIDE utilities.bespokeSources
// mentions either hatch. Warning only — the lint gate owns enforcement.
function warnOnUndeclaredHatches(appDir, bespokePaths) {
  const srcRoot = path.resolve(appDir, "../src");
  if (!fs.existsSync(srcRoot)) return;
  const declared = bespokePaths.map((p) => path.resolve(p));
  // A bespokeSources entry may be a directory (extractBespoke walks it), so a
  // file counts as declared when any entry IS the file or an ancestor of it —
  // a flat Set lookup would falsely warn for every file inside a declared dir.
  const isDeclared = (f) => declared.some((p) => f === p || f.startsWith(p + path.sep));
  for (const f of elmFiles(srcRoot)) {
    if (isDeclared(path.resolve(f))) continue;
    // Strip Elm comments (line + non-nested block) so prose mentions don't trip the guard.
    const src = fs.readFileSync(f, "utf8").replace(/\{-[\s\S]*?-\}/g, "").replace(/--.*$/gm, "");
    if (/\baddRaw\b/.test(src) || /Config\.set\b/.test(src)) {
      console.warn(
        `generate-inventory: WARNING ${path.relative(srcRoot, f)} mentions addRaw/Config.set but is not in utilities.bespokeSources — its class literals are NOT in the inventory`
      );
    }
  }
}

module.exports = {
  isClassLike,
  isNearMiss,
  extractClassLiterals,
  findNearMisses,
  extractBespoke,
  buildPackageInventory,
  buildAppInventory,
  warnOnUndeclaredHatches,
  hoverColorKeys,
  hoverColorPrefixes,
  hoverStructureBases,
  hoverTokenGroupSections,
};
