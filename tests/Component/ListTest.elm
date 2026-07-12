module Component.ListTest exposing (suite)

import Html
import Tebru.Component.List as CList
import Tebru.Component.ListItem as ListItem
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.List and Component.ListItem"
        [ describe "Component.List"
            [ test "renders a ul (not a div) containing the items" <|
                \_ ->
                    CList.default
                        [ ListItem.default [ Html.text "First" ] |> ListItem.view
                        , ListItem.default [ Html.text "Second" ] |> ListItem.view
                        ]
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "ul", Selector.text "First", Selector.text "Second" ]
            , test "lays out as a vertical flex stack with gap-sm" <|
                \_ ->
                    CList.default []
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "flex", Selector.class "flex-col", Selector.class "gap-sm" ]
            , test "renders a list-none ul with no margin/padding" <|
                \_ ->
                    CList.default []
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "ul", Selector.class "list-none", Selector.class "m-0", Selector.class "p-0" ]
            , test "is transparent by default (no card surface)" <|
                \_ ->
                    CList.default []
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "bg-surface-card" ]
            , test "withStyle can add a surface" <|
                \_ ->
                    CList.default []
                        |> CList.withStyle (Surface.withSurface Surface.Subtle)
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-subtle" ]
            , test "has no divider classes by default" <|
                \_ ->
                    CList.default []
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.hasNot
                            [ Selector.class "[&>*:not(:last-child)]:border-b"
                            , Selector.class "[&>*:not(:last-child)]:border-border-default"
                            ]
            , test "withDividers True adds the between-item divider classes" <|
                \_ ->
                    CList.default []
                        |> CList.withDividers True
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.class "[&>*:not(:last-child)]:border-b"
                            , Selector.class "[&>*:not(:last-child)]:border-border-default"
                            ]
            , test "withDividers False keeps dividers off" <|
                \_ ->
                    CList.default []
                        |> CList.withDividers False
                        |> CList.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "[&>*:not(:last-child)]:border-b" ]
            ]
        , describe "Component.ListItem"
            [ test "renders a bare li with children content" <|
                \_ ->
                    ListItem.default [ Html.text "Hello" ]
                        |> ListItem.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "li", Selector.text "Hello" ]
            , test "bakes no border by default" <|
                \_ ->
                    ListItem.default []
                        |> ListItem.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "border-border-divider" ]
            , test "withStyle applies a surface override" <|
                \_ ->
                    ListItem.default []
                        |> ListItem.withStyle (Surface.withSurface Surface.Subtle)
                        |> ListItem.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-subtle" ]
            ]
        ]
