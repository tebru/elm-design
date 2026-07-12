const { test } = require("node:test");
const assert = require("node:assert");
const path = require("path");
const {
  naturalCompare, escapeClass, arbitraryValue, shadowValue,
  buildContext, compileBase, compileClass, compareRules, emitCss,
} = require("./emit-css");
const U = require("./utility-css");
const structureDef = require("./structure-def");
const inventory = require("./generate-inventory");

// Real app checkout when present, vendored fixture otherwise ($APP_TOKENS overrides).
const APP_TOKENS = require("./fixtures/resolve-app-tokens").resolveAppTokens();
const ctx = buildContext(require(APP_TOKENS));
const pkgCtx = buildContext(null);

/* ---------------- token mapping (mechanical prefix+key -> var) ---------------- */

test("buildContext FAILS LOUDLY on a valueless/ref-less facet key matching no engine color token", () => {
  // A keyless variant only works by REUSING an engine color key; any other key
  // would emit a live utility resolving a var nothing registers — dead styling.
  const facetGroup = (key) => ({
    groups: { x: { facetGroup: true, hosts: { surface: { prefix: "bg" } }, variants: { BrandSage: { facet: "surface", key } } } },
  });
  assert.throws(() => buildContext(facetGroup("surface-brnad")), /surface-brnad.*var\(--color-surface-brnad\), which nothing defines/s);
  // The engine-reuse idiom (real engine role) and handwritten keys still pass.
  assert.deepStrictEqual(
    compileBase("bg-surface-brand", buildContext(facetGroup("surface-brand"))).decls,
    ["background-color: var(--color-surface-brand)"]
  );
  buildContext(facetGroup("busy-cell")); // HANDWRITTEN_COLOR_KEYS — no throw
});

test("color tokens map to their property + --color-* var per prefix", () => {
  assert.deepStrictEqual(compileBase("bg-surface-brand", ctx).decls, ["background-color: var(--color-surface-brand)"]);
  assert.deepStrictEqual(compileBase("text-fg-muted", ctx).decls, ["color: var(--color-fg-muted)"]);
  assert.deepStrictEqual(compileBase("border-border-default", ctx).decls, ["border-color: var(--color-border-default)"]);
  assert.deepStrictEqual(compileBase("bg-avail-available", ctx).decls, ["background-color: var(--color-avail-available)"]); // app token
});

test("builtin colors stay var-less; white/black route through the engine vars", () => {
  assert.deepStrictEqual(compileBase("bg-transparent", ctx).decls, ["background-color: transparent"]);
  assert.deepStrictEqual(compileBase("border-transparent", ctx).decls, ["border-color: transparent"]);
  assert.deepStrictEqual(compileBase("bg-white", ctx).decls, ["background-color: var(--color-white)"]);
});

test("border-side colors map to the side/axis color property", () => {
  assert.deepStrictEqual(compileBase("border-r-dark", ctx).decls, ["border-right-color: var(--color-dark)"]);
  assert.deepStrictEqual(compileBase("border-y-transparent", ctx).decls, ["border-block-color: transparent"]);
});

test("radius tokens: bare scale + per-corner classes", () => {
  assert.deepStrictEqual(compileBase("rounded-md", ctx).decls, ["border-radius: var(--radius-md)"]);
  assert.deepStrictEqual(compileBase("rounded-tl-lg", ctx).decls, ["border-top-left-radius: var(--radius-lg)"]);
  assert.deepStrictEqual(compileBase("rounded", ctx).decls, ["border-radius: 0.25rem"]); // unnamed bespoke default
});

test("elevation tokens inline their value through the --tw-shadow channel", () => {
  const md = compileBase("shadow-md", ctx).decls;
  assert.strictEqual(md[0], "--tw-shadow: 0 4px 14px 0 var(--tw-shadow-color, rgb(0 0 0 / 0.1))");
  assert.strictEqual(md[1], U.BOX_SHADOW);
  assert.strictEqual(compileBase("shadow-none", ctx).decls[0], "--tw-shadow: 0 0 #0000");
});

