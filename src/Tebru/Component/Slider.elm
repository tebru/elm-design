module Tebru.Component.Slider exposing (Slider, default, onChange, view, withStyle)

{-| Headless range-slider primitive — a native `<input type="range">`.

    Slider.default { min = 1, max = 6, step = 1, value = 3 }
        |> Slider.onChange GotValue
        |> Slider.view

Bakes a full-width, pointer-cursor default style; override via `withStyle`. The
bound value is clamped to `[min, max]` on render. `onChange` decodes the input's
value to an `Int` and calls the handler.

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Structure as Structure


type Slider msg
    = Slider
        { min : Int
        , max : Int
        , step : Int
        , value : Int
        , onChange : Maybe (Int -> msg)
        , style : Config Standard
        }


{-| Slider with full-width, pointer-cursor default styling.
-}
default : { min : Int, max : Int, step : Int, value : Int } -> Slider msg
default cfg =
    Slider
        { min = cfg.min
        , max = cfg.max
        , step = cfg.step
        , value = cfg.value
        , onChange = Nothing
        , style = baseStyle
        }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Structure.withWidth Structure.SizeFull
        |> Structure.withCursor Structure.CursorPointer


{-| Handle value changes. The decoded `Int` is the slider's new value.
-}
onChange : (Int -> msg) -> Slider msg -> Slider msg
onChange handler (Slider s) =
    Slider { s | onChange = Just handler }


withStyle : (Config Standard -> Config Standard) -> Slider msg -> Slider msg
withStyle fn (Slider s) =
    Slider { s | style = fn s.style }


view : Slider msg -> Html msg
view (Slider s) =
    let
        clamped =
            Basics.max s.min (Basics.min s.max s.value)

        onChangeAttr =
            case s.onChange of
                Just handler ->
                    [ Html.Events.on "input" (intDecoder handler) ]

                Nothing ->
                    []
    in
    Html.input
        (Html.Attributes.class (Config.toClasses s.style)
            :: Html.Attributes.type_ "range"
            :: Html.Attributes.min (String.fromInt s.min)
            :: Html.Attributes.max (String.fromInt s.max)
            :: Html.Attributes.step (String.fromInt s.step)
            :: Html.Attributes.value (String.fromInt clamped)
            :: Config.toStyleAttributes s.style
            ++ onChangeAttr
        )
        []


intDecoder : (Int -> msg) -> Decode.Decoder msg
intDecoder handler =
    Decode.field "target" (Decode.field "value" Decode.string)
        |> Decode.andThen
            (\str ->
                case String.toInt str of
                    Just n ->
                        Decode.succeed (handler n)

                    Nothing ->
                        Decode.fail "not an int"
            )
