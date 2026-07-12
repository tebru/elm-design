module Tebru.Component.Text exposing (Tag(..), Text, body, heading, view, withStyle, withTag)

{-| Headless Text primitive.

    Text.body "Hello"
        |> Text.withStyle (Typography.withFontSize Typography.Lg)
        |> Text.view

    Text.heading "Title" |> Text.view

No variant enums — app variants are presets with `withStyle`.

`body` matches the old `Ui.Text.body` (inline `<span>`, base size, normal
weight, default color). `heading` matches the old `Ui.Text.heading1`
(`<h1>`, 3xl size, bold weight, default color). Other typographic variants
(heading3/muted/caption/error/success/sectionLabel/…) are app-side presets
built with `withStyle` (and `withTag` when a different element is needed),
e.g. in `Style.Kit`.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Text as TextColor
import Tebru.Theme.Typography as Typography


{-| The rendered element. `body` defaults to `Span` (inline, matching the old
`Ui.Text.body`), `heading` to `H1` (matching the old `Ui.Text.heading1`). Use
`withTag` to render a different semantic element while keeping the builder —
e.g. `H3` for a section heading, `P` for a paragraph.
-}
type Tag
    = P
    | Span
    | H1
    | H2
    | H3


type Text msg
    = Text
        { tag : Tag
        , content : String
        , style : Config Standard
        }


{-| Body text — renders as `<span>` with base size, normal weight, and default
text color. Matches the old `Ui.Text.body`.
-}
body : String -> Text msg
body content =
    Text { tag = Span, content = content, style = bodyStyle }


{-| Heading text — renders as `<h1>` with 3xl size and bold weight. Matches the
old `Ui.Text.heading1`.
-}
heading : String -> Text msg
heading content =
    Text { tag = H1, content = content, style = headingStyle }


bodyStyle : Config Standard
bodyStyle =
    Config.default
        |> Typography.withFontSize Typography.Base
        |> Typography.withFontWeight Typography.Normal
        |> TextColor.withText TextColor.Default


headingStyle : Config Standard
headingStyle =
    Config.default
        |> Typography.withFontSize Typography.X3l
        |> Typography.withFontWeight Typography.Bold
        |> TextColor.withText TextColor.Default


{-| Override the rendered element. Lets app presets reproduce variants that need
a different semantic tag (e.g. `withTag H3` for a section title) without leaving
the builder.
-}
withTag : Tag -> Text msg -> Text msg
withTag tag (Text t) =
    Text { t | tag = tag }


withStyle : (Config Standard -> Config Standard) -> Text msg -> Text msg
withStyle fn (Text t) =
    Text { t | style = fn t.style }


view : Text msg -> Html msg
view (Text t) =
    let
        attrs =
            Html.Attributes.class (Config.toClasses t.style) :: Config.toStyleAttributes t.style

        children =
            [ Html.text t.content ]
    in
    case t.tag of
        P ->
            Html.p attrs children

        Span ->
            Html.span attrs children

        H1 ->
            Html.h1 attrs children

        H2 ->
            Html.h2 attrs children

        H3 ->
            Html.h3 attrs children
