module Tebru.Theme.Config exposing
    ( Config
    , Hover
    , Standard
    , Styling
    , addRaw
    , default
    , defaultHover
    , hoverToClasses
    , set
    , setStyle
    , toAttributes
    , toClasses
    , toStyleAttributes
    , withBackgroundHex
    , withBorderHex
    , withInlineStyle
    , withTextHex
    )

import Dict exposing (Dict)
import Html
import Html.Attributes


{-| Phantom-tagged style config. `tag` is `Standard` or `Hover` so the compiler
keeps base and hover styling apart.

THE HOVER BOUNDARY IS TYPE-CLOSED (and Elm has no should-not-compile tests, so
this doc is the boundary's specification): only setters of `hoverable: true`
groups — colors (`withSurface`/`withText`/`withBorder` and the app facet
wrappers), elevation (`withElevation`), text decoration (`withDecoration`),
and border structure (`withBorderWidth`/`withBorderStyle`/`withBorderSide`) —
are tag-polymorphic (`Config tag -> Config tag`) and therefore usable inside
`withHoverStyle`. Every other generated setter (radius, spacing, sizing,
typography, opacity, …) is pinned to `Config Standard -> Config Standard`, so
out-of-policy hover styling is a compile error rather than a silent no-op.
The flags live in `tokens.js` / `codegen/structure-def.js`; the SAME flags
drive the `hover:` CSS enumeration (`codegen/generate-inventory.js`), so the
type boundary and the emitted hover CSS cannot drift apart. `set`/`addRaw`
(bespoke) deliberately stay tag-polymorphic — a raw class on a Hover config is
only styled if the inventory hover-enumerates it (arbitrary shadows today).

`keyed` stores one class-string per property group — inserting a key REPLACES
the previous value (last-wins). This prevents the duplicate-class bug where
`withSurface Card >> withSurface Brand` would emit both `bg-surface-card` and
`bg-surface-brand` and let Tailwind source-order decide.

`extras` is an append-only list of raw component-local class fragments
(positioning, sizing, etc.) that aren't a single overridable property.

`styles` holds inline CSS as `property -> value`, last-wins per property. This
is the generic channel for **runtime-computed values** Tailwind cannot generate
as utilities — arbitrary hex colors (`withBackgroundHex`), dynamic geometry, etc.
It renders as an inline `style` attribute, so it works for any value without a
safelist. Use it only when a token or static utility cannot express the value.
The inline-style channel is **Standard-only**: hover rendering goes through
`hoverToClasses`, which reads classes exclusively — a Hover config's styles
Dict is never rendered. All five inline setters (`setStyle`, `withInlineStyle`,
`withBackgroundHex`, `withTextHex`, `withBorderHex`) are therefore pinned to
`Config Standard -> Config Standard`, so inline styling a hover config is a
compile error rather than a silent no-op.

-}
type Config tag
    = Config
        { keyed : Dict String String
        , extras : List String
        , styles : Dict String String
        }


type Standard
    = Standard


type Hover
    = Hover


{-| Convenience alias for a style modifier function — the currency passed to `withStyle`.
-}
type alias Styling =
    Config Standard -> Config Standard


{-| Empty base config — no classes.
-}
default : Config Standard
default =
    Config { keyed = Dict.empty, extras = [], styles = Dict.empty }


{-| Empty hover config — no classes.
-}
defaultHover : Config Hover
defaultHover =
    Config { keyed = Dict.empty, extras = [], styles = Dict.empty }


{-| Insert (or replace) a property-group class under the given key.
Last call wins — later `withX` calls override earlier ones for the same
property. The value may be a multi-token string (e.g. `"p-sm pt-lg"`).
-}
set : String -> String -> Config tag -> Config tag
set key cls (Config c) =
    Config { c | keyed = Dict.insert key cls c.keyed }


{-| Append a raw class fragment that is not a single overridable property
(e.g. positioning: `"absolute inset-0 z-50"`, sizing: `"w-full"`, `"grow"`).
These are not deduplicated — they accumulate.
-}
addRaw : String -> Config tag -> Config tag
addRaw cls (Config c) =
    Config { c | extras = c.extras ++ [ cls ] }


{-| Set (or replace) an inline CSS declaration, keyed by property — last-wins,
so a later `setStyle "background-color"` overrides an earlier one. Renders as an
inline `style` attribute. Reach for this only for runtime-computed values that
no token or static utility can express (arbitrary hex colors, dynamic px).
Standard-only: hover renders via classes (`hoverToClasses`), never inline styles.
-}
setStyle : String -> String -> Config Standard -> Config Standard
setStyle prop value (Config c) =
    Config { c | styles = Dict.insert prop value c.styles }


{-| Apply several inline CSS declarations at once. Standard-only, like `setStyle`.
-}
withInlineStyle : List ( String, String ) -> Config Standard -> Config Standard
withInlineStyle pairs config =
    List.foldl (\( prop, value ) acc -> setStyle prop value acc) config pairs


{-| Set the background color to an arbitrary hex value, inline. The generic
escape for per-instance colors (e.g. per-name identity colors) that aren't part
of the semantic surface vocabulary. Standard-only, like `setStyle`.
-}
withBackgroundHex : String -> Config Standard -> Config Standard
withBackgroundHex hex =
    setStyle "background-color" hex


{-| Set the text color to an arbitrary hex value, inline. Standard-only, like `setStyle`.
-}
withTextHex : String -> Config Standard -> Config Standard
withTextHex hex =
    setStyle "color" hex


{-| Set the border color to an arbitrary hex value, inline. Standard-only, like `setStyle`.
-}
withBorderHex : String -> Config Standard -> Config Standard
withBorderHex hex =
    setStyle "border-color" hex


{-| The inline `style` attributes for this config (one per declaration).
-}
toStyleAttributes : Config tag -> List (Html.Attribute msg)
toStyleAttributes (Config c) =
    Dict.toList c.styles |> List.map (\( prop, value ) -> Html.Attributes.style prop value)


{-| Collect all individual class tokens from the config.
Keyed values and extras are all split on spaces and filtered for empties.
-}
classTokens : Config tag -> List String
classTokens (Config c) =
    let
        keyedClasses =
            Dict.values c.keyed
                |> List.concatMap (String.split " ")

        extraClasses =
            c.extras
                |> List.concatMap (String.split " ")
    in
    (keyedClasses ++ extraClasses)
        |> List.filter (\s -> s /= "")


toClasses : Config Standard -> String
toClasses config =
    classTokens config |> String.join " "


{-| The `hover:`-prefixed class string for a hover config. This is the ONLY
render path for hover styling — it reads classes exclusively, so a hover
config carries no inline styles (the inline-style setters are pinned to
`Config Standard`, making the styles Dict unreachable on a Hover config).
-}
hoverToClasses : Config Hover -> String
hoverToClasses config =
    classTokens config |> List.map (\s -> "hover:" ++ s) |> String.join " "


toAttributes : Config Standard -> Maybe (Config Hover) -> List (Html.Attribute msg)
toAttributes config maybeHover =
    let
        hover =
            maybeHover |> Maybe.map hoverToClasses |> Maybe.withDefault ""
    in
    Html.Attributes.class
        (String.join " " (List.filter (\s -> s /= "") [ toClasses config, hover ]))
        :: toStyleAttributes config
