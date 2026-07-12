const { test } = require("node:test");
const assert = require("node:assert");
const path = require("path");
const { emitType, emitResolver, emitWithX, emitThemeCss, emitGeometryResolver, emitPaletteTemplate, emitCorners, emitModule, emitMultiModule } = require("./generate");

test("resolveOutput defaults CSS next to the tokens file", () => {
  const { resolveOutput } = require("./generate");
  const out = resolveOutput({ groups: {} }, "/x/tokens.js");
  assert.strictEqual(out.css, path.resolve("/x/generated.css"));
  assert.strictEqual(out.paletteTemplate, path.resolve("/x/palette.template.css"));
});
test("resolveOutput honors tokens.output overrides (relative to tokens dir)", () => {
  const { resolveOutput } = require("./generate");
  const out = resolveOutput(
    { output: { css: "../static/app.generated.css", paletteTemplate: "../static/app.palette.css" }, groups: {} },
    "/x/app-theme/app-tokens.js"
  );
  assert.strictEqual(out.css, path.resolve("/x/static/app.generated.css"));
  assert.strictEqual(out.paletteTemplate, path.resolve("/x/static/app.palette.css"));
});

test("emitType renders an Elm union from a simple-scale group", () => {
  const group = { elmType: "Radius", steps: { Sm: {}, Md: {}, Lg: {}, Full: {} } };
  assert.strictEqual(emitType(group), "type Radius\n    = Sm\n    | Md\n    | Lg\n    | Full");
});

test("emitType appends Custom a for an extensible group", () => {
  const group = { elmType: "Radius", extensible: true, steps: { Sm: {}, Lg: {} } };
  assert.strictEqual(emitType(group), "type Radius a\n    = Sm\n    | Lg\n    | Custom a");
});

test("emitResolver builds literal classes for a simple-scale group", () => {
  const group = { elmType: "Radius", class: { prefix: "rounded" },
    steps: { Sm: { key: "sm" }, Lg: { key: "lg" } } };
  assert.strictEqual(
    emitResolver(group),
    "radiusToClass : Radius -> String\nradiusToClass v =\n    case v of\n        Sm ->\n            \"rounded-sm\"\n\n        Lg ->\n            \"rounded-lg\""
  );
});

test("emitResolver uses the role key verbatim with the bg prefix", () => {
  const group = { elmType: "Surface", class: { prefix: "bg" },
    variants: { Card: { key: "surface-card" } } };
  assert.match(emitResolver(group), /Card ->\n {12}"bg-surface-card"/);
});

test("emitResolver is handler-threaded for an extensible group", () => {
  const group = { elmType: "Surface", extensible: true, class: { prefix: "bg" },
    variants: { Card: { key: "surface-card" } } };
  const out = emitResolver(group);
  assert.match(out, /surfaceToClass : \(a -> String\) -> Surface a -> String/);
  assert.match(out, /surfaceToClass toCustom v =/);
  assert.match(out, /Card ->\n {12}"bg-surface-card"/);
  assert.match(out, /Custom a ->\n {12}toCustom a/);
});

test("emitResolver emits a bare key when the prefix is empty", () => {
  const group = { elmType: "TextTransform", class: { prefix: "" },
    variants: { Uppercase: { key: "uppercase" } } };
  assert.match(emitResolver(group), /Uppercase ->\n {12}"uppercase"/);
  assert.doesNotMatch(emitResolver(group), /"-uppercase"/);
});

test("emitWithX sets the bare class for a prefix-less group", () => {
  const group = { elmType: "TextTransform", class: { prefix: "" },
    withX: { name: "withTextTransform", setter: "setTextTransform" },
    variants: { Uppercase: { key: "uppercase" } } };
  const out = emitWithX(group);
  assert.strictEqual(
    out,
    "withTextTransform : TextTransform -> Config Config.Standard -> Config Config.Standard\nwithTextTransform v =\n    Config.set \"textTransform\" (textTransformToClass v)"
  );
});

test("emitWithX builds a last-wins keyed setter", () => {
  const group = { elmType: "Radius", withX: { name: "withRadius", setter: "setRadius" } };
  assert.strictEqual(
    emitWithX(group),
    "withRadius : Radius -> Config Config.Standard -> Config Config.Standard\nwithRadius v =\n    Config.set \"radius\" (radiusToClass v)"
  );
});

