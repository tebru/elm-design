module Tebru.Component.IconText exposing
    ( IconText
    , default
    , view
    , withInlineSuffix
    , withLeading
    , withRenderer
    , withSpacing
    , withStyle
    , withSubtitle
    , withSubtitleHtml
    , withTruncate
    )

{-| Headless IconText primitive — a leading element (icon, avatar, chip) plus a
primary text line, with optional secondary line, inline suffix, and truncation.

    -- Simple icon + label (back-compatible shorthand)
    IconText.default { icon = Icon.view myIcon, label = "Settings" }
        |> IconText.view

    -- Leading + truncating text inside a flex row
    IconText.default { icon = chip, label = longTitle }
        |> IconText.withTruncate
        |> IconText.view

    -- Two-line: title above, muted small subtitle below
    IconText.default { icon = chip, label = eventTitle }
        |> IconText.withSubtitle "Cello Quintet · Henry's place"
        |> IconText.withTruncate
        |> IconText.view

`withTruncate` enables ellipsis on both lines AND adds the
`flex-grow: 1 / min-width: 0` content wrapper required for truncation
inside a flex container.

-}

import Html exposing (Html, text)
import Tebru.Box as Layout
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type IconText msg
    = IconText
        { label : String
        , leading : Maybe (Html msg)
        , subtitle : Maybe (Subtitle msg)
        , inlineSuffix : Maybe (Html msg)
        , renderer : String -> Html msg
        , spacing : Space
        , style : Config Standard
        , truncate : Bool
        }


{-| Subtitle slot: either a plain string (rendered with the standard
muted-small style) or pre-built HTML (when the subtitle needs links / chips).
-}
type Subtitle msg
    = SubtitleText String
    | SubtitleHtml (Html msg)


{-| Create an IconText from a leading element and a label. The `icon` field
is the leading slot (icon, avatar, chip); pass any rendered `Html`.
-}
default : { icon : Html msg, label : String } -> IconText msg
default opts =
    IconText
        { label = opts.label
        , leading = Just opts.icon
        , subtitle = Nothing
        , inlineSuffix = Nothing
        , renderer = text
        , spacing = Md
        , style = Config.default
        , truncate = False
        }


{-| Set the text renderer for the primary label (e.g. a body-text helper that
applies type styling). Defaults to a plain text node.
-}
withRenderer : (String -> Html msg) -> IconText msg -> IconText msg
withRenderer renderer (IconText config) =
    IconText { config | renderer = renderer }


{-| Replace the leading element (icon, avatar, chip).
-}
withLeading : Html msg -> IconText msg -> IconText msg
withLeading html (IconText config) =
    IconText { config | leading = Just html }


{-| Modify the style config applied to the primary label node.
-}
withStyle : (Config Standard -> Config Standard) -> IconText msg -> IconText msg
withStyle fn (IconText config) =
    IconText { config | style = fn config.style }


{-| Override the inline gap between the leading element and the text content.
Defaults to `Md` (0.75rem).
-}
withSpacing : Space -> IconText msg -> IconText msg
withSpacing spacing (IconText config) =
    IconText { config | spacing = spacing }


{-| Add a secondary line rendered in muted small type below the main text.
Standard "list row" pattern.
-}
withSubtitle : String -> IconText msg -> IconText msg
withSubtitle subtitle (IconText config) =
    IconText { config | subtitle = Just (SubtitleText subtitle) }


{-| Add a secondary line that's already-rendered HTML (e.g. text containing
inline links). The styling is the caller's responsibility — the styled
muted-small wrapper that `withSubtitle` provides is NOT applied.
-}
withSubtitleHtml : Html msg -> IconText msg -> IconText msg
withSubtitleHtml html (IconText config) =
    IconText { config | subtitle = Just (SubtitleHtml html) }


{-| Enable ellipsis truncation. Applies to both title and subtitle and adds
`grow / min-w-0` to the content wrapper so it can shrink inside a flex
container (required for truncation to actually trigger).
-}
withTruncate : IconText msg -> IconText msg
withTruncate (IconText config) =
    IconText { config | truncate = True }


{-| Render a small element to the right of the main text on the same line
("(you)" muted note, a role chip, a small badge). Distinct from
`withSubtitle` (rendered below the title).
-}
withInlineSuffix : Html msg -> IconText msg -> IconText msg
withInlineSuffix html (IconText config) =
    IconText { config | inlineSuffix = Just html }


view : IconText msg -> Html msg
view (IconText config) =
    let
        labelStyle =
            config.style |> applyIf config.truncate (Typography.withTextOverflow Typography.Truncate)

        titleNode =
            Html.span (Config.toAttributes labelStyle Nothing) [ config.renderer config.label ]

        titleEl =
            case config.inlineSuffix of
                Just suffix ->
                    Layout.row Sm [ titleNode, suffix ]
                        |> Layout.withStyle (Structure.withAlign Structure.AlignCenter)
                        |> Layout.view

                Nothing ->
                    titleNode

        subtitleEl s =
            Layout.box [ text s ]
                |> Layout.withElement Layout.Span
                |> Layout.withStyle
                    (Typography.withFontSize Typography.Xs
                        >> Typography.withFontWeight Typography.Normal
                        >> Text.withText Text.Muted
                    )
                |> applyIf config.truncate (Layout.withStyle (Typography.withTextOverflow Typography.Truncate))
                |> Layout.view

        wrapForFlex =
            Structure.withGrow True >> Structure.withMinWidth Structure.SizeZero

        contentNode =
            case config.subtitle of
                Just (SubtitleText s) ->
                    Layout.stack Xs [ titleEl, subtitleEl s ]
                        |> Layout.withStyle wrapForFlex
                        |> Layout.view

                Just (SubtitleHtml html) ->
                    Layout.stack Xs [ titleEl, html ]
                        |> Layout.withStyle wrapForFlex
                        |> Layout.view

                Nothing ->
                    if config.truncate then
                        Layout.box [ titleEl ]
                            |> Layout.withStyle wrapForFlex
                            |> Layout.view

                    else
                        titleEl
    in
    case config.leading of
        Just leadingHtml ->
            Layout.row config.spacing
                [ Layout.box [ leadingHtml ]
                    |> Layout.withStyle (Structure.withShrink False)
                    |> Layout.view
                , contentNode
                ]
                |> Layout.withStyle (Structure.withAlign Structure.AlignCenter)
                |> Layout.view

        Nothing ->
            contentNode


applyIf : Bool -> (a -> a) -> a -> a
applyIf cond fn value =
    if cond then
        fn value

    else
        value
