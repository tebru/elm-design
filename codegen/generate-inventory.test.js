const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const {
  isClassLike,
  isNearMiss,
  extractClassLiterals,
  findNearMisses,
  extractBespoke,
  buildPackageInventory,
  buildAppInventory,
  warnOnUndeclaredHatches,
} = require("./generate-inventory");

// Real app checkout when present, vendored fixture otherwise ($APP_TOKENS overrides).
const APP_TOKENS = require("./fixtures/resolve-app-tokens").resolveAppTokens();

const allClasses = (sections) => new Set(sections.flatMap((s) => s.classes));

/* ---------------- class-shape heuristic ---------------- */

test("isClassLike accepts utility-shaped tokens incl. variants and arbitrary values", () => {
  for (const cls of [
    "bg-surface-brand",
    "w-[15.5rem]",
    "hover:underline",
    "before:content-['']",
    "min-[2048px]:aspect-[2/1]",
    "disabled:opacity-50",
    "[&>*:not(:last-child)]:border-b",
    "-translate-y-1/2",
    "md:grid-cols-4",
    "shadow-[0_4px_14px_rgba(0,0,0,0.04)]",
    "skeleton-dark",
  ]) {
    assert.ok(isClassLike(cls), `expected class-like: ${cls}`);
  }
});

test("isClassLike rejects Config keys, CSS property names, and prose", () => {
  for (const tok of [
    "border-width",
    "background-color",
    "max-width",
    "height",
    "the",
    "unknownvariant:bg-red",
    "Groups.Id_",
    "https://example.com/x",
  ]) {
    assert.ok(!isClassLike(tok), `expected NOT class-like: ${tok}`);
  }
});

test("extractClassLiterals reads string literals only and splits multi-class strings", () => {
  const elm = [
    "{-| Doc comment mentioning bg-surface-danger in prose — not a literal. -}",
    'a = Config.addRaw "flex items-center gap-sm"',
    'b = Config.set "height" "h-[42px]"',
    "-- comment px-9000",
  ].join("\n");
  const found = extractClassLiterals(elm);
  assert.deepStrictEqual([...found].sort(), ["flex", "gap-sm", "h-[42px]", "items-center"]);
});

/* ---------------- near-miss guard: unknown-shaped literals fail loudly ---------------- */

test("isNearMiss flags utility-shaped tokens the filter would silently drop", () => {
  for (const tok of ["select-none", "columns-2", "hover:select-none", "backdrop-blur-sm"]) {
    assert.ok(isNearMiss(tok), `expected near-miss: ${tok}`);
  }
});

test("isNearMiss ignores recognized classes, blocklisted keys, and non-utility shapes", () => {
  for (const tok of [
    "gap-sm", // recognized → in the inventory, not a near-miss
    "hover:underline",
    "aria-hidden", // BLOCKLIST: attribute name
    "border-width", // BLOCKLIST: config key
    "radius-tl", // BLOCKLIST: config key
    "pointer-events", // BLOCKLIST: bare config key (pointer-events-none stays a class)
    "unknownvariant:bg-red", // invalid variant chain → prose
    "the",
    "Groups.Id_",
    "https://example.com/x",
    ".5-.5h3a1", // SVG path data
  ]) {
    assert.ok(!isNearMiss(tok), `expected NOT near-miss: ${tok}`);
  }
});

test("findNearMisses reads string literals only", () => {
  const elm = ['a = Config.addRaw "flex select-none"', "-- comment columns-2"].join("\n");
  assert.deepStrictEqual([...findNearMisses(elm)], ["select-none"]);
});

test("extractBespoke FAILS LOUDLY on an unknown-shaped literal, naming literal and module", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bespoke-"));
  const bad = path.join(dir, "Bad.elm");
  fs.writeFileSync(bad, 'x = Config.addRaw "flex select-none columns-2"\n');
  assert.throws(
    () => extractBespoke([bad]),
    (e) =>
      /SILENTLY DROPPED/.test(e.message) &&
      e.message.includes('"select-none"') &&
      e.message.includes('"columns-2"') &&
      e.message.includes(bad) &&
      /extend ROOTS\/BARE/.test(e.message)
  );
});

test("warnOnUndeclaredHatches understands directory bespokeSources entries (no false warning)", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "hatch-"));
  const appDir = path.join(dir, "app-theme"); // srcRoot resolves to ../src
  const srcRoot = path.join(dir, "src");
  fs.mkdirSync(appDir);
  fs.mkdirSync(path.join(srcRoot, "Ui"), { recursive: true });
  fs.writeFileSync(path.join(srcRoot, "Ui", "Hatch.elm"), 'x =\n    Config.addRaw "flex"\n');
  fs.writeFileSync(path.join(srcRoot, "Stray.elm"), 'y =\n    Config.addRaw "flex"\n');
  const warnings = [];
  const orig = console.warn;
  console.warn = (m) => warnings.push(m);
  try {
    warnOnUndeclaredHatches(appDir, [path.join(srcRoot, "Ui")]);
  } finally {
    console.warn = orig;
  }
  assert.ok(!warnings.some((w) => w.includes("Hatch.elm")), "a file inside a declared directory must not warn");
  assert.ok(warnings.some((w) => w.includes("Stray.elm")), "an undeclared file still warns");
});