test("font sizes pair with their line-height var; xxs is font-size only", () => {
  assert.deepStrictEqual(compileBase("text-sm", ctx).decls, [
    "font-size: var(--text-sm)",
    "line-height: var(--tw-leading, var(--text-sm--line-height))",
  ]);
  assert.deepStrictEqual(compileBase("text-xxs", ctx).decls, ["font-size: var(--text-xxs)"]);
});

test("font weights set the --tw-font-weight channel and the property", () => {
  assert.deepStrictEqual(compileBase("font-semibold", ctx).decls, [
    "--tw-font-weight: var(--font-weight-semibold)",
    "font-weight: var(--font-weight-semibold)",
  ]);
});

/* ---------------- spacing geometry + numeric grammar ---------------- */

test("spacing geometry: edge prefixes x the Space scale", () => {
  assert.deepStrictEqual(compileBase("p-md", ctx).decls, ["padding: var(--spacing-md)"]);
  assert.deepStrictEqual(compileBase("px-xl", ctx).decls, ["padding-inline: var(--spacing-xl)"]);
  assert.deepStrictEqual(compileBase("gap-y-xxs", ctx).decls, ["row-gap: var(--spacing-xxs)"]);
  assert.deepStrictEqual(compileBase("p-0", ctx).decls, ["padding: calc(var(--spacing) * 0)"]); // 0 = numeric scale
});

test("numeric scale: bare numbers are --spacing multiples (margins, sizes, offsets)", () => {
  assert.deepStrictEqual(compileBase("mt-1", ctx).decls, ["margin-top: calc(var(--spacing) * 1)"]);
  assert.deepStrictEqual(compileBase("h-1.5", ctx).decls, ["height: calc(var(--spacing) * 1.5)"]);
  assert.deepStrictEqual(compileBase("px-2.5", ctx).decls, ["padding-inline: calc(var(--spacing) * 2.5)"]);
  assert.deepStrictEqual(compileBase("top-0", ctx).decls, ["top: calc(var(--spacing) * 0)"]);
});

test("keywords and fractions: full/screen/fit/min/max/auto/none, a/b -> percentage", () => {
  assert.deepStrictEqual(compileBase("w-full", ctx).decls, ["width: 100%"]);
  assert.deepStrictEqual(compileBase("h-screen", ctx).decls, ["height: 100vh"]);
  assert.deepStrictEqual(compileBase("min-w-screen", ctx).decls, ["min-width: 100vw"]);
  assert.deepStrictEqual(compileBase("max-w-none", ctx).decls, ["max-width: none"]);
  assert.deepStrictEqual(compileBase("w-fit", ctx).decls, ["width: fit-content"]);
  assert.deepStrictEqual(compileBase("top-1/2", ctx).decls, ["top: calc(1/2 * 100%)"]);
  assert.deepStrictEqual(compileBase("left-full", ctx).decls, ["left: 100%"]);
});

test("maxWidth scale: every named step -> --container-* (the historical --spacing-* collision that collapsed modals is dead)", () => {
  assert.deepStrictEqual(compileBase("max-w-2xl", ctx).decls, ["max-width: var(--container-2xl)"]);
  assert.deepStrictEqual(compileBase("max-w-3xs", ctx).decls, ["max-width: var(--container-3xs)"]);
  assert.deepStrictEqual(compileBase("max-w-md", ctx).decls, ["max-width: var(--container-md)"]);
});

test("translate composes the --tw-translate channel, negatives multiply by -1", () => {
  assert.deepStrictEqual(compileBase("-translate-y-1/2", ctx).decls, [
    "--tw-translate-y: calc(calc(1/2 * 100%) * -1)",
    "translate: var(--tw-translate-x) var(--tw-translate-y)",
  ]);
});

