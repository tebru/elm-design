module Component.TooltipTest exposing (suite)

import Html
import Html.Attributes
import Tebru.Component.Tooltip as Tooltip
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Tooltip"
        [ test "renders the target" <|
            \_ ->
                Tooltip.default
                    { label = "Save document"
                    , target = Html.text "Save"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Save" ]
        , test "renders the label" <|
            \_ ->
                Tooltip.default
                    { label = "Save document"
                    , target = Html.text "Save"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Save document" ]
        , test "bubble carries role=tooltip" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.attribute (Html.Attributes.attribute "role" "tooltip") ]
        , test "has default inverse surface on bubble" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.withPosition Tooltip.Below
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-inverse" ]
        , test "bubble carries corrected typography and elevation classes" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.class "text-xs"
                        , Selector.class "font-medium"
                        , Selector.class "shadow-md"
                        ]
        , test "bubble carries sizing constraints" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.class "w-max"
                        , Selector.class "max-w-[260px]"
                        , Selector.class "z-30"
                        ]
        , test "bubble is hover-gated (hidden until group-hover)" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.class "opacity-0"
                        , Selector.class "group-hover:opacity-100"
                        , Selector.class "transition-opacity"
                        , Selector.class "pointer-events-none"
                        ]
        , test "wrapper carries the group class for hover gating" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.classes [ "relative", "inline-block", "group" ] ]
        , test "renders an aria-hidden arrow" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.class "rotate-45"
                        , Selector.attribute (Html.Attributes.attribute "aria-hidden" "true")
                        ]
        , test "arrow inherits the bubble surface background" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip label"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.class "rotate-45" ]
                    |> Query.each (Query.has [ Selector.class "bg-surface-inverse" ])
        , test "withStyle overrides the bubble surface" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.withStyle (Surface.withSurface Surface.Subtle)
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        , test "above position anchors to bottom with calc offset" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bottom-[calc(100%+14px)]" ]
        , test "below position anchors to top with calc offset" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.withPosition Tooltip.Below
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "top-[calc(100%+14px)]" ]
        , test "left position anchors to right with calc offset" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.withPosition Tooltip.Left
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "right-[calc(100%+14px)]" ]
        , test "right position anchors to left with calc offset" <|
            \_ ->
                Tooltip.default
                    { label = "Tooltip"
                    , target = Html.text "Target"
                    }
                    |> Tooltip.withPosition Tooltip.Right
                    |> Tooltip.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "left-[calc(100%+14px)]" ]
        ]