test("extractBespoke passes when every literal is recognized or plainly not a class", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "bespoke-"));
  const ok = path.join(dir, "Ok.elm");
  fs.writeFileSync(ok, ['a = Config.addRaw "flex items-center gap-sm shadow-[0_1px_2px_rgba(0,0,0,0.1)]"', 'b = Config.set "border-width" "w-full"', 'c = text "Pick a time"'].join("\n"));
  const classes = extractBespoke([ok]);
  for (const cls of ["flex", "items-center", "gap-sm", "shadow-[0_1px_2px_rgba(0,0,0,0.1)]", "w-full"]) {
    assert.ok(classes.has(cls), `expected extracted: ${cls}`);
  }
});

/* ---------------- package inventory ---------------- */

test("package inventory carries token, geometry, structure, bespoke and hover-policy classes", () => {
  const classes = allClasses(buildPackageInventory());
  const expected = [
    // engine tokens
    "bg-surface-brand",
    "text-fg-muted",
    "rounded-md",
    "rounded-tl-lg", // per-corner radius
    "shadow-sm",
    "max-w-md",
    // spacing geometry (edge x Space scale)
    "p-md",
    "gap-x-xs",
    "py-xxl",
    // structure enums + verbatim + GridCols
    "items-center",
    "overflow-y-auto",
    "h-[34px]",
    "mx-auto",
    "grid-cols-2",
    "md:grid-cols-12",
    // package bespoke literals
    "animate-modal-enter",
    "skeleton",
    // hover policy: colors / border structure / elevation / decoration / bespoke shadow
    "hover:bg-surface-brand-hover",
    "hover:text-fg-default",
    "hover:border-border-hover",
    "hover:border-dashed",
    "hover:border-t",
    "hover:shadow-md",
    "hover:shadow-[0_4px_14px_rgba(0,0,0,0.04)]",
    "hover:underline",
  ];
  for (const cls of expected) assert.ok(classes.has(cls), `package inventory missing ${cls}`);
});

test("package inventory hover-enumerates the consumer-contract color keys (Choice's hover:bg-surface-hover)", () => {
  // CONSUMER_CONTRACT_COLORS keys are composed by PACKAGE bespoke code, so the
  // PACKAGE half must emit their hover cross product — a standalone theme.css
  // consumer never merges an app half (the 9bf.4 dead-class bug).
  const classes = allClasses(buildPackageInventory());
  for (const cls of ["hover:bg-surface-hover", "hover:text-surface-hover", "hover:border-surface-hover"]) {
    assert.ok(classes.has(cls), `package inventory missing consumer-contract hover class ${cls}`);
  }
});

test("package inventory does NOT hover-enumerate non-policy families", () => {
  const classes = allClasses(buildPackageInventory());
  for (const cls of ["hover:rounded-md", "hover:p-md", "hover:w-full", "hover:font-semibold"]) {
    assert.ok(!classes.has(cls), `unexpected hover enumeration: ${cls}`);
  }
});

/* ---------------- hover channel: byte-stable golden ----------------
   The hover enumeration is derived from the `hoverable` flags in tokens.js /
   structure-def.js — the SAME flags that pin the generated withX signatures
   (generate.js configTagFor), so type boundary and hover CSS cannot drift.
   This golden pins the package half byte-for-byte: any flag/derivation change
   that alters the emitted hover class set must consciously update
   fixtures/hover-golden.json (and is, by construction, also a signature
   change visible in the generated Elm). */

test("package hover class set is byte-stable against the golden", () => {
  const golden = JSON.parse(fs.readFileSync(path.join(__dirname, "fixtures", "hover-golden.json"), "utf8"));
  const hover = [
    ...new Set(
      buildPackageInventory()
        .filter((s) => /hover channel/.test(s.comment))
        .flatMap((s) => s.classes)
    ),
  ].sort();
  assert.deepStrictEqual(hover, golden);
});

test("every hover-enumerated class comes from a hover channel section (single source)", () => {
  for (const s of buildPackageInventory()) {
    const isHoverSection = /hover channel/.test(s.comment);
    for (const cls of s.classes) {
      if (cls.startsWith("hover:") && !isHoverSection) {
        // bespoke extraction may legitimately pick up hover:* literals written
        // raw in component source (e.g. group-hover tooltips are not hover:).
        // Those are allowed only in the bespoke section.
        assert.match(s.comment, /bespoke/, `hover class ${cls} outside hover channel + bespoke: ${s.comment}`);
      }
    }
  }
});

/* ---------------- app inventory ---------------- */

