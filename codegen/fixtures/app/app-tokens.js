/* Vendored TEST FIXTURE — a snapshot of the Overlap app's app-tokens.js used
   by the codegen suite when no real app checkout is present (standalone
   package checkout / CI); see codegen/fixtures/resolve-app-tokens.js.

   Kept structurally faithful to the real file: same breakpoints, same
   appColor variant keys/facets (the tests assert on specific emitted classes
   and on the hand-written no-CSS keys), and a bespoke src tree carrying the
   exact literals the tests expect. Color values are irrelevant to the
   inventory/emitter tests and are dummies. No `output` block: the fixture
   feeds generate-inventory/emit-css only, never generate.js. */

module.exports = {
  breakpoints: { sm: "640px", md: "960px", lg: "1600px", xl: "2048px" },
  utilities: {
    css: "../static/utilities.generated.css",
    bespokeSources: ["./src"],
  },
  groups: {
    appColor: {
      elmModule: "Style.AppColor", elmType: "AppColor", facetGroup: true,
      hosts: {
        surface: { fn: "surfaceClass", prefix: "bg",     applyFn: "appSurface", import: "Tebru.Theme.Surface as Surface", hostWith: "withSurfaceCustom" },
        text:    { fn: "textClass",    prefix: "text",   applyFn: "appText",    import: "Tebru.Theme.Text as TextColor",  hostWith: "withTextCustom" },
        border:  { fn: "borderClass",  prefix: "border", applyFn: "appBorder",  import: "Tebru.Theme.Border as Border",   hostWith: "withBorderCustom" },
      },
      variants: {
        AvailAvailable:    { facet: "surface", key: "avail-available", value: "#dde9e0" },
        AvailPreferred:    { facet: "surface", key: "avail-preferred", value: "#7fa68c" },
        AvailIfNeeded:     { facet: "surface", key: "avail-ifneeded",  value: "#ecebe5" },
        SageWash:          { facet: "surface", key: "sage-wash",   value: "#e8efe9" },
        SageSoft:          { facet: "surface", key: "sage-soft",   value: "#cfdfd4" },
        SageBright:        { facet: "surface", key: "sage-bright", value: "#7fa68c" },
        StatusAmber:       { facet: "surface", key: "status-amber",      value: "#c98a3a" },
        StatusAmberWash:   { facet: "surface", key: "status-amber-wash", value: "#faf2e3" },
        StatusBlue:        { facet: "surface", key: "status-blue",       value: "#5b7fb0" },
        StatusBlueSoft:    { facet: "surface", key: "status-blue-soft",  value: "#d8e2f0" },
        StatusConfirmedBg: { facet: "surface", key: "status-confirmed-bg",  value: "#ecebe5" },
        StatusConfirmedDot:{ facet: "surface", key: "status-confirmed-dot", value: "#a8a9b0" },
        ProposedBlock:     { facet: "surface", key: "proposed-block" }, // hand-written rule, no CSS
        ErrorSolid:        { facet: "surface", key: "error",    value: "#c45d42" },
        ErrorWash:         { facet: "surface", key: "error-bg", value: "#fdf6f4" },
        DarkRail:          { facet: "surface", key: "dark",       value: "#1c1d22" },
        DarkRailHover:     { facet: "surface", key: "dark-hover", value: "#2a2c32" },
        SurfaceHover:      { facet: "surface", key: "surface-hover", value: "#ebebeb" },
        RailMuted:         { facet: "surface", key: "rail-muted",    value: "#8c8f99" },
        BrandSage:         { facet: "surface", key: "surface-brand" }, // engine-class reuse
        AvailUnavailable:  { facet: "surface", key: "surface-card" }, // engine-class reuse
        BusyCell:          { facet: "surface", key: "busy-cell" }, // hand-written rule, no CSS
        BusySolid:         { facet: "surface", key: "busy-solid" }, // hand-written rule, no CSS
        AvailTextAvailable:{ facet: "text", key: "avail-text-available", value: "#3d5e4a" },
        AvailTextIfNeeded: { facet: "text", key: "avail-text-ifneeded",  value: "#5b5e69" },
        SageInk:           { facet: "text", key: "sage-ink",          value: "#2b4a3a" },
        StatusAmberInk:    { facet: "text", key: "status-amber-ink",  value: "#7a4f10" },
        StatusBlueInk:     { facet: "text", key: "status-blue-ink",   value: "#2f4a73" },
        StatusConfirmedFg: { facet: "text", key: "status-confirmed-fg", value: "#5a5b62" },
        ErrorInk:          { facet: "text", key: "error-text",        value: "#8b3d2a" },
        AvailTextPreferred:{ facet: "text", key: "avail-text-preferred", ref: "fg-on-brand" },
        AvailBorderLight:  { facet: "border", key: "avail-border-light", value: "#b8d3c2" },
        AvailBorderMuted:  { facet: "border", key: "avail-border-muted", value: "#c9c5b8" },
        SuccessBorder:     { facet: "border", key: "success-border", value: "#a8c4ad" },
        AvailBorderGreen:  { facet: "border", key: "avail-border-green", ref: "surface-brand" },
        BorderDefault:     { facet: "border", key: "border-default" },
        BorderTransparent: { facet: "border", key: "transparent" },
      },
    },
  },
};
