module Tebru.Component.Badge exposing (Badge, dot, pill, statusPill, view, withDotStyle, withHoverStyle, withStyle)

{-| Headless Badge primitive.

Two entry points — no variant enums. Tone overrides are `withStyle` call-site concerns.

    Badge.pill "New" |> Badge.view

    Badge.dot |> Badge.view

For a status pill with a colored leading dot, use `withDotStyle` to override the dot's surface.
`withSurfaceCustom` takes a resolver function (`yourTone -> String`, returning the class for your
custom token — NOT a class string itself) plus the `Custom`-wrapped token:

    import Tebru.Theme.Surface as Surface exposing (Surface(..))

    type MyTone
        = Active

    toClass : MyTone -> String
    toDotClass : MyTone -> String

    Badge.statusPill "Active"
        |> Badge.withStyle (Surface.withSurfaceCustom toClass (Custom Active))
        |> Badge.withDotStyle (Surface.withSurfaceCustom toDotClass (Custom Active))
        |> Badge.view

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type BadgeKind
    = Dot
    | Pill String
    | StatusPill String


type Badge msg
    = Badge
        { kind : BadgeKind
        , style : Config Standard
        , dotConfig : Config Standard
        , hoverStyle : Config Hover
        }


dot : Badge msg
dot =
    Badge { kind = Dot, style = dotStyle, dotConfig = dotStyle, hoverStyle = Config.defaultHover }


pill : String -> Badge msg
pill label =
    Badge { kind = Pill label, style = pillStyle, dotConfig = dotStyle, hoverStyle = Config.defaultHover }


{-| A pill badge with a leading status dot followed by a text label.

    Badge.statusPill "Active" |> Badge.view

Use `withDotStyle` to override the dot's surface independently from the pill surface.

-}
statusPill : String -> Badge msg
statusPill label =
    Badge { kind = StatusPill label, style = pillStyle, dotConfig = dotStyle, hoverStyle = Config.defaultHover }


dotStyle : Config Standard
dotStyle =
    Config.default
        |> Surface.withSurface Surface.Subtle
        |> Radius.withRadius Radius.Full
        |> Config.addRaw dotSize
        |> Structure.withShrink False


{-| Intrinsic 0.375rem square of the status dot. No size scale token covers this
fixed dimension, so it stays as a named raw constant.
-}
dotSize : String
dotSize =
    "w-1.5 h-1.5"


pillStyle : Config Standard
pillStyle =
    Config.default
        |> Surface.withSurface Surface.Subtle
        |> Text.withText Text.Secondary
        |> Typography.withFontSize Typography.Xs
        |> Typography.withFontWeight Typography.Medium
        |> Radius.withRadius Radius.Full
        |> Spacing.withPadding (Spacing.xy Sm Xs)


withStyle : (Config Standard -> Config Standard) -> Badge msg -> Badge msg
withStyle fn (Badge b) =
    Badge { b | style = fn b.style }


{-| Override the styling of the leading dot in a `statusPill`. No-op for `pill` and `dot` kinds.
-}
withDotStyle : (Config Standard -> Config Standard) -> Badge msg -> Badge msg
withDotStyle fn (Badge b) =
    Badge { b | dotConfig = fn b.dotConfig }


{-| Modify the hover style config — emitted as `hover:`-prefixed classes on the badge's root element.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Badge msg -> Badge msg
withHoverStyle fn (Badge b) =
    Badge { b | hoverStyle = fn b.hoverStyle }


view : Badge msg -> Html msg
view (Badge b) =
    case b.kind of
        Dot ->
            Html.span
                (Html.Attributes.class (rootClass b "") :: Config.toStyleAttributes b.style)
                []

        Pill label ->
            Html.span
                (Html.Attributes.class (rootClass b "") :: Config.toStyleAttributes b.style)
                [ Html.text label ]

        StatusPill label ->
            Html.span
                (Html.Attributes.class (rootClass b "inline-flex items-center gap-2") :: Config.toStyleAttributes b.style)
                [ Html.span
                    (Html.Attributes.class (Config.toClasses b.dotConfig) :: Config.toStyleAttributes b.dotConfig)
                    []
                , Html.text label
                ]


{-| Root-element class string: base style classes, optional extra layout classes,
and the typed hover-style classes, joined with empty segments dropped.
-}
rootClass : { kind : BadgeKind, style : Config Standard, dotConfig : Config Standard, hoverStyle : Config Hover } -> String -> String
rootClass b extra =
    [ Config.toClasses b.style, extra, Config.hoverToClasses b.hoverStyle ]
        |> List.filter (\s -> s /= "")
        |> String.join " "
