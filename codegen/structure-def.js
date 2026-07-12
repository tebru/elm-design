// Structural-module spec DATA for codegen/generate.js (referenced from tokens.js
// via `structure:`). Two generated modules live here:
//
//   1. Tebru.Theme.Structure — structural enums (display, flex, position,
//      size, border structure, …). LITERAL-CLASS-PER-VARIANT mode: unlike the
//      token groups there is no prefix-key regularity (Display/Position map to
//      bare Tailwind classes), so every variant carries its FULL literal class
//      string and the generator never builds a class by concatenation — the
//      Tailwind source scanner must see each class as a literal in the emitted
//      Elm. Multi-setter types (Size, Overflow) list one class per setter, in
//      setter order. The genuinely irregular leftovers (Bool toggles, Edge-keyed
//      border sides, fixed-px control sizing, sugar) ride through as VERBATIM
//      Elm blocks.
//
//   2. Tebru.Box.GridCols — the breakpoint × columns grid-cols matrix Tebru.Box
//      imports. Each breakpoint fn is a CLOSED case over 1..maxCols returning a
//      literal class INCLUDING its breakpoint prefix (a composed `"md:" ++ n`
//      would be invisible to the scanner); out of range falls back to 1 column.
//
// HOVER POLICY IS DATA (see tokens.js): a type with `hoverable: true` keeps the
// tag-polymorphic setter signature (`Config tag -> Config tag`, usable on Hover
// configs) and its classes join the hover: enumeration in generate-inventory.js;
// everything else is emitted `Config Config.Standard -> ...` so hover styling of
// it is a compile error. Verbatim blocks carry the boundary in their authored
// signatures — only blocks marked `hoverable: true` (withBorderSide) may be
// tag-polymorphic over setters of hoverable families; the rest pin Standard.
//
// These are var-less (no @theme output): the classes are stock Tailwind
// utilities, so the generator emits Elm only.

