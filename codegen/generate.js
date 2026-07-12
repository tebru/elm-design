#!/usr/bin/env node
// Token compiler. Run as a CLI against any tokens file:
//   overlap-theme-gen <path/to/tokens.js>
// Emits the Elm token modules + generated.css (+ palette.template.css when the
// tokens declare engine color contracts) into the tokens file's sibling `src/`.
// A consuming app points it at its OWN tokens file to generate app-specific
// typed tokens through the same disciplined pipeline.
function variantNames(group) {
  return Object.keys(group.steps || group.variants);
}

// The extensible escape-hatch constructor. Defaults to `Custom`, but when several
// extensible groups share ONE module (e.g. FontSize + FontWeight → Theme.Typography)
// a bare `Custom` would clash, so callers pass a per-type name (`<ElmType>Custom`).
function customCtorFor(group) {
  return group.customCtor || "Custom";
}

function emitType(group) {
  const ctors = variantNames(group);
  const param = group.extensible ? " a" : "";
  const head = `type ${group.elmType}${param}\n    = ${ctors[0]}`;
  const rest = ctors.slice(1).map((c) => `    | ${c}`).join("\n");
  const customLine = group.extensible ? `\n    | ${customCtorFor(group)} a` : "";
  return rest ? `${head}\n${rest}${customLine}` : `${head}${customLine}`;
}

function entries(group) {
  return Object.entries(group.steps || group.variants);
}

function classFor(group, entry) {
  const [, meta] = entry;
  return group.class.prefix ? `${group.class.prefix}-${meta.key}` : meta.key;
}

function lowerFirst(s) {
  return s.charAt(0).toLowerCase() + s.slice(1);
}

function emitResolver(group) {
  const fn = `${lowerFirst(group.elmType)}ToClass`;
  if (group.extensible) {
    const branches = entries(group)
      .map(([ctor, meta]) => `        ${ctor} ->\n            "${classFor(group, [ctor, meta])}"`)
      .join("\n\n");
    const customBranch = `        ${customCtorFor(group)} a ->\n            toCustom a`;
    return `${fn} : (a -> String) -> ${group.elmType} a -> String\n${fn} toCustom v =\n    case v of\n${branches}\n\n${customBranch}`;
  }
  const branches = entries(group)
    .map(([ctor, meta]) => `        ${ctor} ->\n            "${classFor(group, [ctor, meta])}"`)
    .join("\n\n");
  return `${fn} : ${group.elmType} -> String\n${fn} v =\n    case v of\n${branches}`;
}

// HOVER POLICY IS DATA: `hoverable: true` on a group (tokens.js) / structural
// type or verbatim block (structure-def.js) keeps the setter tag-polymorphic
// (`Config tag -> Config tag`), so it works on Hover configs and its classes
// join the hover: enumeration in generate-inventory.js. Everything else pins
// `Config Config.Standard`, making out-of-policy hover styling a COMPILE error
// instead of a silent no-op. One flag drives both the Elm types and the CSS.
function configTagFor(spec) {
  return spec.hoverable ? "tag" : "Config.Standard";
}

function emitWithX(group) {
  const { name, setter } = group.withX;
  // Config dict key: an explicit `withX.key` wins; otherwise derive it from the
  // setter name (e.g. "surface", "radius", "text"). The override exists for
  // properties that ANOTHER module's setter also targets (e.g. maxWidth vs
  // structure-def.js Size withMaxWidth) — both setters MUST share one key or
  // last-wins breaks across modules and both classes emit.
  const groupKey = group.withX.key || group.withX.setter.replace(/^set/, "").replace(/^(.)/, c => c.toLowerCase());
  const resolver = `${lowerFirst(group.elmType)}ToClass`;
  const tag = configTagFor(group);
  if (group.extensible) {
    const customName = name + "Custom";
    const customFn = `${customName} : (a -> String) -> ${group.elmType} a -> Config ${tag} -> Config ${tag}\n${customName} toCustom v =\n    Config.set "${groupKey}" (${resolver} toCustom v)`;
    const plainFn = `${name} : ${group.elmType} Never -> Config ${tag} -> Config ${tag}\n${name} =\n    ${customName} never`;
    return `${customFn}\n\n\n${plainFn}`;
  }
  return `${name} : ${group.elmType} -> Config ${tag} -> Config ${tag}\n${name} v =\n    Config.set "${groupKey}" (${resolver} v)`;
}