test("app inventory carries app tokens, app bespoke literals, and the app hover half", () => {
  const { sections } = buildAppInventory(APP_TOKENS);
  const classes = allClasses(sections);
  const expected = [
    // app tokens (facet host prefix x key)
    "bg-avail-available",
    "text-sage-ink",
    "border-avail-border-light",
    // bespoke literals from the declared hatch modules (real app: Style.Bespoke /
    // Component.TimePicker / Ui.SearchBox / Style.Kit; fixture: Bespoke.elm)
    "pt-[20vh]",
    "w-[15.5rem]",
    "min-w-[220px]",
    "h-[42px]",
    // hover half: full color cross product + bespoke arbitrary shadow
    "hover:border-avail-border-green",
    "hover:bg-sage-wash",
    "hover:shadow-[0_4px_14px_rgba(0,0,0,0.04)]",
  ];
  for (const cls of expected) assert.ok(classes.has(cls), `app inventory missing ${cls}`);
});

/* ---------------- app inventory: every facet group, not just `appColor` ---------------- */

// Minimal two-facet-group app tokens fixture written to a temp dir: generate.js
// and emit-css.js handle any number of facet groups under any key, so the
// inventory must too (a hardcoded `appColor` read silently dropped the second
// group's classes — CSS-less classes, the closed inventory's own bug class).
function writeTwoGroupFixture() {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "app-tokens-"));
  fs.mkdirSync(path.join(dir, "src"));
  fs.writeFileSync(path.join(dir, "src", "Bespoke.elm"), 'x = Config.addRaw "pt-[20vh]"\n');
  const tokens = `module.exports = {
  breakpoints: { md: "960px" },
  utilities: { css: "./out.css", bespokeSources: ["./src"] },
  groups: {
    brandColor: {
      elmModule: "Style.BrandColor", elmType: "BrandColor", facetGroup: true,
      hosts: { surface: { fn: "surfaceClass", prefix: "bg", applyFn: "appSurface", import: "Tebru.Theme.Surface as Surface", hostWith: "withSurfaceCustom" } },
      variants: { Wash: { facet: "surface", key: "brand-wash", value: "#eee" } },
    },
    chartColor: {
      elmModule: "Style.ChartColor", elmType: "ChartColor", facetGroup: true,
      hosts: {
        surface: { fn: "surfaceClass", prefix: "bg",   applyFn: "chartSurface", import: "Tebru.Theme.Surface as Surface", hostWith: "withSurfaceCustom" },
        text:    { fn: "textClass",    prefix: "text", applyFn: "chartText",    import: "Tebru.Theme.Text as TextColor",  hostWith: "withTextCustom" },
      },
      variants: {
        Line:  { facet: "surface", key: "chart-line",  value: "#345" },
        Label: { facet: "text",    key: "chart-label", value: "#123" },
      },
    },
  },
};\n`;
  const p = path.join(dir, "app-tokens.js");
  fs.writeFileSync(p, tokens);
  return p;
}

test("buildAppInventory enumerates EVERY facet group, whatever its key (not just `appColor`)", () => {
  const { sections } = buildAppInventory(writeTwoGroupFixture());
  const classes = allClasses(sections);
  for (const cls of [
    "bg-brand-wash", // first group (not named appColor — no TypeError)
    "bg-chart-line", // second group's classes were silently dropped before
    "text-chart-label",
    "hover:bg-chart-line", // hover half covers all facet groups too
    "hover:text-brand-wash",
    "pt-[20vh]", // bespoke unaffected
  ]) {
    assert.ok(classes.has(cls), `app inventory missing ${cls}`);
  }
});

test("buildAppInventory fails LOUDLY on a variant whose facet names no host", () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "app-tokens-"));
  fs.mkdirSync(path.join(dir, "src"));
  const p = path.join(dir, "app-tokens.js");
  fs.writeFileSync(
    p,
    `module.exports = {
  utilities: { css: "./out.css", bespokeSources: ["./src"] },
  groups: { ac: { facetGroup: true, hosts: { surface: { prefix: "bg" } }, variants: { Mystery: { facet: "text", key: "mystery", value: "#000" } } } },
};\n`
  );
  assert.throws(() => buildAppInventory(p), /variant Mystery in facet group "ac".*unknown facet "text".*known hosts: surface/s);
});

/* ---------------- determinism ---------------- */

test("full inventories are idempotent (same inputs -> identical section data)", () => {
  assert.deepStrictEqual(buildPackageInventory(), buildPackageInventory());
  assert.deepStrictEqual(buildAppInventory(APP_TOKENS).sections, buildAppInventory(APP_TOKENS).sections);
});

test("buildAppInventory resolves the app utilities output path from app-tokens.js", () => {
  const { outPath } = buildAppInventory(APP_TOKENS);
  assert.strictEqual(outPath, path.resolve(path.dirname(APP_TOKENS), "../static/utilities.generated.css"));
});
