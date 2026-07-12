module Tebru.Component.Notification exposing (Notification, banner, toast, toastOverlay, view, withIcon, withStyle)

{-| Headless Notification primitive — consolidates Banner and Toast.

    Notification.banner
        { content = Html.text "Settings saved."
        , onDismiss = Just Dismiss
        }
        |> Notification.view

    Notification.toast
        { content = Html.text "Error occurred."
        , onDismiss = Nothing
        }
        |> Notification.withStyle (Surface.withSurface Surface.Danger)
        |> Notification.view

No variant enums for level coloring — use `withStyle` to apply e.g. `Surface.withSurface Surface.Warning`.
`toastOverlay` follows the same rule: the caller supplies the icon geometry and the level-color modifier.

-}

import Html exposing (Html)
import Svg
import Tebru.Box as Layout
import Tebru.Icon as Icon
import Tebru.Icon.Geometry as Geometry
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text


type NotificationKind
    = Banner
    | Toast


type Notification msg
    = Notification
        { kind : NotificationKind
        , content : Html msg
        , icon : Maybe (Html msg)
        , onDismiss : Maybe msg
        , style : Config Standard -> Config Standard
        }


{-| A full-width banner notification. Default neutral styling.
Use `withStyle` for level coloring (Surface.Warning, Surface.Danger, etc.).
-}
banner : { content : Html msg, onDismiss : Maybe msg } -> Notification msg
banner opts =
    Notification
        { kind = Banner
        , content = opts.content
        , icon = Nothing
        , onDismiss = opts.onDismiss
        , style = bannerBaseStyle
        }


{-| A compact toast notification. Default neutral styling.
Use `withStyle` for level coloring (Surface.Warning, Surface.Danger, etc.).
-}
toast : { content : Html msg, onDismiss : Maybe msg } -> Notification msg
toast opts =
    Notification
        { kind = Toast
        , content = opts.content
        , icon = Nothing
        , onDismiss = opts.onDismiss
        , style = toastBaseStyle
        }


{-| The base styles are MODIFIERS, not Config values: `view` applies them (plus
any `withStyle` additions) on top of the Box constructor's config, so the
constructor-seeded gap survives and stays last-wins overridable.
-}
bannerBaseStyle : Config Standard -> Config Standard
bannerBaseStyle =
    Surface.withSurface Surface.Subtle
        >> Border.withBorder Border.Default
        >> Spacing.withPadding (Spacing.xy Md Sm)


toastBaseStyle : Config Standard -> Config Standard
toastBaseStyle =
    Surface.withSurface Surface.Inverse
        >> Text.withText Text.Inverse
        >> Radius.withRadius Radius.Lg
        >> Spacing.withPadding (Spacing.xy Md Sm)


{-| Add an optional leading icon, rendered in a row before the content.
Generic/headless — the caller supplies the icon (e.g. a status check/info/alert).
Defaults to no icon.
-}
withIcon : Html msg -> Notification msg -> Notification msg
withIcon icon (Notification n) =
    Notification { n | icon = Just icon }


withStyle : (Config Standard -> Config Standard) -> Notification msg -> Notification msg
withStyle fn (Notification n) =
    Notification { n | style = n.style >> fn }


view : Notification msg -> Html msg
view (Notification n) =
    let
        leadingIcon =
            case n.icon of
                Just icon ->
                    [ icon ]

                Nothing ->
                    []

        trailing =
            case n.onDismiss of
                Just msg ->
                    [ dismissButton msg ]

                Nothing ->
                    []

        gap =
            -- Old Ui.Banner spaced its leading icon / message / actions with
            -- `InlineL` (gap-4 = 1rem = Lg); old toast (Ui.Alert.toastAlert)
            -- spaced body / dismiss with `Md` (gap-md = 0.75rem). Reproduce
            -- each kind's gap rather than a single flat Sm.
            case n.kind of
                Banner ->
                    Lg

                Toast ->
                    Md
    in
    Layout.row gap
        (leadingIcon ++ (n.content :: trailing))
        -- Compose (never replace): the row constructor seeded the gap into
        -- this config, so a wholesale `\_ -> …` here would drop the gap class.
        |> Layout.withStyle n.style
        |> Layout.view


{-| Dismiss control — reproduces the old `Ui.Alert.toastAlert` dismiss: a muted
"x" glyph with snug `p-xs` padding and a pointer cursor.
-}
dismissButton : msg -> Html msg
dismissButton msg =
    Layout.box
        [ Icon.default Geometry.x |> Icon.view ]
        |> Layout.withStyle
            (Text.withText Text.Muted
                >> Spacing.withPadding (Spacing.all Xs)
                >> Structure.withCursor Structure.CursorPointer
            )
        |> Layout.withOnClick msg
        |> Layout.view


{-| A fully-positioned toast: fixed at top-center, slides down. No variant enum
for level coloring — the caller supplies the leading icon geometry and a style
modifier for the level colors; this owns layout, chrome, positioning and the
entry animation. The `style` modifier composes on top of the chrome, so it can
also override chrome channels (radius, elevation, …) if it needs to.

    Notification.toastOverlay
        { icon = Geometry.circleCheck
        , style = Surface.withSurface Surface.Success >> Text.withText Text.Success >> Border.withBorder Border.Success
        , content = Html.text "Saved."
        , onDismiss = Dismiss
        }

-}
toastOverlay :
    { icon : List (Svg.Svg msg)
    , style : Config Standard -> Config Standard
    , content : Html msg
    , onDismiss : msg
    }
    -> Html msg
toastOverlay opts =
    let
        body =
            Layout.row Md
                [ Icon.default opts.icon |> Icon.view
                , Layout.box [ opts.content ] |> Layout.view
                ]
                |> Layout.withStyle (Structure.withAlign Structure.AlignCenter)
                |> Layout.view

        card =
            toast { content = body, onDismiss = Just opts.onDismiss }
                |> withStyle
                    (\_ ->
                        Config.default
                            |> Structure.withBorderWidth Structure.BorderThin
                            |> Radius.withRadius Radius.Lg
                            |> Spacing.withPadding (Spacing.xy Lg Md)
                            -- Re-seed the toast row gap: this wholesale `\_ ->` replacement
                            -- discards the constructor-seeded `gap-md` along with the base style.
                            |> Spacing.withGap Md
                            |> Structure.withAlign Structure.AlignCenter
                            |> Elevation.withElevation Elevation.Xl
                            |> Structure.withPointerEvents Structure.PointerAuto
                            |> opts.style
                    )
                |> view
    in
    Layout.row None [ card ]
        |> Layout.withStyle
            (Structure.withJustify Structure.JustifyCenter
                >> Spacing.withPadding (Spacing.all Lg)
                >> Structure.withPosition Structure.Fixed
                >> edgePins
                >> Structure.withZ Structure.ZModal
                >> slideDown
                >> Structure.withPointerEvents Structure.PointerNone
            )
        |> Layout.view


{-| Pin the fixed container to the top edges (`top-0 left-0 right-0`). No Theme
token models individual edge offsets, so this is library-internal bespoke styling.
-}
edgePins : Config tag -> Config tag
edgePins =
    Config.addRaw "top-0 left-0 right-0"


{-| Toast entry animation (`animate-slide-down`). Keyframe utility, no token
channel — library-internal bespoke styling.
-}
slideDown : Config tag -> Config tag
slideDown =
    Config.addRaw "animate-slide-down"
