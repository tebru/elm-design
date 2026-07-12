const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { bundle, stripComments, assertNoImports } = require("./bundle-css");

function dir(files) {
  const d = fs.mkdtempSync(path.join(os.tmpdir(), "bundle-css-"));
  for (const [name, content] of Object.entries(files)) fs.writeFileSync(path.join(d, name), content);
  return d;
}

/* ---------------- bundling ---------------- */

test("bundle flattens quoted relative imports, wrapping layer(...) imports in @layer", () => {
  const d = dir({
    "entry.css": '@import "a.css";\n@import "b.css" layer(components);\nbody { color: red; }\n',
    "a.css": ".a { top: 0; }\n",
    "b.css": ".b { left: 0; }\n",
  });
  const out = bundle(path.join(d, "entry.css"));
  assert.match(out, /\.a \{ top: 0; \}/);
  assert.match(out, /@layer components \{\n\.b \{ left: 0; \}\n\}/);
  assert.match(out, /body \{ color: red; \}/);
  assert.ok(!/@import/.test(out), "no @import may survive a clean bundle");
});

test("bundle hard-errors on a missing file and on an import cycle", () => {
  const d = dir({
    "entry.css": '@import "missing.css";\n',
    "x.css": '@import "y.css";\n',
    "y.css": '@import "x.css";\n',
  });
  assert.throws(() => bundle(path.join(d, "entry.css")), /no such file/);
  assert.throws(() => bundle(path.join(d, "x.css")), /import cycle/);
});

/* ---------------- post-bundle @import assertion ---------------- */

test("an @import shape IMPORT_RE does not flatten survives bundling and then fails the assertion", () => {
  const d = dir({ "entry.css": '@import url("https://example.com/x.css");\nbody { color: red; }\n' });
  const out = stripComments(bundle(path.join(d, "entry.css")));
  assert.throws(
    () => assertNoImports(out),
    (e) => /unresolved @import/.test(e.message) && e.message.includes('@import url("https://example.com/x.css");')
  );
});

test("assertNoImports reports every offending line, with line numbers", () => {
  assert.throws(
    () => assertNoImports('@import url(a.css);\n.x { top: 0; }\n@import "b.css" screen;'),
    (e) => /2 unresolved @import line\(s\)/.test(e.message) && /line 1:/.test(e.message) && /line 3:/.test(e.message)
  );
});

test("assertNoImports passes clean CSS", () => {
  assert.doesNotThrow(() => assertNoImports(".x { background: url(import.png); }"));
});

/* ---------------- comment stripping (bundle output only) ---------------- */

test("stripComments removes block comments, including multi-line headers", () => {
  const css = "/* header\n   line two */\n.a { top: 0; /* inline */ left: 0; }\n";
  assert.strictEqual(stripComments(css), ".a { top: 0;  left: 0; }\n");
});

test("stripComments leaves comment-lookalikes inside strings alone", () => {
  const css = '.a { content: "/* not a comment */"; }\n.b { background: url("x/*y*/z.png"); }\n';
  assert.strictEqual(stripComments(css), css);
});

test("stripComments handles escaped quotes in selectors (emitted content-[''] classes)", () => {
  const css = ".before\\:content-\\[\\'\\'\\] { --tw-content: ''; }\n/* trailing */\n";
  assert.strictEqual(stripComments(css), ".before\\:content-\\[\\'\\'\\] { --tw-content: ''; }\n");
});

test("stripComments collapses the blank-line holes comments leave behind", () => {
  const css = "/* a */\n\n/* b */\n\n\n.x { top: 0; }\n";
  assert.strictEqual(stripComments(css), ".x { top: 0; }\n");
});

test("stripComments preserves /*! bang comments (license/attribution) verbatim while stripping plain ones", () => {
  const css = "/*! preflight (MIT License, Copyright (c) Tailwind Labs, Inc.)\n   line two */\n/* plain */\n.a { top: 0; }\n";
  const out = stripComments(css);
  assert.match(out, /\/\*! preflight \(MIT License, Copyright \(c\) Tailwind Labs, Inc\.\)\n {3}line two \*\//);
  assert.ok(!/plain/.test(out), "plain comments are still stripped");
  assert.match(out, /\.a \{ top: 0; \}/);
});

test("the vendored preflight's MIT attribution survives to the stripped bundle", () => {
  const preflight = fs.readFileSync(path.join(__dirname, "..", "preflight.css"), "utf8");
  assert.match(preflight, /^\/\*!/, "preflight.css header must be a /*! bang comment");
  const stripped = stripComments(preflight);
  assert.match(stripped, /MIT License, Copyright \(c\)\n?\s*Tailwind Labs, Inc\./);
});

test("an @import mentioned in a comment is stripped, not flagged", () => {
  const d = dir({
    "entry.css": '/* docs: use @import "x.css" to compose */\n@import "a.css";\n',
    "a.css": ".a { top: 0; }\n",
  });
  const out = stripComments(bundle(path.join(d, "entry.css")));
  assert.doesNotThrow(() => assertNoImports(out));
  assert.strictEqual(out.trim(), ".a { top: 0; }");
});
