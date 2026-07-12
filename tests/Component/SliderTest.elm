module Component.SliderTest exposing (suite)

import Html.Attributes
import Tebru.Component.Slider as Slider
import Tebru.Theme.Structure as Structure
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Slider"
        [ test "renders an <input type=range>" <|
            \_ ->
                Slider.default { min = 1, max = 6, step = 1, value = 3 }
                    |> Slider.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "input", Selector.attribute (Html.Attributes.type_ "range") ]
        , test "clamps the bound value into [min, max]" <|
            \_ ->
                Slider.default { min = 1, max = 6, step = 1, value = 99 }
                    |> Slider.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Html.Attributes.value "6") ]
        , test "onChange decodes the input value to an Int" <|
            \_ ->
                Slider.default { min = 1, max = 6, step = 1, value = 3 }
                    |> Slider.onChange identity
                    |> Slider.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.input "5")
                    |> Event.expect 5
        , test "withStyle overrides the default cursor" <|
            \_ ->
                Slider.default { min = 1, max = 6, step = 1, value = 3 }
                    |> Slider.withStyle (Structure.withCursor Structure.CursorDefault)
                    |> Slider.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "cursor-default" ]
        ]
