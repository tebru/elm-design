// Utility-class → CSS declaration DATA for codegen/emit-css.js — the design
// system's OWN CSS emitter (no Tailwind). Three kinds of knowledge live here:
//
//   1. STATIC — the one-time hand table for the closed structural vocabulary
//      (structure-def.js literal classes + the var-less utility families the
//      bespoke hatches use). Every entry is copied from the last
//      Tailwind-built output.css, --tw-* machinery included, so the cut-over
//      is provable rule-for-rule. Declarations are strings ("prop: value") or
//      { nest, decls } for a nested block (e.g. the color-mix @supports
//      upgrade inside gradient stops).
//
//   2. ENGINE_VARS — the Tailwind-default theme variables our utility bodies
//      reference (var(--spacing), var(--container-*), --tw fallback chains…).
//      They are engine CONVENTION (not brand identity, not tokens.js scales),
//      registered as plain :root custom properties in @layer theme.
//
//   3. TW_PROPERTIES / PROPERTIES_FALLBACK — the @property registrations (and
//      the Safari/Firefox fallback block) for the --tw-* channel variables the
//      utility bodies compose through. Copied verbatim from Tailwind v4.1.17
//      output so composed utilities (border style+width, shadow slots,
//      translate x/y) keep their exact semantics.
//
// FAMILY_ORDER encodes Tailwind's utility cascade order (which utility wins
// when two same-specificity rules touch the same property, e.g. p-md + px-lg).
// emit-css.js sorts emitted rules by (variant chain, family rank, natural
// name); the order below reproduces the baseline output.css sequence.

// The box-shadow slot chain every shadow/ring utility resolves through.
const BOX_SHADOW =
  "box-shadow: var(--tw-inset-shadow), var(--tw-inset-ring-shadow), var(--tw-ring-offset-shadow), var(--tw-ring-shadow), var(--tw-shadow)";

const TRANSITION_TIMING = [
  "transition-timing-function: var(--tw-ease, var(--default-transition-timing-function))",
  "transition-duration: var(--tw-duration, var(--default-transition-duration))",
];

