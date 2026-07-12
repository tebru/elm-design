module Component.ActionRowTest exposing (suite)

import Html
import Tebru.Component.ActionRow as ActionRow
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.ActionRow"
        [ test "renders action elements" <|
            \_ ->
                ActionRow.default
                    [ Html.button [] [ Html.text "Cancel" ]
                    , Html.button [] [ Html.text "Save" ]
                    ]
                    |> ActionRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Cancel", Selector.text "Save" ]
        , test "has justify-end class for right alignment" <|
            \_ ->
                ActionRow.default []
                    |> ActionRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "justify-end" ]
        , test "withStyle can override the row style" <|
            \_ ->
                ActionRow.default []
                    |> ActionRow.withStyle (Text.withText Text.Secondary)
                    |> ActionRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-secondary" ]
        ]
