module Tebru.Component.Tooltip exposing (Position(..), Tooltip, default, view, withPosition, withStyle)

{-| Headless Tooltip primitive — target + positioned label bubble.

    Tooltip.default { label = "Save document", target = saveIcon }
        |> Tooltip.withPosition Below
        |> Tooltip.view

Hover-gated by default: the bubble is hidden (`opacity-0`) until the wrapper is
hovered (`group-hover:opacity-100`), fading in via `transition-opacity` — the
wrapper carries the `group` class, so consumers don't add their own show/hide.
`withStyle` overrides the bubble's Config.

No variant enums — position is a simple type; surface, radius etc. are overridable
via `withStyle`.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


{-| Where the tooltip bubble appears relative to the target.
-}
type Position
    = Above
    | Below
    | Left
    | Right


type Tooltip msg
    = Tooltip
        { position : Position
        , label : String
        , target : Html msg
        , bubbleStyle : Config Standard
        }


{-| Build a Tooltip, positioned `Above` the target; `withPosition` moves it,
`withStyle` overrides the bubble.
-}
default : { label : String, target : Html msg } -> Tooltip msg
default opts =
    Tooltip
        { position = Above
        , label = opts.label
        , target = opts.target
        , bubbleStyle = baseBubbleStyle
        }


{-| Where the bubble appears relative to the target (default `Above`).
-}
withPosition : Position -> Tooltip msg -> Tooltip msg
withPosition position (Tooltip t) =
    Tooltip { t | position = position }


{-| Override the bubble's Config.
-}
withStyle : (Config Standard -> Config Standard) -> Tooltip msg -> Tooltip msg
withStyle fn (Tooltip t) =
    Tooltip { t | bubbleStyle = fn t.bubbleStyle }


{-| Render the tooltip wrapper. Hover-gated: the bubble fades in on
`group-hover` and is `pointer-events-none` so it never steals hover.
-}
view : Tooltip msg -> Html msg
view (Tooltip t) =
    Html.div
        [ Html.Attributes.class "relative inline-block group" ]
        [ t.target
        , Html.div
            (Html.Attributes.class (positionClasses t.position)
                :: Html.Attributes.class (Config.toClasses t.bubbleStyle)
                :: Config.toStyleAttributes t.bubbleStyle
                ++ [ Html.Attributes.class "absolute z-30 w-max max-w-[260px] pointer-events-none"
                   , Html.Attributes.class "opacity-0 group-hover:opacity-100 transition-opacity"
                   , Html.Attributes.attribute "role" "tooltip"
                   ]
            )
            [ Html.text t.label
            , arrow t.position t.bubbleStyle
            ]
        ]


{-| A small rotated square on the bubble edge facing the target. Inherits the
bubble's surface class so its color always tracks the bubble background.
-}
arrow : Position -> Config Standard -> Html msg
arrow position bubbleStyle =
    Html.div
        (Html.Attributes.class (arrowSurfaceClass bubbleStyle)
            :: Config.toStyleAttributes bubbleStyle
            ++ [ Html.Attributes.class "absolute w-2 h-2 rotate-45"
               , Html.Attributes.class (arrowPositionClasses position)
               , Html.Attributes.attribute "aria-hidden" "true"
               ]
        )
        []


{-| Pull just the resolved surface (bg) class out of the bubble's Config so the
arrow paints with the same background color as the bubble.
-}
arrowSurfaceClass : Config Standard -> String
arrowSurfaceClass bubbleStyle =
    Config.toClasses bubbleStyle
        |> String.words
        |> List.filter (String.startsWith "bg-")
        |> String.join " "


{-| Place the rotated square centered on the bubble edge nearest the target.
The square is shifted half its width past the edge so its outer corner points
at the target.
-}
arrowPositionClasses : Position -> String
arrowPositionClasses position =
    case position of
        Above ->
            "bottom-0 left-1/2 -translate-x-1/2 translate-y-1/2"

        Below ->
            "top-0 left-1/2 -translate-x-1/2 -translate-y-1/2"

        Left ->
            "right-0 top-1/2 -translate-y-1/2 translate-x-1/2"

        Right ->
            "left-0 top-1/2 -translate-y-1/2 -translate-x-1/2"


positionClasses : Position -> String
positionClasses position =
    case position of
        Above ->
            "bottom-[calc(100%+14px)] left-1/2 -translate-x-1/2"

        Below ->
            "top-[calc(100%+14px)] left-1/2 -translate-x-1/2"

        Left ->
            "right-[calc(100%+14px)] top-1/2 -translate-y-1/2"

        Right ->
            "left-[calc(100%+14px)] top-1/2 -translate-y-1/2"


baseBubbleStyle : Config Standard
baseBubbleStyle =
    Config.default
        |> Surface.withSurface Surface.Inverse
        |> Text.withText Text.Inverse
        |> Typography.withFontSize Typography.Xs
        |> Typography.withFontWeight Typography.Medium
        |> Radius.withRadius Radius.Md
        |> Elevation.withElevation Elevation.Md
        |> Spacing.withPadding (Spacing.xy Sm Xs)
