#!/usr/bin/env node
/* emit-css.js — the design system's OWN utility-CSS emitter. Replaces the
   offline Tailwind compile: the class inventory (codegen/generate-inventory.js
   — tokens.js + structure-def.js + app tokens + bespoke literal extraction +
   the hover policy) is compiled DIRECTLY to CSS. No Tailwind anywhere.

   Mapping knowledge:
     - token groups are mechanical (class prefix+key → property: var(--…));
     - the structural vocabulary uses the one-time hand table in
       codegen/utility-css.js (declaration bodies verbatim from the last
       Tailwind build, --tw-* machinery included, so the cut-over is provable
       rule-for-rule against the old output.css);
     - spacing geometry (p/px/…/gap-y × the Space scale) and the numeric /
       fraction / keyword / arbitrary-value grammar the bespoke hatches use are
       small grammars implemented below;
     - variants (hover:, focus:, disabled:, placeholder:, before:,
       group-hover:, md:/lg:/xl:, min-[…]:, [&…]:) wrap declarations in the
       same nested selector/media shapes Tailwind v4 emitted.

   CASCADE: utilities are emitted into `@layer utilities`, sorted by
   (variant chain, utility family, natural name) — utility-css.js FAMILY_ORDER
   reproduces Tailwind's property order, so same-property composition
   (p-md + px-lg, border + border-t) keeps its exact winner. hover: rules wrap
   in `@media (hover: hover)` and win over base by :hover specificity.

   BREAKPOINTS are a consumer-owned config: `breakpoints` in the tokens file
   (engine defaults in tokens.js; an app overrides in its app-tokens.js, e.g.
   Overlap's sm 640 / md 960 / lg 1600 / xl 2048). They drive the emitted
   md:/lg:/xl: grid-cols media queries. `min-[Npx]:` bespoke variants stay
   literal.

   VALIDATION is loud: a class the emitter cannot compile is a hard error
   unless it is one of the exact known no-CSS classes (utility-css.js NO_CSS:
   the `group` marker + hand-written component/app rules) — the closed-
   vocabulary contract, enforced at build time.

   Outputs (mirroring generate-inventory's ownership split):
     1. PACKAGE:  <package root>/utilities.css — the package-scope inventory
        compiled with engine-default breakpoints. Imported by theme.css, so
        the published package is consumable as plain CSS with no build step.
     2. APP:      run with an app tokens file (argv[2]) — the MERGED package +
        app inventory, compiled with the app's breakpoints, written to the
        path in <app-tokens>.utilities.css. One file, globally sorted, exactly
        like the old single Tailwind output. (An app consuming this file must
        NOT also import the package utilities.css.)

   Run by `npm run theme:gen` (package half) and `npm run css:build` (both). */

const fs = require("fs");
const path = require("path");

const pkgRoot = path.join(__dirname, "..");
const tokens = require(path.join(pkgRoot, "tokens.js"));
const U = require("./utility-css");
const inventory = require("./generate-inventory");

/* ---------------- class-name plumbing ---------------- */

// Split a class into [variant, ..., base] on ':' outside brackets.
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

// CSS-escape a class name for use as a selector (Tailwind-style: every
// non-identifier character gets a backslash).
function escapeClass(cls) {
  return cls.replace(/[^A-Za-z0-9_-]/g, (ch) => "\\" + ch);
}

// Natural comparator: character-wise, comparing digit runs numerically —
// reproduces Tailwind's value ordering (h-2 < h-10 < h-[3px] < h-auto).
function naturalCompare(a, b) {
  let i = 0;
  let j = 0;
  while (i < a.length && j < b.length) {
    const ca = a[i];
    const cb = b[j];
    const da = ca >= "0" && ca <= "9";
    const db = cb >= "0" && cb <= "9";
    if (da && db) {
      let na = "";
      let nb = "";
      while (i < a.length && a[i] >= "0" && a[i] <= "9") na += a[i++];
      while (j < b.length && b[j] >= "0" && b[j] <= "9") nb += b[j++];
      const diff = parseInt(na, 10) - parseInt(nb, 10);
      if (diff !== 0) return diff;
    } else {
      if (ca !== cb) return ca < cb ? -1 : 1;
      i++;
      j++;
    }
  }
  return a.length - i - (b.length - j);
}

