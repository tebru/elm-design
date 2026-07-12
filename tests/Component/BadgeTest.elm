module Component.BadgeTest exposing (suite)

import Tebru.Component.Badge as Badge
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Badge"
        [ test "pill renders its label text" <|
            \_ ->
                Badge.pill "New"
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "New" ]
        , test "pill renders a span element" <|
            \_ ->
                Badge.pill "New"
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "span" ]
        , test "dot renders a span element" <|
            \_ ->
                Badge.dot
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "span" ]
        , test "dot has default subtle surface class" <|
            \_ ->
                Badge.dot
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        , test "withStyle overrides the surface on pill" <|
            \_ ->
                Badge.pill "Active"
                    |> Badge.withStyle (Surface.withSurface Surface.Success)
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-success" ]
        , test "withStyle overrides the surface on dot" <|
            \_ ->
                Badge.dot
                    |> Badge.withStyle (Surface.withSurface Surface.Danger)
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-danger" ]
        , test "statusPill renders its label text" <|
            \_ ->
                Badge.statusPill "Active"
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Active" ]
        , test "statusPill renders a span element" <|
            \_ ->
                Badge.statusPill "Active"
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "span" ]
        , test "statusPill renders a leading dot span inside" <|
            \_ ->
                Badge.statusPill "Active"
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "span" ]
                    |> Query.has [ Selector.class "rounded-full" ]
        , test "statusPill withStyle overrides the surface on both pill and dot" <|
            \_ ->
                Badge.statusPill "Online"
                    |> Badge.withStyle (Surface.withSurface Surface.Success)
                    |> Badge.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-success" ]
        ]