test("z / opacity / duration / grid-cols / rotate numeric utilities", () => {
  assert.deepStrictEqual(compileBase("z-30", ctx).decls, ["z-index: 30"]);
  assert.deepStrictEqual(compileBase("opacity-60", ctx).decls, ["opacity: 60%"]);
  assert.deepStrictEqual(compileBase("duration-200", ctx).decls, ["--tw-duration: 200ms", "transition-duration: 200ms"]);
  assert.deepStrictEqual(compileBase("grid-cols-7", ctx).decls, ["grid-template-columns: repeat(7, minmax(0, 1fr))"]);
  assert.deepStrictEqual(compileBase("rotate-45", ctx).decls, ["rotate: 45deg"]);
});

/* ---------------- arbitrary-value grammar (the bespoke subset) ---------------- */

test("arbitrary values: length/viewport/calc, underscores to spaces, calc operator spacing", () => {
  assert.deepStrictEqual(compileBase("h-[34px]", ctx).decls, ["height: 34px"]);
  assert.deepStrictEqual(compileBase("w-[15.5rem]", ctx).decls, ["width: 15.5rem"]);
  assert.deepStrictEqual(compileBase("max-h-[80vh]", ctx).decls, ["max-height: 80vh"]);
  assert.deepStrictEqual(compileBase("pt-[20vh]", ctx).decls, ["padding-top: 20vh"]);
  assert.deepStrictEqual(compileBase("left-[-12px]", ctx).decls, ["left: -12px"]);
  assert.deepStrictEqual(compileBase("top-[calc(100%+14px)]", ctx).decls, ["top: calc(100% + 14px)"]);
  assert.deepStrictEqual(compileBase("aspect-[2/1]", ctx).decls, ["aspect-ratio: 2/1"]);
});

test("arbitrary border widths keep the --tw-border-style channel", () => {
  assert.deepStrictEqual(compileBase("border-y-[5px]", ctx).decls, [
    "border-block-style: var(--tw-border-style)",
    "border-block-width: 5px",
  ]);
});

test("arbitrary shadows: underscores to spaces, colors wrapped in --tw-shadow-color, segments comma-joined", () => {
  const decls = compileBase("shadow-[-4px_6px_14px_-3px_rgba(0,0,0,0.35),-2px_3px_6px_-2px_rgba(0,0,0,0.25)]", ctx).decls;
  assert.strictEqual(
    decls[0],
    "--tw-shadow: -4px 6px 14px -3px var(--tw-shadow-color, rgba(0,0,0,0.35)), -2px 3px 6px -2px var(--tw-shadow-color, rgba(0,0,0,0.25))"
  );
  assert.strictEqual(
    compileBase("shadow-[inset_0_1px_0_rgba(255,255,255,0.15)]", ctx).decls[0],
    "--tw-shadow: inset 0 1px 0 var(--tw-shadow-color, rgba(255,255,255,0.15))"
  );
});

test("content-[''] sets the --tw-content channel", () => {
  assert.deepStrictEqual(compileBase("content-['']", ctx).decls, ["--tw-content: ''", "content: var(--tw-content)"]);
});

/* ---------------- variant wrapping ---------------- */

test("hover wraps in :hover + (hover: hover) media", () => {
  const r = compileClass("hover:bg-surface-brand-hover", ctx);
  assert.deepStrictEqual(r.nest, ["&:hover", "@media (hover: hover)"]);
  assert.strictEqual(r.selector, ".hover\\:bg-surface-brand-hover");
});

test("before injects content: var(--tw-content) ahead of the declarations", () => {
  const r = compileClass("before:absolute", ctx);
  assert.deepStrictEqual(r.nest, ["&::before"]);
  assert.deepStrictEqual(r.decls, ["content: var(--tw-content)", "position: absolute"]);
  // …but not when the base itself sets content
  const c = compileClass("before:content-['']", ctx);
  assert.deepStrictEqual(c.decls, ["--tw-content: ''", "content: var(--tw-content)"]);
});

