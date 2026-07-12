module Tebru.Theme.Spacing exposing (Spacing, all, bottom, left, render, right, top, withGap, withGapX, withGapY, withPadding, withPaddingX, withPaddingY, xy)

import Tebru.Theme.Config as Config
import Tebru.Theme.Space as Space exposing (Edge(..), Space)


type Spacing
    = Spacing
        { base : Maybe Space
        , x : Maybe Space
        , y : Maybe Space
        , top : Maybe Space
        , right : Maybe Space
        , bottom : Maybe Space
        , left : Maybe Space
        }


empty : Spacing
empty =
    Spacing { base = Nothing, x = Nothing, y = Nothing, top = Nothing, right = Nothing, bottom = Nothing, left = Nothing }


all : Space -> Spacing
all s =
    let
        (Spacing g) =
            empty
    in
    Spacing { g | base = Just s }


xy : Space -> Space -> Spacing
xy h v =
    let
        (Spacing g) =
            empty
    in
    Spacing { g | x = Just h, y = Just v }


top : Space -> Spacing -> Spacing
top s (Spacing g) =
    Spacing { g | top = Just s }


right : Space -> Spacing -> Spacing
right s (Spacing g) =
    Spacing { g | right = Just s }


bottom : Space -> Spacing -> Spacing
bottom s (Spacing g) =
    Spacing { g | bottom = Just s }


left : Space -> Spacing -> Spacing
left s (Spacing g) =
    Spacing { g | left = Just s }


render : Spacing -> String
render (Spacing g) =
    [ Maybe.map (Space.spaceClass All) g.base
    , Maybe.map (Space.spaceClass Px) g.x
    , Maybe.map (Space.spaceClass Py) g.y
    , Maybe.map (Space.spaceClass Top) g.top
    , Maybe.map (Space.spaceClass Right) g.right
    , Maybe.map (Space.spaceClass Bottom) g.bottom
    , Maybe.map (Space.spaceClass Left) g.left
    ]
        |> List.filterMap identity
        |> String.join " "


{-| Padding decomposes into ONE keyed-dict entry per geometry slot ("padding",
"padding-x", "padding-y", "padding-top", …) — the same slots `withPaddingX`/
`withPaddingY` write — and clears the slots this geometry doesn't set. This
keeps last-call-wins intact when the setters are mixed: after
`withPadding (xy Md Sm) >> withPaddingX Lg` exactly `px-lg py-sm` emit. If all
setters shared one slot they'd wipe each other entirely; if they used disjoint
slots (the old behavior) both `px-md` and `px-lg` would emit and CSS source
order — not pipeline order — would pick the winner. Where slots legitimately
coexist (`p-md` + `px-lg`), the emitted CSS orders shorthand < axis < edge, so
the more specific class wins, matching CSS's own longhand-over-shorthand feel.
-}
withPadding : Spacing -> Config.Config Config.Standard -> Config.Config Config.Standard
withPadding (Spacing g) config =
    let
        slot edge key maybeSpace =
            Config.set key (maybeSpace |> Maybe.map (Space.spaceClass edge) |> Maybe.withDefault "")
    in
    config
        |> slot All "padding" g.base
        |> slot Px "padding-x" g.x
        |> slot Py "padding-y" g.y
        |> slot Top "padding-top" g.top
        |> slot Right "padding-right" g.right
        |> slot Bottom "padding-bottom" g.bottom
        |> slot Left "padding-left" g.left


withPaddingX : Space -> Config.Config Config.Standard -> Config.Config Config.Standard
withPaddingX s =
    Config.set "padding-x" (Space.spaceClass Px s)


withPaddingY : Space -> Config.Config Config.Standard -> Config.Config Config.Standard
withPaddingY s =
    Config.set "padding-y" (Space.spaceClass Py s)


{-| Flex/grid gap, on the same `Space` scale as padding. For standalone elements;
`Box.row`/`stack`/`grid` already take a `Space` gap directly.

Clears the "gap-x"/"gap-y" slots so `withGapX Lg >> withGap Sm` honors the
later call (see `withPadding` for the slot model). The converse
`withGap Sm >> withGapX Lg` keeps both — `gap-x-lg` refines the shorthand and
wins in the emitted CSS (shorthand < axis order).

-}
withGap : Space -> Config.Config Config.Standard -> Config.Config Config.Standard
withGap s config =
    config
        |> Config.set "gap" (Space.spaceClass Gap s)
        |> Config.set "gap-x" ""
        |> Config.set "gap-y" ""


withGapX : Space -> Config.Config Config.Standard -> Config.Config Config.Standard
withGapX s =
    Config.set "gap-x" (Space.spaceClass GapX s)


withGapY : Space -> Config.Config Config.Standard -> Config.Config Config.Standard
withGapY s =
    Config.set "gap-y" (Space.spaceClass GapY s)
