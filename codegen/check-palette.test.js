/* Tests for check-palette.js — the palette-contract build gate (first step of
   the app's css:build). The gate's whole purpose is turning silent runtime
   failures (an undefined contract var → utilities resolve to nothing) into
   loud build failures, so the suite pins every loud path AND the previously
   silent parse paths: comment-brace truncation (P2), 0-var contracts (P3),
   and case-sensitive var names (P4). */

const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { varKeys, checkPalette, main } = require("./check-palette");

function write(dir, name, content) {
  const p = path.join(dir, name);
  fs.writeFileSync(p, content);
  return p;
}

function tmp() {
  return fs.mkdtempSync(path.join(os.tmpdir(), "check-palette-"));
}

// Capture console output around a main() call: [code, errText, warnText, logText].
function runMain(t, argv) {
  const err = [];
  const warn = [];
  const log = [];
  t.mock.method(console, "error", (...a) => err.push(a.join(" ")));
  t.mock.method(console, "warn", (...a) => warn.push(a.join(" ")));
  t.mock.method(console, "log", (...a) => log.push(a.join(" ")));
  const code = main(argv);
  t.mock.restoreAll();
  return { code, err: err.join("\n"), warn: warn.join("\n"), log: log.join("\n") };
}

const TEMPLATE = ":root {\n  --surface-page: #ff00ff;\n  --fg-default: #ff00ff;\n  --font-family-sans: sans-serif;\n}\n";

/* ---------------- varKeys parsing ---------------- */

test("varKeys reads every --var: declaration in the :root block", () => {
  const dir = tmp();
  const p = write(dir, "a.css", TEMPLATE);
  assert.deepStrictEqual([...varKeys(p)].sort(), ["fg-default", "font-family-sans", "surface-page"]);
});

test("varKeys throws LOUDLY when no :root block exists (P1: `:root, :host` form included)", () => {
  const dir = tmp();
  const none = write(dir, "none.css", ".x { color: red; }\n");
  assert.throws(() => varKeys(none), /no :root block found/);
  // The generated.css form `:root, :host {` is NOT accepted by this parser —
  // that is deliberate: the contract/palette files use plain `:root {`, and an
  // unexpected form must fail loud, never parse to a partial set.
  const rootHost = write(dir, "roothost.css", ":root, :host {\n  --surface-page: #fff;\n}\n");
  assert.throws(() => varKeys(rootHost), /no :root block found/);
});

test("varKeys is immune to a `}` inside a comment within :root (P2 — was a silent var drop)", () => {
  const dir = tmp();
  const p = write(dir, "c.css", ":root {\n  --surface-page: #fff;\n  /* weird brace } in prose */\n  --fg-default: #111;\n}\n");
  assert.deepStrictEqual([...varKeys(p)].sort(), ["fg-default", "surface-page"]);
});

test("varKeys sees uppercase/underscore var names instead of silently ignoring them (P4)", () => {
  const dir = tmp();
  const p = write(dir, "u.css", ":root {\n  --Surface-Page: #fff;\n  --snake_case: #111;\n}\n");
  assert.deepStrictEqual([...varKeys(p)].sort(), ["Surface-Page", "snake_case"]);
});

test("varKeys ignores var() REFERENCES in values (only declarations count)", () => {
  const dir = tmp();
  const p = write(dir, "r.css", ":root {\n  --color-surface-page: var(--surface-page);\n}\n");
  assert.deepStrictEqual([...varKeys(p)], ["color-surface-page"]);
});

/* ---------------- checkPalette diffing ---------------- */

test("checkPalette reports missing and extra keys with the contract count", () => {
  const dir = tmp();
  const template = write(dir, "template.css", TEMPLATE);
  const palette = write(dir, "palette.css", ":root {\n  --surface-page: #f6f5f1;\n  --font-family-sans: Inter;\n  --stale-key: #000;\n}\n");
  const { missing, extra, contractCount } = checkPalette(template, palette);
  assert.deepStrictEqual(missing, ["fg-default"]);
  assert.deepStrictEqual(extra, ["stale-key"]);
  assert.strictEqual(contractCount, 3);
});

/* ---------------- main: exit codes + messages ---------------- */

test("main: happy path — full palette passes with exit 0", (t) => {
  const dir = tmp();
  const template = write(dir, "template.css", TEMPLATE);
  const palette = write(dir, "palette.css", ":root {\n  --surface-page: #f6f5f1;\n  --fg-default: #26261f;\n  --font-family-sans: Inter;\n}\n");
  const r = runMain(t, [template, palette]);
  assert.strictEqual(r.code, 0);
  assert.match(r.log, /palette check: OK \(3 contract vars defined\)/);
});

test("main: a missing contract var fails with exit 1 and NAMES the var", (t) => {
  const dir = tmp();
  const template = write(dir, "template.css", TEMPLATE);
  const palette = write(dir, "palette.css", ":root {\n  --surface-page: #f6f5f1;\n  --font-family-sans: Inter;\n}\n");
  const r = runMain(t, [template, palette]);
  assert.strictEqual(r.code, 1);
  assert.match(r.err, /palette check: FAILED/);
  assert.match(r.err, /--fg-default/);
});

test("main: extra palette vars only WARN (exit 0), naming each extra", (t) => {
  const dir = tmp();
  const template = write(dir, "template.css", TEMPLATE);
  const palette = write(
    dir,
    "palette.css",
    ":root {\n  --surface-page: #f6f5f1;\n  --fg-default: #26261f;\n  --font-family-sans: Inter;\n  --app-only-extra: #123;\n}\n"
  );
  const r = runMain(t, [template, palette]);
  assert.strictEqual(r.code, 0);
  assert.match(r.warn, /WARNING/);
  assert.match(r.warn, /--app-only-extra/);
  assert.match(r.log, /1 extra/);
});

test("main: a contract that parses to 0 vars FAILS LOUDLY instead of silently passing (P3)", (t) => {
  const dir = tmp();
  const template = write(dir, "template.css", ":root {\n}\n");
  const palette = write(dir, "palette.css", ":root {\n  --surface-page: #f6f5f1;\n}\n");
  const r = runMain(t, [template, palette]);
  assert.strictEqual(r.code, 1);
  assert.match(r.err, /FAILED — contract parsed to 0 vars/);
});

test("main: missing arguments exit 2 with usage", (t) => {
  const r = runMain(t, []);
  assert.strictEqual(r.code, 2);
  assert.match(r.err, /usage: check-palette/);
});

test("gate sanity: the REAL shipped template and app palette satisfy the contract", (t) => {
  const template = path.resolve(__dirname, "..", "palette.template.css");
  const appPalette = path.resolve(__dirname, "../../frontend/static/palette.css");
  if (!fs.existsSync(appPalette)) return t.skip("no sibling app checkout");
  const { missing, contractCount } = checkPalette(template, appPalette);
  assert.deepStrictEqual(missing, []);
  assert.ok(contractCount > 0);
});