const STATIC = {
  // ---- display ----
  block: ["display: block"],
  flex: ["display: flex"],
  grid: ["display: grid"],
  hidden: ["display: none"],
  "inline-block": ["display: inline-block"],
  "inline-flex": ["display: inline-flex"],

  // ---- position ----
  static: ["position: static"],
  relative: ["position: relative"],
  absolute: ["position: absolute"],
  fixed: ["position: fixed"],
  sticky: ["position: sticky"],
  "inset-auto": ["inset: auto"],

  // ---- pointer events / cursor ----
  "pointer-events-auto": ["pointer-events: auto"],
  "pointer-events-none": ["pointer-events: none"],
  "cursor-default": ["cursor: default"],
  "cursor-grab": ["cursor: grab"],
  "cursor-not-allowed": ["cursor: not-allowed"],
  "cursor-ns-resize": ["cursor: ns-resize"],
  "cursor-pointer": ["cursor: pointer"],

  // ---- flex behavior ----
  "flex-1": ["flex: 1"],
  "flex-auto": ["flex: auto"],
  "flex-initial": ["flex: 0 auto"],
  "flex-none": ["flex: none"],
  grow: ["flex-grow: 1"],
  "grow-0": ["flex-grow: 0"],
  shrink: ["flex-shrink: 1"],
  "shrink-0": ["flex-shrink: 0"],
  "basis-auto": ["flex-basis: auto"],
  "flex-col": ["flex-direction: column"],
  "flex-row": ["flex-direction: row"],
  "flex-nowrap": ["flex-wrap: nowrap"],
  "flex-wrap": ["flex-wrap: wrap"],
  "items-center": ["align-items: center"],
  "items-end": ["align-items: flex-end"],
  "items-start": ["align-items: flex-start"],
  "items-stretch": ["align-items: stretch"],
  "justify-between": ["justify-content: space-between"],
  "justify-center": ["justify-content: center"],
  "justify-end": ["justify-content: flex-end"],
  "justify-start": ["justify-content: flex-start"],

  // ---- margin sugar ----
  "mx-auto": ["margin-inline: auto"],

  // ---- aspect ----
  "aspect-square": ["aspect-ratio: 1 / 1"],

  // ---- lists / overflow / text flow ----
  "list-none": ["list-style-type: none"],
  truncate: ["overflow: hidden", "text-overflow: ellipsis", "white-space: nowrap"],
  "overflow-auto": ["overflow: auto"],
  "overflow-hidden": ["overflow: hidden"],
  "overflow-scroll": ["overflow: scroll"],
  "overflow-visible": ["overflow: visible"],
  "overflow-x-auto": ["overflow-x: auto"],
  "overflow-x-hidden": ["overflow-x: hidden"],
  "overflow-x-scroll": ["overflow-x: scroll"],
  "overflow-x-visible": ["overflow-x: visible"],
  "overflow-y-auto": ["overflow-y: auto"],
  "overflow-y-hidden": ["overflow-y: hidden"],
  "overflow-y-scroll": ["overflow-y: scroll"],
  "overflow-y-visible": ["overflow-y: visible"],

  // ---- bare radius (Tailwind's unnamed 0.25rem default, used by bespoke) ----
  rounded: ["border-radius: 0.25rem"],

  // ---- border width / style (structure-def BorderWidth/BorderStyle + sides) ----
  border: ["border-style: var(--tw-border-style)", "border-width: 1px"],
  "border-0": ["border-style: var(--tw-border-style)", "border-width: 0px"],
  "border-2": ["border-style: var(--tw-border-style)", "border-width: 2px"],
  "border-t": ["border-top-style: var(--tw-border-style)", "border-top-width: 1px"],
  "border-r": ["border-right-style: var(--tw-border-style)", "border-right-width: 1px"],
  "border-b": ["border-bottom-style: var(--tw-border-style)", "border-bottom-width: 1px"],
  "border-l": ["border-left-style: var(--tw-border-style)", "border-left-width: 1px"],
  "border-solid": ["--tw-border-style: solid", "border-style: solid"],
  "border-dashed": ["--tw-border-style: dashed", "border-style: dashed"],
  "border-dotted": ["--tw-border-style: dotted", "border-style: dotted"],

  // ---- gradients (bespoke: Ui.Rail pill sheen) ----
  "bg-gradient-to-b": ["--tw-gradient-position: to bottom in oklab", "background-image: linear-gradient(var(--tw-gradient-stops))"],
  "from-white/10": [
    "--tw-gradient-from: color-mix(in srgb, #fff 10%, transparent)",
    {
      nest: "@supports (color: color-mix(in lab, red, red))",
      decls: ["--tw-gradient-from: color-mix(in oklab, var(--color-white) 10%, transparent)"],
    },
    "--tw-gradient-stops: var(--tw-gradient-via-stops, var(--tw-gradient-position), var(--tw-gradient-from) var(--tw-gradient-from-position), var(--tw-gradient-to) var(--tw-gradient-to-position))",
  ],
  "to-black/[0.08]": [
    "--tw-gradient-to: color-mix(in srgb, #000 8%, transparent)",
    {
      nest: "@supports (color: color-mix(in lab, red, red))",
      decls: ["--tw-gradient-to: color-mix(in oklab, var(--color-black) 8%, transparent)"],
    },
    "--tw-gradient-stops: var(--tw-gradient-via-stops, var(--tw-gradient-position), var(--tw-gradient-from) var(--tw-gradient-from-position), var(--tw-gradient-to) var(--tw-gradient-to-position))",
  ],

  // ---- typography utilities (var-less token groups) ----
  "text-center": ["text-align: center"],
  "text-left": ["text-align: left"],
  "text-right": ["text-align: right"],
  "leading-none": ["--tw-leading: 1", "line-height: 1"],
  "leading-tight": ["--tw-leading: var(--leading-tight)", "line-height: var(--leading-tight)"],
  "tracking-tight": ["--tw-tracking: var(--tracking-tight)", "letter-spacing: var(--tracking-tight)"],
  "tracking-normal": ["--tw-tracking: var(--tracking-normal)", "letter-spacing: var(--tracking-normal)"],
  "tracking-wide": ["--tw-tracking: var(--tracking-wide)", "letter-spacing: var(--tracking-wide)"],
  "whitespace-normal": ["white-space: normal"],
  "whitespace-nowrap": ["white-space: nowrap"],
  uppercase: ["text-transform: uppercase"],
  underline: ["text-decoration-line: underline"],
  "no-underline": ["text-decoration-line: none"],

  // ---- focus ring / outline (bespoke: Component.Input focus treatment) ----
  "ring-1": [
    "--tw-ring-shadow: var(--tw-ring-inset,) 0 0 0 calc(1px + var(--tw-ring-offset-width)) var(--tw-ring-color, currentcolor)",
    BOX_SHADOW,
  ],
  "ring-border-focus": ["--tw-ring-color: var(--color-border-focus)"],
  "outline-none": ["--tw-outline-style: none", "outline-style: none"],

  // ---- transitions (var-less token group Tebru.Theme.Transition) ----
  transition: [
    "transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke, --tw-gradient-from, --tw-gradient-via, --tw-gradient-to, opacity, box-shadow, transform, translate, scale, rotate, filter, -webkit-backdrop-filter, backdrop-filter, display, content-visibility, overlay, pointer-events",
    ...TRANSITION_TIMING,
  ],
  "transition-all": ["transition-property: all", ...TRANSITION_TIMING],
  "transition-colors": [
    "transition-property: color, background-color, border-color, outline-color, text-decoration-color, fill, stroke, --tw-gradient-from, --tw-gradient-via, --tw-gradient-to",
    ...TRANSITION_TIMING,
  ],
  "transition-opacity": ["transition-property: opacity", ...TRANSITION_TIMING],
  "transition-shadow": ["transition-property: box-shadow", ...TRANSITION_TIMING],
  "transition-transform": ["transition-property: transform, translate, scale, rotate", ...TRANSITION_TIMING],
  "transition-[width]": ["transition-property: width", ...TRANSITION_TIMING],
  "transition-none": ["transition-property: none"],
  "ease-linear": ["--tw-ease: linear", "transition-timing-function: linear"],
  "ease-in": ["--tw-ease: var(--ease-in)", "transition-timing-function: var(--ease-in)"],
  "ease-out": ["--tw-ease: var(--ease-out)", "transition-timing-function: var(--ease-out)"],
  "ease-in-out": ["--tw-ease: var(--ease-in-out)", "transition-timing-function: var(--ease-in-out)"],
};

