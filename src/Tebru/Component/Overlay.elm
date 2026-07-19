module Tebru.Component.Overlay exposing
    ( Overlay, Placement(..)
    , default, withPlacement, withEdgePadding
    , panelChrome, view
    )

{-| Shared overlay substrate — a fixed full-screen container, a click-to-close
backdrop sibling, and the entrance animations. The consumer's panel is passed as
`content` and rendered as the second sibling, with no extra wrapper, so consumers
keep their own single-box panel structure. The consumer applies `panelChrome` to
its own panel for the relative positioning, z-index, and entrance animation.

    Overlay.default { isOpen = True, onClose = Close, content = panel }
        |> Overlay.view

When closed, renders `Html.text ""`. When open, a flex container holds two
siblings: the backdrop (clicking fires `onClose`) and `content`.

Deliberately minimal: the container and backdrop expose no style channels —
as the substrate under Modal/Dropdown/Palette it stays easiest to reason
about with few knobs (placement and edge padding are the only ones). Style
slots get added when a real consumer needs one, not speculatively.


# Build & configure

@docs Overlay, Placement
@docs default, withPlacement, withEdgePadding


# Render

@docs panelChrome, view

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Theme.Config as Config exposing (Config)
import Tebru.Theme.Space as Space exposing (Space)
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface


{-| Where the panel sits in the container: vertically centered or pinned to the top.
-}
type Placement
    = Center
    | Top


{-| An overlay around a consumer-supplied panel.
-}
type Overlay msg
    = Overlay
        { isOpen : Bool
        , onClose : msg
        , content : Html msg
        , placement : Placement
        , edgePad : Space
        }


{-| Build an overlay from its required fields. Defaults reproduce Modal's behavior:
`Center` placement and `Space.Lg` edge padding.
-}
default : { isOpen : Bool, onClose : msg, content : Html msg } -> Overlay msg
default opts =
    Overlay
        { isOpen = opts.isOpen
        , onClose = opts.onClose
        , content = opts.content
        , placement = Center
        , edgePad = Space.Lg
        }


{-| Set the panel placement.
-}
withPlacement : Placement -> Overlay msg -> Overlay msg
withPlacement placement (Overlay m) =
    Overlay { m | placement = placement }


{-| Set the container edge padding.
-}
withEdgePadding : Space -> Overlay msg -> Overlay msg
withEdgePadding edgePad (Overlay m) =
    Overlay { m | edgePad = edgePad }


{-| The blessed panel positioning + animation modifier. Apply to the consumer's own
panel so it sits relative, above the backdrop, with the entrance animation.
-}
panelChrome : Config Config.Standard -> Config Config.Standard
panelChrome =
    Structure.withPosition Structure.Relative >> Structure.withZ Structure.ZModal >> modalEnter


{-| Panel entry animation. A keyframe utility with no token channel, so it stays raw
behind this named constant (bespoke).
-}
modalEnter : Config tag -> Config tag
modalEnter =
    Config.addRaw "animate-modal-enter"


{-| Backdrop fade-in entry animation. A keyframe utility with no token channel, so it
stays raw behind this named constant (bespoke).
-}
backdropFade : Config tag -> Config tag
backdropFade =
    Config.addRaw "animate-backdrop-fade"


{-| Render the overlay. When closed, returns `Html.text ""`.
-}
view : Overlay msg -> Html msg
view (Overlay m) =
    if not m.isOpen then
        Html.text ""

    else
        Layout.row Space.None [ backdropEl m.onClose, m.content ]
            |> Layout.withStyle
                (Structure.withPosition Structure.Fixed
                    >> Structure.withInset Structure.Inset0
                    >> Structure.withZ Structure.ZModal
                    >> Structure.withJustify Structure.JustifyCenter
                    >> Structure.withAlign (placementAlign m.placement)
                    >> Spacing.withPadding (Spacing.all m.edgePad)
                )
            |> Layout.view


{-| The flex-align utility for a placement: `Center` centers, `Top` pins to the start.
-}
placementAlign : Placement -> Structure.FlexAlign
placementAlign placement =
    case placement of
        Center ->
            Structure.AlignCenter

        Top ->
            Structure.AlignStart


{-| The click-to-close backdrop sibling: a fixed full-screen layer behind the panel.
-}
backdropEl : msg -> Html msg
backdropEl onClose =
    Layout.box []
        |> Layout.withOnClick onClose
        |> Layout.withStyle
            (Surface.withSurface Surface.Backdrop
                >> Structure.withPosition Structure.Fixed
                >> Structure.withInset Structure.Inset0
                >> Structure.withZ Structure.ZOverlay
                >> backdropFade
            )
        |> Layout.view