// The explicit key override exists for properties that ANOTHER module's setter
// also targets (e.g. tokens.js MaxWidth `key: "max-width"` sharing a Config
// entry) — both setters must share one key or last-wins breaks across modules.
test("emitWithX: an explicit withX.key wins over the setter-derived key", () => {
  const group = { elmType: "MaxWidth", withX: { name: "withMaxWidth", setter: "setMaxWidth", key: "max-width" } };
  const out = emitWithX(group);
  assert.match(out, /Config\.set "max-width"/);
  assert.doesNotMatch(out, /Config\.set "maxWidth"/);
});

// HOVER POLICY IS DATA: the `hoverable` flag decides the signature. A hoverable
// group stays tag-polymorphic (usable on Hover configs); a non-hoverable one is
// pinned to Config.Standard, so hover styling of it is a compile error.
test("emitWithX: hoverable group keeps the tag-polymorphic signature", () => {
  const group = { elmType: "Elevation", hoverable: true, withX: { name: "withElevation", setter: "setElevation" } };
  assert.match(emitWithX(group), /withElevation : Elevation -> Config tag -> Config tag/);
});

test("emitWithX: non-hoverable group is pinned to Config.Standard", () => {
  const group = { elmType: "Radius", withX: { name: "withRadius", setter: "setRadius" } };
  assert.match(emitWithX(group), /withRadius : Radius -> Config Config\.Standard -> Config Config\.Standard/);
  assert.doesNotMatch(emitWithX(group), /Config tag/);
});

test("emitWithX emits both withXCustom and plain withX for an extensible group", () => {
  const group = { elmType: "Surface", extensible: true, hoverable: true, withX: { name: "withSurface", setter: "setSurface" } };
  const out = emitWithX(group);
  // withSurfaceCustom: handler-threaded, uses Config.set
  assert.match(out, /withSurfaceCustom : \(a -> String\) -> Surface a -> Config tag -> Config tag/);
  assert.match(out, /withSurfaceCustom toCustom v =/);
  assert.match(out, /Config\.set "surface" \(surfaceToClass toCustom v\)/);
  // plain withSurface: Never form delegating to Custom handler
  assert.match(out, /withSurface : Surface Never -> Config tag -> Config tag/);
  assert.match(out, /withSurface =\n {4}withSurfaceCustom never/);
});

test("emitMultiModule disambiguates Custom ctors when >1 extensible group shares a module", () => {
  const { emitMultiModule } = require("./generate");
  const fontSize = {
    elmModule: "Theme.Typography", elmType: "FontSize", extensible: true, class: { prefix: "text" },
    withX: { name: "withFontSize", setter: "setFontSize" }, steps: { Base: { key: "base" } },
  };
  const fontWeight = {
    elmModule: "Theme.Typography", elmType: "FontWeight", extensible: true, class: { prefix: "font" },
    withX: { name: "withFontWeight", setter: "setFontWeight" }, steps: { Bold: { key: "bold" } },
  };
  const out = emitMultiModule("Theme.Typography", [fontSize, fontWeight]);
  // Each extensible type gets a unique <ElmType>Custom ctor — no bare `| Custom a` clash.
  assert.match(out, /type FontSize a\n {4}= Base\n {4}\| FontSizeCustom a/);
  assert.match(out, /type FontWeight a\n {4}= Bold\n {4}\| FontWeightCustom a/);
  assert.match(out, /FontSizeCustom a ->\n {12}toCustom a/);
  assert.match(out, /FontWeightCustom a ->\n {12}toCustom a/);
  assert.doesNotMatch(out, /\| Custom a/);
});

test("a lone extensible group keeps the bare Custom ctor", () => {
  const group = { elmType: "Surface", extensible: true, class: { prefix: "bg" },
    variants: { Card: { key: "surface-card" } } };
  assert.match(emitType(group), /\| Custom a/);
});

