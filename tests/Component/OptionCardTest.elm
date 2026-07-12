module Component.OptionCardTest exposing (suite)

import Html
import Tebru.Component.OptionCard as OptionCard
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.OptionCard"
        [ test "renders the content" <|
            \_ ->
                OptionCard.default
                    { selected = False, onSelect = (), content = Html.text "Option A" }
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Option A" ]
        , test "unselected card uses default card surface" <|
            \_ ->
                OptionCard.default
                    { selected = False, onSelect = (), content = Html.text "" }
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card" ]
        , test "selected card uses selected surface" <|
            \_ ->
                OptionCard.default
                    { selected = True, onSelect = (), content = Html.text "" }
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-selected" ]
        , test "selected card has focus border" <|
            \_ ->
                OptionCard.default
                    { selected = True, onSelect = (), content = Html.text "" }
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "border-border-focus" ]
        , test "clicking fires onSelect" <|
            \_ ->
                OptionCard.default
                    { selected = False, onSelect = (), content = Html.text "" }
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Event.simulate Event.click
                    |> Event.expect ()
        , test "withStyle overrides the base card style" <|
            \_ ->
                OptionCard.default
                    { selected = False, onSelect = (), content = Html.text "" }
                    |> OptionCard.withStyle (Surface.withSurface Surface.Subtle)
                    |> OptionCard.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        ]
