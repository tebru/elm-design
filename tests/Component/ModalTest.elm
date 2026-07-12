module Component.ModalTest exposing (suite)

import Expect
import Html
import Tebru.Component.Modal as Modal
import Tebru.Theme.MaxWidth as MaxWidth
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Modal"
        [ test "when closed renders nothing" <|
            \_ ->
                Modal.default { isOpen = False, onClose = (), content = Html.text "Hello" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Hello" ]
        , test "when open renders content" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "Modal content" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Modal content" ]
        , test "when open renders the full-screen backdrop layer" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.classes [ "fixed", "inset-0", "z-40", "animate-backdrop-fade", "bg-surface-backdrop" ] ]
        , test "clicking the backdrop fires onClose" <|
            \_ ->
                Modal.default { isOpen = True, onClose = "closed", content = Html.text "Content" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "bg-surface-backdrop" ]
                    |> Event.simulate Event.click
                    |> Event.expect "closed"
        , test "the panel sits above the backdrop with the enter animation" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.has
                        [ Selector.classes [ "relative", "z-50", "animate-modal-enter" ] ]
        , test "the panel defaults to max-w-md w-full" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.classes [ "max-w-md", "w-full" ] ]
        , test "withMaxWidth swaps max-w-md for a larger named cap" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.withMaxWidth MaxWidth.Lg
                    |> Modal.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.classes [ "max-w-lg", "w-full" ] ]
                        , Query.hasNot [ Selector.class "max-w-md" ]
                        ]
        , test "withStyle overrides the panel surface" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.withStyle (Surface.withSurface Surface.Subtle)
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        , test "with no chrome the panel renders bare content (no header divider)" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "Bare" }
                    |> Modal.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Bare" ]
                        , Query.hasNot [ Selector.class "border-b" ]
                        , Query.hasNot [ Selector.class "border-t" ]
                        ]
        , test "withTitle renders a header title with a bottom divider" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.withTitle "My Title"
                    |> Modal.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "My Title" ]
                        , Query.has [ Selector.class "border-b" ]
                        ]
        , test "withCloseButton renders a dismiss glyph that fires onClose" <|
            \_ ->
                Modal.default { isOpen = True, onClose = "closed", content = Html.text "" }
                    |> Modal.withCloseButton
                    |> Modal.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.class "cursor-pointer" ]
                    |> Event.simulate Event.click
                    |> Event.expect "closed"
        , test "withDismiss renders the caller-supplied icon and fires onClose" <|
            \_ ->
                Modal.default { isOpen = True, onClose = "closed", content = Html.text "" }
                    |> Modal.withDismiss (Html.text "ICON")
                    |> Modal.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "ICON" ]
                        , \q ->
                            q
                                |> Query.find [ Selector.class "cursor-pointer" ]
                                |> Event.simulate Event.click
                                |> Event.expect "closed"
                        ]
        , test "withFooter renders a footer row with a top divider" <|
            \_ ->
                Modal.default { isOpen = True, onClose = (), content = Html.text "" }
                    |> Modal.withFooter (Html.text "Footer actions")
                    |> Modal.view
                    |> Query.fromHtml
                    |> Expect.all
                        [ Query.has [ Selector.text "Footer actions" ]
                        , Query.has [ Selector.class "border-t" ]
                        ]
        ]
