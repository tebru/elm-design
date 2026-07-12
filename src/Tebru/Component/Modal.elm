module Tebru.Component.Modal exposing
    ( Modal, default, view
    , withStyle
    , withTitle, withDismiss, withCloseButton, withFooter, withMaxWidth
    )

{-| Headless Modal primitive — backdrop + centered panel, with optional chrome.

    Modal.default { isOpen = True, onClose = CloseModal, content = Html.text "Hello" }
        |> Modal.view

When closed, renders `Html.text ""`. When open, renders a full-screen container with
two siblings: a backdrop layer (clicking it fires `onClose`) and a centered panel
holding `content`. `withStyle` overrides the panel's Config.

No variant enums — surface, radius, elevation etc. are all overridable via `withStyle`.

By **default the panel has no chrome** — just `content`. Optional, additive chrome:

  - `withTitle` — a header title row.
  - `withDismiss` / `withCloseButton` — a close (X) button in the header that fires
    `onClose`. `withDismiss` takes a caller-supplied icon (`Html msg`); `withCloseButton`
    renders a plain `×` glyph so consumers needn't depend on an icon set.
  - `withFooter` — a footer row, typically holding action buttons.
  - `withMaxWidth` — cap the panel width to a named scale (`MaxWidth`).

A divider is drawn under the header whenever a title or dismiss button is present.


# Build & render

@docs Modal, default, view


# Style

@docs withStyle


# Optional chrome

@docs withTitle, withDismiss, withCloseButton, withFooter, withMaxWidth

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Component.Overlay as Overlay
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.MaxWidth as MaxWidth
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space as Space
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


{-| Default panel max width — the `Md` rung of the shared `Theme.MaxWidth` scale.
-}
maxWidthDefault : Config Standard -> Config Standard
maxWidthDefault =
    MaxWidth.withMaxWidth MaxWidth.Md


type Modal msg
    = Modal
        { isOpen : Bool
        , onClose : msg
        , content : Html msg
        , panelStyle : Config Standard
        , title : Maybe String
        , dismiss : Maybe (Html msg)
        , footer : Maybe (Html msg)
        , maxWidth : Maybe MaxWidth.MaxWidth
        }


{-| Build a Modal from its required fields. No chrome by default.
-}
default : { isOpen : Bool, onClose : msg, content : Html msg } -> Modal msg
default opts =
    Modal
        { isOpen = opts.isOpen
        , onClose = opts.onClose
        , content = opts.content
        , panelStyle = basePanelStyle
        , title = Nothing
        , dismiss = Nothing
        , footer = Nothing
        , maxWidth = Nothing
        }


{-| Override the panel's Config.
-}
withStyle : (Config Standard -> Config Standard) -> Modal msg -> Modal msg
withStyle fn (Modal m) =
    Modal { m | panelStyle = fn m.panelStyle }


{-| Render a header title row.
-}
withTitle : String -> Modal msg -> Modal msg
withTitle title (Modal m) =
    Modal { m | title = Just title }


{-| Render a dismiss (X) button in the header using the caller-supplied icon.
Clicking it fires `onClose`. Stays generic — the consumer decides the icon.
-}
withDismiss : Html msg -> Modal msg -> Modal msg
withDismiss icon (Modal m) =
    Modal { m | dismiss = Just icon }


{-| Render a dismiss button using a plain `×` glyph — no icon-set dependency.
-}
withCloseButton : Modal msg -> Modal msg
withCloseButton (Modal m) =
    Modal { m | dismiss = Just (Html.text "×") }


{-| Render a footer row, typically for action buttons.
-}
withFooter : Html msg -> Modal msg -> Modal msg
withFooter footer (Modal m) =
    Modal { m | footer = Just footer }


{-| Cap the panel to a named max-width scale (`MaxWidth`).
-}
withMaxWidth : MaxWidth.MaxWidth -> Modal msg -> Modal msg
withMaxWidth mw (Modal m) =
    Modal { m | maxWidth = Just mw }


{-| Render the modal. When closed, returns `Html.text ""`.
-}
view : Modal msg -> Html msg
view (Modal m) =
    if not m.isOpen then
        Html.text ""

    else
        let
            panel =
                Layout.box [ renderPanel (Modal m) ]
                    |> Layout.withStyle (\_ -> m.panelStyle)
                    |> Layout.withStyle Overlay.panelChrome
                    |> Layout.withStyle (widthStyle m.maxWidth)
                    |> Layout.view
        in
        Overlay.default { isOpen = m.isOpen, onClose = m.onClose, content = panel }
            |> Overlay.view


{-| Lay the optional chrome (header / content / footer) into a vertical stack.
With no chrome, the panel is just `content` — identical to the original behavior.
-}
renderPanel : Modal msg -> Html msg
renderPanel (Modal m) =
    let
        header =
            renderHeader (Modal m)

        -- Body gets the old PadXl (p-6); header/footer carry their own padding so the
        -- sections butt together with no gap, divided only by their borders.
        body =
            Layout.box [ m.content ]
                |> Layout.withStyle bodyStyle
                |> Layout.view

        footer =
            m.footer
                |> Maybe.map
                    (\f ->
                        Layout.box [ f ]
                            |> Layout.withStyle footerStyle
                            |> Layout.view
                    )

        sections =
            List.filterMap identity
                [ header
                , Just body
                , footer
                ]
    in
    case ( header, m.footer ) of
        ( Nothing, Nothing ) ->
            -- No chrome: keep the bare-content default untouched.
            m.content

        _ ->
            -- Old stack was StackNone (no gap) — sections are separated by their own
            -- borders/padding, not a flex gap.
            Layout.stack Space.None sections
                |> Layout.view


{-| Header is present only when a title or dismiss button was supplied. It spaces the
title and dismiss to opposite ends and draws a divider underneath.
-}
renderHeader : Modal msg -> Maybe (Html msg)
renderHeader (Modal m) =
    case ( m.title, m.dismiss ) of
        ( Nothing, Nothing ) ->
            Nothing

        _ ->
            let
                titleEl =
                    m.title
                        |> Maybe.map
                            (\t ->
                                Layout.box [ Html.text t ]
                                    |> Layout.withStyle (Typography.withFontSize Typography.Lg >> Typography.withFontWeight Typography.Semibold)
                                    |> Layout.view
                            )
                        |> Maybe.withDefault (Html.text "")

                dismissEl =
                    m.dismiss
                        |> Maybe.map
                            (\icon ->
                                Layout.box [ icon ]
                                    |> Layout.withOnClick m.onClose
                                    |> Layout.withStyle (Structure.withCursor Structure.CursorPointer)
                                    |> Layout.view
                            )
                        |> Maybe.withDefault (Html.text "")
            in
            Layout.box
                [ Layout.row Space.Sm [ titleEl, dismissEl ]
                    |> Layout.withStyle (Structure.withJustify Structure.JustifyBetween >> Structure.withAlign Structure.AlignCenter)
                    |> Layout.view
                ]
                |> Layout.withStyle headerStyle
                |> Layout.view
                |> Just


{-| Width sizing. With no override the panel is `max-w-md w-full`; a named override
swaps `max-w-md` for the chosen scale (still `w-full` so it fills up to it).
-}
widthStyle : Maybe MaxWidth.MaxWidth -> Config Standard -> Config Standard
widthStyle maybeMax =
    case maybeMax of
        Just mw ->
            MaxWidth.withMaxWidth mw >> Structure.withWidth Structure.SizeFull

        Nothing ->
            maxWidthDefault >> Structure.withWidth Structure.SizeFull


{-| Header row: old used PadLg (p-4) all round plus a bottom divider. Theme.Border emits
only a color class, so pair Divider with the `border-b` width utility.
-}
headerStyle : Config Standard -> Config Standard
headerStyle =
    Spacing.withPadding (Spacing.all Space.Lg)
        >> Border.withBorder Border.Divider
        >> Structure.withBorderSide Space.Bottom


{-| Body: old used PadXl (p-6).
-}
bodyStyle : Config Standard -> Config Standard
bodyStyle =
    Spacing.withPadding (Spacing.all Space.Xl)


{-| Footer: old used PadLg (p-4), a top divider and muted text.
-}
footerStyle : Config Standard -> Config Standard
footerStyle =
    Spacing.withPadding (Spacing.all Space.Lg)
        >> Border.withBorder Border.Divider
        >> Structure.withBorderSide Space.Top
        >> Text.withText Text.Muted


{-| The panel surface. The old panel had no border and no padding of its own (each
section pads itself), a subtle two-layer shadow, the card surface and a large radius.
-}
basePanelStyle : Config Standard
basePanelStyle =
    Config.default
        |> Surface.withSurface Surface.Card
        |> Radius.withRadius Radius.Lg
        |> Elevation.withElevation Elevation.Xs