// Classes that deliberately emit NO utility rule. Kept exact and tiny — any
// other uncompilable class is a hard error (the closed-vocabulary contract).
const NO_CSS = new Set([
  // marker class: styling hook for group-hover:*, carries no declarations
  "group",
  // hand-written component CSS (package components.css)
  "skeleton", "skeleton-dark", "skeleton-narrow", "skeleton-medium", "skeleton-wide",
  "animate-modal-enter", "animate-backdrop-fade", "animate-slide-down", "animate-dropdown-enter",
  "lucide-icon",
  // hand-written app CSS (static/styles.css)
  "bg-busy-cell", "bg-busy-solid", "bg-proposed-block",
]);

// App color keys whose classes are hand-written rules rather than color tokens
// (no --color-* var exists). The hover cross-product enumerates them; the
// emitter skips those variants exactly as Tailwind (finding no token) did.
const HANDWRITTEN_COLOR_KEYS = new Set(["busy-cell", "busy-solid", "proposed-block"]);

// Color keys the PACKAGE's own bespoke literals reference but whose VALUE is
// CONSUMER-owned (part of the palette contract, not an engine role group):
// Tebru.Component.Choice's switch hover fallback composes `bg-surface-hover`
// into a Hover config (rendered as `hover:bg-surface-hover`). Each key here is
// wired through the full contract story: generate-inventory.js cross-products
// it into the PACKAGE hover half (hover:{bg,text,border}-<key>), emit-css.js
// buildContext resolves it as var(--color-<key>), and generate.js registers the
// delegation `--color-<key>: var(--<key>)` in generated.css and lists `--<key>`
// in palette.template.css — so check-palette.js fails the build of any consumer
// that does not define it. (The Overlap app defines --surface-hover in
// static/palette.css; its app-tokens.js SurfaceHover facet value, emitted later
// in the theme layer, wins with the same value.)
const CONSUMER_CONTRACT_COLORS = new Set(["surface-hover"]);

