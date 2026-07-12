const { test } = require("node:test");
const assert = require("node:assert");
const fs = require("fs");
const os = require("os");
const path = require("path");
const { parseAllowedModules, checkBespokeSync } = require("./check-bespoke-sync");

// Real app checkout when present, vendored fixture otherwise ($APP_TOKENS overrides).
const APP_TOKENS = require("./fixtures/resolve-app-tokens").resolveAppTokens();

/* ---------------- fixture scaffolding ---------------- */

// A minimal NoAddRawOutside.elm carrying the shapes the parser anchors on.
function ruleSource(moduleLists) {
  const items = moduleLists.map((mod) => "[ " + mod.map((p) => `"${p}"`).join(", ") + " ]");
  return [
    "module NoAddRawOutside exposing (rule)",
    "",
    "{-| Doc comment that mentions isAllowedModule in prose. -}",
    "",
    "isAllowedModule : ModuleName -> Bool",
    "isAllowedModule moduleName =",
    "    List.member moduleName",
    "        [ " + items.join("\n        , "),
    "        ]",
    "",
    "",
    "expressionVisitor : Node Expression -> Context",
    "expressionVisitor node =",
    "    node",
    "",
  ].join("\n");
}

// Writes an app dir (tokens file + review rule + src stubs) and returns the tokens path.
let n = 0;
function scaffold({ allowList, bespokeSources, bespokeExtras, declareRule = true }) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), "bespoke-sync-"));
  const appDir = path.join(root, "app-theme");
  fs.mkdirSync(appDir, { recursive: true });
  fs.mkdirSync(path.join(root, "review", "src"), { recursive: true });
  fs.writeFileSync(path.join(root, "review", "src", "NoAddRawOutside.elm"), ruleSource(allowList));
  const utilities = { css: "./out.css", bespokeSources };
  if (bespokeExtras) utilities.bespokeExtras = bespokeExtras;
  if (declareRule) utilities.addRawRule = "../review/src/NoAddRawOutside.elm";
  const tokensPath = path.join(appDir, `app-tokens-${n++}.js`);
  fs.writeFileSync(tokensPath, `module.exports = { utilities: ${JSON.stringify(utilities)}, groups: {} };\n`);
  return tokensPath;
}

/* ---------------- parser ---------------- */

test("parseAllowedModules reads the inner string lists of isAllowedModule", () => {
  const mods = parseAllowedModules(ruleSource([["Ui", "Calendar"], ["Style", "Bespoke"]]));
  assert.deepStrictEqual(mods, [["Ui", "Calendar"], ["Style", "Bespoke"]]);
});

test("parseAllowedModules throws when the rule shape is unrecognizable", () => {
  assert.throws(() => parseAllowedModules("module X exposing (rule)"), /cannot find/);
});

/* ---------------- sync verdicts ---------------- */

test("in sync: allow-list modules + declared extras exactly cover bespokeSources", () => {
  const tokensPath = scaffold({
    allowList: [["Ui", "Calendar"], ["Style", "Bespoke"]],
    bespokeSources: ["../src/Ui/Calendar.elm", "../src/Style/Bespoke.elm", "../src/Style/Kit.elm"],
    bespokeExtras: ["../src/Style/Kit.elm"],
  });
  const res = checkBespokeSync(tokensPath);
  assert.deepStrictEqual(res.allowedModules, ["Ui.Calendar", "Style.Bespoke"]);
  assert.deepStrictEqual(res.extras, ["../src/Style/Kit.elm"]);
});

test("drift: a lint-blessed module missing from bespokeSources fails", () => {
  const tokensPath = scaffold({
    allowList: [["Ui", "Calendar"], ["Ui", "Rail"]],
    bespokeSources: ["../src/Ui/Calendar.elm"],
  });
  assert.throws(() => checkBespokeSync(tokensPath), /NoAddRawOutside allows Ui\.Rail but utilities\.bespokeSources does not scan it/);
});

test("drift: a bespokeSources entry neither lint-blessed nor a declared extra fails", () => {
  const tokensPath = scaffold({
    allowList: [["Ui", "Calendar"]],
    bespokeSources: ["../src/Ui/Calendar.elm", "../src/Style/Kit.elm"],
  });
  assert.throws(() => checkBespokeSync(tokensPath), /Style\/Kit\.elm is neither in the NoAddRawOutside allow-list nor declared/);
});

test("drift: an extra that is not itself scanned fails", () => {
  const tokensPath = scaffold({
    allowList: [["Ui", "Calendar"]],
    bespokeSources: ["../src/Ui/Calendar.elm"],
    bespokeExtras: ["../src/Style/Kit.elm"],
  });
  assert.throws(() => checkBespokeSync(tokensPath), /bespokeExtras entry is not in bespokeSources/);
});

test("no addRawRule declared: the check is skipped (standalone consumers)", () => {
  const tokensPath = scaffold({ allowList: [["Ui", "Calendar"]], bespokeSources: ["../src/Ui/Calendar.elm"], declareRule: false });
  assert.strictEqual(checkBespokeSync(tokensPath), null);
});

test("a declared rule path that does not exist is a hard error, not a skip", () => {
  const tokensPath = scaffold({ allowList: [["Ui", "Calendar"]], bespokeSources: ["../src/Ui/Calendar.elm"] });
  fs.rmSync(path.resolve(path.dirname(tokensPath), "../review/src/NoAddRawOutside.elm"));
  assert.throws(() => checkBespokeSync(tokensPath), /declared but not found/);
});

/* ---------------- the real app (when a checkout is present) ---------------- */

test("the resolved app tokens file passes the sync check (or declares no rule)", () => {
  assert.doesNotThrow(() => checkBespokeSync(APP_TOKENS));
});
