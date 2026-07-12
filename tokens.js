module.exports = {
  // Structural-module specs (Tebru.Theme.Structure, Tebru.Box.GridCols) — data,
  // not tokens: literal utility classes per variant, var-less (no theme-var output).
  structure: require("./codegen/structure-def"),
  // HOVER POLICY IS DATA: a group marked `hoverable: true` may be styled through
  // the hover channel (`withHoverStyle`). The flag drives BOTH halves of the
  // contract from one source:
  //   - generate.js emits the group's withX as `Config tag -> Config tag`
  //     (usable on Standard AND Hover configs); non-hoverable groups get
  //     `Config Config.Standard -> ...`, so out-of-policy hover styling is a
  //     COMPILE ERROR rather than a silent no-op;
  //   - generate-inventory.js enumerates `hover:` classes for exactly the
  //     hoverable groups (plus the hoverable structure-def types/verbatims),
  //     so the emitted hover CSS and the type boundary can never drift apart.
  // Policy: colors (surface/text/border), elevation, and text-decoration are
  // hoverable; scales/structure (radius, spacing, sizing, typography, ...) are not.
  // Engine-DEFAULT responsive breakpoints, consumed by codegen/emit-css.js for
  // the md:/lg:/xl: grid-cols media queries. A consuming app overrides them
  // with a `breakpoints` key in its own tokens file (the app owns its layout
  // phases; these defaults only serve package-scope builds/previews).
  breakpoints: { sm: "640px", md: "768px", lg: "1024px", xl: "1280px" },
  groups: {
    // GEOMETRY scale — closed; woven into structural types. Custom spacing = component-local arbitrary value.
    space: {
      elmModule: "Tebru.Theme.Space", elmType: "Space", cssVar: "spacing", geometry: true,
      steps: {
        None: { key: "0",   value: "0" },      Xs:  { key: "xs",  value: "0.25rem" },
        Xxs:  { key: "xxs", value: "0.125rem" },
        Sm:   { key: "sm",  value: "0.5rem" },  Md:  { key: "md",  value: "0.75rem" },
        Lg:   { key: "lg",  value: "1rem" },    Xl:  { key: "xl",  value: "1.5rem" },
        Xxl:  { key: "xxl", value: "2rem" },
        Xxxl: { key: "xxxl", value: "4rem" },
      },
    },

    // ROLE — background surfaces. class: bg-surface-*, var: --color-surface-*.
    // VALUE-FREE: only the role STRUCTURE lives here; the consumer supplies the
    // values for each `key` as a --<key> custom property (see palette.template.css).
    surface: {
      elmModule: "Tebru.Theme.Surface", elmType: "Surface", cssVar: "color",
      class: { prefix: "bg" },
      withX: { name: "withSurface", field: "visual", setter: "setSurface" },
      extensible: true, hoverable: true,
      variants: {
        Page:         { key: "surface-page" },
        Card:         { key: "surface-card" },
        CardAlt:      { key: "surface-card-alt" },
        Subtle:       { key: "surface-subtle" },
        Selected:     { key: "surface-selected" },
        Disabled:     { key: "surface-disabled" },
        Brand:        { key: "surface-brand" },
        BrandHover:   { key: "surface-brand-hover" },
        Danger:       { key: "surface-danger" },
        DangerHover:  { key: "surface-danger-hover" },
        Success:      { key: "surface-success" },
        Warning:      { key: "surface-warning" },
        Info:         { key: "surface-info" },
        Error:        { key: "surface-error" },
        Inverse:      { key: "surface-inverse" },
        InverseHover: { key: "surface-inverse-hover" },
        InverseActive: { key: "surface-inverse-active" },
        Backdrop:     { key: "surface-backdrop" },
        Transparent:  { key: "transparent", builtin: true },
      },
    },

    // ROLE — text/foreground colors. Keys are fg-* to avoid text-text-* doubling.
    // class: text-fg-*, var: --color-fg-*. VALUE-FREE (consumer supplies --fg-*).
    text: {
      elmModule: "Tebru.Theme.Text", elmType: "Text", cssVar: "color",
      class: { prefix: "text" },
      withX: { name: "withText", field: "visual", setter: "setText" },
      extensible: true, hoverable: true,
      variants: {
        Default:      { key: "fg-default" },
        Secondary:    { key: "fg-secondary" },
        Muted:        { key: "fg-muted" },
        Hint:         { key: "fg-hint" },
        Inverse:      { key: "fg-inverse" },
        InverseMuted: { key: "fg-inverse-muted" },
        OnBrand:      { key: "fg-on-brand" },
        Link:         { key: "fg-link" },
        LinkHover:    { key: "fg-link-hover" },
        Error:        { key: "fg-error" },
        Success:      { key: "fg-success" },
      },
    },

    // ROLE — border colors. Keys are border-* so class is border-border-*, var
    // --color-border-*. VALUE-FREE (consumer supplies --border-*).
    border: {
      elmModule: "Tebru.Theme.Border", elmType: "Border", cssVar: "color",
      class: { prefix: "border" },
      withX: { name: "withBorder", field: "visual", setter: "setBorder" },
      extensible: true, hoverable: true,
      variants: {
        Default:     { key: "border-default" },
        Hover:       { key: "border-hover" },
        Divider:     { key: "border-divider" },
        Focus:       { key: "border-focus" },
        Error:       { key: "border-error" },
        Success:     { key: "border-success" },
        Transparent: { key: "border-transparent" },
        OnDark:      { key: "border-on-dark" },
      },
    },

    // SIMPLE scale — border radius. class: rounded-*, var: --radius-*
    radius: {
      elmModule: "Tebru.Theme.Radius", elmType: "Radius", cssVar: "radius",
      class: { prefix: "rounded" },
      withX: { name: "withRadius", field: "visual", setter: "setRadius" },
      extensible: true,
      corners: true,
      steps: {
        None: { key: "none", value: "0" },
        Sm:   { key: "sm",   value: "0.25rem" },
        Md:   { key: "md",   value: "0.375rem" },
        Lg:   { key: "lg",   value: "0.5rem" },
        Xl:   { key: "xl",   value: "0.75rem" },
        Full: { key: "full", value: "9999px" },
      },
    },

    // SIMPLE scale — box shadows. class: shadow-*, var: --shadow-*
    elevation: {
      elmModule: "Tebru.Theme.Elevation", elmType: "Elevation", cssVar: "shadow",
      class: { prefix: "shadow" },
      withX: { name: "withElevation", field: "visual", setter: "setElevation" },
      extensible: true, hoverable: true,
      steps: {
        None: { key: "none", value: "none" },
        Xs:   { key: "xs",   value: "0 1px 2px rgba(0,0,0,0.04), 0 1px 4px rgba(0,0,0,0.03)" },
        Sm:   { key: "sm",   value: "0 1px 2px 0 rgb(0 0 0 / 0.05)" },
        Md:   { key: "md",   value: "0 4px 14px 0 rgb(0 0 0 / 0.1)" },
        Lg:   { key: "lg",   value: "0 10px 30px 0 rgb(0 0 0 / 0.15)" },
        Xl:   { key: "xl",   value: "0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)" },
        Xxl:  { key: "xxl",  value: "0 25px 50px -12px rgb(0 0 0 / 0.25)" },
      },
    },

    // BRAND FONT — like colors, the font stack is brand identity, not engine
    // convention, so it follows the color contract: registered VALUE-FREE in
    // @theme (--font-sans delegates to the consumer contract var named by
    // `contract:`, which joins palette.template.css next to the color roles).
    // Overriding it re-fonts everything: Tailwind's preflight body font and the
    // `font-sans` utility both resolve through --font-sans. CSS-ONLY: no Elm
    // module (Elm code never sets font-family), so no elmModule/withX.
    fontFamily: {
      cssOnly: true, cssVar: "font",
      variants: {
        Sans: { key: "sans", contract: "font-family-sans", placeholder: "ui-sans-serif, system-ui, sans-serif" },
      },
    },

    // SIMPLE scale — font sizes. class: text-*, var: --text-* (+ the paired
    // --text-*--line-height when `lineHeight:` is present — each text-K
    // utility then sets line-height: var(--tw-leading, var(--text-K--line-height)),
    // exactly like the Tailwind scale these values historically came from.
    // xxs deliberately has NO lineHeight: it never did, so its utility sets
    // font-size only.)
    fontSize: {
      elmModule: "Tebru.Theme.Typography", elmType: "FontSize", cssVar: "text",
      class: { prefix: "text" },
      withX: { name: "withFontSize", field: "visual", setter: "setFontSize" },
      extensible: true,
      steps: {
        Xxs:  { key: "xxs",  value: "0.625rem" },
        Xs:   { key: "xs",   value: "0.75rem",  lineHeight: "calc(1 / 0.75)" },
        Sm:   { key: "sm",   value: "0.875rem", lineHeight: "calc(1.25 / 0.875)" },
        Base: { key: "base", value: "1rem",     lineHeight: "calc(1.5 / 1)" },
        Lg:   { key: "lg",   value: "1.125rem", lineHeight: "calc(1.75 / 1.125)" },
        Xl:   { key: "xl",   value: "1.25rem",  lineHeight: "calc(1.75 / 1.25)" },
        X2l:  { key: "2xl",  value: "1.5rem",   lineHeight: "calc(2 / 1.5)" },
        X3l:  { key: "3xl",  value: "1.875rem", lineHeight: "calc(2.25 / 1.875)" },
      },
    },

    // SIMPLE scale — font weights. class: font-*, var: --font-weight-*
    fontWeight: {
      elmModule: "Tebru.Theme.Typography", elmType: "FontWeight", cssVar: "font-weight",
      class: { prefix: "font" },
      withX: { name: "withFontWeight", field: "visual", setter: "setFontWeight" },
      extensible: true,
      steps: {
        Normal:   { key: "normal",   value: "400" },
        Medium:   { key: "medium",   value: "500" },
        Semibold: { key: "semibold", value: "600" },
        Bold:     { key: "bold",     value: "700" },
      },
    },

    // UTILITY — value-less text utilities. Var-less: fixed Tailwind classes, no
    // @theme var. All share elmModule Theme.Typography.
    textAlign: {
      elmModule: "Tebru.Theme.Typography", elmType: "TextAlign", class: { prefix: "text" },
      withX: { name: "withTextAlign", setter: "setTextAlign" },
      variants: { TextLeft: { key: "left" }, TextCenter: { key: "center" }, TextRight: { key: "right" } },
    },
    letterSpacing: {
      elmModule: "Tebru.Theme.Typography", elmType: "LetterSpacing", class: { prefix: "tracking" },
      withX: { name: "withLetterSpacing", setter: "setLetterSpacing" },
      variants: { TrackingTight: { key: "tight" }, TrackingNormal: { key: "normal" }, TrackingWide: { key: "wide" } },
    },
    lineHeight: {
      elmModule: "Tebru.Theme.Typography", elmType: "LineHeight", class: { prefix: "leading" },
      withX: { name: "withLineHeight", setter: "setLineHeight" },
      variants: { LineNone: { key: "none" }, LineTight: { key: "tight" } },
    },
    whiteSpace: {
      elmModule: "Tebru.Theme.Typography", elmType: "WhiteSpace", class: { prefix: "whitespace" },
      withX: { name: "withWhiteSpace", setter: "setWhiteSpace" },
      variants: { WhiteSpaceNormal: { key: "normal" }, WhiteSpaceNowrap: { key: "nowrap" } },
    },
    textTransform: {
      elmModule: "Tebru.Theme.Typography", elmType: "TextTransform", class: { prefix: "" },
      withX: { name: "withTextTransform", setter: "setTextTransform" },
      variants: { Uppercase: { key: "uppercase" } },
    },
    decoration: {
      elmModule: "Tebru.Theme.Typography", elmType: "Decoration", class: { prefix: "" },
      hoverable: true,
      withX: { name: "withDecoration", setter: "setDecoration" },
      variants: { Underline: { key: "underline" }, NoUnderline: { key: "no-underline" } },
    },
    textOverflow: {
      elmModule: "Tebru.Theme.Typography", elmType: "TextOverflow", class: { prefix: "" },
      withX: { name: "withTextOverflow", setter: "setTextOverflow" },
      variants: { Truncate: { key: "truncate" } },
    },

    // UTILITY — transition property. Var-less: these map to fixed Tailwind utilities
    // (no @theme value), so the codegen emits the Elm type/resolver/withX only.
    // All three share elmModule Theme.Transition. class: transition-*
    transition: {
      elmModule: "Tebru.Theme.Transition", elmType: "Transition",
      class: { prefix: "transition" },
      withX: { name: "withTransition", setter: "setTransition" },
      variants: {
        TransitionColors:    { key: "colors" },
        TransitionAll:       { key: "all" },
        TransitionOpacity:   { key: "opacity" },
        TransitionTransform: { key: "transform" },
        TransitionShadow:    { key: "shadow" },
        TransitionWidth:     { key: "[width]" },
        TransitionNone:      { key: "none" },
      },
    },

    // UTILITY — transition duration. Var-less. class: duration-*
    transitionDuration: {
      elmModule: "Tebru.Theme.Transition", elmType: "Duration",
      class: { prefix: "duration" },
      withX: { name: "withDuration", setter: "setDuration" },
      variants: {
        DurationFast:   { key: "75" },
        DurationNormal: { key: "150" },
        DurationSlow:   { key: "300" },
      },
    },

    // UTILITY — transition timing function. Var-less. class: ease-*
    transitionEasing: {
      elmModule: "Tebru.Theme.Transition", elmType: "Easing",
      class: { prefix: "ease" },
      withX: { name: "withEasing", setter: "setEasing" },
      variants: {
        EaseLinear: { key: "linear" },
        EaseIn:     { key: "in" },
        EaseOut:    { key: "out" },
        EaseInOut:  { key: "in-out" },
      },
    },

    // SCALE — container max-widths. Var-less: maps to Tailwind's built-in
    // `--container-*` scale (shipped by default), so the codegen emits the Elm
    // type/resolver/withX only — no @theme var. The full named scale lives here
    // as the single home for content/panel width caps. class: max-w-*
    maxWidth: {
      elmModule: "Tebru.Theme.MaxWidth", elmType: "MaxWidth",
      class: { prefix: "max-w" },
      // key MUST match structure-def.js Size's withMaxWidth key ("max-width"):
      // both setters target CSS max-width, so they share one Config dict key
      // for cross-module last-wins (otherwise both max-w-* classes emit).
      withX: { name: "withMaxWidth", setter: "setMaxWidth", key: "max-width" },
      variants: {
        X3s: { key: "3xs" },
        X2s: { key: "2xs" },
        Xs:  { key: "xs" },
        Sm:  { key: "sm" },
        Md:  { key: "md" },
        Lg:  { key: "lg" },
        Xl:  { key: "xl" },
        X2l: { key: "2xl" },
        X3l: { key: "3xl" },
        X4l: { key: "4xl" },
        X5l: { key: "5xl" },
        X6l: { key: "6xl" },
        X7l: { key: "7xl" },
      },
    },
  },
};