// Per-corner radius sugar. When a group sets `corners: true`, emit a Corner type
// plus cornerRadiusClass / withRadiusCorner / withRadiusTop / withRadiusBottom.
// CRITICAL: the per-corner classes are emitted as LITERAL strings (one branch per
// corner×step) so Tailwind's source scanner sees `rounded-tl-md` etc. — never
// build them with `++` (computed classes are invisible to the scanner).
const CORNERS = [
  ["TopLeft", "tl"],
  ["TopRight", "tr"],
  ["BottomLeft", "bl"],
  ["BottomRight", "br"],
];

function emitCorners(group) {
  const tag = configTagFor(group);
  const cornerType = "type Corner\n    = " + CORNERS.map(([c]) => c).join("\n    | ");
  const classBranches = [];
  for (const [corner, infix] of CORNERS) {
    for (const [step, meta] of entries(group)) {
      classBranches.push(`        ( ${corner}, ${step} ) ->\n            "rounded-${infix}-${meta.key}"`);
    }
  }
  // customCtorFor, not a bare `Custom`: in a shared module the ctor is renamed
  // (e.g. `RadiusCustom`) and a hardcoded `Custom` branch would not compile.
  classBranches.push(`        ( _, ${customCtorFor(group)} a ) ->\n            never a`);
  const cornerClassFn =
    `cornerRadiusClass : Corner -> ${group.elmType} Never -> String\ncornerRadiusClass corner v =\n    case ( corner, v ) of\n${classBranches.join("\n\n")}`;
  const withCornerFn =
    `withRadiusCorner : Corner -> ${group.elmType} Never -> Config ${tag} -> Config ${tag}\nwithRadiusCorner corner v =\n    Config.set (cornerSetKey corner) (cornerRadiusClass corner v)`;
  const setKeyBranches = [
    ["TopLeft", "radius-tl"],
    ["TopRight", "radius-tr"],
    ["BottomLeft", "radius-bl"],
    ["BottomRight", "radius-br"],
  ].map(([corner, key]) => `        ${corner} ->\n            "${key}"`).join("\n\n");
  const setKeyFn = `cornerSetKey : Corner -> String\ncornerSetKey corner =\n    case corner of\n${setKeyBranches}`;
  const withTopFn =
    `withRadiusTop : ${group.elmType} Never -> Config ${tag} -> Config ${tag}\nwithRadiusTop v =\n    withRadiusCorner TopLeft v >> withRadiusCorner TopRight v`;
  const withBottomFn =
    `withRadiusBottom : ${group.elmType} Never -> Config ${tag} -> Config ${tag}\nwithRadiusBottom v =\n    withRadiusCorner BottomLeft v >> withRadiusCorner BottomRight v`;
  return [cornerType, cornerClassFn, withCornerFn, setKeyFn, withTopFn, withBottomFn].join("\n\n");
}

// Consumer-contract color keys the PACKAGE's own bespoke literals reference
// (utility-css.js CONSUMER_CONTRACT_COLORS, e.g. surface-hover for the Choice
// switch hover). They are not tokens.js groups, but their utilities resolve
// var(--color-<key>) exactly like engine color roles do — so the ENGINE run
// (any tokens file that declares engine color groups) must register the
// delegation in generated.css and list the contract var in palette.template.css,
// or the emitted classes are dead for a standalone consumer and check-palette
// cannot flag the gap. App-tokens runs (facet groups only) contribute nothing.
const { CONSUMER_CONTRACT_COLORS } = require("./utility-css");

function hasEngineColorGroup(tokens) {
  return Object.values(tokens.groups).some((g) => g.cssVar === "color" && !g.facetGroup);
}

// A "color" group's VALUES are not the engine's to own — they're the consumer's
// palette. So we REGISTER each color token as a :root custom property (which the
// emitted bg-/text-/border- utilities resolve through) but DELEGATE its value to
// a contract var the consumer defines (see palette.css):
// `--color-surface-brand: var(--surface-brand)`.
// Non-color scales (space/radius/font/…) keep their literal values — they're
// conventional, not brand identity.
function isColorGroup(group) {
  return group.cssVar === "color";
}