test("stacked variants chain their nests (hover:before:*)", () => {
  const r = compileClass("hover:before:opacity-100", ctx);
  assert.deepStrictEqual(r.nest, ["&:hover", "@media (hover: hover)", "&::before"]);
  assert.deepStrictEqual(r.decls, ["content: var(--tw-content)", "opacity: 100%"]);
});

test("group-hover / placeholder / focus / disabled shapes", () => {
  assert.deepStrictEqual(compileClass("group-hover:opacity-100", ctx).nest, ["&:is(:where(.group):hover *)", "@media (hover: hover)"]);
  assert.deepStrictEqual(compileClass("placeholder:text-fg-muted", ctx).nest, ["&::placeholder"]);
  assert.deepStrictEqual(compileClass("focus:border-border-focus", ctx).nest, ["&:focus"]);
  assert.deepStrictEqual(compileClass("disabled:opacity-50", ctx).nest, ["&:disabled"]);
});

test("arbitrary selector variants become real child-selector rules", () => {
  const r = compileClass("[&>*:not(:last-child)]:border-b", ctx);
  assert.deepStrictEqual(r.nest, ["&>*:not(:last-child)"]);
  assert.strictEqual(r.selector, ".\\[\\&\\>\\*\\:not\\(\\:last-child\\)\\]\\:border-b");
});

/* ---------------- breakpoints: a consumer-owned config ---------------- */

test("app breakpoints override the engine defaults in responsive variants", () => {
  assert.deepStrictEqual(compileClass("md:grid-cols-2", ctx).nest, ["@media (width >= 960px)"]);
  assert.deepStrictEqual(compileClass("lg:grid-cols-2", ctx).nest, ["@media (width >= 1600px)"]);
  assert.deepStrictEqual(compileClass("xl:grid-cols-2", ctx).nest, ["@media (width >= 2048px)"]);
  // package scope falls back to the engine defaults in tokens.js
  assert.deepStrictEqual(compileClass("md:grid-cols-2", pkgCtx).nest, ["@media (width >= 768px)"]);
});

test("min-[Npx] arbitrary breakpoints stay literal regardless of config", () => {
  assert.deepStrictEqual(compileClass("min-[2048px]:aspect-[2/1]", ctx).nest, ["@media (width >= 2048px)"]);
});

/* ---------------- no-CSS classes + loud failure ---------------- */

test("known no-CSS classes (markers + hand-written rules) compile to nothing", () => {
  for (const cls of ["group", "skeleton", "lucide-icon", "animate-modal-enter", "bg-busy-cell"]) {
    assert.strictEqual(compileClass(cls, ctx), null, `${cls} should emit no rule`);
  }
});

test("border-border (dead legacy token, dropped from NO_CSS) is a hard error again", () => {
  // List.dividerClass now emits border-border-default; nothing references the
  // old no-op class, so it must fall through to the closed-vocabulary error.
  assert.throws(() => compileBase("border-border", ctx), /cannot compile/);
});

test("hover cross-product entries for hand-written color keys are skipped like Tailwind skipped them", () => {
  assert.strictEqual(compileClass("hover:bg-busy-cell", ctx), null);
  assert.strictEqual(compileClass("hover:border-proposed-block", ctx), null);
});

test("an unknown class is a hard, loud error (closed vocabulary)", () => {
  assert.throws(() => compileBase("bg-nonexistent-color", ctx), /cannot compile/);
  assert.throws(() => compileBase("tw-nonsense", ctx), /cannot compile/);
  assert.throws(() => emitCss(["bg-nope"], ctx, "/*x*/"), /failed to compile/);
});

/* ---------------- structure coverage: every structure-def variant compiles ---------------- */

