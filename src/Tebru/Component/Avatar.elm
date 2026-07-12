module Tebru.Component.Avatar exposing (Avatar, default, view, withStyle)

{-| Headless Avatar primitive — a round identity chip.

Renders an `<img>` when an image is present; otherwise renders the name's
initials in a centered, rounded container.

    Avatar.default { name = "Ada Lovelace", image = Just "https://…" }
        |> Avatar.view

    Avatar.default { name = "Ada Lovelace", image = Nothing }
        |> Avatar.view

The baked default reproduces the shape/markup of the old `Ui.Avatar`: a
`rounded-full`, `inline-flex`, center-aligned, `shrink-0` chip with a medium
font weight. Color, fixed pixel size, font size, and the depth gradient /
inner-glow overlay are per-instance concerns the caller layers on with
`withStyle` (the app's `Style.Kit.avatar` does exactly this — per-name hex via
`Config.withBackgroundHex`, inverse text, the glow + gradient, and the size
box). A neutral `Subtle` surface remains as the fallback when no surface
override is applied.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type Avatar msg
    = Avatar
        { name : String
        , image : Maybe String
        , style : Config Standard
        }


default : { name : String, image : Maybe String } -> Avatar msg
default opts =
    Avatar { name = opts.name, image = opts.image, style = baseStyle }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Surface.withSurface Surface.Subtle
        |> Text.withText Text.Secondary
        |> Typography.withFontWeight Typography.Medium
        |> Radius.withRadius Radius.Full
        |> inlineFlex
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withJustify Structure.JustifyCenter
        |> shrink0


{-| Inline flex container — the old `Config.withShrink False` + `DisplayInlineFlex`
combo. `inline-flex` has no `Theme.Structure.Display` constructor (only `Block` /
`Flex`), so it goes through the keyed `display` slot directly, keeping it
overridable rather than accumulating as a raw extra.
-}
inlineFlex : Config Standard -> Config Standard
inlineFlex =
    Config.set "display" "inline-flex"


{-| Never let the chip be squeezed by a flex parent — matches the old
`Config.withShrink False`.
-}
shrink0 : Config Standard -> Config Standard
shrink0 =
    Structure.withShrink False


withStyle : (Config Standard -> Config Standard) -> Avatar msg -> Avatar msg
withStyle fn (Avatar a) =
    Avatar { a | style = fn a.style }


{-| Initials for the chip glyph, uppercased.

Mirrors the app's `Name.initial`: a single-word name yields one letter (its
first character); a multi-word name yields two (first character of the first
word + first character of the last word). Middle words are ignored.

Crucially, an already-computed short initials string (one "word" of one or two
characters, e.g. `"A"` or `"AK"`) is passed through verbatim — so a caller that
hands us a pre-derived initial (as `Style.Kit.avatar` does) renders exactly
that, single letter included, rather than having it re-truncated.

-}
initials : String -> String
initials name =
    case name |> String.trim |> String.words of
        [] ->
            ""

        [ single ] ->
            if String.length single <= 2 then
                String.toUpper single

            else
                String.left 1 single |> String.toUpper

        first :: rest ->
            let
                last =
                    rest |> List.reverse |> List.head |> Maybe.withDefault ""
            in
            String.toUpper (String.left 1 first ++ String.left 1 last)


view : Avatar msg -> Html msg
view (Avatar a) =
    let
        cls =
            Config.toClasses a.style

        styleAttrs =
            Config.toStyleAttributes a.style
    in
    case a.image of
        Just src ->
            Html.img
                (Html.Attributes.src src
                    :: Html.Attributes.alt a.name
                    :: Html.Attributes.class cls
                    :: styleAttrs
                )
                []

        Nothing ->
            Html.span
                (Html.Attributes.class cls :: styleAttrs)
                [ Html.text (initials a.name) ]