// The consumer contract var a token delegates to, or null when the engine owns the
// value. Color groups delegate implicitly (contract var = the token key, e.g.
// --color-surface-brand → var(--surface-brand)); any other brand-identity token
// opts in by naming its contract var explicitly via `contract:` (e.g. the brand
// font: --font-sans → var(--font-family-sans)). Every non-null contract var is
// listed in palette.template.css and enforced by check-palette.js.
function contractVarFor(group, meta) {
  if (meta.contract) return meta.contract;
  return isColorGroup(group) ? meta.key : null;
}

// Fail loud on the two silent-failure modes a hand-authored config can introduce:
// (1) a variant whose `facet` matches no host → a dead ctor that maps to "" under
//     every resolver yet still emits a live --color-* line;
// (2) a variant with BOTH `value` and `ref` → two conflicting --color-* lines.
// Called from every facet entry point so neither the Elm nor the CSS path coerces.
function validateFacetGroup(group) {
  const knownHosts = Object.keys(group.hosts);
  for (const [ctor, m] of Object.entries(group.variants)) {
    if (!knownHosts.includes(m.facet)) {
      throw new Error(`Unknown facet "${m.facet}" for variant ${ctor} (known hosts: ${knownHosts.join(", ")})`);
    }
    if (m.value !== undefined && m.ref !== undefined) {
      throw new Error(`Variant ${ctor} has both value and ref (mutually exclusive)`);
    }
  }
}

function facetValueEntries(group) {
  validateFacetGroup(group);
  return Object.entries(group.variants).filter(([, m]) => m.value !== undefined);
}
function facetRefEntries(group) {
  validateFacetGroup(group);
  return Object.entries(group.variants).filter(([, m]) => m.ref !== undefined);
}

function emitThemeCss(tokens) {
  const lines = [];
  for (const group of Object.values(tokens.groups)) {
    if (group.facetGroup) {
      // Facet groups are APP-owned tokens: `value:` variants are value-AUTHORITATIVE
      // (the tokens file IS the palette, so the hex is emitted directly — one source
      // of truth, no consumer-side :root block); `ref:` variants delegate to an
      // engine role var (the engine contract still owns THOSE values).
      for (const [, m] of facetValueEntries(group)) lines.push(`  --color-${m.key}: ${m.value};`);
      for (const [, m] of facetRefEntries(group))   lines.push(`  --color-${m.key}: var(--${m.ref});`);
      continue;
    }
    if (!group.cssVar) continue; // var-less utility group (e.g. Transition) — Elm-only, no theme var
    for (const [, meta] of entries(group)) {
      if (meta.key === "0") continue; // numeric-scale built-in (calc(var(--spacing) * 0)) — no var
      if (meta.builtin) continue; // var-less CSS built-in (e.g. bg-transparent) — no theme var
      const name = `--${group.cssVar}-${meta.key}`;
      const contract = contractVarFor(group, meta);
      lines.push(contract !== null ? `  ${name}: var(--${contract});` : `  ${name}: ${meta.value};`);
      // Paired line-height var for font-size steps that declare one — the
      // emitted text-K utility reads var(--text-K--line-height).
      if (meta.lineHeight) lines.push(`  ${name}--line-height: ${meta.lineHeight};`);
    }
  }
  // Consumer-contract colors (package bespoke keys, header note above): register
  // the same value-free delegation the engine color roles get.
  if (hasEngineColorGroup(tokens)) {
    for (const key of [...CONSUMER_CONTRACT_COLORS].sort()) lines.push(`  --color-${key}: var(--${key});`);
  }
  // Plain-CSS var registration (no Tailwind @theme): :root custom properties in
  // cascade layer `theme`, so unlayered consumer overrides (palette.css) win.
  const indented = lines.map((l) => "  " + l);
  return `@layer theme {\n  :root, :host {\n${indented.join("\n")}\n  }\n}`;
}

