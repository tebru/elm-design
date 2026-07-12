module ReviewConfig exposing (config)

{-| elm-review configuration for `tebru/elm-design` — the design system
(token engine + Box + components + icons) in ONE package. Do not rename the
ReviewConfig module or the `config` function; `elm-review` looks for them.


# What runs here, and why so little

The app-side `No*Outside` **location** rules (NoAddRawOutside,
NoInlineStyleOutside, NoClassOutside, NoHtmlElementOutside,
NoStyleEscapeHatchOutside, NoConfigDefaultOutside) do NOT run in this package:
they exist to keep escape hatches out of a consuming app's composition layer,
and this package IS the sanctioned implementation layer they point at —
components legitimately render raw HTML, set `class` in their view renderers,
carry bespoke `addRaw` constants, implement the inline-style channel, and
define `withXCustom`. Running them "fully armed" (as an earlier one-time audit
did) makes lint permanently red with by-design findings, which is useless as a
gate. The audit's conclusion (no accidental hatch leakage) is locked in by
what DOES run:

  - **NoComposedAddRaw** — the content rule, still load-bearing after the
    Tailwind removal: the bespoke inventory extraction is string-literal-based,
    so a class token spliced across a `++` seam would silently evade the
    emitted CSS. (The inventory's near-miss detector catches unknown-shaped
    literals; this rule catches splices that happen to FORM valid classes.)
  - **NoDebug + NoUnused hygiene** — dead code, stray Debug calls.

`tests/` is excluded globally (fixtures intentionally exercise the hatches).
Generated modules are ignored for the in-body unused rules (they are never
hand-edited; the generator is their formatter and linter of record).

-}

import NoComposedAddRaw
import NoDebug.Log
import NoDebug.TodoOrToString
import NoUnused.Dependencies
import NoUnused.Parameters
import NoUnused.Patterns
import NoUnused.Variables
import Review.Rule as Rule exposing (Rule)


generatedModules : List String
generatedModules =
    [ "src/Tebru/Theme/Border.elm"
    , "src/Tebru/Theme/Elevation.elm"
    , "src/Tebru/Theme/MaxWidth.elm"
    , "src/Tebru/Theme/Radius.elm"
    , "src/Tebru/Theme/Space.elm"
    , "src/Tebru/Theme/Structure.elm"
    , "src/Tebru/Theme/Surface.elm"
    , "src/Tebru/Theme/Text.elm"
    , "src/Tebru/Theme/Transition.elm"
    , "src/Tebru/Theme/Typography.elm"
    , "src/Tebru/Box/GridCols.elm"
    , "src/Tebru/Icon/Geometry.elm"
    ]


config : List Rule
config =
    [ -- Content rule — applies everywhere, including generated modules
      -- (a generator emitting a spliced class would be a real bug).
      NoComposedAddRaw.rule

    -- Generic hygiene.
    , NoDebug.Log.rule
    , NoDebug.TodoOrToString.rule
    , NoUnused.Dependencies.rule
    , NoUnused.Parameters.rule
        |> Rule.ignoreErrorsForFiles generatedModules
    , NoUnused.Patterns.rule
        |> Rule.ignoreErrorsForFiles generatedModules
    , NoUnused.Variables.rule
        |> Rule.ignoreErrorsForFiles generatedModules
    ]
        -- tests/ excluded globally.
        |> List.map (Rule.ignoreErrorsForDirectories [ "tests/" ])