/* ---------------- context: what the token vocabulary means ---------------- */

function groupEntries(g) {
  return Object.values(g.variants || g.steps || {});
}

// appTokens: the app extension tokens module (or null for package scope).
function buildContext(appTokens) {
  const colors = new Map([
    ["white", "var(--color-white)"],
    ["black", "var(--color-black)"],
  ]);
  for (const g of Object.values(tokens.groups)) {
    if (g.cssVar !== "color") continue;
    for (const v of groupEntries(g)) colors.set(v.key, v.builtin ? v.key : `var(--color-${v.key})`);
  }
  for (const key of U.CONSUMER_CONTRACT_COLORS) colors.set(key, `var(--color-${key})`);
  if (appTokens) {
    for (const g of Object.values(appTokens.groups)) {
      if (!g.facetGroup) continue;
      for (const v of groupEntries(g)) {
        if (U.HANDWRITTEN_COLOR_KEYS.has(v.key)) colors.set(v.key, null); // hand-written rule, no token — skip
        else if (colors.has(v.key)) continue; // engine-class reuse idiom (key names an engine color role)
        else if (v.value === undefined && v.ref === undefined) {
          // A variant with no value:/ref: only works by REUSING an engine key —
          // any other key would compile to a live utility resolving
          // var(--color-<key>) that generate.js never registers: invisible
          // styling at runtime, no build error. Fail loud instead (same
          // hardening family as generate.js validateFacetGroup).
          throw new Error(
            `Facet variant key "${v.key}" has no value:/ref: and matches no engine color token or handwritten color key — ` +
            `its utilities would resolve var(--color-${v.key}), which nothing defines. Fix the key, or give the variant a value:/ref:.`
          );
        }
        else colors.set(v.key, `var(--color-${v.key})`);
      }
    }
  }
  const fontSize = {};
  for (const [, m] of Object.entries(tokens.groups.fontSize.steps)) fontSize[m.key] = m;
  return {
    colors,
    spacing: new Set(Object.values(tokens.groups.space.steps).map((s) => s.key)),
    radius: new Set(Object.values(tokens.groups.radius.steps).map((s) => s.key)),
    shadows: Object.fromEntries(Object.values(tokens.groups.elevation.steps).map((s) => [s.key, s.value])),
    fontSize,
    fontWeight: new Set(Object.values(tokens.groups.fontWeight.steps).map((s) => s.key)),
    // Every named maxWidth token routes to the --container-* scale — single
    // source: the maxWidth group itself. (Historically max-w-{xs..xl} collided
    // with --spacing-* under Tailwind and resolved to 0.25–1.5rem, which
    // collapsed default-width modals to 12px; owning the emitter killed the
    // collision — see the max-w note in compileBase.)
    maxWidthContainer: new Set(Object.values(tokens.groups.maxWidth.variants).map((v) => v.key)),
    breakpoints: { ...(tokens.breakpoints || {}), ...((appTokens && appTokens.breakpoints) || {}) },
  };
}

/* ---------------- value grammars ---------------- */

// Tailwind arbitrary-value decoding: [..] → raw value, underscores → spaces,
// `+`/`-` inside math functions get breathing room (calc(100%+14px) → 100% + 14px):
// CSS requires whitespace around binary +/- in calc(), so the compact form would
// otherwise emit invalid CSS the browser silently drops. The minus pass is
// operator-aware: var(--x-y) custom-property names are never touched (split out
// first), a unary minus after `(` stays attached, and exponents (1e-5) survive.
function arbitraryValue(raw) {
  let v = raw.slice(1, -1).replace(/_/g, " ");
  if (/calc\(/.test(v)) {
    // A minus directly before var() sits on the split boundary below, so space
    // it first ("var(" cannot occur inside a custom-property name).
    v = v
      .replace(/(?<=[0-9%)A-Za-z])-(?=var\()/g, " - ")
      .split(/(var\([^)]*\))/g)
      .map((seg, i) =>
        i % 2 ? seg : seg.replace(/\+/g, " + ").replace(/(?<![0-9][eE])(?<=[0-9%)A-Za-z])-(?=[0-9.(])/g, " - ")
      )
      .join("")
      .replace(/\s+/g, " ");
  }
  return v;
}

