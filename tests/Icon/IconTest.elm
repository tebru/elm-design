module Icon.IconTest exposing (suite)

import Expect
import Tebru.Icon as Icon
import Tebru.Icon.Geometry as Geometry
import Tebru.Theme.Config as Config
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Icon"
        [ test "renders an svg carrying the geometry and the lucide-icon class" <|
            \_ ->
                Icon.default Geometry.plus
                    |> Icon.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "svg" ]
                        , Query.has [ Selector.class "lucide-icon" ]
                        ]

        -- Icon.view must honor BOTH Config channels: classes and the inline
        -- style Dict (withTextHex etc.), like every other render path.
        , test "withStyle inline-style setters render on the span" <|
            \_ ->
                Icon.default Geometry.plus
                    |> Icon.withStyle (Config.withTextHex "#ff0000")
                    |> Icon.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.style "color" "#ff0000" ]
        ]
