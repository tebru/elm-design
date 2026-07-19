module Tebru.Component.ConfirmModal exposing
    ( ConfirmModal, default, view
    , withStyle, withConfirmStyle, withCancelStyle, withDisabled, dangerConfirm
    )

{-| ConfirmModal composes Modal + Button: a confirmation dialog with a titled,
dismissable header, a body paragraph, and a Cancel / Confirm action pair.

    ConfirmModal.default
        { isOpen = model.confirmOpen
        , title = "Delete group?"
        , body = "This cannot be undone."
        , confirmLabel = "Delete"
        , cancelLabel = "Cancel"
        , onConfirm = ConfirmDelete
        , onCancel = CancelDelete
        }
        |> ConfirmModal.dangerConfirm
        |> ConfirmModal.view

Built on the chrome-aware `Component.Modal`: the title renders in the Modal
header alongside an X dismiss (both fire `onCancel`), under a divider, in a
`max-w-md` panel. The body sits in the Modal body padding. Cancel and Confirm
sit in a `justify-between` action row inside the body — Cancel (ghost) on the
left, the confirm action on the right — mirroring the legacy `ActionRow.split`.

Headless and overridable:

  - `withStyle` overrides the inner Modal panel's Config.
  - `withConfirmStyle` / `withCancelStyle` override the respective button Config.
  - `dangerConfirm` is a preset that swaps the confirm button to the danger
    surface (for destructive actions like delete / leave).
  - `withDisabled` disables the confirm button (e.g. while a request is in
    flight, or until input is valid).


# Build & render

@docs ConfirmModal, default, view


# Style & state

@docs withStyle, withConfirmStyle, withCancelStyle, withDisabled, dangerConfirm

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Component.Button as Button
import Tebru.Component.Modal as Modal
import Tebru.Theme.Border as Border
import Tebru.Theme.Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type ConfirmModal msg
    = ConfirmModal
        { isOpen : Bool
        , title : String
        , body : String
        , confirmLabel : String
        , cancelLabel : String
        , onConfirm : msg
        , onCancel : msg
        , disabled : Bool
        , panelStyle : Config Standard -> Config Standard
        , confirmStyle : Config Standard -> Config Standard
        , cancelStyle : Config Standard -> Config Standard
        }


{-| Build a ConfirmModal from its required fields. The confirm button defaults to
the brand surface (a benign primary action); call `dangerConfirm` for destructive
actions. The cancel button defaults to a ghost (text-only) look.
-}
default :
    { isOpen : Bool
    , title : String
    , body : String
    , confirmLabel : String
    , cancelLabel : String
    , onConfirm : msg
    , onCancel : msg
    }
    -> ConfirmModal msg
default opts =
    ConfirmModal
        { isOpen = opts.isOpen
        , title = opts.title
        , body = opts.body
        , confirmLabel = opts.confirmLabel
        , cancelLabel = opts.cancelLabel
        , onConfirm = opts.onConfirm
        , onCancel = opts.onCancel
        , disabled = False
        , panelStyle = identity
        , confirmStyle = brandConfirmStyle
        , cancelStyle = ghostCancelStyle
        }


{-| Override the panel's Config (delegates to the inner Modal's `withStyle`).
-}
withStyle : (Config Standard -> Config Standard) -> ConfirmModal msg -> ConfirmModal msg
withStyle fn (ConfirmModal c) =
    ConfirmModal { c | panelStyle = c.panelStyle >> fn }


{-| Override the confirm button's Config, composing onto the current style.
-}
withConfirmStyle : (Config Standard -> Config Standard) -> ConfirmModal msg -> ConfirmModal msg
withConfirmStyle fn (ConfirmModal c) =
    ConfirmModal { c | confirmStyle = c.confirmStyle >> fn }


{-| Override the cancel button's Config, composing onto the current style.
-}
withCancelStyle : (Config Standard -> Config Standard) -> ConfirmModal msg -> ConfirmModal msg
withCancelStyle fn (ConfirmModal c) =
    ConfirmModal { c | cancelStyle = c.cancelStyle >> fn }


{-| Disable the confirm button (applies the HTML `disabled` attribute).
-}
withDisabled : Bool -> ConfirmModal msg -> ConfirmModal msg
withDisabled isDisabled (ConfirmModal c) =
    ConfirmModal { c | disabled = isDisabled }


{-| Preset: render the confirm button on the danger surface, for destructive
actions (delete group, leave group, remove member). Equivalent to the legacy
`Button.Danger` confirm variant. Composes onto the current confirm style like
every other modifier, so it is order-independent with `withConfirmStyle`.
-}
dangerConfirm : ConfirmModal msg -> ConfirmModal msg
dangerConfirm (ConfirmModal c) =
    ConfirmModal { c | confirmStyle = c.confirmStyle >> dangerConfirmStyle }


{-| Render the confirm modal.
-}
view : ConfirmModal msg -> Html msg
view (ConfirmModal c) =
    Modal.default
        { isOpen = c.isOpen
        , onClose = c.onCancel
        , content = renderContent (ConfirmModal c)
        }
        |> Modal.withTitle c.title
        |> Modal.withCloseButton
        |> Modal.withStyle c.panelStyle
        |> Modal.view


{-| The body paragraph + the Cancel / Confirm action row. The title and X live in
the Modal header; this is the Modal `content`, rendered inside the body padding.
-}
renderContent : ConfirmModal msg -> Html msg
renderContent (ConfirmModal c) =
    Layout.stack Lg
        [ Layout.box [ Html.text c.body ]
            |> Layout.withStyle bodyStyle
            |> Layout.view
        , Layout.row Sm
            [ Button.default c.cancelLabel
                |> Button.onClick c.onCancel
                |> Button.withStyle c.cancelStyle
                |> Button.view
            , Button.default c.confirmLabel
                |> Button.onClick c.onConfirm
                |> Button.withDisabled c.disabled
                |> Button.withStyle c.confirmStyle
                |> Button.view
            ]
            |> Layout.withStyle (Structure.withJustify Structure.JustifyBetween)
            |> Layout.view
        ]
        |> Layout.view


{-| Body copy: the legacy `Text.body` was base-size, normal-weight, default-color
text. The default surface text color already matches, so only the size is set.
-}
bodyStyle : Config Standard -> Config Standard
bodyStyle =
    Typography.withFontSize Typography.Base
        >> Typography.withFontWeight Typography.Normal
        >> Text.withText Text.Default


{-| Default confirm: the legacy `Button.Primary` — brand surface, inverse text.
-}
brandConfirmStyle : Config Standard -> Config Standard
brandConfirmStyle =
    Surface.withSurface Surface.Brand
        >> Text.withText Text.Inverse


{-| Danger confirm: the legacy `Button.Danger` — danger surface, inverse text.
-}
dangerConfirmStyle : Config Standard -> Config Standard
dangerConfirmStyle =
    Surface.withSurface Surface.Danger
        >> Text.withText Text.Inverse


{-| Cancel: the legacy `Button.Ghost` — text-only, no surface or visible border.
The base Button carries a card surface + hairline border, so both are cleared.
-}
ghostCancelStyle : Config Standard -> Config Standard
ghostCancelStyle =
    Tebru.Theme.Config.set "surface" "bg-transparent"
        >> Border.withBorder Border.Transparent
        >> Text.withText Text.Default
