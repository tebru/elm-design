module Tebru.Icon exposing (IconConfig, default, view, withStyle)

{-| Theme-styled Lucide icon wrapper.

    import Tebru.Icon as Icon
    import Tebru.Icon.Geometry as Geometry
    import Tebru.Theme.Text as Text

    Icon.default Geometry.plus
        |> Icon.withStyle (Text.withText Text.Muted)
        |> Icon.view

The geometry values live in `Icon.Geometry` — one top-level value per icon
(e.g. `Geometry.calendar`, `Geometry.plus`). Referencing only the
icons you use means Elm's DCE ships only those paths in your build.

-}

import Html exposing (Html)
import Html.Attributes as HA
import Svg
import Svg.Attributes as SA
import Tebru.Theme.Config as Config exposing (Config, Standard)


type IconConfig msg
    = IconConfig { shapes : List (Svg.Svg msg), style : Config Standard }


default : List (Svg.Svg msg) -> IconConfig msg
default shapes =
    IconConfig { shapes = shapes, style = Config.default }


withStyle : (Config Standard -> Config Standard) -> IconConfig msg -> IconConfig msg
withStyle fn (IconConfig c) =
    IconConfig { c | style = fn c.style }


view : IconConfig msg -> Html msg
view (IconConfig c) =
    Html.span
        (HA.class (String.join " " (List.filter ((/=) "") [ "lucide-icon", Config.toClasses c.style ]))
            :: Config.toStyleAttributes c.style
        )
        [ Svg.svg
            [ SA.viewBox "0 0 24 24"
            , SA.fill "none"
            , SA.stroke "currentColor"
            , SA.strokeWidth "2.5"
            , SA.strokeLinecap "round"
            , SA.strokeLinejoin "round"
            , SA.width "1em"
            , SA.height "1em"
            ]
            c.shapes
        ]
