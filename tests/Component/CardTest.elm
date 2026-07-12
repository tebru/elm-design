module Component.CardTest exposing (suite)

import Html
import Tebru.Component.Card as Card
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Card"
        [ test "renders a section with children" <|
            \_ ->
                Card.default [ Html.text "Content" ]
                    |> Card.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "section", Selector.text "Content" ]
        , test "has default surface, border, and radius classes" <|
            \_ ->
                Card.default []
                    |> Card.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card", Selector.class "border", Selector.class "rounded-lg" ]
        , test "withStyle overrides the surface" <|
            \_ ->
                Card.default []
                    |> Card.withStyle (Surface.withSurface Surface.Subtle)
                    |> Card.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        , test "multi-child card keeps the constructor stack gap (gap-xl) alongside its own style" <|
            \_ ->
                Card.default [ Html.text "Body" ]
                    |> Card.withHeader { title = "Title", subtitle = Nothing }
                    |> Card.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "gap-xl", Selector.class "bg-surface-card" ]
        , test "single-child card has no gap class" <|
            \_ ->
                Card.default [ Html.text "Body" ]
                    |> Card.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.class "gap-xl" ]
        ]