const NUMERIC_RE = /^\d+(\.\d+)?$/;
const FRACTION_RE = /^(\d+)\/(\d+)$/;

function spacingCalc(n) {
  return `calc(var(--spacing) * ${n})`;
}

// Spacing-scale value: token key → var, bare number → --spacing multiple.
function spacingValue(v, ctx) {
  if (v.startsWith("[")) return arbitraryValue(v);
  if (NUMERIC_RE.test(v)) return spacingCalc(v);
  if (ctx.spacing.has(v)) return `var(--spacing-${v})`;
  return null;
}

// Size/offset keyword tables.
const SIZE_KEYWORDS = {
  auto: "auto",
  full: "100%",
  fit: "fit-content",
  min: "min-content",
  max: "max-content",
  none: "none",
};

function sizeValue(root, v, ctx) {
  if (v.startsWith("[")) return arbitraryValue(v);
  if (NUMERIC_RE.test(v)) return spacingCalc(v);
  const m = FRACTION_RE.exec(v);
  if (m) return `calc(${m[1]}/${m[2]} * 100%)`;
  if (v === "screen") return root.endsWith("h") ? "100vh" : "100vw";
  if (v === "none") return root === "max-w" ? "none" : null;
  if (v in SIZE_KEYWORDS) return SIZE_KEYWORDS[v];
  return null;
}

function offsetValue(v, ctx) {
  if (v.startsWith("[")) return arbitraryValue(v);
  if (NUMERIC_RE.test(v)) return spacingCalc(v);
  const m = FRACTION_RE.exec(v);
  if (m) return `calc(${m[1]}/${m[2]} * 100%)`;
  if (v === "full") return "100%";
  if (v === "auto") return "auto";
  return null;
}