const structure = {
  kind: "classPerVariant",
  elmModule: "Tebru.Theme.Structure",
  doc:
    "Structural styling — display, flex behavior, position, sizing, border structure, and friends.\n" +
    "The structural-enum bucket of the styling model: closed typed enums over stock Tailwind utility classes (var-less; no @theme tokens).",
  imports: ["Tebru.Theme.Space as Space exposing (Edge)"],
  types: [
    {
      elmType: "BorderStyle",
      hoverable: true,
      setters: [{ name: "withBorderStyle", key: "border-style" }],
      variants: {
        BorderSolid: "border-solid",
        BorderDashed: "border-dashed",
        BorderDotted: "border-dotted",
      },
    },
    {
      elmType: "Display",
      setters: [{ name: "withDisplay", key: "display" }],
      variants: {
        Block: "block",
        Flex: "flex",
        InlineFlex: "inline-flex",
        InlineBlock: "inline-block",
        Grid: "grid",
        None: "hidden",
      },
    },
    {
      elmType: "FlexJustify",
      setters: [{ name: "withJustify", key: "justify" }],
      variants: {
        JustifyStart: "justify-start",
        JustifyCenter: "justify-center",
        JustifyEnd: "justify-end",
        JustifyBetween: "justify-between",
      },
    },
    {
      elmType: "FlexAlign",
      setters: [{ name: "withAlign", key: "align" }],
      variants: {
        AlignStart: "items-start",
        AlignCenter: "items-center",
        AlignEnd: "items-end",
        AlignStretch: "items-stretch",
      },
    },
    {
      elmType: "Cursor",
      setters: [{ name: "withCursor", key: "cursor" }],
      variants: {
        CursorPointer: "cursor-pointer",
        CursorDefault: "cursor-default",
        CursorGrab: "cursor-grab",
        CursorNsResize: "cursor-ns-resize",
      },
    },
    {
      elmType: "Position",
      setters: [{ name: "withPosition", key: "position" }],
      variants: {
        Static: "static",
        Relative: "relative",
        Absolute: "absolute",
        Fixed: "fixed",
        Sticky: "sticky",
      },
    },
    {
      elmType: "Inset",
      setters: [{ name: "withInset", key: "inset" }],
      variants: {
        Inset0: "inset-0",
        InsetAuto: "inset-auto",
      },
    },
    {
      elmType: "ZLayer",
      setters: [{ name: "withZ", key: "z" }],
      variants: {
        ZBase: "z-0",
        ZRaised: "z-10",
        ZSticky: "z-20",
        ZDropdown: "z-30",
        ZOverlay: "z-40",
        ZModal: "z-50",
      },
    },
    {
      elmType: "Opacity",
      doc:
        "Element opacity. A small generic scale (the stock Tailwind rungs the app\n" +
        "actually uses) — opacity is a structural property, not design-language colour,\n" +
        "so it lives here rather than in an app token.",
      setters: [{ name: "withOpacity", key: "opacity" }],
      variants: {
        Opacity0: "opacity-0",
        Opacity50: "opacity-50",
        Opacity60: "opacity-60",
        Opacity100: "opacity-100",
      },
    },
    {
      // One type, three setters: plain / x-axis / y-axis, each with its own
      // last-wins Config key and its own literal class per variant.
      elmType: "Overflow",
      setters: [
        { name: "withOverflow", key: "overflow" },
        { name: "withOverflowX", key: "overflow-x" },
        { name: "withOverflowY", key: "overflow-y" },
      ],
      variants: {
        OverflowVisible: ["overflow-visible", "overflow-x-visible", "overflow-y-visible"],
        OverflowHidden: ["overflow-hidden", "overflow-x-hidden", "overflow-y-hidden"],
        OverflowAuto: ["overflow-auto", "overflow-x-auto", "overflow-y-auto"],
        OverflowScroll: ["overflow-scroll", "overflow-x-scroll", "overflow-y-scroll"],
      },
    },
    {
      elmType: "PointerEvents",
      setters: [{ name: "withPointerEvents", key: "pointer-events" }],
      variants: {
        PointerNone: "pointer-events-none",
        PointerAuto: "pointer-events-auto",
      },
    },
    {
      elmType: "Flex",
      setters: [{ name: "withFlex", key: "flex" }],
      variants: {
        Flex1: "flex-1",
        FlexAuto: "flex-auto",
        FlexInitial: "flex-initial",
        FlexNone: "flex-none",
      },
    },
    {
      // One size scale, five setters (width/height/min/min/max), each with its
      // own Config key. Column order below follows the setter order.
      elmType: "Size",
      setters: [
        { name: "withWidth", key: "width" },
        { name: "withHeight", key: "height" },
        { name: "withMinWidth", key: "min-width" },
        { name: "withMinHeight", key: "min-height" },
        // key MUST match tokens.js maxWidth's withX.key: Structure.withMaxWidth and
        // MaxWidth.withMaxWidth target the same CSS property, so they share one
        // Config dict key for cross-module last-wins (otherwise both classes emit).
        { name: "withMaxWidth", key: "max-width" },
      ],
      variants: {
        SizeFull: ["w-full", "h-full", "min-w-full", "min-h-full", "max-w-full"],
        // max-width has no `auto` in CSS — `max-w-none` is the real escape (max-w-auto emits nothing).
        SizeAuto: ["w-auto", "h-auto", "min-w-auto", "min-h-auto", "max-w-none"],
        SizeScreen: ["w-screen", "h-screen", "min-w-screen", "min-h-screen", "max-w-screen"],
        SizeFit: ["w-fit", "h-fit", "min-w-fit", "min-h-fit", "max-w-fit"],
        SizeMin: ["w-min", "h-min", "min-w-min", "min-h-min", "max-w-min"],
        SizeMax: ["w-max", "h-max", "min-w-max", "min-h-max", "max-w-max"],
        SizeZero: ["w-0", "h-0", "min-w-0", "min-h-0", "max-w-0"],
        S1_5: ["w-1.5", "h-1.5", "min-w-1.5", "min-h-1.5", "max-w-1.5"],
        S3: ["w-3", "h-3", "min-w-3", "min-h-3", "max-w-3"],
        S4: ["w-4", "h-4", "min-w-4", "min-h-4", "max-w-4"],
        S6: ["w-6", "h-6", "min-w-6", "min-h-6", "max-w-6"],
        S7: ["w-7", "h-7", "min-w-7", "min-h-7", "max-w-7"],
        S9: ["w-9", "h-9", "min-w-9", "min-h-9", "max-w-9"],
        S10: ["w-10", "h-10", "min-w-10", "min-h-10", "max-w-10"],
        S11: ["w-11", "h-11", "min-w-11", "min-h-11", "max-w-11"],
        S12: ["w-12", "h-12", "min-w-12", "min-h-12", "max-w-12"],
        S14: ["w-14", "h-14", "min-w-14", "min-h-14", "max-w-14"],
        S16: ["w-16", "h-16", "min-w-16", "min-h-16", "max-w-16"],
        S20: ["w-20", "h-20", "min-w-20", "min-h-20", "max-w-20"],
      },
    },
    {
      elmType: "BorderWidth",
      hoverable: true,
      setters: [{ name: "withBorderWidth", key: "border-width" }],
      variants: {
        BorderNone: "border-0",
        BorderThin: "border",
        BorderThick: "border-2",
      },
    },
    {
      elmType: "FlexBasis",
      setters: [{ name: "withFlexBasis", key: "basis" }],
      variants: {
        BasisZero: "basis-0",
        BasisAuto: "basis-auto",
      },
    },
    {
      elmType: "AspectRatio",
      setters: [{ name: "withAspectRatio", key: "aspect" }],
      variants: {
        AspectSquare: "aspect-square",
      },
    },
  ],
  // The irregular leftovers — Bool toggles, Edge-keyed border sides, fixed-px
  // control sizing, and composition sugar. Passed through verbatim; `exposes`
  // feeds the module's exposing list and @docs.
  verbatim: [
    {
      exposes: ["withGrow"],
      code:
        "withGrow : Bool -> Config Config.Standard -> Config Config.Standard\n" +
        "withGrow grow =\n" +
        '    Config.set "grow"\n' +
        "        (if grow then\n" +
        '            "grow"\n' +
        "\n" +
        "         else\n" +
        '            "grow-0"\n' +
        "        )",
    },
    {
      exposes: ["withShrink"],
      code:
        "withShrink : Bool -> Config Config.Standard -> Config Config.Standard\n" +
        "withShrink shrink =\n" +
        '    Config.set "shrink"\n' +
        "        (if shrink then\n" +
        '            "shrink"\n' +
        "\n" +
        "         else\n" +
        '            "shrink-0"\n' +
        "        )",
    },
    {
      exposes: ["square"],
      code:
        "{-| Set width and height to the same size. -}\n" +
        "square : Size -> Config Config.Standard -> Config Config.Standard\n" +
        "square s =\n" +
        "    withWidth s >> withHeight s",
    },
    {
      exposes: ["withBorderSide"],
      hoverable: true,
      code:
        "withBorderSide : Edge -> Config tag -> Config tag\n" +
        "withBorderSide edge =\n" +
        "    let\n" +
        "        ( key, cls ) =\n" +
        "            case edge of\n" +
        "                Space.Top ->\n" +
        '                    ( "border-t", "border-t" )\n' +
        "\n" +
        "                Space.Right ->\n" +
        '                    ( "border-r", "border-r" )\n' +
        "\n" +
        "                Space.Bottom ->\n" +
        '                    ( "border-b", "border-b" )\n' +
        "\n" +
        "                Space.Left ->\n" +
        '                    ( "border-l", "border-l" )\n' +
        "\n" +
        "                _ ->\n" +
        '                    ( "border-side", "border" )\n' +
        "    in\n" +
        "    Config.set key cls",
    },
    {
      exposes: ["withControlHeight"],
      code:
        "withControlHeight : Config Config.Standard -> Config Config.Standard\n" +
        "withControlHeight =\n" +
        '    Config.set "height" "h-[34px]"',
    },
    {
      exposes: ["controlSquare"],
      code:
        "controlSquare : Config Config.Standard -> Config Config.Standard\n" +
        "controlSquare =\n" +
        '    Config.set "width" "w-[34px]" >> Config.set "height" "h-[34px]"',
    },
    {
      exposes: ["withFlexWrap"],
      code:
        "withFlexWrap : Bool -> Config Config.Standard -> Config Config.Standard\n" +
        "withFlexWrap wrap =\n" +
        '    Config.set "flex-wrap"\n' +
        "        (if wrap then\n" +
        '            "flex-wrap"\n' +
        "\n" +
        "         else\n" +
        '            "flex-nowrap"\n' +
        "        )",
    },
    {
      exposes: ["withCenterX"],
      code:
        "withCenterX : Config Config.Standard -> Config Config.Standard\n" +
        "withCenterX =\n" +
        '    Config.set "mx" "mx-auto"',
    },
  ],
};

const gridCols = {
  kind: "breakpointCols",
  elmModule: "Tebru.Box.GridCols",
  doc:
    "The responsive grid-cols matrix `Tebru.Box` resolves `withGridCols` through.\n" +
    "Each breakpoint fn is a closed case over 1..12 returning a literal class including\n" +
    "its breakpoint prefix (out of range falls back to a single column).",
  maxCols: 12,
  fallbackCols: 1,
  breakpoints: [
    { fn: "smCols", prefix: "" },
    { fn: "mdCols", prefix: "md:" },
    { fn: "lgCols", prefix: "lg:" },
    { fn: "xlCols", prefix: "xl:" },
  ],
};

module.exports = { modules: [structure, gridCols] };
