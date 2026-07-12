module Component.SegmentedControlTest exposing (suite)

import Expect
import Html
import Html.Attributes
import Tebru.Component.SegmentedControl as SegmentedControl
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


type Period
    = Day
    | Week


suite : Test
suite =
    describe "Component.SegmentedControl"
        [ test "renders all option labels" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Day" ]
                        , Query.has [ Selector.text "Week" ]
                        ]

        -- A bare <button> defaults to type="submit" and would submit an
        -- enclosing <form> on every segment click.
        , test "option buttons are type=button (never submit an enclosing form)" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.each (Query.has [ Selector.attribute (Html.Attributes.type_ "button") ])
        , test "selected option is the white card sub-pill (surface, semibold, shadow)" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Expect.all
                        [ Query.has [ Selector.class "bg-surface-card" ]
                        , Query.has [ Selector.class "font-semibold" ]
                        , Query.has [ Selector.text "Day" ]
                        ]
        , test "unselected option has the transparent secondary-ink style with hover preview" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.index 1
                    |> Expect.all
                        [ Query.has [ Selector.class "text-fg-secondary", Selector.class "font-medium" ]
                        , Query.has [ Selector.class "hover:bg-surface-card", Selector.class "hover:text-fg-default" ]
                        , Query.hasNot [ Selector.class "bg-surface-card" ]
                        ]
        , test "container is the cardAlt track with border and inline-flex gap" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day } ], selected = Day, onSelect = identity }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card-alt", Selector.class "border", Selector.class "inline-flex", Selector.class "gap-xs" ]
        , test "selecting an option fires onSelect with the value" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = "day" }, { label = "Week", value = "week" } ]
                    , selected = "week"
                    , onSelect = identity
                    }
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Event.simulate Event.click
                    |> Event.expect "day"
        , test "withStyle overrides the container surface" <|
            \_ ->
                SegmentedControl.default
                    { options = [], selected = (), onSelect = identity }
                    |> SegmentedControl.withStyle (Surface.withSurface Surface.Card)
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card" ]
        , test "withSelectedStyle overrides the selected option item's surface" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.withSelectedStyle (Surface.withSurface Surface.Brand)
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Query.has [ Selector.class "bg-surface-brand" ]
        , test "withUnselectedStyle overrides the unselected option item's surface" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
                    , selected = Day
                    , onSelect = identity
                    }
                    |> SegmentedControl.withUnselectedStyle (Surface.withSurface Surface.Danger)
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.index 1
                    |> Query.has [ Selector.class "bg-surface-danger" ]
        , test "withLeadingOptions renders the leading slot before the label in the segment" <|
            \_ ->
                SegmentedControl.default
                    { options = [ { label = "Red", value = Day } ], selected = Day, onSelect = identity }
                    |> SegmentedControl.withLeadingOptions
                        [ { label = "Red", value = Day, leading = Just (Html.span [ Html.Attributes.class "swatch" ] []) }
                        , { label = "None", value = Week, leading = Nothing }
                        ]
                    |> SegmentedControl.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.findAll [ Selector.tag "button" ] >> Query.first >> Query.has [ Selector.class "swatch", Selector.text "Red" ]
                        , Query.findAll [ Selector.tag "button" ] >> Query.index 1 >> Query.hasNot [ Selector.class "swatch" ]
                        , Query.findAll [ Selector.tag "button" ] >> Query.index 1 >> Query.has [ Selector.text "None" ]
                        ]
        ]
