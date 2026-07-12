module Component.SectionHeaderTest exposing (suite)

import Expect
import Html
import Tebru.Component.SectionHeader as SectionHeader
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.SectionHeader"
        [ test "renders the title text" <|
            \_ ->
                SectionHeader.default "Members"
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Members" ]
        , test "no action slot renders without the action content" <|
            \_ ->
                SectionHeader.default "Members"
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Add" ]
        , test "withAction slot renders the action content" <|
            \_ ->
                SectionHeader.default "Members"
                    |> SectionHeader.withAction (Html.button [] [ Html.text "Add" ])
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Members" ]
                        , Query.has [ Selector.text "Add" ]
                        ]
        , test "no count by default" <|
            \_ ->
                SectionHeader.default "Scheduling"
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.class "text-fg-muted" ]
        , test "withCount renders the count text" <|
            \_ ->
                SectionHeader.default "Scheduling"
                    |> SectionHeader.withCount 3
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Scheduling" ]
                        , Query.has [ Selector.text "3" ]
                        ]
        , test "withCount renders the count muted with the title's size and weight" <|
            \_ ->
                SectionHeader.default "Scheduling"
                    |> SectionHeader.withCount 3
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.all
                            [ Selector.tag "span"
                            , Selector.class "text-fg-muted"
                            , Selector.class "text-sm"
                            , Selector.class "font-semibold"
                            , Selector.containing [ Selector.text "3" ]
                            ]
                        ]
        , test "withCount keeps the title on the default color" <|
            \_ ->
                SectionHeader.default "Scheduling"
                    |> SectionHeader.withCount 3
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.all
                            [ Selector.tag "span"
                            , Selector.class "text-fg-default"
                            , Selector.containing [ Selector.text "Scheduling" ]
                            ]
                        ]
        , test "withStyle overrides title text style" <|
            \_ ->
                SectionHeader.default "Members"
                    |> SectionHeader.withStyle (Text.withText Text.Muted)
                    |> SectionHeader.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-muted" ]
        ]
