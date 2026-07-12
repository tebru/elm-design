#!/usr/bin/env node
/* check-bespoke-sync.js — kills the manual sync point between the app tokens
   file and the app's elm-review escape-hatch rule.

   <app-tokens>.utilities.bespokeSources (the class-inventory input,
   codegen/generate-inventory.js) must track review's NoAddRawOutside
   isAllowedModule allow-list: a module blessed for Config.addRaw whose
   literals are not scanned would render classes that emit no CSS. The two
   lists live in different files, so this check asserts, whenever the app
   declares the rule location:

     bespokeSources  ===  (allow-list modules as ../src/<Module>.elm paths)
                          ∪  utilities.bespokeExtras

   bespokeExtras is the EXPLICIT list of scanned-but-not-lint-blessed entries
   (e.g. Style/Kit.elm carries a Config.set literal — Config.set is not
   lint-confined — and app-theme/src holds the generated resolvers). Every
   extra must itself be a bespokeSources entry. Drift in either direction is a
   hard error.

   Declared via utilities.addRawRule (path to the rule's .elm source,
   relative to the tokens file). When absent the check is skipped — a
   consumer without the lint rule has no list to sync. Runs inside
   emit-css.js writeAppCss (so `npm run css:build` fails on drift) and via
   the codegen test suite; also runnable directly:

     node check-bespoke-sync.js <app-tokens.js> */

const fs = require("fs");
const path = require("path");

// Module names out of the rule's `isAllowedModule` list literal: the inner
// `[ "Ui", "Calendar" ]` string lists of the List.member table. Anchored on
// the type signature so doc-comment mentions of the function name don't bite.
function parseAllowedModules(elmSource) {
  const sig = elmSource.indexOf("isAllowedModule : ModuleName -> Bool");
  if (sig === -1) {
    throw new Error("check-bespoke-sync: cannot find `isAllowedModule : ModuleName -> Bool` in the rule source");
  }
  const gap = elmSource.indexOf("\n\n\n", sig); // elm-format: two blank lines between top-level declarations
  const body = gap === -1 ? elmSource.slice(sig) : elmSource.slice(sig, gap);
  const modules = [];
  for (const m of body.matchAll(/\[((?:\s*"[^"]+"\s*,?)+)\]/g)) {
    modules.push([...m[1].matchAll(/"([^"]+)"/g)].map((x) => x[1]));
  }
  if (modules.length === 0) {
    throw new Error("check-bespoke-sync: isAllowedModule found but no module name lists parsed — rule shape changed?");
  }
  return modules;
}

// Throws on drift; returns null when the tokens file declares no rule to sync
// against, else { allowedModules, extras } for reporting.
function checkBespokeSync(appTokensPath) {
  const appTokens = require(appTokensPath);
  const appDir = path.dirname(appTokensPath);
  const inv = appTokens.utilities || {};
  if (!inv.addRawRule) return null;

  const rulePath = path.resolve(appDir, inv.addRawRule);
  if (!fs.existsSync(rulePath)) {
    throw new Error(`check-bespoke-sync: utilities.addRawRule declared but not found: ${rulePath}`);
  }
  const allowedModules = parseAllowedModules(fs.readFileSync(rulePath, "utf8"));

  const norm = (p) => path.resolve(appDir, p);
  const sources = new Set((inv.bespokeSources || []).map(norm));
  const extras = new Set((inv.bespokeExtras || []).map(norm));
  const problems = [];

  for (const e of inv.bespokeExtras || []) {
    if (!sources.has(norm(e))) problems.push(`bespokeExtras entry is not in bespokeSources: ${e}`);
  }

  // Allow-list modules map to <app src root>/<Module path>.elm — the same
  // ../src/... convention bespokeSources uses relative to the tokens file.
  const allowPaths = new Map(allowedModules.map((mod) => [norm(path.join("../src", ...mod) + ".elm"), mod.join(".")]));
  for (const [p, mod] of allowPaths) {
    if (!sources.has(p)) {
      problems.push(`NoAddRawOutside allows ${mod} but utilities.bespokeSources does not scan it (expected entry: ../src/${mod.split(".").join("/")}.elm)`);
    }
  }
  for (const s of inv.bespokeSources || []) {
    const p = norm(s);
    if (!allowPaths.has(p) && !extras.has(p)) {
      problems.push(`bespokeSources entry ${s} is neither in the NoAddRawOutside allow-list nor declared in utilities.bespokeExtras`);
    }
  }

  if (problems.length > 0) {
    throw new Error(
      `check-bespoke-sync: utilities.bespokeSources has drifted from ${inv.addRawRule} (${problems.length} problem(s)):\n  ` +
        problems.join("\n  ")
    );
  }
  return { allowedModules: [...allowPaths.values()], extras: (inv.bespokeExtras || []).slice() };
}

module.exports = { parseAllowedModules, checkBespokeSync };

if (require.main === module) {
  const appTokensArg = process.argv[2];
  if (!appTokensArg) {
    console.error("usage: check-bespoke-sync.js <app-tokens.js>");
    process.exit(1);
  }
  const res = checkBespokeSync(path.resolve(process.cwd(), appTokensArg));
  if (res === null) console.log("check-bespoke-sync: no utilities.addRawRule declared — nothing to sync");
  else console.log(`check-bespoke-sync: in sync (${res.allowedModules.length} allow-list modules + ${res.extras.length} extras)`);
}
