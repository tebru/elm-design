module Component.TextTest exposing (suite)

import Tebru.Component.Text as Text
import Tebru.Theme.Typography as FontSize
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Text"
        [ test "body renders a <span> with base size, normal weight, and default color" <|
            \_ ->
                Text.body "Hello world"
                    |> Text.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "span"
                        , Selector.text "Hello world"
                        , Selector.class "text-base"
                        , Selector.class "font-normal"
                        , Selector.class "text-fg-default"
                        ]
        , test "heading renders a <h1> with 3xl size, bold weight, and default color" <|
            \_ ->
                Text.heading "Title"
                    |> Text.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.tag "h1"
                        , Selector.text "Title"
                        , Selector.class "text-3xl"
                        , Selector.class "font-bold"
                        , Selector.class "text-fg-default"
                        ]
        , test "withTag renders the chosen element (H3) while keeping the content" <|
            \_ ->
                Text.heading "Section"
                    |> Text.withTag Text.H3
                    |> Text.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "h3", Selector.text "Section" ]
        , test "withTag P renders a paragraph element" <|
            \_ ->
                Text.body "Paragraph"
                    |> Text.withTag Text.P
                    |> Text.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "p", Selector.text "Paragraph" ]
        , test "withStyle overrides the font size" <|
            \_ ->
                Text.body "Big text"
                    |> Text.withStyle (FontSize.withFontSize FontSize.Xl)
                    |> Text.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-xl" ]
        ]