// The theme CONTRACT, as a starter template. The engine owns NO brand values, so
// this enumerates every contract var a consumer must define (derived from tokens.js
// keys: color roles implicitly, plus explicit `contract:` tokens like the brand
// font) with a loud placeholder. A consumer copies it, fills in real values, and
// imports their own copy — it is a checklist, not a usable palette.
// Facet groups contribute NOTHING here: their `value:` hexes are emitted directly
// into @theme (the tokens file is value-authoritative), so there is no consumer
// contract to template. Returns null when no group produces a contract line
// (e.g. an app tokens file with only facet groups) — the caller skips the file.
function emitPaletteTemplate(tokens) {
  const lines = [];
  for (const group of Object.values(tokens.groups)) {
    if (group.facetGroup) continue; // value-authoritative — no contract var
    for (const [, meta] of entries(group)) {
      if (meta.key === "0") continue;
      if (meta.builtin) continue; // var-less Tailwind built-in — no contract var
      const contract = contractVarFor(group, meta);
      if (contract === null) continue; // engine-owned value (scale/utility) — no contract var
      lines.push(`  --${contract}: ${meta.placeholder || "#ff00ff"}; /* TODO: replace with your value */`);
    }
  }
  // Consumer-contract colors (package bespoke keys, header note above): the
  // consumer must define --<key> or the package's own hover:bg-<key> etc. are
  // dead — listing them here is what lets check-palette.js enforce that.
  if (hasEngineColorGroup(tokens)) {
    for (const key of [...CONSUMER_CONTRACT_COLORS].sort()) {
      lines.push(`  --${key}: #ff00ff; /* TODO: replace with your value */`);
    }
  }
  if (lines.length === 0) return null;
  return `:root {\n${lines.join("\n")}\n}`;
}

// Edge ctor -> tailwind padding/gap infix
const EDGES = { All: "p", Top: "pt", Right: "pr", Bottom: "pb", Left: "pl", Px: "px", Py: "py", Gap: "gap", GapX: "gap-x", GapY: "gap-y" };

function emitGeometryResolver(group) {
  const branches = [];
  for (const [edgeCtor, infix] of Object.entries(EDGES)) {
    for (const [step, meta] of entries(group)) {
      branches.push(`        ( ${edgeCtor}, ${step} ) ->\n            "${infix}-${meta.key}"`);
    }
  }
  return `spaceClass : Edge -> Space -> String\nspaceClass edge v =\n    case ( edge, v ) of\n${branches.join("\n\n")}`;
}

function emitFacetType(group) {
  const ctors = Object.keys(group.variants);
  return `type ${group.elmType}\n    = ${ctors[0]}` + ctors.slice(1).map((c) => `\n    | ${c}`).join("");
}
function emitFacetResolvers(group) {
  validateFacetGroup(group);
  return Object.entries(group.hosts).map(([facet, host]) => {
    const branches = Object.entries(group.variants).map(([ctor, meta]) => {
      const cls = meta.facet === facet ? `${host.prefix}-${meta.key}` : "";
      return `        ${ctor} ->\n            "${cls}"`;
    }).join("\n\n");
    return `${host.fn} : ${group.elmType} -> String\n${host.fn} c =\n    case c of\n${branches}`;
  }).join("\n\n\n");
}

const fs = require("fs");
const path = require("path");

// Module doc comment with @docs lines covering EVERY exposed name (types drop
// their `(..)`), wrapped at ~110 chars — the elm-publish documentation format.
function docComment(desc, exposed) {
  const names = exposed.map((e) => e.replace("(..)", ""));
  const lines = [];
  let cur = "@docs " + names[0];
  for (const n of names.slice(1)) {
    if (cur.length + n.length + 2 > 110) {
      lines.push(cur);
      cur = "@docs " + n;
    } else {
      cur += ", " + n;
    }
  }
  lines.push(cur);
  return `{-| ${desc}\n\n${lines.join("\n")}\n\n-}`;
}

const GENERIC_DOC =
  "Generated token module — do not edit by hand.\nTo change a token, edit the tokens file and regenerate (codegen/generate.js).";

// opts: { doc: module doc description (default GENERIC_DOC),
//         configImport: import Tebru.Theme.Config (default true),
//         extraImports: additional import lines, sans the `import ` keyword }.
function moduleHeader(elmModule, exposed, opts = {}) {
  const imports = [];
  if (opts.configImport !== false) imports.push("import Tebru.Theme.Config as Config exposing (Config)");
  for (const imp of opts.extraImports || []) imports.push(`import ${imp}`);
  const importBlock = imports.length ? imports.join("\n") + "\n" : "";
  return (
    `-- GENERATED by codegen/generate.js — do not edit by hand.\n` +
    `module ${elmModule} exposing (${exposed.join(", ")})\n\n` +
    `${docComment(opts.doc || GENERIC_DOC, exposed)}\n\n` +
    importBlock
  );
}