test("every structure-def literal class compiles (table completeness)", () => {
  const [structure, gridCols] = structureDef.modules;
  const classes = new Set();
  for (const t of structure.types) {
    for (const v of Object.values(t.variants)) for (const cls of [].concat(v)) classes.add(cls);
  }
  for (const block of structure.verbatim) {
    for (const cls of inventory.extractClassLiterals(block.code)) classes.add(cls);
  }
  for (const bp of gridCols.breakpoints) {
    for (let n = 1; n <= gridCols.maxCols; n++) classes.add(`${bp.prefix}grid-cols-${n}`);
  }
  for (const cls of classes) {
    assert.doesNotThrow(() => compileClass(cls, ctx), `structure class failed: ${cls}`);
  }
});

test("the full package + app inventory compiles end to end", () => {
  const classes = [
    ...inventory.buildPackageInventory().flatMap((s) => s.classes),
    ...inventory.buildAppInventory(APP_TOKENS).sections.flatMap((s) => s.classes),
  ];
  assert.doesNotThrow(() => emitCss(classes, ctx, "/* smoke */"));
});

/* ---------------- ordering ---------------- */

test("cascade order: shorthand before axis before edge; variants after base; natural value sort", () => {
  const order = (names) =>
    names
      .map((n) => compileClass(n, ctx))
      .sort(compareRules)
      .map((r) => r.cls);
  assert.deepStrictEqual(order(["pt-md", "p-md", "px-md"]), ["p-md", "px-md", "pt-md"]);
  assert.deepStrictEqual(order(["border-t", "border"]), ["border", "border-t"]);
  assert.deepStrictEqual(order(["hover:bg-dark", "bg-dark", "md:grid-cols-2", "before:absolute"]), [
    "bg-dark", "before:absolute", "hover:bg-dark", "md:grid-cols-2",
  ]);
  assert.deepStrictEqual(order(["h-10", "h-2", "h-[3px]", "h-auto"]), ["h-2", "h-10", "h-[3px]", "h-auto"]);
  assert.deepStrictEqual(order(["transition-none", "transition-opacity"]), ["transition-opacity", "transition-none"]);
});

test("naturalCompare basics", () => {
  assert.ok(naturalCompare("duration-75", "duration-150") < 0);
  assert.ok(naturalCompare("max-w-2xl", "max-w-2xs") < 0);
  assert.ok(naturalCompare("top-1", "top-1/2") < 0);
  assert.ok(naturalCompare("shadow-[-4px", "shadow-[0_1px") < 0);
});

/* ---------------- helpers ---------------- */

test("escapeClass escapes every non-identifier character", () => {
  assert.strictEqual(escapeClass("h-1.5"), "h-1\\.5");
  assert.strictEqual(escapeClass("top-1/2"), "top-1\\/2");
  assert.strictEqual(escapeClass("min-[2048px]:aspect-[2/1]"), "min-\\[2048px\\]\\:aspect-\\[2\\/1\\]");
});

test("arbitraryValue / shadowValue transforms", () => {
  assert.strictEqual(arbitraryValue("[inset_0_1px_0_rgba(255,255,255,0.15)]"), "inset 0 1px 0 rgba(255,255,255,0.15)");
  assert.strictEqual(arbitraryValue("[calc(100%+14px)]"), "calc(100% + 14px)");
  // Binary minus needs the same breathing room as plus — CSS drops
  // calc(100%-14px) as invalid. Unary minus, var() names, exponents survive.
  assert.strictEqual(arbitraryValue("[calc(100%-14px)]"), "calc(100% - 14px)");
  assert.strictEqual(arbitraryValue("[calc(100%-var(--x-y))]"), "calc(100% - var(--x-y))");
  assert.strictEqual(arbitraryValue("[calc(-50%-8px)]"), "calc(-50% - 8px)");
  assert.strictEqual(arbitraryValue("[calc(1e-5*100px)]"), "calc(1e-5*100px)");
  assert.strictEqual(shadowValue("0 1px 2px rgb(0 0 0 / 0.05)"), "0 1px 2px var(--tw-shadow-color, rgb(0 0 0 / 0.05))");
  assert.strictEqual(shadowValue("0 0 4px currentcolor"), "0 0 4px var(--tw-shadow-color, currentcolor)");
});
