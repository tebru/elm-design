module Layout.BoxTest exposing (suite)

import Expect
import Json.Decode
import Json.Encode as Encode
import Tebru.Box as Layout
import Tebru.Theme.Config as Config
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Layout"
        [ test "row is flex-row with gap" <|
            \_ -> Layout.toClasses (Layout.row Sm []) |> Expect.equal "flex-row flex gap-sm"
        , test "stack is flex-col with gap" <|
            \_ -> Layout.toClasses (Layout.stack Md []) |> Expect.equal "flex-col flex gap-md"
        , test "box has no flex direction" <|
            \_ -> Layout.toClasses (Layout.box []) |> Expect.equal ""
        , test "view defaults to a div" <|
            \_ -> Layout.row Sm [] |> Layout.view |> Query.fromHtml |> Query.has [ Selector.tag "div" ]

        -- Task 5: withStyle / withHoverStyle / withElement
        , test "withElement Nav renders a nav" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withElement Layout.Nav
                    |> Layout.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "nav" ]
        , test "withStyle composes a Config modifier onto the box" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withStyle (Tebru.Theme.Structure.withDisplay Tebru.Theme.Structure.Block)
                    |> Layout.toClasses
                    |> Expect.equal "flex-row block gap-sm"

        -- The constructor display class rides the Config keyed dict (same
        -- "display" key as Structure.withDisplay), so a later withDisplay
        -- REPLACES it — exactly one display class ever emits, instead of both
        -- (e.g. `flex` + `block`) with CSS source order deciding the winner.
        , test "withDisplay overrides the row constructor display (exactly one display class)" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withStyle (Tebru.Theme.Structure.withDisplay Tebru.Theme.Structure.Block)
                    |> Layout.toClasses
                    |> String.split " "
                    |> List.filter (\c -> List.member c [ "flex", "block", "grid", "inline-flex", "inline-block", "hidden" ])
                    |> Expect.equal [ "block" ]
        , test "withDisplay overrides the grid constructor display (exactly one display class)" <|
            \_ ->
                Layout.grid Sm []
                    |> Layout.withStyle (Tebru.Theme.Structure.withDisplay Tebru.Theme.Structure.Flex)
                    |> Layout.toClasses
                    |> String.split " "
                    |> List.filter (\c -> List.member c [ "flex", "block", "grid", "inline-flex", "inline-block", "hidden" ])
                    |> Expect.equal [ "flex" ]

        -- The constructor gap rides the Config keyed dict (same "gap" key as
        -- Spacing.withGap), so a later withGap OVERRIDES it — last-wins across
        -- both channels, never both gap classes with CSS source order deciding.
        , test "Spacing.withGap overrides the row constructor gap (exactly one gap class)" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withStyle (Spacing.withGap Lg)
                    |> Layout.toClasses
                    |> String.split " "
                    |> List.filter (String.startsWith "gap-")
                    |> Expect.equal [ "gap-lg" ]
        , test "Spacing.withGap overrides the grid constructor gap (exactly one gap class)" <|
            \_ ->
                Layout.grid Sm []
                    |> Layout.withStyle (Spacing.withGap Lg)
                    |> Layout.toClasses
                    |> String.split " "
                    |> List.filter (String.startsWith "gap-")
                    |> Expect.equal [ "gap-lg" ]

        -- Task 6: event modifiers
        , test "withOnClick wires a click handler" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnClick ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate Event.click
                    |> Event.expect ()
        , test "withOnKeyDown decodes the pressed key" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnKeyDown identity
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.custom "keydown" (Encode.object [ ( "key", Encode.string "Enter" ) ]))
                    |> Event.expect "Enter"
        , test "withOn reaches an arbitrary event" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOn "scroll" (Json.Decode.succeed ())
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.custom "scroll" (Encode.object []))
                    |> Event.expect ()

        -- THE FIREFOX DRAG LESSON: drag interactions MUST preventDefault on
        -- mousedown. Without it the browser starts a text selection and
        -- Firefox then stops firing mouseenter for the drag's duration,
        -- breaking drag-to-paint / move / resize in every consumer (Chrome is
        -- lenient; Firefox is not). These pins make that regression loud.
        , test "withOnMouseDownPreventDefault preventDefaults (Firefox drag-to-paint)" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnMouseDownPreventDefault ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate Event.mouseDown
                    |> Event.expectPreventDefault
        , test "withOnMouseDown is a plain listener (no preventDefault)" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnMouseDown ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate Event.mouseDown
                    |> Event.expectNotPreventDefault
        , test "withOnMouseUp does not preventDefault (proves the flag is observable, not always-on)" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnMouseUp ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate Event.mouseUp
                    |> Event.expectNotPreventDefault
        , test "withOnMouseDownStopPropagation stops propagation but does not preventDefault" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnMouseDownStopPropagation ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate Event.mouseDown
                    |> Expect.all [ Event.expectStopPropagation, Event.expectNotPreventDefault ]
        , test "withOnContextMenuPreventDefault suppresses the native context menu" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnContextMenuPreventDefault ()
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.custom "contextmenu" (Encode.object []))
                    |> Event.expectPreventDefault
        , test "withOnKeyDownPreventDefault preventDefaults the keypress" <|
            \_ ->
                Layout.row Sm []
                    |> Layout.withOnKeyDownPreventDefault identity
                    |> Layout.view
                    |> Query.fromHtml
                    |> Event.simulate (Event.custom "keydown" (Encode.object [ ( "key", Encode.string "Enter" ) ]))
                    |> Event.expectPreventDefault

        -- Task 7: withGridCols (Grid-only, phantom-gated)
        , test "grid with cols emits responsive grid-cols classes" <|
            \_ ->
                Layout.grid None []
                    |> Layout.withGridCols { sm = 1, md = 2, lg = 3, xl = 4 }
                    |> Layout.toClasses
                    |> Expect.equal "grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 grid"
        , test "grid emits its gap class" <|
            \_ -> Layout.toClasses (Layout.grid Lg []) |> Expect.equal "grid gap-lg"
        , test "grid with None gap emits no gap class" <|
            \_ -> Layout.toClasses (Layout.grid None []) |> Expect.equal "grid"

        -- withInlineStyle routes through the Config styles channel (keyed, last-wins)
        , test "withInlineStyle renders every distinct property as an inline style" <|
            \_ ->
                Layout.box []
                    |> Layout.withInlineStyle [ ( "top", "437px" ), ( "height", "58px" ), ( "left", "0" ), ( "right", "0" ) ]
                    |> Layout.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.style "top" "437px"
                        , Selector.style "height" "58px"
                        , Selector.style "left" "0"
                        , Selector.style "right" "0"
                        ]
        , test "a later withInlineStyle wins over an earlier one for the same property" <|
            \_ ->
                Layout.box []
                    |> Layout.withInlineStyle [ ( "top", "10px" ) ]
                    |> Layout.withInlineStyle [ ( "top", "20px" ) ]
                    |> Layout.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.style "top" "20px" ]
                        , Query.hasNot [ Selector.style "top" "10px" ]
                        ]
        , test "withInlineStyle wins over an earlier Config.setStyle for the same property" <|
            \_ ->
                Layout.box []
                    |> Layout.withStyle (Config.setStyle "top" "10px")
                    |> Layout.withInlineStyle [ ( "top", "20px" ) ]
                    |> Layout.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.style "top" "20px" ]
                        , Query.hasNot [ Selector.style "top" "10px" ]
                        ]
        , test "a later Config.setStyle wins over an earlier withInlineStyle for the same property" <|
            \_ ->
                Layout.box []
                    |> Layout.withInlineStyle [ ( "top", "10px" ) ]
                    |> Layout.withStyle (Config.setStyle "top" "20px")
                    |> Layout.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.style "top" "20px" ]
                        , Query.hasNot [ Selector.style "top" "10px" ]
                        ]
        , test "withInlineStyle merges properties across calls" <|
            \_ ->
                Layout.box []
                    |> Layout.withInlineStyle [ ( "top", "10px" ) ]
                    |> Layout.withInlineStyle [ ( "height", "20px" ) ]
                    |> Layout.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.style "top" "10px", Selector.style "height" "20px" ]
        ]
