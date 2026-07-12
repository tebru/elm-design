#!/usr/bin/env node
/* bundle-css.js — minimal plain-CSS bundler: flattens `@import "path";` (and
   `@import "path" layer(name);`, which wraps the imported file's content in
   `@layer name { … }`) into ONE output file. This is the whole CSS "build"
   now that the utilities are emitted directly (codegen/emit-css.js): no
   postcss, no Tailwind — just deterministic file inlining.

   Only quoted relative-path imports are supported (that is all the design
   system uses); an unresolvable import or an import cycle is a hard error.
   Belt and braces on top of that: after bundling, ANY surviving @import line
   (e.g. an unquoted `@import url(...)` that IMPORT_RE deliberately does not
   flatten) fails the build — an import that reaches the browser from the
   bundle would be a silent 404 at runtime.

   The CLI strips block comments from the BUNDLED OUTPUT only (the source
   files keep theirs): output.css is a build artifact, and the generated
   headers + hand-written prose were ~10KB of every page load. Exception:
   `/*!` bang comments survive stripping — that is the standard "legally
   significant" marker, and the vendored Tailwind preflight's MIT attribution
   header uses it so the license notice ships in the bundle.

   Usage: node bundle-css.js <entry.css> <out.css> */

const fs = require("fs");
const path = require("path");

const IMPORT_RE = /^@import\s+"([^"]+)"(?:\s+layer\(([A-Za-z-]+)\))?\s*;\s*$/;

function bundle(entryPath, stack = []) {
  const abs = path.resolve(entryPath);
  if (stack.includes(abs)) {
    throw new Error(`bundle-css: import cycle: ${[...stack, abs].join(" -> ")}`);
  }
  if (!fs.existsSync(abs)) throw new Error(`bundle-css: no such file: ${abs}`);
  const dir = path.dirname(abs);
  const out = [];
  let inComment = false; // an @import inside a /* … */ block is prose, not an import
  for (const line of fs.readFileSync(abs, "utf8").split("\n")) {
    const m = inComment ? null : IMPORT_RE.exec(line.trim());
    // track block-comment state across lines (comments never nest in CSS)
    let rest = line;
    for (;;) {
      if (inComment) {
        const end = rest.indexOf("*/");
        if (end === -1) break;
        inComment = false;
        rest = rest.slice(end + 2);
      } else {
        const start = rest.indexOf("/*");
        if (start === -1) break;
        inComment = true;
        rest = rest.slice(start + 2);
      }
    }
    if (!m) {
      out.push(line);
      continue;
    }
    const inlined = bundle(path.resolve(dir, m[1]), [...stack, abs]).trimEnd();
    out.push(m[2] ? `@layer ${m[2]} {\n${inlined}\n}` : inlined);
  }
  return out.join("\n");
}

// Strip block comments — string-aware (a "/*" inside a quoted value is data,
// not a comment; a backslash escapes the next char both in and out of strings,
// covering escaped quotes in emitted selectors). `/*!` bang comments are
// PRESERVED verbatim: they carry license/attribution text (the vendored
// Tailwind preflight's MIT header) that must reach the shipped bundle. Then
// collapse the whitespace holes the stripped comments leave behind. Applied
// to the bundle OUTPUT only.
function stripComments(css) {
  let out = "";
  let i = 0;
  let inStr = null;
  while (i < css.length) {
    const ch = css[i];
    if (inStr) {
      if (ch === "\\") {
        out += ch + (css[i + 1] || "");
        i += 2;
        continue;
      }
      if (ch === inStr) inStr = null;
      out += ch;
      i++;
      continue;
    }
    if (ch === "\\") {
      out += ch + (css[i + 1] || "");
      i += 2;
      continue;
    }
    if (ch === '"' || ch === "'") {
      inStr = ch;
      out += ch;
      i++;
      continue;
    }
    if (ch === "/" && css[i + 1] === "*") {
      const end = css.indexOf("*/", i + 2);
      if (end === -1) throw new Error("bundle-css: unterminated block comment in bundled output");
      if (css[i + 2] === "!") out += css.slice(i, end + 2); // /*! bang comment: license/attribution, keep verbatim
      i = end + 2;
      continue;
    }
    out += ch;
    i++;
  }
  return out
    .split("\n")
    .map((l) => l.replace(/\s+$/, ""))
    .join("\n")
    .replace(/\n{3,}/g, "\n\n")
    .replace(/^\n+/, "")
    .replace(/\n+$/, "\n");
}

// Post-bundle assertion: ZERO @import lines may survive bundling. IMPORT_RE
// flattens only quoted relative imports; anything else (url(...), media-
// qualified, unquoted) would pass through silently and 404 in the browser.
// Run on comment-stripped output, where every remaining @import is real.
function assertNoImports(css) {
  const offenders = [];
  css.split("\n").forEach((line, idx) => {
    if (/@import\b/.test(line)) offenders.push(`  line ${idx + 1}: ${line.trim()}`);
  });
  if (offenders.length > 0) {
    throw new Error(
      `bundle-css: ${offenders.length} unresolved @import line(s) in bundled output — only ` +
        `\`@import "relative/path";\` (optionally with layer(name)) is flattened:\n${offenders.join("\n")}`
    );
  }
}

module.exports = { bundle, stripComments, assertNoImports };

if (require.main === module) {
  const [entry, outFile] = process.argv.slice(2);
  if (!entry || !outFile) {
    console.error("usage: bundle-css.js <entry.css> <out.css>");
    process.exit(1);
  }
  const raw = bundle(entry);
  const css = stripComments(raw);
  assertNoImports(css);
  fs.writeFileSync(outFile, css.trimEnd() + "\n");
  const saved = raw.length - css.length;
  console.log(`bundled: ${outFile} (${css.trimEnd().length + 1} bytes; comment strip saved ~${saved} bytes)`);
}