// The exposing list for one standard (non-geometry) group: its type, its resolver, its withX.
function moduleExposed(group) {
  const fn = `${lowerFirst(group.elmType)}ToClass`;
  const base = group.extensible
    ? [`${group.elmType}(..)`, fn, group.withX.name, group.withX.name + "Custom"]
    : [`${group.elmType}(..)`, fn, group.withX.name];
  return group.corners
    ? [...base, "Corner(..)", "withRadiusCorner", "withRadiusTop", "withRadiusBottom"]
    : base;
}

// The import's `as` alias is the SINGLE SOURCE OF TRUTH for a host's qualifier.
// Both the resolver call (`<alias>.withXCustom`) and the engine's extensible
// `Custom a` ctor (`<alias>.Custom`) must reference the SAME alias the module
// imports under, or the generated Elm imports one name and references another.
function hostAlias(host) {
  const m = / as (\S+)/.exec(host.import);
  if (!m) throw new Error(`Host import "${host.import}" must have an "as <Alias>" qualifier`);
  return m[1];
}

// Facet apply fns stay tag-polymorphic: facet groups host into the engine color
// modules, which are hoverable by policy. Self-checking — if a facet ever hosted
// into a non-hoverable module, the host's withXCustom would demand Config.Standard
// and this generated `Config tag` wrapper would fail to COMPILE, not silently no-op.
function emitFacetApplyFns(group) {
  return Object.values(group.hosts).map((host) => {
    const alias = hostAlias(host); // single source: qualifier follows the import alias
    return `${host.applyFn} : ${group.elmType} -> Config tag -> Config tag\n` +
      `${host.applyFn} c =\n    ${alias}.${host.hostWith} ${host.fn} (${alias}.Custom c)`;
  }).join("\n\n\n");
}

function emitModule(group) {
  if (group.facetGroup) {
    validateFacetGroup(group);
    const exposed = [`${group.elmType}(..)`,
      ...Object.values(group.hosts).map((h) => h.fn),
      ...Object.values(group.hosts).map((h) => h.applyFn)];
    // configImport: false — the Config import joins extraImports so the host
    // imports keep their authored order (Config last).
    const header = moduleHeader(group.elmModule, exposed, {
      doc: group.doc,
      configImport: false,
      extraImports: [...Object.values(group.hosts).map((h) => h.import), "Tebru.Theme.Config as Config exposing (Config)"],
    });
    return [header, emitFacetType(group), emitFacetResolvers(group), emitFacetApplyFns(group)].join("\n\n") + "\n";
  }
  if (group.geometry) {
    // Space module: type + Edge type + geometry resolver (withPadding lives in Theme.Spacing, hand-written)
    const exposed = [`${group.elmType}(..)`, "Edge(..)", "spaceClass"];
    const edgeType = "type Edge\n    = All\n    | Top\n    | Right\n    | Bottom\n    | Left\n    | Px\n    | Py\n    | Gap\n    | GapX\n    | GapY";
    return [moduleHeader(group.elmModule, exposed, { doc: group.doc, configImport: false }), emitType(group), edgeType, emitGeometryResolver(group)]
      .join("\n\n") + "\n";
  }
  const parts = [moduleHeader(group.elmModule, moduleExposed(group), { doc: group.doc }), emitType(group), emitResolver(group), emitWithX(group)];
  if (group.corners) parts.push(emitCorners(group));
  return parts.join("\n\n") + "\n";
}

// Several groups sharing one elmModule (e.g. Transition/Duration/Easing → Theme.Transition):
// emit each group's type + resolver + withX into a single module with a combined exposing list.
function emitMultiModule(elmModule, groups) {
  // Within ONE module, two bare `Custom` ctors would clash. When >1 extensible
  // group shares the module, give each a unique `<ElmType>Custom` ctor so the
  // generated union compiles. A lone extensible group keeps the bare `Custom`.
  const extensible = groups.filter((g) => g.extensible);
  if (extensible.length > 1) {
    for (const g of extensible) g.customCtor = `${g.elmType}Custom`;
  }
  const exposed = groups.flatMap(moduleExposed);
  const bodies = groups.flatMap((g) => g.corners
    ? [emitType(g), emitResolver(g), emitWithX(g), emitCorners(g)]
    : [emitType(g), emitResolver(g), emitWithX(g)]);
  const doc = groups.map((g) => g.doc).find((d) => d);
  return [moduleHeader(elmModule, exposed, { doc }), ...bodies].join("\n\n") + "\n";
}

