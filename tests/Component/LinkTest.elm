module Component.LinkTest exposing (suite)

import Expect
import Html
import Html.Attributes
import Tebru.Component.Link as Link
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Link"
        [ test "renders an <a> with the correct href and content" <|
            \_ ->
                Link.default { href = "/home", content = Html.text "Home" }
                    |> Link.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "a", Selector.text "Home" ]
                        , Query.has [ Selector.attribute (Html.Attributes.href "/home") ]
                        ]
        , test "default style includes link text class" <|
            \_ ->
                Link.default { href = "/", content = Html.text "X" }
                    |> Link.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-link" ]
        , test "withStyle overrides the text color" <|
            \_ ->
                Link.default { href = "/", content = Html.text "X" }
                    |> Link.withStyle (Text.withText Text.Secondary)
                    |> Link.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-secondary" ]
        , test "content can be arbitrary Html" <|
            \_ ->
                Link.default { href = "/docs", content = Html.span [] [ Html.text "Docs" ] }
                    |> Link.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "a", Selector.text "Docs" ]
        ]