test("emitThemeCss emits namespaced vars, skipping the built-in 0", () => {
  const tokens = { groups: {
    radius: { cssVar: "radius", steps: { Sm: { key: "sm", value: "0.25rem" } } },
    surface: { cssVar: "color", variants: { Card: { key: "surface-card", value: "#fff" } } },
    space: { cssVar: "spacing", steps: { None: { key: "0", value: "0" }, Sm: { key: "sm", value: "0.5rem" } } },
  }};
  const css = emitThemeCss(tokens);
  assert.match(css, /--radius-sm: 0\.25rem;/);
  assert.match(css, /--color-surface-card: var\(--surface-card\);/);
  assert.match(css, /--spacing-sm: 0\.5rem;/);
  assert.doesNotMatch(css, /--spacing-0:/); // 0 rides the numeric scale (calc(var(--spacing) * 0)) — no var
});

test("emitThemeCss registers plain :root custom properties in cascade layer theme (no Tailwind @theme)", () => {
  const css = emitThemeCss({ groups: { radius: { cssVar: "radius", steps: { Sm: { key: "sm", value: "0.25rem" } } } } });
  assert.match(css, /^@layer theme \{\n {2}:root, :host \{\n/);
  assert.doesNotMatch(css, /@theme/);
});

test("emitThemeCss emits the paired --text-K--line-height var for fontSize steps that declare one", () => {
  const css = emitThemeCss({ groups: { fontSize: { cssVar: "text", steps: {
    Xxs: { key: "xxs", value: "0.625rem" },
    Sm: { key: "sm", value: "0.875rem", lineHeight: "calc(1.25 / 0.875)" },
  } } } });
  assert.match(css, /--text-sm: 0\.875rem;/);
  assert.match(css, /--text-sm--line-height: calc\(1\.25 \/ 0\.875\);/);
  assert.doesNotMatch(css, /--text-xxs--line-height/); // xxs has no line-height, only font-size
});

const FACET = {
  elmModule: "Style.AppColor", elmType: "AppColor", facetGroup: true,
  hosts: {
    surface: { fn: "surfaceClass", prefix: "bg",   applyFn: "appSurface", import: "Theme.Surface as Surface", hostWith: "withSurfaceCustom" },
    border:  { fn: "borderClass",  prefix: "border", applyFn: "appBorder", import: "Theme.Border as Border",   hostWith: "withBorderCustom" },
  },
  variants: {
    AvailAvailable:   { facet: "surface", key: "avail-available", value: "#dde9e0" },
    BrandSage:        { facet: "surface", key: "surface-brand" },
    AvailBorderGreen: { facet: "border", key: "avail-border-green", ref: "surface-brand" },
  },
};
test("emitFacetType lists every variant once", () => {
  const { emitFacetType } = require("./generate");
  assert.strictEqual(emitFacetType(FACET), "type AppColor\n    = AvailAvailable\n    | BrandSage\n    | AvailBorderGreen");
});
test("emitFacetResolvers builds one resolver per host; off-facet variants map to empty string", () => {
  const { emitFacetResolvers } = require("./generate");
  const out = emitFacetResolvers(FACET);
  assert.match(out, /surfaceClass : AppColor -> String/);
  assert.match(out, /AvailAvailable ->\n {12}"bg-avail-available"/);
  assert.match(out, /BrandSage ->\n {12}"bg-surface-brand"/);
  assert.match(out, /AvailBorderGreen ->\n {12}""/);          // not a surface variant
  assert.match(out, /borderClass : AppColor -> String/);
  assert.match(out, /AvailBorderGreen ->\n {12}"border-avail-border-green"/);
});

test("emitFacetApplyFns routes each host through its withXCustom + Custom ctor", () => {
  const { emitFacetApplyFns } = require("./generate");
  const out = emitFacetApplyFns(FACET);
  assert.match(out, /appSurface : AppColor -> Config tag -> Config tag/);
  assert.match(out, /appSurface c =\n {4}Surface\.withSurfaceCustom surfaceClass \(Surface\.Custom c\)/);
  assert.match(out, /appBorder c =\n {4}Border\.withBorderCustom borderClass \(Border\.Custom c\)/);
});

test("emitFacetApplyFns: qualifier follows the import alias (single source of truth)", () => {
  const { emitFacetApplyFns } = require("./generate");
  const divergent = {
    elmType: "AppColor",
    hosts: {
      surface: { fn: "surfaceClass", applyFn: "appSurface", import: "Theme.Surface as Sfc", hostWith: "withSurfaceCustom" },
    },
    variants: { AvailAvailable: { facet: "surface", key: "avail-available", value: "#dde9e0" } },
  };
  const out = emitFacetApplyFns(divergent);
  assert.match(out, /appSurface c =\n {4}Sfc\.withSurfaceCustom surfaceClass \(Sfc\.Custom c\)/);
});

test("facet validation: throws on a variant whose facet matches no host", () => {
  const { emitModule } = require("./generate");
  const bad = {
    elmModule: "Style.AppColor", elmType: "AppColor", facetGroup: true,
    hosts: { surface: { fn: "surfaceClass", prefix: "bg", applyFn: "appSurface", import: "Theme.Surface as Surface", hostWith: "withSurfaceCustom" } },
    variants: { Mystery: { facet: "text", key: "mystery", value: "#000" } },
  };
  assert.throws(() => emitModule(bad), /Unknown facet "text" for variant Mystery \(known hosts: surface\)/);
});

test("facet validation: throws when a variant has both value and ref", () => {
  const { emitModule } = require("./generate");
  const bad = {
    elmModule: "Style.AppColor", elmType: "AppColor", facetGroup: true,
    hosts: { surface: { fn: "surfaceClass", prefix: "bg", applyFn: "appSurface", import: "Theme.Surface as Surface", hostWith: "withSurfaceCustom" } },
    variants: { Conflict: { facet: "surface", key: "conflict", value: "#000", ref: "surface-brand" } },
  };
  assert.throws(() => emitModule(bad), /Variant Conflict has both value and ref \(mutually exclusive\)/);
});
test("emitModule for a facet group emits header with host imports + type + resolvers + apply fns", () => {
  const { emitModule } = require("./generate");
  const out = emitModule(FACET);
  assert.match(out, /module Style\.AppColor exposing \(AppColor\(\.\.\), surfaceClass, borderClass, appSurface, appBorder\)/);
  assert.match(out, /import Theme\.Surface as Surface/);
  assert.match(out, /import Theme\.Border as Border/);
  assert.match(out, /import Tebru\.Theme\.Config as Config exposing \(Config\)/);
});

test("emitThemeCss: value variants emit their hex directly, ref variants delegate to engine role, others none", () => {
  const { emitThemeCss } = require("./generate");
  const css = emitThemeCss({ groups: { ac: FACET } });
  assert.match(css, /--color-avail-available: #dde9e0;/);                      // value → literal hex (tokens file is authoritative)
  assert.doesNotMatch(css, /--color-avail-available: var\(/);                  // no consumer-side delegation
  assert.match(css, /--color-avail-border-green: var\(--surface-brand\);/);    // ref → engine role
  assert.doesNotMatch(css, /--color-surface-brand:/);                          // BrandSage = engine-class reuse → no line
});
test("emitThemeCss/emitPaletteTemplate: consumer-contract colors ride the ENGINE run only (utility-css.js CONSUMER_CONTRACT_COLORS)", () => {
  const { emitThemeCss, emitPaletteTemplate } = require("./generate");
  const engineColor = { cssVar: "color", variants: { Card: { key: "surface-card", value: "#fff" } } };
  // Engine run (has an engine color group): registers the delegation and lists
  // the contract var — without these, the package's own hover:bg-surface-hover
  // (Choice's switch hover) is dead for a standalone consumer and check-palette
  // cannot flag it.
  const css = emitThemeCss({ groups: { surface: engineColor } });
  assert.match(css, /--color-surface-hover: var\(--surface-hover\);/);
  const tpl = emitPaletteTemplate({ groups: { surface: engineColor } });
  assert.match(tpl, /--surface-hover: #ff00ff;/);
  // App-tokens run (facet groups only): contributes nothing — the app supplies
  // its own value-authoritative --color-* lines.
  const appCss = emitThemeCss({ groups: { ac: FACET } });
  assert.doesNotMatch(appCss, /var\(--surface-hover\)/);
  assert.strictEqual(emitPaletteTemplate({ groups: { ac: FACET } }), null);
});

test("emitPaletteTemplate: facet groups contribute no contract lines; facet-only tokens yield null (no template file)", () => {
  const { emitPaletteTemplate } = require("./generate");
  assert.strictEqual(emitPaletteTemplate({ groups: { ac: FACET } }), null);
  // A facet group alongside an engine color group adds nothing to the template.
  const engineColor = { cssVar: "color", variants: { Card: { key: "surface-card", value: "#fff" } } };
  const tpl = emitPaletteTemplate({ groups: { surface: engineColor, ac: FACET } });
  assert.match(tpl, /--surface-card: #ff00ff;/);
  assert.doesNotMatch(tpl, /avail-available/);
  assert.doesNotMatch(tpl, /avail-border-green/);
});

// CSS-only contract group — the brand-font pattern: no Elm module, value-free
// @theme registration delegating to an explicit consumer contract var.
const FONT = {
  cssOnly: true, cssVar: "font",
  variants: { Sans: { key: "sans", contract: "font-family-sans", placeholder: "ui-sans-serif, system-ui, sans-serif" } },
};

test("contractVarFor: colors delegate implicitly, explicit contract wins, scales are engine-owned", () => {
  const { contractVarFor } = require("./generate");
  assert.strictEqual(contractVarFor({ cssVar: "color" }, { key: "surface-card" }), "surface-card");
  assert.strictEqual(contractVarFor(FONT, FONT.variants.Sans), "font-family-sans");
  assert.strictEqual(contractVarFor({ cssVar: "radius" }, { key: "md", value: "0.375rem" }), null);
});

test("emitThemeCss: an explicit-contract token registers value-free, delegating to its contract var", () => {
  const css = emitThemeCss({ groups: { fontFamily: FONT } });
  assert.match(css, /--font-sans: var\(--font-family-sans\);/);
  assert.doesNotMatch(css, /--font-sans: ui-sans-serif/); // no literal value — the consumer owns it
});

test("emitPaletteTemplate: explicit-contract tokens join the template with their placeholder", () => {
  const engineColor = { cssVar: "color", variants: { Card: { key: "surface-card" } } };
  const tpl = emitPaletteTemplate({ groups: { surface: engineColor, fontFamily: FONT } });
  assert.match(tpl, /--surface-card: #ff00ff; \/\* TODO: replace with your value \*\//);
  assert.match(tpl, /--font-family-sans: ui-sans-serif, system-ui, sans-serif; \/\* TODO: replace with your value \*\//);
});

test("writeAll: a cssOnly group emits no Elm module", () => {
  const { writeAll } = require("./generate");
  const fs = require("fs");
  const os = require("os");
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "gen-cssonly-"));
  const tokensPath = path.join(dir, "tokens.js");
  fs.writeFileSync(tokensPath, `module.exports = { groups: { fontFamily: ${JSON.stringify(FONT)} } };`);
  writeAll(tokensPath);
  assert.strictEqual(fs.existsSync(path.join(dir, "src")), false); // no Elm output at all
  assert.match(fs.readFileSync(path.join(dir, "generated.css"), "utf8"), /--font-sans: var\(--font-family-sans\);/);
  assert.match(fs.readFileSync(path.join(dir, "palette.template.css"), "utf8"), /--font-family-sans: ui-sans-serif/);
});

test("emitGeometryResolver expands edges × steps to literal classes", () => {
  const group = { elmType: "Space", steps: { None: { key: "0" }, Sm: { key: "sm" } } };
  const out = emitGeometryResolver(group);
  assert.match(out, /spaceClass : Edge -> Space -> String/);
  assert.match(out, /\( All, Sm \) ->\n {12}"p-sm"/);
  assert.match(out, /\( Top, Sm \) ->\n {12}"pt-sm"/);
  assert.match(out, /\( Px, Sm \) ->\n {12}"px-sm"/);
  assert.match(out, /\( All, None \) ->\n {12}"p-0"/);
});

test("geometry resolver includes gap edges", () => {
  const group = { elmType: "Space", steps: { Sm: { key: "sm" } } };
  const out = emitGeometryResolver(group);
  assert.match(out, /\( Gap, Sm \) ->\n {12}"gap-sm"/);
});

test("builtin color variant: no --color-* in @theme, no contract var, but live Elm class", () => {
  const group = {
    elmType: "Surface", extensible: true, cssVar: "color", class: { prefix: "bg" },
    variants: { Card: { key: "surface-card" }, Transparent: { key: "transparent", builtin: true } },
  };
  const css = emitThemeCss({ groups: { surface: group } });
  assert.match(css, /--color-surface-card: var\(--surface-card\);/);
  assert.doesNotMatch(css, /--color-transparent/);
  const tpl = emitPaletteTemplate({ groups: { surface: group } });
  assert.doesNotMatch(tpl, /--transparent:/);
  // Elm resolver still emits the literal built-in class.
  assert.match(emitResolver(group), /Transparent ->\n {12}"bg-transparent"/);
});

test("corners group: emits Corner type, sugar fns, literal corner classes, and never branch", () => {
  const group = {
    elmType: "Radius", extensible: true, corners: true, class: { prefix: "rounded" },
    withX: { name: "withRadius", setter: "setRadius" },
    steps: { None: { key: "none" }, Sm: { key: "sm" }, Md: { key: "md" } },
  };
  const out = emitCorners(group);
  assert.match(out, /type Corner\n {4}= TopLeft\n {4}\| TopRight\n {4}\| BottomLeft\n {4}\| BottomRight/);
  assert.match(out, /cornerRadiusClass : Corner -> Radius Never -> String/);
  // Literal corner class, NOT a ++ expression.
  assert.match(out, /\( TopLeft, Md \) ->\n {12}"rounded-tl-md"/);
  assert.doesNotMatch(out, /\+\+/);
  assert.match(out, /\( _, Custom a \) ->\n {12}never a/);
  assert.match(out, /withRadiusCorner : Corner -> Radius Never -> Config Config.Standard -> Config Config.Standard/);
  assert.match(out, /withRadiusTop : Radius Never -> Config Config.Standard -> Config Config.Standard/);
  assert.match(out, /withRadiusTop v =\n {4}withRadiusCorner TopLeft v >> withRadiusCorner TopRight v/);
  assert.match(out, /withRadiusBottom v =\n {4}withRadiusCorner BottomLeft v >> withRadiusCorner BottomRight v/);
});

test("corners group: never branch uses the renamed custom ctor when the module is shared", () => {
  // emitMultiModule renames each extensible ctor to <ElmType>Custom when >1
  // extensible group shares a module; a hardcoded `Custom` in the corners
  // never-branch would then reference a nonexistent ctor and not compile.
  const group = {
    elmType: "Radius", extensible: true, corners: true, customCtor: "RadiusCustom", class: { prefix: "rounded" },
    withX: { name: "withRadius", setter: "setRadius" },
    steps: { None: { key: "none" }, Md: { key: "md" } },
  };
  const out = emitCorners(group);
  assert.match(out, /\( _, RadiusCustom a \) ->\n {12}never a/);
  assert.doesNotMatch(out, /\( _, Custom a \)/);
});

// --- Module doc comments + @docs ------------------------------------------

test("docComment covers every exposed name, stripping (..) from types", () => {
  const { docComment } = require("./generate");
  const out = docComment("A description.", ["Radius(..)", "radiusToClass", "withRadius"]);
  assert.match(out, /^\{-\| A description\./);
  assert.match(out, /@docs Radius, radiusToClass, withRadius/);
  assert.doesNotMatch(out, /\(\.\.\)/);
  assert.match(out, /-\}$/);
});

test("docComment wraps long @docs runs onto multiple @docs lines", () => {
  const { docComment } = require("./generate");
  const names = Array.from({ length: 30 }, (_, i) => `withSomethingLongish${i}`);
  const out = docComment("D.", names);
  const docsLines = out.split("\n").filter((l) => l.startsWith("@docs "));
  assert.ok(docsLines.length > 1);
  for (const l of docsLines) assert.ok(l.length <= 120, `line too long: ${l}`);
  // every name appears exactly once across the @docs lines
  const listed = docsLines.flatMap((l) => l.replace("@docs ", "").split(", "));
  assert.deepStrictEqual(listed.sort(), [...names].sort());
});

test("emitModule emits a module doc comment with @docs for a standard group", () => {
  const group = {
    elmModule: "Theme.Radius", elmType: "Radius", class: { prefix: "rounded" },
    withX: { name: "withRadius", setter: "setRadius" }, steps: { Md: { key: "md" } },
  };
  const out = emitModule(group);
  assert.match(out, /module Theme\.Radius exposing \(Radius\(\.\.\), radiusToClass, withRadius\)\n\n\{-\|/);
  assert.match(out, /@docs Radius, radiusToClass, withRadius/);
});

test("emitModule facet branch keeps host imports first and adds @docs", () => {
  const out = emitModule(FACET);
  assert.match(out, /@docs AppColor, surfaceClass, borderClass, appSurface, appBorder/);
  // Import order preserved: hosts first, Config last.
  assert.match(out, /import Theme\.Surface as Surface\nimport Theme\.Border as Border\nimport Tebru\.Theme\.Config as Config exposing \(Config\)/);
});

test("emitMultiModule covers every group's exposed names in @docs", () => {
  const a = { elmModule: "Theme.T", elmType: "A", class: { prefix: "a" }, withX: { name: "withA", setter: "setA" }, variants: { A1: { key: "1" } } };
  const b = { elmModule: "Theme.T", elmType: "B", class: { prefix: "b" }, withX: { name: "withB", setter: "setB" }, variants: { B1: { key: "1" } } };
  const out = emitMultiModule("Theme.T", [a, b]);
  assert.match(out, /@docs A, aToClass, withA, B, bToClass, withB/);
});

// --- Structural-module specs (classPerVariant / breakpointCols) -------------

const STRUCT = {
  kind: "classPerVariant",
  elmModule: "Tebru.Theme.Structure",
  doc: "Structural styling.",
  imports: ["Tebru.Theme.Space as Space exposing (Edge)"],
  types: [
    {
      elmType: "Display",
      setters: [{ name: "withDisplay", key: "display" }],
      variants: { Block: "block", None: "hidden" },
    },
    {
      elmType: "Overflow",
      setters: [
        { name: "withOverflow", key: "overflow" },
        { name: "withOverflowX", key: "overflow-x" },
      ],
      variants: {
        OverflowAuto: ["overflow-auto", "overflow-x-auto"],
        OverflowHidden: ["overflow-hidden", "overflow-x-hidden"],
      },
    },
  ],
  verbatim: [
    {
      exposes: ["withGrow"],
      code: "withGrow : Bool -> Config tag -> Config tag\nwithGrow grow =\n    Config.set \"grow\" \"grow\"",
    },
  ],
};

test("classPerVariant: literal class per variant, no prefix regularity required", () => {
  const { emitStructureSpec } = require("./generate");
  const out = emitStructureSpec(STRUCT);
  assert.match(out, /type Display\n {4}= Block\n {4}\| None/);
  // Display's classes have no shared prefix — each is the full literal.
  assert.match(out, /Block ->\n {16}"block"/);
  assert.match(out, /None ->\n {16}"hidden"/);
  // No class string is ever composed with ++.
  assert.doesNotMatch(out, /\+\+ "/);
});

test("classPerVariant: multi-setter type emits one setter per Config key with its own class column", () => {
  const { emitStructureSpec } = require("./generate");
  const out = emitStructureSpec(STRUCT);
  assert.match(out, /withOverflow : Overflow -> Config Config.Standard -> Config Config.Standard\nwithOverflow v =\n {4}Config\.set "overflow"/);
  assert.match(out, /withOverflowX : Overflow -> Config Config.Standard -> Config Config.Standard\nwithOverflowX v =\n {4}Config\.set "overflow-x"/);
  assert.match(out, /OverflowAuto ->\n {16}"overflow-auto"/);
  assert.match(out, /OverflowAuto ->\n {16}"overflow-x-auto"/);
});

test("classPerVariant: a hoverable structural type keeps the tag-polymorphic signature", () => {
  const { emitStructureSpec } = require("./generate");
  const spec = {
    kind: "classPerVariant",
    elmModule: "Theme.Structure",
    types: [
      { elmType: "BorderWidth", hoverable: true, setters: [{ name: "withBorderWidth", key: "border-width" }], variants: { BorderThin: "border" } },
      { elmType: "Opacity", setters: [{ name: "withOpacity", key: "opacity" }], variants: { Opacity50: "opacity-50" } },
    ],
  };
  const out = emitStructureSpec(spec);
  assert.match(out, /withBorderWidth : BorderWidth -> Config tag -> Config tag/);
  assert.match(out, /withOpacity : Opacity -> Config Config\.Standard -> Config Config\.Standard/);
});

test("classPerVariant: verbatim blocks pass through and join the exposing list + @docs", () => {
  const { emitStructureSpec } = require("./generate");
  const out = emitStructureSpec(STRUCT);
  assert.match(out, /withGrow : Bool -> Config tag -> Config tag/);
  assert.match(out, /exposing \(Display\(\.\.\), Overflow\(\.\.\), withDisplay, withGrow, withOverflow, withOverflowX\)/);
  assert.match(out, /@docs Display, Overflow, withDisplay, withGrow, withOverflow, withOverflowX/);
});

test("classPerVariant: spec-level imports are emitted after the Config import", () => {
  const { emitStructureSpec } = require("./generate");
  const out = emitStructureSpec(STRUCT);
  assert.match(out, /import Tebru\.Theme\.Config as Config exposing \(Config\)\nimport Tebru\.Theme\.Space as Space exposing \(Edge\)/);
});

test("classPerVariant: throws when a variant's class count doesn't match the setter count", () => {
  const { emitStructureSpec } = require("./generate");
  const bad = {
    kind: "classPerVariant", elmModule: "M", doc: "D.",
    types: [{
      elmType: "Overflow",
      setters: [{ name: "withOverflow", key: "overflow" }, { name: "withOverflowX", key: "overflow-x" }],
      variants: { OverflowAuto: "overflow-auto" }, // one class, two setters
    }],
  };
  assert.throws(() => emitStructureSpec(bad), /Overflow\.OverflowAuto: expected 2 class\(es\)/);
});

test("breakpointCols: literal prefixed arms for 1..maxCols plus a fallback arm", () => {
  const { emitStructureSpec } = require("./generate");
  const spec = {
    kind: "breakpointCols", elmModule: "Tebru.Box.GridCols", doc: "Grid matrix.",
    maxCols: 3, fallbackCols: 1,
    breakpoints: [{ fn: "smCols", prefix: "" }, { fn: "mdCols", prefix: "md:" }],
  };
  const out = emitStructureSpec(spec);
  assert.match(out, /module Tebru\.Box\.GridCols exposing \(mdCols, smCols\)/);
  assert.match(out, /@docs mdCols, smCols/);
  assert.match(out, /smCols : Int -> String/);
  // The breakpoint prefix is INSIDE the literal — never composed.
  assert.match(out, /2 ->\n {12}"md:grid-cols-2"/);
  assert.match(out, /_ ->\n {12}"md:grid-cols-1"/);
  assert.doesNotMatch(out, /\+\+/);
  // No Config import — the module is a pure Int -> String matrix.
  assert.doesNotMatch(out, /import Tebru\.Theme\.Config/);
});

test("emitStructureSpec: throws on an unknown kind", () => {
  const { emitStructureSpec } = require("./generate");
  assert.throws(() => emitStructureSpec({ kind: "nope", elmModule: "M" }), /Unknown structure-module kind "nope"/);
});

test("writeAll: tokens.structure modules are written to src/ and regen is idempotent", () => {
  const { writeAll } = require("./generate");
  const fs = require("fs");
  const os = require("os");
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "gen-structure-"));
  const tokensPath = path.join(dir, "tokens.js");
  fs.writeFileSync(
    tokensPath,
    `module.exports = { structure: { modules: [${JSON.stringify(STRUCT)}] }, groups: {} };`
  );
  writeAll(tokensPath);
  const out = path.join(dir, "src", "Tebru", "Theme", "Structure.elm");
  const first = fs.readFileSync(out, "utf8");
  assert.match(first, /module Tebru\.Theme\.Structure exposing/);
  writeAll(tokensPath);
  assert.strictEqual(fs.readFileSync(out, "utf8"), first); // byte-identical regen
});

test("corners group: emitModule exposes Corner(..) and the corner sugar fns", () => {
  const group = {
    elmModule: "Theme.Radius", elmType: "Radius", extensible: true, corners: true, cssVar: "radius",
    class: { prefix: "rounded" }, withX: { name: "withRadius", setter: "setRadius" },
    steps: { None: { key: "none" }, Md: { key: "md" } },
  };
  const out = emitModule(group);
  assert.match(out, /module Theme\.Radius exposing \(.*Corner\(\.\.\), withRadiusCorner, withRadiusTop, withRadiusBottom\)/);
  assert.match(out, /\( TopLeft, Md \) ->\n {12}"rounded-tl-md"/);
});