// ---------------------------------------------------------------------------
// Structural-module specs (tokens.structure.modules — see codegen/structure-def.js).
// Var-less by construction: these emit Elm only, never @theme lines.

// LITERAL-CLASS-PER-VARIANT mode. No prefix-key regularity here (Display →
// "block"/"hidden", Position → "static"/…), so each variant carries its FULL
// literal class string per setter — the generator NEVER concatenates class
// fragments, keeping every class visible to Tailwind's source scanner.
function structureVariantClasses(t, ctor) {
  const v = t.variants[ctor];
  const arr = Array.isArray(v) ? v : [v];
  if (arr.length !== t.setters.length) {
    throw new Error(
      `${t.elmType}.${ctor}: expected ${t.setters.length} class(es) (one per setter: ${t.setters.map((s) => s.name).join(", ")}), got ${arr.length}`
    );
  }
  return arr;
}

function emitStructureType(t) {
  const ctors = Object.keys(t.variants);
  const doc = t.doc ? `{-| ${t.doc}\n-}\n` : "";
  return doc + `type ${t.elmType}\n    = ` + ctors.join("\n    | ");
}

// MULTI-SETTER-PER-TYPE: each setter owns its own last-wins Config key and its
// own literal class column (Size → withWidth/withHeight/…, Overflow → plain/X/Y).
function emitStructureSetter(t, i) {
  const { name, key } = t.setters[i];
  const tag = configTagFor(t);
  const branches = Object.keys(t.variants)
    .map((ctor) => `            ${ctor} ->\n                "${structureVariantClasses(t, ctor)[i]}"`)
    .join("\n\n");
  return `${name} : ${t.elmType} -> Config ${tag} -> Config ${tag}\n${name} v =\n    Config.set "${key}"\n        (case v of\n${branches}\n        )`;
}

function emitClassPerVariantModule(spec) {
  const exposed = [
    ...spec.types.map((t) => `${t.elmType}(..)`),
    ...spec.types.flatMap((t) => t.setters.map((s) => s.name)),
    ...(spec.verbatim || []).flatMap((v) => v.exposes),
  ].sort();
  const bodies = spec.types.flatMap((t) => [emitStructureType(t), ...t.setters.map((_, i) => emitStructureSetter(t, i))]);
  // VERBATIM escape: the genuinely irregular leftovers ride through as authored Elm.
  const verbatims = (spec.verbatim || []).map((v) => v.code);
  const header = moduleHeader(spec.elmModule, exposed, { doc: spec.doc, extraImports: spec.imports });
  return [header, ...bodies, ...verbatims].join("\n\n") + "\n";
}

// BREAKPOINT-COLS mode (Tebru.Box.GridCols): one closed Int case per breakpoint,
// each arm a literal class INCLUDING its breakpoint prefix — `"md:" ++ n` would
// be invisible to the scanner. Out of range falls back to fallbackCols.
function emitBreakpointColsFn(spec, bp) {
  const arms = [];
  for (let i = 1; i <= spec.maxCols; i++) arms.push(`        ${i} ->\n            "${bp.prefix}grid-cols-${i}"`);
  arms.push(`        _ ->\n            "${bp.prefix}grid-cols-${spec.fallbackCols}"`);
  return `${bp.fn} : Int -> String\n${bp.fn} n =\n    case n of\n${arms.join("\n\n")}`;
}

function emitBreakpointColsModule(spec) {
  const exposed = spec.breakpoints.map((b) => b.fn).sort();
  const header = moduleHeader(spec.elmModule, exposed, { doc: spec.doc, configImport: false });
  return [header, ...spec.breakpoints.map((b) => emitBreakpointColsFn(spec, b))].join("\n\n") + "\n";
}

function emitStructureSpec(spec) {
  if (spec.kind === "classPerVariant") return emitClassPerVariantModule(spec);
  if (spec.kind === "breakpointCols") return emitBreakpointColsModule(spec);
  throw new Error(`Unknown structure-module kind "${spec.kind}" (${spec.elmModule})`);
}

