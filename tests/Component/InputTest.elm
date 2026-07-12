module Component.InputTest exposing (suite)

import Expect
import Html.Attributes
import Tebru.Component.Input as Input
import Tebru.Theme.Border as Border
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Input"
        [ test "renders an <input> element" <|
            \_ ->
                Input.default
                    |> Input.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "input" ]
        , test "withPlaceholder sets the placeholder attribute" <|
            \_ ->
                Input.default
                    |> Input.withPlaceholder "Search…"
                    |> Input.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Html.Attributes.placeholder "Search…") ]
        , test "onInput wires a handler" <|
            \_ ->
                Input.default
                    |> Input.onInput identity
                    |> Input.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.input "hello")
                    |> Event.expect "hello"
        , test "default styles the placeholder with the muted text token" <|
            \_ ->
                Input.default
                    |> Input.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "placeholder:text-fg-muted" ]
        , test "default styles the disabled state with the disabled surface token" <|
            \_ ->
                Input.default
                    |> Input.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.classes [ "disabled:bg-surface-disabled", "disabled:cursor-not-allowed" ] ]
        , test "withStyle overrides border" <|
            \_ ->
                Input.default
                    |> Input.withStyle (Border.withBorder Border.Error)
                    |> Input.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "border-border-error" ]
        , test "withLabel wraps the input in a <label> with the caption" <|
            \_ ->
                Input.default
                    |> Input.withLabel "Email address"
                    |> Input.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "label" ]
                        , Query.has [ Selector.text "Email address" ]
                        , Query.has [ Selector.tag "input" ]
                        ]
        ]
