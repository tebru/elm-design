module Component.ConfirmModalTest exposing (suite)

import Tebru.Component.ConfirmModal as ConfirmModal
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.ConfirmModal"
        [ test "when closed renders nothing" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = False
                    , title = "Delete item?"
                    , body = "This cannot be undone."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.hasNot [ Selector.text "Delete item?" ]
        , test "when open renders title" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "This cannot be undone."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Delete item?" ]
        , test "when open renders body" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "This cannot be undone."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "This cannot be undone." ]
        , test "when open renders confirm button" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "This cannot be undone."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Delete" ]
        , test "when open renders cancel button" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "This cannot be undone."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Cancel" ]
        , test "clicking confirm fires onConfirm" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "Body text."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = "confirmed"
                    , onCancel = "cancelled"
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "button", Selector.containing [ Selector.text "Delete" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect "confirmed"
        , test "clicking cancel fires onCancel" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Delete item?"
                    , body = "Body text."
                    , confirmLabel = "Delete"
                    , cancelLabel = "Cancel"
                    , onConfirm = "confirmed"
                    , onCancel = "cancelled"
                    }
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "button", Selector.containing [ Selector.text "Cancel" ] ]
                    |> Event.simulate Event.click
                    |> Event.expect "cancelled"
        , test "withStyle overrides the panel surface" <|
            \_ ->
                ConfirmModal.default
                    { isOpen = True
                    , title = "Title"
                    , body = "Body"
                    , confirmLabel = "OK"
                    , cancelLabel = "Cancel"
                    , onConfirm = ()
                    , onCancel = ()
                    }
                    |> ConfirmModal.withStyle (Surface.withSurface Surface.Subtle)
                    |> ConfirmModal.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "bg-surface-subtle" ]
        ]