function resolveOutput(tokens, tokensPath) {
  const root = path.dirname(path.resolve(tokensPath));
  const o = tokens.output || {};
  return {
    css: path.resolve(root, o.css || "generated.css"),
    paletteTemplate: path.resolve(root, o.paletteTemplate || "palette.template.css"),
  };
}

function writeAll(tokensPath) {
  const tokens = require(path.resolve(tokensPath));
  const root = path.dirname(path.resolve(tokensPath));
  // Bucket groups by target module so multiple types can share one .elm file.
  const byModule = {};
  for (const group of Object.values(tokens.groups)) {
    if (group.cssOnly) continue; // CSS-only token (e.g. the brand font) — @theme registration only, no Elm module
    (byModule[group.elmModule] = byModule[group.elmModule] || []).push(group);
  }
  for (const [elmModule, groups] of Object.entries(byModule)) {
    const rel = elmModule.replace(/\./g, "/") + ".elm";
    const out = path.join(root, "src", rel);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, groups.length === 1 ? emitModule(groups[0]) : emitMultiModule(elmModule, groups));
  }
  // Structural-module specs (data, not tokens): literal-class enums + grid matrices.
  for (const spec of (tokens.structure && tokens.structure.modules) || []) {
    const rel = spec.elmModule.replace(/\./g, "/") + ".elm";
    const out = path.join(root, "src", rel);
    fs.mkdirSync(path.dirname(out), { recursive: true });
    fs.writeFileSync(out, emitStructureSpec(spec));
  }
  const genHeader =
    "/* AUTO-GENERATED by codegen/generate.js — do not edit by hand.\n" +
    "   Registers the design tokens as :root custom properties (cascade layer\n" +
    "   `theme`) that the emitted utilities (codegen/emit-css.js) resolve through.\n" +
    "   ENGINE color tokens are value-free: each --color-* delegates to a consumer-\n" +
    "   defined contract var (contract: palette.template.css; the consuming app\n" +
    "   defines the values, e.g. static/palette.css), so the engine ships no brand\n" +
    "   values. FACET-group (app-owned) color tokens are value-AUTHORITATIVE: the\n" +
    "   tokens file is the palette, so `value:` hexes are emitted directly (edit the\n" +
    "   tokens file + regen to re-skin) and `ref:` variants delegate to engine roles.\n" +
    "   The brand font is likewise value-free (--font-sans → var(--font-family-sans)).\n" +
    "   Scales (space/radius/text/…) keep their literal defaults. */\n";

  const templateHeader =
    "/* AUTO-GENERATED by codegen/generate.js — do not edit by hand.\n" +
    "   Theme CONTRACT / starter template. The engine ships NO brand values; each\n" +
    "   --color-<role> in generated.css — plus the brand font --font-sans — resolves\n" +
    "   to one of the vars below, which the CONSUMER must define. Copy this into your\n" +
    "   app, replace the placeholder values, and @import your copy (NOT this file). */\n";

  const outPaths = resolveOutput(tokens, tokensPath);
  fs.mkdirSync(path.dirname(outPaths.css), { recursive: true });
  fs.writeFileSync(outPaths.css, genHeader + emitThemeCss(tokens) + "\n");
  // No contract lines (e.g. an app tokens file whose colors are all value-
  // authoritative facet variants) → no template file: nothing to fill in.
  const template = emitPaletteTemplate(tokens);
  if (template !== null) {
    fs.mkdirSync(path.dirname(outPaths.paletteTemplate), { recursive: true });
    fs.writeFileSync(outPaths.paletteTemplate, templateHeader + template + "\n");
  }
}

if (require.main === module) {
  writeAll(process.argv[2] || path.join(__dirname, "..", "tokens.js"));
}

module.exports = {
  configTagFor,
  emitType, emitResolver, emitWithX, emitThemeCss, emitPaletteTemplate, emitGeometryResolver, emitCorners,
  emitModule, emitMultiModule, moduleExposed, writeAll, variantNames, resolveOutput, contractVarFor,
  emitFacetType, emitFacetResolvers, emitFacetApplyFns, facetValueEntries, facetRefEntries,
  docComment, moduleHeader, emitStructureSpec, emitClassPerVariantModule, emitBreakpointColsModule,
};
