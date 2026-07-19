module Tebru.Component.Dropdown exposing
    ( Dropdown, Item, default, view
    , withHeader, withItemStyle, withStyle
    , minWidthPanelSm, minWidthPanelLg
    )

{-| Headless dropdown-menu primitive — trigger + click-outside scrim + popup item list.

    Dropdown.default
        { isOpen = model.menuOpen
        , onToggle = ToggleMenu
        , trigger = triggerButton
        , items = [ { label = "Edit", icon = Nothing, onClick = Edit, style = identity } ]
        }
        |> Dropdown.view

Used for avatar menus, group action menus, and other dropdown interactions.
Supports icons, per-item styling, and click-outside-to-close.

No variant enums — styling composes through Config modifiers. Each `Item`
carries its own `style` slot (e.g. a destructive item passes
`Text.withText Text.Error`), and `withItemStyle` layers a modifier onto every
item. Per-item `style` is applied after `withItemStyle`, so it wins where the
two touch the same channel. `withStyle` composes onto the popup chrome the
same way (surface, radius, placement, min-width floor, …).

Built on the design-system libraries (`Box` + `Theme.*`). Positioning, layering,
sizing, elevation and transition all go through typed `Theme.*` tokens
(`Structure.withPosition`/`withZ`/`withInset`, `Elevation.withElevation`,
`Transition.with*`). The only remaining raw classes are genuinely token-less —
the popup edge offsets (`popupPosition`), the arbitrary-px min-width floors
(`minWidthPanelSm`/`minWidthPanelLg`) and the keyframe animation
(`dropdownEnterAnimation`) — each kept behind a named constant.


# Build & render

@docs Dropdown, Item, default, view


# Optional chrome & styling

@docs withHeader, withItemStyle, withStyle


# Popup min-width presets

@docs minWidthPanelSm, minWidthPanelLg

-}

import Html exposing (Html, text)
import Tebru.Box as Layout
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space as Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Transition as Transition
import Tebru.Theme.Typography as Typography


{-| A single dropdown item. `style` composes on top of the default item style
(and any `withItemStyle` modifier) — pass `identity` for the default look, or
e.g. `Text.withText Text.Error` for a destructive action.
-}
type alias Item msg =
    { label : String
    , icon : Maybe (Html msg)
    , onClick : msg
    , style : Config Standard -> Config Standard
    }


{-| Opaque dropdown configuration. Build with `default`, refine with the
`withX` modifiers, render with `view`.
-}
type Dropdown msg
    = Dropdown
        { isOpen : Bool
        , onToggle : msg
        , trigger : Html msg
        , items : List (Item msg)
        , header : Maybe (Html msg)
        , itemStyle : Config Standard -> Config Standard
        , style : Config Standard -> Config Standard
        }


{-| Default dropdown: right-aligned popup below the trigger, `minWidthPanelSm`
(160px) floor, no header. Refine with `withHeader` / `withItemStyle` / `withStyle`.
-}
default :
    { isOpen : Bool
    , onToggle : msg
    , trigger : Html msg
    , items : List (Item msg)
    }
    -> Dropdown msg
default { isOpen, onToggle, trigger, items } =
    Dropdown
        { isOpen = isOpen
        , onToggle = onToggle
        , trigger = trigger
        , items = items
        , header = Nothing
        , itemStyle = identity
        , style = identity
        }


{-| Add a header block above the items (e.g. name + email at the top of an
account menu), separated from them by a divider.
-}
withHeader : Html msg -> Dropdown msg -> Dropdown msg
withHeader header (Dropdown d) =
    Dropdown { d | header = Just header }


{-| Layer a style modifier onto every item. Composes on top of the default item
style; each item's own `style` slot is applied after it.
-}
withItemStyle : (Config Standard -> Config Standard) -> Dropdown msg -> Dropdown msg
withItemStyle fn (Dropdown d) =
    Dropdown { d | itemStyle = d.itemStyle >> fn }


{-| Layer a style modifier onto the popup chrome (surface, radius, border,
padding, elevation, placement, min-width floor, …). Composes on top of the
default popup style, so later calls win where they touch the same channel —
e.g. `withStyle minWidthPanelLg` replaces the default 160px floor.
-}
withStyle : (Config Standard -> Config Standard) -> Dropdown msg -> Dropdown msg
withStyle fn (Dropdown d) =
    Dropdown { d | style = d.style >> fn }