// Engine-convention theme variables referenced by the utility bodies above and
// by the mechanical rules in emit-css.js (Tailwind v4 default values). Brand
// tokens live in generated.css / app-tokens.generated.css — never here.
const ENGINE_VARS = [
  ["--font-mono", 'ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace'],
  ["--color-black", "#000"],
  ["--color-white", "#fff"],
  ["--spacing", "0.25rem"],
  // Container scale for max-w-*: full Tailwind scale. NOTE the parity quirk:
  // max-w-{xs,sm,md,lg,xl} historically resolved to --spacing-* (namespace
  // collision under Tailwind); emit-css.js preserves that mapping, so only the
  // container steps actually referenced are strictly needed — the full scale
  // is registered because we own the names now (see emit-css.js maxWidth notes).
  ["--container-3xs", "16rem"],
  ["--container-2xs", "18rem"],
  ["--container-xs", "20rem"],
  ["--container-sm", "24rem"],
  ["--container-md", "28rem"],
  ["--container-lg", "32rem"],
  ["--container-xl", "36rem"],
  ["--container-2xl", "42rem"],
  ["--container-3xl", "48rem"],
  ["--container-4xl", "56rem"],
  ["--container-5xl", "64rem"],
  ["--container-6xl", "72rem"],
  ["--container-7xl", "80rem"],
  ["--tracking-tight", "-0.025em"],
  ["--tracking-normal", "0em"],
  ["--tracking-wide", "0.025em"],
  ["--leading-tight", "1.25"],
  ["--ease-in", "cubic-bezier(0.4, 0, 1, 1)"],
  ["--ease-out", "cubic-bezier(0, 0, 0.2, 1)"],
  ["--ease-in-out", "cubic-bezier(0.4, 0, 0.2, 1)"],
  ["--default-transition-duration", "150ms"],
  ["--default-transition-timing-function", "cubic-bezier(0.4, 0, 0.2, 1)"],
  ["--default-font-family", "var(--font-sans)"],
  ["--default-mono-font-family", "var(--font-mono)"],
];

// Utility families in cascade order (Tailwind's property order). A rule's
// family decides which same-property utility wins when an element carries two
// (e.g. p-md px-lg → px wins because px ranks later). Derived from the
// baseline output.css sequence; the equivalence differ checks relative order.
const FAMILY_ORDER = [
  "pointer-events", "position",
  "inset", "inset-x", "inset-y", "top", "right", "bottom", "left",
  "z",
  "m", "mx", "my", "ms", "me", "mt", "mr", "mb", "ml",
  "display", "aspect",
  "h", "max-h", "min-h", "w", "max-w", "min-w",
  "flex-short", "shrink", "grow", "basis",
  "translate-x", "translate-y", "rotate",
  "cursor", "list", "grid-cols", "flex-dir", "flex-wrap-fam", "items", "justify",
  "gap", "gap-x", "gap-y",
  "truncate", "overflow", "overflow-x", "overflow-y",
  "rounded", "rounded-tl", "rounded-tr", "rounded-br", "rounded-bl",
  "border-w", "border-w-x", "border-w-y", "border-w-t", "border-w-r", "border-w-b", "border-w-l",
  "border-style",
  "border-color", "border-color-x", "border-color-y", "border-color-t", "border-color-r", "border-color-b", "border-color-l",
  "bg", "bg-gradient", "from", "to",
  "p", "px", "py", "pt", "pr", "pb", "pl",
  "text-align", "font-size", "leading", "font-weight", "tracking", "whitespace",
  "text-color", "text-transform", "decoration", "opacity",
  "shadow", "ring", "ring-color", "outline",
  "transition", "transition-none", "duration", "ease", "content",
];

