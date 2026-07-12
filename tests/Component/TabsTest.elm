module Component.TabsTest exposing (suite)

import Expect
import Html
import Html.Attributes
import Tebru.Component.Tabs as Tabs
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Tabs"
        [ test "renders all tab labels" <|
            \_ ->
                Tabs.default
                    { tabs =
                        [ { label = "Overview", onSelect = () }
                        , { label = "Members", onSelect = () }
                        ]
                    , active = 0
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Overview" ]
                        , Query.has [ Selector.text "Members" ]
                        ]

        -- A bare <button> defaults to type="submit" and would submit an
        -- enclosing <form> on every tab click.
        , test "tab buttons are type=button (never submit an enclosing form)" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.each (Query.has [ Selector.attribute (Html.Attributes.type_ "button") ])
        , test "active tab uses the default underline indicator (sage focus bottom border, no fill)" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Expect.all
                        [ Query.has [ Selector.class "border-border-focus", Selector.class "border-b" ]
                        , Query.has [ Selector.class "font-semibold", Selector.class "text-fg-default" ]
                        , Query.hasNot [ Selector.class "bg-surface-selected" ]
                        ]
        , test "inactive tab is secondary medium text with a transparent underline placeholder" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.index 1
                    |> Expect.all
                        [ Query.has [ Selector.class "border-border-transparent", Selector.class "border-b" ]
                        , Query.has [ Selector.class "font-medium", Selector.class "text-fg-secondary" ]
                        , Query.hasNot [ Selector.class "border-border-focus" ]
                        ]
        , test "container has the bottom divider and no surface fill" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () } ], active = 0 }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "border-border-default", Selector.class "border-b" ]
        , test "withActiveIndicator Pill fills the active tab with the selected surface" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.withActiveIndicator Tabs.Pill
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Expect.all
                        [ Query.has [ Selector.class "bg-surface-selected", Selector.class "font-semibold" ]
                        , Query.hasNot [ Selector.class "border-border-focus" ]
                        ]
        , test "detailed renders a per-tab badge after the label" <|
            \_ ->
                Tabs.detailed
                    { tabs =
                        [ { label = "Members", onSelect = (), badge = Just (Html.text "3") }
                        , { label = "Events", onSelect = (), badge = Nothing }
                        ]
                    , active = 0
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Members" ]
                        , Query.has [ Selector.text "3" ]
                        , Query.findAll [ Selector.tag "span" ] >> Query.count (Expect.equal 1)
                        ]
        , test "clicking a tab fires its msg" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "Overview", onSelect = "overview-selected" } ]
                    , active = -1
                    }
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "button" ]
                    |> Event.simulate Event.click
                    |> Event.expect "overview-selected"
        , test "withStyle overrides the container surface" <|
            \_ ->
                Tabs.default { tabs = [], active = 0 }
                    |> Tabs.withStyle (Surface.withSurface Surface.Card)
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-card" ]
        , test "withActiveStyle overrides the active tab item's surface" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.withActiveStyle (Surface.withSurface Surface.Brand)
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.first
                    |> Query.has [ Selector.class "bg-surface-brand" ]
        , test "withInactiveStyle overrides the inactive tab item's surface" <|
            \_ ->
                Tabs.default
                    { tabs = [ { label = "One", onSelect = () }, { label = "Two", onSelect = () } ]
                    , active = 0
                    }
                    |> Tabs.withInactiveStyle (Surface.withSurface Surface.Danger)
                    |> Tabs.view
                    |> Query.fromHtml
                    |> Query.findAll [ Selector.tag "button" ]
                    |> Query.index 1
                    |> Query.has [ Selector.class "bg-surface-danger" ]
        ]
