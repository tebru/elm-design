module Tebru.Component.OptionCard exposing (OptionCard, default, view, withStyle)

{-| Headless OptionCard primitive — a clickable card that reflects a selected state.

    OptionCard.default
        { selected = model.choice == A
        , onSelect = SelectA
        , content = Html.text "Option A"
        }
        |> OptionCard.view

When `selected`, the card uses `Surface.Selected` + `Border.Focus`.
Clicking fires `onSelect`. Override the base card style via `withStyle`.

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface


type OptionCard msg
    = OptionCard
        { selected : Bool
        , onSelect : msg
        , content : Html msg
        , style : Config Standard
        }


{-| Default option card: card surface, border, radius, and padding.
When selected, overlays `Surface.Selected` + `Border.Focus`.
-}
default : { selected : Bool, onSelect : msg, content : Html msg } -> OptionCard msg
default opts =
    OptionCard { selected = opts.selected, onSelect = opts.onSelect, content = opts.content, style = baseStyle }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Surface.withSurface Surface.Card
        |> Border.withBorder Border.Default
        |> Radius.withRadius Radius.Md
        |> Spacing.withPadding (Spacing.xy Md Sm)
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Config.set "gap" "gap-md"


selectedStyle : Config Standard -> Config Standard
selectedStyle =
    Surface.withSurface Surface.Selected >> Border.withBorder Border.Focus


{-| Hover affordance for the unselected card: the border darkens to `Border.Hover`
and a faint surface wash appears. Applied only when not selected so it never fights
the selected `Border.Focus` / `Surface.Selected` styling.
-}
hoverStyle : Config.Config Config.Hover -> Config.Config Config.Hover
hoverStyle =
    Border.withBorder Border.Hover >> Surface.withSurface Surface.Subtle


withStyle : (Config Standard -> Config Standard) -> OptionCard msg -> OptionCard msg
withStyle fn (OptionCard c) =
    OptionCard { c | style = fn c.style }


view : OptionCard msg -> Html msg
view (OptionCard c) =
    let
        appliedStyle =
            if c.selected then
                selectedStyle c.style

            else
                c.style
    in
    Layout.box [ c.content ]
        |> Layout.withStyle (always appliedStyle)
        |> Layout.withOnClick c.onSelect
        |> Layout.withStyle (Structure.withCursor Structure.CursorPointer)
        |> applyIf (not c.selected) (Layout.withHoverStyle hoverStyle)
        |> Layout.view


applyIf : Bool -> (a -> a) -> a -> a
applyIf cond fn value =
    if cond then
        fn value

    else
        value
