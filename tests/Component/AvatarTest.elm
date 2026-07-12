module Component.AvatarTest exposing (suite)

import Expect
import Html.Attributes
import Tebru.Component.Avatar as Avatar
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Avatar"
        [ test "image case renders an <img> with the correct src" <|
            \_ ->
                Avatar.default { name = "Ada Lovelace", image = Just "https://example.com/ada.png" }
                    |> Avatar.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.tag "img" ]
                        , Query.has [ Selector.attribute (Html.Attributes.src "https://example.com/ada.png") ]
                        ]
        , test "no-image case renders initials" <|
            \_ ->
                Avatar.default { name = "Ada Lovelace", image = Nothing }
                    |> Avatar.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "AL" ]
        , test "no-image single-word name renders one initial" <|
            \_ ->
                Avatar.default { name = "Ada", image = Nothing }
                    |> Avatar.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "A" ]
        , test "withStyle overrides the surface" <|
            \_ ->
                Avatar.default { name = "Ada Lovelace", image = Nothing }
                    |> Avatar.withStyle (Surface.withSurface Surface.Brand)
                    |> Avatar.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-brand" ]
        ]
