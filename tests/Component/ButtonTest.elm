module Component.ButtonTest exposing (suite)

import Expect
import Tebru.Component.Button as Button
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Button"
        [ test "renders its label in a button with the default styling" <|
            \_ ->
                Button.default "Save"
                    |> Button.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "button", Selector.text "Save" ] ]
        , test "withStyle overrides the default surface" <|
            \_ ->
                Button.default "Save"
                    |> Button.withStyle (Surface.withSurface Surface.Brand)
                    |> Button.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-brand" ]
        , test "onClick wires a handler" <|
            \_ ->
                Button.default "Save"
                    |> Button.onClick ()
                    |> Button.view
                    |> Query.fromHtml
                    |> Event.simulate Event.click
                    |> Event.expect ()
        ]
