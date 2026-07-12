module Tebru.Component.SectionHeader exposing
    ( SectionHeader
    , default
    , view
    , withAction
    , withCompact
    , withCount
    , withIcon
    , withStyle
    )

{-| Headless SectionHeader primitive — a title row with optional leading icon,
optional muted count beside the title, and an optional trailing action slot.

    SectionHeader.default "Members"
        |> SectionHeader.withAction (Button.view addButton)
        |> SectionHeader.view

    SectionHeader.default "Due"
        |> SectionHeader.withCount 3
        |> SectionHeader.view

    SectionHeader.default "Needs you"
        |> SectionHeader.withIcon (Icon.view bellIcon)
        |> SectionHeader.withCount 2
        |> SectionHeader.withCompact Text.Muted
        |> SectionHeader.view

The title defaults to `text-sm`, `font-semibold`, `text-fg-default`. The count
always renders muted (`text-fg-muted`) regardless of the title color, while
inheriting the title's font-size/weight so it stays typographically subordinate
but aligned. `withCompact` swaps to the uppercase-ish section-label style
(`text-xs`, `font-bold`, `tracking-wide`) and lets the caller pick the title
color; the count stays muted. `withStyle` composes after the baked defaults and
after `withCompact`, so callers can override anything.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Box as Layout
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type SectionHeader msg
    = SectionHeader
        { title : String
        , icon : Maybe (Html msg)
        , count : Maybe Int
        , action : Maybe (Html msg)
        , style : Config Standard
        }


default : String -> SectionHeader msg
default title =
    SectionHeader
        { title = title
        , icon = Nothing
        , count = Nothing
        , action = Nothing
        , style = baseStyle
        }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Text.withText Text.Default
        |> Typography.withFontSize Typography.Sm
        |> Typography.withFontWeight Typography.Semibold


{-| Add a leading icon rendered before the title.
-}
withIcon : Html msg -> SectionHeader msg -> SectionHeader msg
withIcon icon (SectionHeader s) =
    SectionHeader { s | icon = Just icon }


{-| Add a muted count rendered beside the title.
-}
withCount : Int -> SectionHeader msg -> SectionHeader msg
withCount count (SectionHeader s) =
    SectionHeader { s | count = Just count }


{-| Add a trailing, right-aligned action slot.
-}
withAction : Html msg -> SectionHeader msg -> SectionHeader msg
withAction action (SectionHeader s) =
    SectionHeader { s | action = Just action }


{-| Swap to the compact "section label" style — `text-xs`, `font-bold`,
`tracking-wide`. The caller picks the title color (`Text.Muted` for the neutral
tone, or an app token via `Text.Custom` injected at the call site). The count
still forces `Text.Muted` so it stays subordinate to the title.
-}
withCompact : Text.Text Never -> SectionHeader msg -> SectionHeader msg
withCompact color (SectionHeader s) =
    SectionHeader
        { s
            | style =
                s.style
                    |> Typography.withFontSize Typography.Xs
                    |> Typography.withFontWeight Typography.Bold
                    |> Typography.withLetterSpacing Typography.TrackingWide
                    |> Text.withText color
        }


withStyle : (Config Standard -> Config Standard) -> SectionHeader msg -> SectionHeader msg
withStyle fn (SectionHeader s) =
    SectionHeader { s | style = fn s.style }


view : SectionHeader msg -> Html msg
view (SectionHeader s) =
    let
        titleGroup =
            Layout.row Sm
                (List.filterMap identity
                    [ s.icon
                    , Just (titleEl s.style s.title)
                    , Maybe.map (countEl s.style) s.count
                    ]
                )
                |> Layout.withStyle (Structure.withAlign Structure.AlignCenter)
                |> Layout.view
    in
    case s.action of
        Nothing ->
            Layout.row None [ titleGroup ] |> Layout.view

        Just action ->
            Layout.row None [ titleGroup, action ]
                |> Layout.withStyle (Structure.withAlign Structure.AlignCenter >> Structure.withJustify Structure.JustifyBetween)
                |> Layout.view


titleEl : Config Standard -> String -> Html msg
titleEl style title =
    Html.span (Html.Attributes.class (Config.toClasses style) :: Config.toStyleAttributes style) [ Html.text title ]


{-| Count node: inherits the title's font-size/weight (and any caller overrides)
but forces `Text.Muted` on top so it always renders lighter than the title.
-}
countEl : Config Standard -> Int -> Html msg
countEl style count =
    let
        mutedStyle =
            Text.withText Text.Muted style
    in
    Html.span (Html.Attributes.class (Config.toClasses mutedStyle) :: Config.toStyleAttributes mutedStyle) [ Html.text (String.fromInt count) ]