// Static-class → family (classes whose family isn't derivable from the name
// by the prefix rules in emit-css.js).
const STATIC_FAMILY = {
  block: "display", flex: "display", grid: "display", hidden: "display",
  "inline-block": "display", "inline-flex": "display",
  static: "position", relative: "position", absolute: "position", fixed: "position", sticky: "position",
  "inset-auto": "inset", "mx-auto": "mx", "aspect-square": "aspect",
  "flex-1": "flex-short", "flex-auto": "flex-short", "flex-initial": "flex-short", "flex-none": "flex-short",
  grow: "grow", "grow-0": "grow", shrink: "shrink", "shrink-0": "shrink", "basis-auto": "basis",
  "flex-col": "flex-dir", "flex-row": "flex-dir", "flex-wrap": "flex-wrap-fam", "flex-nowrap": "flex-wrap-fam",
  truncate: "truncate", rounded: "rounded",
  border: "border-w", "border-0": "border-w", "border-2": "border-w",
  "border-t": "border-w-t", "border-r": "border-w-r", "border-b": "border-w-b", "border-l": "border-w-l",
  "border-solid": "border-style", "border-dashed": "border-style", "border-dotted": "border-style",
  "bg-gradient-to-b": "bg-gradient", "from-white/10": "from", "to-black/[0.08]": "to",
  "text-center": "text-align", "text-left": "text-align", "text-right": "text-align",
  uppercase: "text-transform", underline: "decoration", "no-underline": "decoration",
  "ring-1": "ring", "ring-border-focus": "ring-color", "outline-none": "outline",
  transition: "transition", "transition-all": "transition", "transition-colors": "transition",
  "transition-opacity": "transition", "transition-shadow": "transition", "transition-transform": "transition",
  "transition-[width]": "transition",
  // transition-none ranks AFTER the property-selecting transition utilities
  // (turning transitions off must beat turning them on).
  "transition-none": "transition-none",
};

// @property registrations for the --tw-* channel vars, verbatim from Tailwind
// v4.1.17 (MIT) — plus the @supports fallback block for engines without
// @property support. Emitted at the end of the utilities file, in cascade
// layer `properties` (declared FIRST, so every utility layer beats it).
const TW_PROPERTIES = [
  ["--tw-translate-x", '"*"', "0"],
  ["--tw-translate-y", '"*"', "0"],
  ["--tw-translate-z", '"*"', "0"],
  ["--tw-border-style", '"*"', "solid"],
  ["--tw-gradient-position", '"*"', null],
  ["--tw-gradient-from", '"<color>"', "#0000"],
  ["--tw-gradient-via", '"<color>"', "#0000"],
  ["--tw-gradient-to", '"<color>"', "#0000"],
  ["--tw-gradient-stops", '"*"', null],
  ["--tw-gradient-via-stops", '"*"', null],
  ["--tw-gradient-from-position", '"<length-percentage>"', "0%"],
  ["--tw-gradient-via-position", '"<length-percentage>"', "50%"],
  ["--tw-gradient-to-position", '"<length-percentage>"', "100%"],
  ["--tw-leading", '"*"', null],
  ["--tw-font-weight", '"*"', null],
  ["--tw-tracking", '"*"', null],
  ["--tw-shadow", '"*"', "0 0 #0000"],
  ["--tw-shadow-color", '"*"', null],
  ["--tw-shadow-alpha", '"<percentage>"', "100%"],
  ["--tw-inset-shadow", '"*"', "0 0 #0000"],
  ["--tw-inset-shadow-color", '"*"', null],
  ["--tw-inset-shadow-alpha", '"<percentage>"', "100%"],
  ["--tw-ring-color", '"*"', null],
  ["--tw-ring-shadow", '"*"', "0 0 #0000"],
  ["--tw-inset-ring-color", '"*"', null],
  ["--tw-inset-ring-shadow", '"*"', "0 0 #0000"],
  ["--tw-ring-inset", '"*"', null],
  ["--tw-ring-offset-width", '"<length>"', "0px"],
  ["--tw-ring-offset-color", '"*"', "#fff"],
  ["--tw-ring-offset-shadow", '"*"', "0 0 #0000"],
  ["--tw-duration", '"*"', null],
  ["--tw-ease", '"*"', null],
  ["--tw-content", '"*"', '""'],
];

module.exports = {
  BOX_SHADOW, STATIC, NO_CSS, HANDWRITTEN_COLOR_KEYS, CONSUMER_CONTRACT_COLORS,
  ENGINE_VARS, FAMILY_ORDER, STATIC_FAMILY, TW_PROPERTIES,
};
