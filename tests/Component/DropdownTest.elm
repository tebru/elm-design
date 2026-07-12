module Component.DropdownTest exposing (suite)

import Expect
import Html
import Tebru.Component.Dropdown as Dropdown
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


item : String -> msg -> Dropdown.Item msg
item label onClick =
    { label = label, icon = Nothing, onClick = onClick, style = identity }


suite : Test
suite =
    describe "Component.Dropdown"
        [ test "always renders the trigger" <|
            \_ ->
                Dropdown.default
                    { isOpen = False
                    , onToggle = ()
                    , trigger = Html.text "Open menu"
                    , items = []
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Open menu" ]
        , test "items are not rendered when closed" <|
            \_ ->
                Dropdown.default
                    { isOpen = False
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Item 1" ]
        , test "items are rendered when open" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" (), item "Item 2" () ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Item 1" ]
                        , Query.has [ Selector.text "Item 2" ]
                        ]
        , test "clicking trigger fires onToggle" <|
            \_ ->
                Dropdown.default
                    { isOpen = False
                    , onToggle = "toggled"
                    , trigger = Html.text "Open"
                    , items = []
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.containing [ Selector.text "Open" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect "toggled"
        , test "items default to the default text color" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Plain" () ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "li" ]
                    |> Query.has [ Selector.class "text-fg-default" ]
        , test "an item's style slot overrides the default item style" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ { label = "Delete", icon = Nothing, onClick = (), style = Text.withText Text.Error } ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "li" ]
                    |> Expect.all
                        [ Query.has [ Selector.class "text-fg-error" ]
                        , Query.hasNot [ Selector.class "text-fg-default" ]
                        ]
        , test "withItemStyle applies to every item, and per-item style wins over it" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Plain" (), { label = "Delete", icon = Nothing, onClick = (), style = Text.withText Text.Error } ]
                    }
                    |> Dropdown.withItemStyle (Text.withText Text.Muted)
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.findAll [ Selector.tag "li", Selector.class "text-fg-muted" ] >> Query.count (Expect.equal 1)
                        , Query.findAll [ Selector.tag "li", Selector.class "text-fg-error" ] >> Query.count (Expect.equal 1)
                        ]
        , test "withHeader renders the header block above the items when open" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.withHeader (Html.text "Account header")
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Account header" ]
        , test "withHeader header is not rendered when closed" <|
            \_ ->
                Dropdown.default
                    { isOpen = False
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.withHeader (Html.text "Account header")
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Account header" ]
        , test "popup uses the small min-width floor by default" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "min-w-[160px]" ]
        , test "withStyle minWidthPanelLg replaces the popup floor (no stacked min-w classes)" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.withStyle Dropdown.minWidthPanelLg
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.class "min-w-[280px]" ]
                        , Query.hasNot [ Selector.class "min-w-[160px]" ]
                        ]
        , test "withStyle composes onto the popup chrome (last call wins per channel)" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = ()
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" () ]
                    }
                    |> Dropdown.withStyle (Surface.withSurface Surface.Subtle)
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.class "bg-surface-subtle" ]
                        , Query.hasNot [ Selector.class "bg-surface-card" ]
                        , Query.has [ Selector.class "min-w-[160px]" ]
                        ]
        , test "clicking an item fires its onClick" <|
            \_ ->
                Dropdown.default
                    { isOpen = True
                    , onToggle = "toggled"
                    , trigger = Html.text "Open"
                    , items = [ item "Item 1" "clicked" ]
                    }
                    |> Dropdown.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "li" ]
                    |> Event.simulate Event.click
                    |> Event.expect "clicked"
        ]
