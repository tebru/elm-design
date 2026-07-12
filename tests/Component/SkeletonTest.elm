module Component.SkeletonTest exposing (suite)

import Tebru.Component.Skeleton as Skeleton
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Skeleton"
        [ test "line renders a span with the skeleton class" <|
            \_ ->
                Skeleton.line
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "span", Selector.class "skeleton" ]
        , test "box renders a span with the skeleton class" <|
            \_ ->
                Skeleton.box
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "span", Selector.class "skeleton" ]
        , test "line has default subtle surface class" <|
            \_ ->
                Skeleton.line
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        , test "withStyle overrides the surface" <|
            \_ ->
                Skeleton.box
                    |> Skeleton.withStyle (Surface.withSurface Surface.CardAlt)
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card-alt" ]
        , test "withShimmer Dark adds the dark shimmer class" <|
            \_ ->
                Skeleton.box
                    |> Skeleton.withStyle (Skeleton.withShimmer Skeleton.Dark)
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "skeleton-dark" ]
        , test "withShimmer Light adds the light shimmer class" <|
            \_ ->
                Skeleton.line
                    |> Skeleton.withStyle (Skeleton.withShimmer Skeleton.Light)
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "skeleton" ]
        , test "cardHeight applies the fixed card height class" <|
            \_ ->
                Skeleton.box
                    |> Skeleton.withStyle Skeleton.cardHeight
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "h-[140px]" ]
        , test "bigBoxHeight applies the fixed big-box height class" <|
            \_ ->
                Skeleton.box
                    |> Skeleton.withStyle Skeleton.bigBoxHeight
                    |> Skeleton.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "h-[120px]" ]
        ]
