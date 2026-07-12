#!/usr/bin/env node
/* Engine palette CONTRACT check. The engine's palette.template.css enumerates
   every contract var a consuming app MUST define (color roles + the brand
   font); the app's palette file supplies the values. A missing var fails
   silently at runtime (the utility resolves to nothing), so this check runs
   in the css:build chain and fails LOUDLY instead.

   Usage:
     check-palette <path/to/palette.template.css> <path/to/app-palette.css>

   Exit 1 (build failure) when the app palette is missing a contract var, or
   when the contract itself parses to 0 vars (an empty contract would make any
   palette "pass" — always a broken template, never a satisfied contract).
   Extra vars in the app palette only WARN — they may be deliberate app-side
   additions, but more likely a stale key after a contract rename. */

const fs = require("fs");
const path = require("path");

function varKeys(cssPath) {
  // Strip block comments FIRST: a `}` inside a comment within the :root block
  // would otherwise truncate the [^}]* capture and silently drop every var
  // after it from the parsed set — the exact silent failure this gate exists
  // to catch (and real palette files do carry comments inside :root).
  const css = fs.readFileSync(cssPath, "utf8").replace(/\/\*[\s\S]*?\*\//g, "");
  const roots = [...css.matchAll(/:root\s*\{([^}]*)\}/g)];
  if (roots.length === 0) throw new Error(`${cssPath}: no :root block found`);
  const keys = new Set();
  for (const [, body] of roots) {
    // Custom properties are case-sensitive — match uppercase too, so a
    // wrong-case var surfaces as missing/extra instead of being ignored.
    for (const m of body.matchAll(/--([A-Za-z0-9_-]+)\s*:/g)) keys.add(m[1]);
  }
  return keys;
}

function checkPalette(templatePath, palettePath) {
  const contract = varKeys(templatePath);
  const supplied = varKeys(palettePath);
  const missing = [...contract].filter((k) => !supplied.has(k));
  const extra = [...supplied].filter((k) => !contract.has(k));
  return { missing, extra, contractCount: contract.size };
}

function main(argv) {
  const [templatePath, palettePath] = argv;
  if (!templatePath || !palettePath) {
    console.error("usage: check-palette <palette.template.css> <app-palette.css>");
    return 2;
  }
  const { missing, extra, contractCount } = checkPalette(path.resolve(templatePath), path.resolve(palettePath));
  if (contractCount === 0) {
    // An empty contract makes every palette "pass" — that is a broken/unparsable
    // template (or a generator regression), never a satisfied contract.
    console.error(`palette check: FAILED — contract parsed to 0 vars (${templatePath} is empty or unparsable)`);
    return 1;
  }
  for (const k of extra) {
    console.warn(`palette check: WARNING — ${path.basename(palettePath)} defines --${k}, which is not in the engine contract`);
  }
  if (missing.length > 0) {
    console.error(
      `palette check: FAILED — ${path.basename(palettePath)} is missing ${missing.length} engine contract var(s):\n` +
        missing.map((k) => `  --${k}`).join("\n") +
        `\n(contract: ${templatePath})`
    );
    return 1;
  }
  console.log(`palette check: OK (${contractCount} contract vars defined${extra.length ? `, ${extra.length} extra` : ""})`);
  return 0;
}

if (require.main === module) {
  process.exit(main(process.argv.slice(2)));
}

module.exports = { varKeys, checkPalette, main };
