module Component.ChoiceTest exposing (suite)

import Expect
import Html.Attributes
import Json.Encode as Encode
import Tebru.Component.Choice as Choice
import Tebru.Theme.Config as Config
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Choice"
        [ describe "checkbox"
            [ test "renders a div containing the label text" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "I agree" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "div", Selector.text "I agree" ]
            , test "renders a custom box indicator (no native input)" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "I agree" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ Selector.class "border-2" ]
                            , Query.hasNot [ Selector.tag "input" ]
                            ]
            , test "checked=True shows the sage check glyph inside the box" <|
                \_ ->
                    Choice.checkbox { checked = True, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "lucide-icon" ]
            , test "checked=False shows no check glyph" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "lucide-icon" ]
            , test "checked indicator box has the focus border class" <|
                \_ ->
                    Choice.checkbox { checked = True, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "border-border-focus" ]
            , test "unchecked indicator box has the default border class" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "border-border-default" ]
            , test "clicking the control fires the toggle msg" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = "toggled", label = "I agree" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Event.simulate Event.click
                        |> Event.expect "toggled"
            ]
        , describe "radio"
            [ test "renders a div containing the label text" <|
                \_ ->
                    Choice.radio { checked = False, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "div", Selector.text "Option A" ]
            , test "renders a custom circle indicator (no native input)" <|
                \_ ->
                    Choice.radio { checked = False, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Expect.all
                            [ Query.has [ Selector.class "rounded-full", Selector.class "border" ]
                            , Query.hasNot [ Selector.tag "input" ]
                            ]
            , test "checked=True shows the brand dot inside the circle" <|
                \_ ->
                    Choice.radio { checked = True, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-brand" ]
            , test "checked=False shows no dot" <|
                \_ ->
                    Choice.radio { checked = False, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "bg-surface-brand" ]
            , test "checked circle has the focus border class" <|
                \_ ->
                    Choice.radio { checked = True, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "border-border-focus" ]
            , test "clicking the control fires the select msg" <|
                \_ ->
                    Choice.radio { checked = False, onSelect = "selected", label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Event.simulate Event.click
                        |> Event.expect "selected"
            ]
        , describe "switch"
            [ test "renders a div containing the label text" <|
                \_ ->
                    Choice.switch { checked = False, onToggle = (), label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "div", Selector.text "Notifications" ]
            , test "checked=True track has the brand fill" <|
                \_ ->
                    Choice.switch { checked = True, onToggle = (), label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-brand" ]
            , test "checked=False track has the off fill" <|
                \_ ->
                    Choice.switch { checked = False, onToggle = (), label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-subtle" ]
            , test "clicking the control fires the toggle msg" <|
                \_ ->
                    Choice.switch { checked = False, onToggle = "toggled", label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Event.simulate Event.click
                        |> Event.expect "toggled"
            ]
        , describe "style overrides"
            [ test "withCheckedStyle adds a class to the checked indicator" <|
                \_ ->
                    Choice.checkbox { checked = True, onToggle = (), label = "Check" }
                        |> Choice.withCheckedStyle (Config.addRaw "ring-override")
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "ring-override" ]
            , test "withUncheckedStyle adds a class to the unchecked indicator" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "Check" }
                        |> Choice.withUncheckedStyle (Config.addRaw "ring-override")
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "ring-override" ]
            , test "withStyle adds a class to the container div" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "Check" }
                        |> Choice.withStyle (Config.addRaw "container-override")
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.tag "div", Selector.class "container-override" ]
            ]

        -- A non-native (div-based) control owes assistive tech and the keyboard
        -- the semantics a native <input> provides for free: role, checked state,
        -- focusability, and Space/Enter activation.
        , describe "control semantics"
            [ test "checkbox carries role, aria-checked and tabindex" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.attribute (Html.Attributes.attribute "role" "checkbox")
                            , Selector.attribute (Html.Attributes.attribute "aria-checked" "false")
                            , Selector.attribute (Html.Attributes.tabindex 0)
                            ]
            , test "checked checkbox announces aria-checked=true" <|
                \_ ->
                    Choice.checkbox { checked = True, onToggle = (), label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Html.Attributes.attribute "aria-checked" "true") ]
            , test "radio carries role=radio" <|
                \_ ->
                    Choice.radio { checked = False, onSelect = (), label = "Option A" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.attribute (Html.Attributes.attribute "role" "radio") ]
            , test "switch carries role=switch and tabindex" <|
                \_ ->
                    Choice.switch { checked = False, onToggle = (), label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Query.has
                            [ Selector.attribute (Html.Attributes.attribute "role" "switch")
                            , Selector.attribute (Html.Attributes.tabindex 0)
                            ]
            , test "Space fires the toggle msg and preventDefaults (no page scroll)" <|
                \_ ->
                    Choice.checkbox { checked = False, onToggle = "toggled", label = "Check" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Event.simulate (Event.custom "keydown" (Encode.object [ ( "key", Encode.string " " ) ]))
                        |> Expect.all
                            [ Event.expect "toggled"
                            , Event.expectPreventDefault
                            ]
            , test "Enter fires the toggle msg on a switch" <|
                \_ ->
                    Choice.switch { checked = False, onToggle = "toggled", label = "Notifications" }
                        |> Choice.view
                        |> Query.fromHtml
                        |> Event.simulate (Event.custom "keydown" (Encode.object [ ( "key", Encode.string "Enter" ) ]))
                        |> Event.expect "toggled"
            ]
        ]