{-| Render the dropdown.
-}
view : Dropdown msg -> Html msg
view (Dropdown d) =
    Layout.box
        [ Layout.box [ d.trigger ]
            |> Layout.withOnClick d.onToggle
            |> Layout.withStyle (Structure.withCursor Structure.CursorPointer)
            |> Layout.view
        , if d.isOpen then
            Layout.box []
                |> Layout.withStyle (Structure.withPosition Structure.Fixed >> Structure.withInset Structure.Inset0 >> Structure.withZ Structure.ZOverlay)
                |> Layout.withElement Layout.Div
                |> Layout.withOnClick d.onToggle
                |> Layout.view

          else
            text ""
        , if d.isOpen then
            Layout.stack None
                (case d.header of
                    Just header ->
                        [ headerBlock header, itemsList d.itemStyle d.items ]

                    Nothing ->
                        [ itemsList d.itemStyle d.items ]
                )
                |> Layout.withStyle (popupStyle >> d.style)
                |> Layout.view

          else
            text ""
        ]
        |> Layout.withStyle (Structure.withPosition Structure.Relative)
        |> Layout.view


{-| Token-less popup positioning — below the trigger, right-aligned
(`top-full mt-1 right-0`).
-}
popupPosition : Config Standard -> Config Standard
popupPosition =
    Config.addRaw "top-full mt-1 right-0"


{-| The pop-in animation for the open popup. No token channel exists for
keyframe animation utilities, so it stays a raw class behind this constant.
-}
dropdownEnterAnimation : Config Standard -> Config Standard
dropdownEnterAnimation =
    Config.addRaw "animate-dropdown-enter"


{-| Popup minimum-width floor preset: the default 160px. Token-less arbitrary
px (`Theme.Structure.Size` tops out well below panel widths), so it lives here
as a named preset for `withStyle`. Keyed, so applying either preset REPLACES
the current floor instead of stacking a second `min-w-*` class.
-}
minWidthPanelSm : Config Standard -> Config Standard
minWidthPanelSm =
    Config.set "min-width" "min-w-[160px]"


{-| Popup minimum-width floor preset: 280px, for richer items (chips + names).

    Dropdown.default { ... }
        |> Dropdown.withStyle Dropdown.minWidthPanelLg
        |> Dropdown.view

-}
minWidthPanelLg : Config Standard -> Config Standard
minWidthPanelLg =
    Config.set "min-width" "min-w-[280px]"


popupStyle : Config Standard -> Config Standard
popupStyle =
    Surface.withSurface Surface.Card
        >> Radius.withRadius Radius.Lg
        >> Border.withBorder Border.Default
        >> Spacing.withPadding (Spacing.all Xs)
        >> Structure.withBorderWidth Structure.BorderThin
        >> Structure.withPosition Structure.Absolute
        >> Structure.withZ Structure.ZModal
        >> popupPosition
        >> minWidthPanelSm
        >> Elevation.withElevation Elevation.Xl
        >> dropdownEnterAnimation


headerBlock : Html msg -> Html msg
headerBlock header =
    Layout.box [ header ]
        |> Layout.withStyle
            (Spacing.withPadding (Spacing.xy Md Sm)
                >> Border.withBorder Border.Divider
                >> Structure.withBorderSide Space.Bottom
            )
        |> Layout.view


itemsList : (Config Standard -> Config Standard) -> List (Item msg) -> Html msg
itemsList itemStyle items =
    Layout.stack None (List.map (viewItem itemStyle) items)
        |> Layout.withElement Layout.Ul
        |> Layout.view


viewItem : (Config Standard -> Config Standard) -> Item msg -> Html msg
viewItem allItemsStyle item =
    Layout.box [ itemContent item ]
        |> Layout.withElement Layout.Li
        |> Layout.withOnClick item.onClick
        |> Layout.withStyle
            (Text.withText Text.Default
                >> Typography.withFontSize Typography.Sm
                >> Typography.withFontWeight Typography.Normal
                >> Radius.withRadius Radius.None
                >> Spacing.withPadding (Spacing.xy Lg Sm)
                >> Structure.withCursor Structure.CursorPointer
                >> Structure.withWidth Structure.SizeFull
                >> Transition.withTransition Transition.TransitionColors
                >> Transition.withDuration Transition.DurationNormal
                >> allItemsStyle
                >> item.style
            )
        |> Layout.withHoverStyle (Surface.withSurface Surface.CardAlt)
        |> Layout.view


{-| Item inner content: icon + truncating label row when an icon is present,
plain label otherwise. Mirrors the old Ghost-button `iconLabelRow` /
truncating label behaviour.
-}
itemContent : Item msg -> Html msg
itemContent item =
    case item.icon of
        Just iconEl ->
            Layout.row Sm [ iconEl, truncatingLabel item.label ]
                |> Layout.withStyle (Structure.withAlign Structure.AlignCenter >> Structure.withWidth Structure.SizeFull >> Structure.withMinWidth Structure.SizeZero)
                |> Layout.view

        Nothing ->
            text item.label


truncatingLabel : String -> Html msg
truncatingLabel label =
    Layout.box [ text label ]
        |> Layout.withElement Layout.Span
        |> Layout.withStyle (Typography.withTextOverflow Typography.Truncate >> Structure.withMinWidth Structure.SizeZero >> Structure.withGrow True >> Typography.withTextAlign Typography.TextLeft)
        |> Layout.view
