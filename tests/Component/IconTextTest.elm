module Component.IconTextTest exposing (suite)

import Html
import Tebru.Component.IconText as IconText
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.IconText"
        [ test "renders the label text" <|
            \_ ->
                IconText.default { icon = Html.text "[icon]", label = "Settings" }
                    |> IconText.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Settings" ]
        , test "renders the icon content" <|
            \_ ->
                IconText.default { icon = Html.text "[icon]", label = "Settings" }
                    |> IconText.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "[icon]" ]
        , test "withStyle applies classes to the label" <|
            \_ ->
                IconText.default { icon = Html.text "[icon]", label = "Settings" }
                    |> IconText.withStyle (Text.withText Text.Muted)
                    |> IconText.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-muted" ]
        ]
