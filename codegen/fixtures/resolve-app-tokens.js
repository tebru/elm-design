/* resolve-app-tokens.js — where the codegen tests find an app tokens file.

   The suite exercises the app half of the inventory/emitter against a REAL
   consumer config when one is available, and against the vendored fixture
   otherwise, so the tests run in a standalone package checkout (submodule,
   CI) with no consuming app. Resolution order:

     1. $APP_TOKENS            — explicit override (absolute or cwd-relative)
     2. <cwd>/app-theme/app-tokens.js — the consuming app, when the tests are
        invoked from its root (how the app's gates run them). Cwd-based, not
        package-relative, so it survives the package living anywhere (sibling
        dir, ~/Development, git submodule inside the app).
     3. codegen/fixtures/app/app-tokens.js — the vendored snapshot fixture

   The fixture mirrors the shapes the tests assert on (breakpoints, variant
   keys, bespoke literals); keep it in step when those assertions change. */

const fs = require("fs");
const path = require("path");

function resolveAppTokens() {
  if (process.env.APP_TOKENS) return path.resolve(process.env.APP_TOKENS);
  const fromCwd = path.resolve(process.cwd(), "app-theme/app-tokens.js");
  if (fs.existsSync(fromCwd)) return fromCwd;
  return path.join(__dirname, "app", "app-tokens.js");
}

module.exports = { resolveAppTokens };