// Rewrite a box-shadow value so every color component routes through
// var(--tw-shadow-color, <color>) — Tailwind's shadow-color channel. Also
// normalizes the top-level segment separators to ", " (arbitrary values
// arrive comma-tight from the class name).
function shadowValue(value) {
  const segments = [];
  let depth = 0;
  let cur = "";
  for (const ch of value) {
    if (ch === "(") depth++;
    if (ch === ")") depth--;
    if (ch === "," && depth === 0) {
      segments.push(cur.trim());
      cur = "";
    } else {
      cur += ch;
    }
  }
  segments.push(cur.trim());
  return segments
    .map((s) => s.replace(/(rgba?\([^)]*\)|#[0-9a-fA-F]{3,8}|currentcolor)/g, "var(--tw-shadow-color, $1)"))
    .join(", ");
}

/* ---------------- base-class compiler ---------------- */

const SPACING_PROPS = {
  p: "padding", px: "padding-inline", py: "padding-block",
  pt: "padding-top", pr: "padding-right", pb: "padding-bottom", pl: "padding-left",
  m: "margin", mx: "margin-inline", my: "margin-block",
  mt: "margin-top", mr: "margin-right", mb: "margin-bottom", ml: "margin-left",
  gap: "gap", "gap-x": "column-gap", "gap-y": "row-gap",
};

const SIZE_PROPS = {
  w: "width", h: "height",
  "min-w": "min-width", "min-h": "min-height",
  "max-w": "max-width", "max-h": "max-height",
};

const OFFSET_PROPS = { inset: "inset", top: "top", right: "right", bottom: "bottom", left: "left" };

const BORDER_SIDES = { t: "top", r: "right", b: "bottom", l: "left", x: "inline", y: "block" };

const CORNER_PROPS = { tl: "top-left", tr: "top-right", br: "bottom-right", bl: "bottom-left" };

// Longest-first split of `base` on the LAST hyphen group boundary for a known
// multi-part root (gap-x, min-w, grid-cols, translate-x, …).
function splitRoot(base, roots) {
  for (const r of roots) {
    if (base.startsWith(r + "-") && base.length > r.length + 1) return [r, base.slice(r.length + 1)];
  }
  return null;
}

// Compile a variant-free class to { family, decls } — or null when the class
// deliberately has no rule (NO_CSS / hand-written color keys). Throws on
// anything unknown: the vocabulary is closed.
function compileBase(base, ctx) {
  if (U.NO_CSS.has(base)) return null;
  if (U.STATIC[base]) {
    const family = U.STATIC_FAMILY[base] || familyByPrefix(base);
    return { family, decls: U.STATIC[base].slice() };
  }

  let m;

  // spacing geometry + margins (longest roots first so gap-x wins over gap)
  m = splitRoot(base, ["gap-x", "gap-y", "gap", "px", "py", "pt", "pr", "pb", "pl", "p", "mx", "my", "mt", "mr", "mb", "ml", "m"]);
  if (m && SPACING_PROPS[m[0]]) {
    const val = spacingValue(m[1], ctx);
    if (val !== null) return { family: m[0], decls: [`${SPACING_PROPS[m[0]]}: ${val}`] };
  }

  // sizing
  m = splitRoot(base, ["min-w", "min-h", "max-w", "max-h", "w", "h"]);
  if (m) {
    const [root, v] = m;
    // maxWidth named scale → the --container-* widths. Under Tailwind,
    // max-w-{xs,sm,md,lg,xl} collided with our --spacing-* namespace and
    // resolved to 0.25–1.5rem — a live bug that collapsed default-width modals
    // to ~12px (found by the wave-5 visual pass; carried at parity through the
    // pipeline inversion, fixed here now that the emitter owns the names).
    if (root === "max-w") {
      if (ctx.maxWidthContainer.has(v)) return { family: "max-w", decls: [`max-width: var(--container-${v})`] };
      if (ctx.spacing.has(v) && v !== "0") return { family: "max-w", decls: [`max-width: var(--spacing-${v})`] };
    }
    const val = sizeValue(root, v, ctx);
    if (val !== null) return { family: root, decls: [`${SIZE_PROPS[root]}: ${val}`] };
  }

  // offsets
  m = splitRoot(base, ["inset", "top", "right", "bottom", "left"]);
  if (m) {
    const val = offsetValue(m[1], ctx);
    if (val !== null) return { family: m[0], decls: [`${OFFSET_PROPS[m[0]]}: ${val}`] };
  }

  // flex-basis (keyword arm `basis-auto` is in the static table)
  m = splitRoot(base, ["basis"]);
  if (m) {
    const val = spacingValue(m[1], ctx);
    if (val !== null) return { family: "basis", decls: [`flex-basis: ${val}`] };
  }

  // z / opacity / duration / grid-cols / rotate
  if ((m = /^z-(\d+)$/.exec(base))) return { family: "z", decls: [`z-index: ${m[1]}`] };
  if ((m = /^opacity-(\d+)$/.exec(base))) return { family: "opacity", decls: [`opacity: ${m[1]}%`] };
  if ((m = /^duration-(\d+)$/.exec(base))) {
    return { family: "duration", decls: [`--tw-duration: ${m[1]}ms`, `transition-duration: ${m[1]}ms`] };
  }
  if ((m = /^grid-cols-(\d+)$/.exec(base))) {
    return { family: "grid-cols", decls: [`grid-template-columns: repeat(${m[1]}, minmax(0, 1fr))`] };
  }
  if ((m = /^rotate-(\d+)$/.exec(base))) return { family: "rotate", decls: [`rotate: ${m[1]}deg`] };

  // translate
  if ((m = /^(-?)translate-([xy])-(.+)$/.exec(base))) {
    const [, neg, axis, v] = m;
    let val = offsetValue(v, ctx);
    if (val !== null) {
      if (neg) val = `calc(${val} * -1)`;
      return {
        family: `translate-${axis}`,
        decls: [`--tw-translate-${axis}: ${val}`, "translate: var(--tw-translate-x) var(--tw-translate-y)"],
      };
    }
  }

  // radius (corners before the bare scale)
  if ((m = /^rounded-(tl|tr|br|bl)-(.+)$/.exec(base)) && ctx.radius.has(m[2])) {
    return { family: `rounded-${m[1]}`, decls: [`border-${CORNER_PROPS[m[1]]}-radius: var(--radius-${m[2]})`] };
  }
  if ((m = /^rounded-(.+)$/.exec(base)) && ctx.radius.has(m[1])) {
    return { family: "rounded", decls: [`border-radius: var(--radius-${m[1]})`] };
  }

  // shadows (token scale + arbitrary values)
  if ((m = /^shadow-(.+)$/.exec(base))) {
    let raw = null;
    if (m[1].startsWith("[")) raw = arbitraryValue(m[1]);
    else if (m[1] in ctx.shadows) raw = ctx.shadows[m[1]];
    if (raw !== null) {
      const tw = raw === "none" ? "0 0 #0000" : shadowValue(raw);
      return { family: "shadow", decls: [`--tw-shadow: ${tw}`, U.BOX_SHADOW] };
    }
  }

  // colors: bg-K / text-K / border-K / border-<side>-K
  const colorOf = (key) => (ctx.colors.has(key) ? ctx.colors.get(key) : undefined);
  if (base.startsWith("bg-")) {
    const c = colorOf(base.slice(3));
    if (c === null) return null;
    if (c !== undefined) return { family: "bg", decls: [`background-color: ${c}`] };
  }
  if ((m = /^border-([trblxy])-(.+)$/.exec(base))) {
    const c = colorOf(m[2]);
    if (c === null) return null;
    if (c !== undefined) return { family: `border-color-${m[1]}`, decls: [`border-${BORDER_SIDES[m[1]]}-color: ${c}`] };
    if (m[2].startsWith("[")) {
      const len = arbitraryValue(m[2]);
      const side = BORDER_SIDES[m[1]];
      return { family: `border-w-${m[1]}`, decls: [`border-${side}-style: var(--tw-border-style)`, `border-${side}-width: ${len}`] };
    }
  }
  if (base.startsWith("border-")) {
    const c = colorOf(base.slice(7));
    if (c === null) return null;
    if (c !== undefined) return { family: "border-color", decls: [`border-color: ${c}`] };
  }

  // typography: font sizes (text-K), weights (font-K)
  if (base.startsWith("text-")) {
    const key = base.slice(5);
    if (ctx.fontSize[key]) {
      const decls = [`font-size: var(--text-${key})`];
      if (ctx.fontSize[key].lineHeight) decls.push(`line-height: var(--tw-leading, var(--text-${key}--line-height))`);
      return { family: "font-size", decls };
    }
    const c = colorOf(key);
    if (c === null) return null;
    if (c !== undefined) return { family: "text-color", decls: [`color: ${c}`] };
  }
  if (base.startsWith("font-") && ctx.fontWeight.has(base.slice(5))) {
    const key = base.slice(5);
    return { family: "font-weight", decls: [`--tw-font-weight: var(--font-weight-${key})`, `font-weight: var(--font-weight-${key})`] };
  }

  // aspect-[..] / content-[..]
  if ((m = /^aspect-(\[.+\])$/.exec(base))) return { family: "aspect", decls: [`aspect-ratio: ${arbitraryValue(m[1])}`] };
  if ((m = /^content-(\[.+\])$/.exec(base))) {
    return { family: "content", decls: [`--tw-content: ${arbitraryValue(m[1])}`, "content: var(--tw-content)"] };
  }

  throw new Error(`emit-css: cannot compile class "${base}" — extend the mapping (codegen/utility-css.js) or fix the source class`);
}

// Family for STATIC entries not listed in STATIC_FAMILY (prefix-shaped names).
function familyByPrefix(base) {
  const prefixes = [
    "pointer-events", "cursor", "inset", "items", "justify", "list",
    "overflow-x", "overflow-y", "overflow", "leading", "tracking", "whitespace", "ease",
  ];
  for (const p of prefixes) if (base === p || base.startsWith(p + "-")) return p === "cursor" ? "cursor" : p;
  throw new Error(`emit-css: no family for static class "${base}"`);
}

/* ---------------- variants ---------------- */

// Variant descriptor: { rank: [major, minor], nest: [...], before: bool }
function compileVariant(v, ctx) {
  switch (v) {
    case "group-hover":
      return { rank: [1, 0], nest: ["&:is(:where(.group):hover *)", "@media (hover: hover)"] };
    case "placeholder":
      return { rank: [2, 0], nest: ["&::placeholder"] };
    case "before":
      return { rank: [3, 0], nest: ["&::before"], before: true };
    case "hover":
      return { rank: [4, 0], nest: ["&:hover", "@media (hover: hover)"] };
    case "focus":
      return { rank: [5, 0], nest: ["&:focus"] };
    case "disabled":
      return { rank: [6, 0], nest: ["&:disabled"] };
  }
  if (ctx.breakpoints[v]) {
    const px = parseInt(ctx.breakpoints[v], 10);
    return { rank: [7, px * 10 + 1], nest: [`@media (width >= ${ctx.breakpoints[v]})`] };
  }
  const m = /^min-\[(\d+)px\]$/.exec(v);
  if (m) return { rank: [7, parseInt(m[1], 10) * 10], nest: [`@media (width >= ${m[1]}px)`] };
  if (/^\[.*\]$/.test(v)) return { rank: [8, 0], nest: [v.slice(1, -1)] };
  throw new Error(`emit-css: unknown variant "${v}:"`);
}

/* ---------------- rule assembly + rendering ---------------- */

// Compile one full class to a rule { cls, sortKey, selector, nest, decls } or null.
function compileClass(cls, ctx) {
  const parts = splitVariants(cls);
  const base = parts[parts.length - 1];
  const variants = parts.slice(0, -1);
  const compiled = compileBase(base, ctx);
  if (compiled === null) return null;

  const nest = [];
  const rank = [];
  let wantsContent = false;
  for (const v of variants) {
    const cv = compileVariant(v, ctx);
    nest.push(...cv.nest);
    rank.push(cv.rank);
    if (cv.before) wantsContent = true;
  }
  let decls = compiled.decls;
  if (wantsContent && !decls.some((d) => typeof d === "string" && d.startsWith("content:") && d.includes("var(--tw-content)"))) {
    decls = ["content: var(--tw-content)", ...decls];
  }
  const familyRank = U.FAMILY_ORDER.indexOf(compiled.family);
  if (familyRank === -1) throw new Error(`emit-css: family "${compiled.family}" (${cls}) missing from FAMILY_ORDER`);
  return { cls, selector: "." + escapeClass(cls), nest, decls, sortKey: { rank, familyRank } };
}

function compareRules(a, b) {
  // variant chain, element-wise; shorter chain first when prefixes equal
  const ra = a.sortKey.rank;
  const rb = b.sortKey.rank;
  for (let i = 0; i < Math.max(ra.length, rb.length); i++) {
    if (!ra[i]) return -1;
    if (!rb[i]) return 1;
    if (ra[i][0] !== rb[i][0]) return ra[i][0] - rb[i][0];
    if (ra[i][1] !== rb[i][1]) return ra[i][1] - rb[i][1];
  }
  if (a.sortKey.familyRank !== b.sortKey.familyRank) return a.sortKey.familyRank - b.sortKey.familyRank;
  return naturalCompare(a.cls, b.cls);
}

function renderDecls(decls, indent) {
  const lines = [];
  for (const d of decls) {
    if (typeof d === "string") lines.push(`${indent}${d};`);
    else {
      lines.push(`${indent}${d.nest} {`);
      lines.push(...renderDecls(d.decls, indent + "  "));
      lines.push(`${indent}}`);
    }
  }
  return lines;
}

function renderRule(rule) {
  const out = [`  ${rule.selector} {`];
  let ind = "    ";
  for (const n of rule.nest) {
    out.push(`${ind}${n} {`);
    ind += "  ";
  }
  out.push(...renderDecls(rule.decls, ind));
  for (let i = rule.nest.length; i > 0; i--) {
    ind = ind.slice(2);
    out.push(`${ind}}`);
  }
  out.push("  }");
  return out.join("\n");
}

function renderEngineVars() {
  const lines = U.ENGINE_VARS.map(([k, v]) => `    ${k}: ${v};`);
  return `@layer theme {\n  :root, :host {\n${lines.join("\n")}\n  }\n}`;
}

function renderProperties() {
  const blocks = U.TW_PROPERTIES.map(([name, syntax, initial]) => {
    const init = initial === null ? "" : `\n  initial-value: ${initial};`;
    return `@property ${name} {\n  syntax: ${syntax};\n  inherits: false;${init}\n}`;
  });
  const fallback = U.TW_PROPERTIES
    .map(([name, , initial]) => `      ${name}: ${initial === null ? "initial" : initial};`)
    .join("\n");
  return (
    blocks.join("\n") +
    "\n@layer properties {\n" +
    "  @supports ((-webkit-hyphens: none) and (not (margin-trim: inline))) or ((-moz-orient: inline) and (not (color:rgb(from red r g b)))) {\n" +
    "    *, ::before, ::after, ::backdrop {\n" +
    fallback +
    "\n    }\n  }\n}"
  );
}

// classes: iterable of class names. Returns the complete utilities file text.
function emitCss(classes, ctx, headerComment) {
  const rules = [];
  const seen = new Set();
  const failures = [];
  for (const cls of classes) {
    if (seen.has(cls)) continue;
    seen.add(cls);
    try {
      const rule = compileClass(cls, ctx);
      if (rule) rules.push(rule);
    } catch (e) {
      failures.push(`  ${cls}: ${e.message}`);
    }
  }
  if (failures.length > 0) {
    throw new Error(`emit-css: ${failures.length} class(es) failed to compile:\n${failures.join("\n")}`);
  }
  rules.sort(compareRules);
  return [
    headerComment,
    renderEngineVars(),
    `@layer utilities {\n${rules.map(renderRule).join("\n")}\n}`,
    renderProperties(),
    "",
  ].join("\n");
}

/* ---------------- entry points ---------------- */

function sectionClasses(sections) {
  const out = [];
  for (const { classes } of sections) out.push(...classes);
  return out;
}

const pkgHeader = `/* AUTO-GENERATED by codegen/emit-css.js — do not edit by hand.
   The package's utility CSS, compiled directly from the class inventory
   (tokens.js + structure-def.js + bespoke literals + the hover policy) — no
   Tailwind. Engine-convention variables register in @layer theme; utilities
   in @layer utilities; the --tw-* channel machinery at the end. Imported by
   theme.css. Apps with their own extension tokens consume their MERGED file
   (emit-css.js <app-tokens.js>) INSTEAD of this one. */`;

const appHeader = `/* AUTO-GENERATED by codegen/emit-css.js (from the app tokens file) — do not
   edit by hand. The MERGED package + app utility CSS: every class the typed
   vocabulary can emit, compiled with the app's breakpoints. This file
   replaces the package's utilities.css for the app build (one globally
   sorted @layer utilities block, like the old single Tailwind output). */`;

function writePackageCss() {
  const ctx = buildContext(null);
  const out = path.join(pkgRoot, "utilities.css");
  fs.writeFileSync(out, emitCss(sectionClasses(inventory.buildPackageInventory()), ctx, pkgHeader));
  return out;
}

function writeAppCss(appTokensPath) {
  const appTokens = require(appTokensPath);
  const ctx = buildContext(appTokens);
  // Fail the build on bespokeSources ↔ NoAddRawOutside allow-list drift before
  // emitting anything (no-op for consumers that declare no addRawRule).
  require("./check-bespoke-sync").checkBespokeSync(appTokensPath);
  const { sections, outPath, appDir, bespokePaths } = inventory.buildAppInventory(appTokensPath);
  const classes = [...sectionClasses(inventory.buildPackageInventory()), ...sectionClasses(sections)];
  fs.writeFileSync(outPath, emitCss(classes, ctx, appHeader));
  inventory.warnOnUndeclaredHatches(appDir, bespokePaths);
  return outPath;
}

module.exports = {
  naturalCompare, escapeClass, splitVariants, arbitraryValue, shadowValue,
  buildContext, compileBase, compileVariant, compileClass, compareRules, emitCss,
  writePackageCss, writeAppCss,
};

if (require.main === module) {
  const pkgOut = writePackageCss();
  console.log(`package utilities: ${path.relative(process.cwd(), pkgOut)}`);
  const appTokensArg = process.argv[2];
  if (appTokensArg) {
    const appOut = writeAppCss(path.resolve(process.cwd(), appTokensArg));
    console.log(`app utilities: ${path.relative(process.cwd(), appOut)}`);
  }
}
