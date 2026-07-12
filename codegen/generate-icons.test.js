const { test } = require("node:test");
const assert = require("node:assert");
const { elmName, elmValueFor } = require("./generate-icons");

test("elmName camelCases kebab and escapes reserved words / leading digits", () => {
  assert.strictEqual(elmName("a-arrow-down"), "aArrowDown");
  assert.strictEqual(elmName("calendar"), "calendar");
  assert.strictEqual(elmName("type"), "type_");        // Elm keyword
  assert.strictEqual(elmName("1-circle"), "n1Circle"); // leading-digit guard
});

test("elmValueFor emits a top-level value from structured node data", () => {
  const nodes = [["path", { d: "M5 12h14" }], ["path", { d: "M12 5v14" }]];  // icon-nodes.json shape
  const elm = elmValueFor("plus", nodes);
  assert.match(elm, /^plus : List \(Svg\.Svg msg\)/m);
  assert.match(elm, /Svg\.path \[ SA\.d "M5 12h14" \] \[\]/);
});
