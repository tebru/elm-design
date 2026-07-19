module Tebru.Component.Card exposing (Card, default, view, withFooter, withHeader, withHoverStyle, withHoverable, withStyle)

{-| Headless Card primitive — a styled surface container with an optional
header/footer + hover treatment.

    -- Basic card
    Card.default [ someContent ]
        |> Card.withStyle (Surface.withSurface Surface.Subtle)
        |> Card.view

    -- Section card with title + footer actions
    Card.default [ picker ]
        |> Card.withHeader { title = "Submit your availability", subtitle = Just "3 of 6 have submitted" }
        |> Card.withFooter actionsRow
        |> Card.view

The default reproduces the legacy `Ui.Card`: card surface, a hairline border,
large radius, large padding, and a subtle resting shadow. `withHoverStyle` is
the standard hover channel; `withHoverable` is the preset built on it (border
darken + soft lift shadow). No variant enums — surface, spacing, and the rest
are overridable via `withStyle`.

-}

import Html exposing (Html, text)
import Tebru.Box as Layout
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space as Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


{-| Soft card-lift shadow used on hover. A bespoke one-off value (alpha 0.04, not
the theme's `shadow-md`), so it stays raw behind this named constant (bespoke).
-}
liftShadow : Config tag -> Config tag
liftShadow =
    Config.addRaw "shadow-[0_4px_14px_rgba(0,0,0,0.04)]"


type Card msg
    = Card
        { children : List (Html msg)
        , header : Maybe { title : String, subtitle : Maybe String }
        , footer : Maybe (Html msg)
        , hoverStyle : Maybe (Config Hover -> Config Hover)
        , style : Config Standard -> Config Standard
        }


{-| Card with default surface, hairline border, large radius, large padding,
and a subtle resting shadow. Override any part via `withStyle`.
-}
default : List (Html msg) -> Card msg
default children =
    Card
        { children = children
        , header = Nothing
        , footer = Nothing
        , hoverStyle = Nothing
        , style = baseStyle
        }


{-| A MODIFIER, not a Config value: `view` applies it (plus any `withStyle`
additions) on top of the Box constructor's config, so the constructor-seeded
gap survives and stays last-wins overridable.
-}
baseStyle : Config Standard -> Config Standard
baseStyle =
    Surface.withSurface Surface.Card
        >> Border.withBorder Border.Default
        -- Theme.Border emits color only; add the 1px width utility.
        >> Structure.withBorderWidth Structure.BorderThin
        >> Radius.withRadius Radius.Lg
        >> Spacing.withPadding (Spacing.all Lg)
        -- Subtle resting shadow (legacy ShadowSubtle); Elevation.Xs resolves to the same value.
        >> Elevation.withElevation Elevation.Xs


{-| Add a title + optional subtitle row at the top of the card.
-}
withHeader : { title : String, subtitle : Maybe String } -> Card msg -> Card msg
withHeader header (Card c) =
    Card { c | header = Just header }


{-| Add a footer row separated by a top divider, matching the modal footers.
-}
withFooter : Html msg -> Card msg -> Card msg
withFooter actions (Card c) =
    Card { c | footer = Just actions }


{-| Modify the card's hover style — the standard hover channel every
hover-capable component exposes. Composes across calls.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Card msg -> Card msg
withHoverStyle fn (Card c) =
    Card { c | hoverStyle = Just (Maybe.withDefault identity c.hoverStyle >> fn) }


{-| Preset built on the hover channel: the legacy hover treatment (darkened
border + soft lift shadow). `False` clears the whole hover channel.
-}
withHoverable : Bool -> Card msg -> Card msg
withHoverable hoverable (Card c) =
    if hoverable then
        withHoverStyle (Border.withBorder Border.Hover >> liftShadow) (Card c)

    else
        Card { c | hoverStyle = Nothing }


withStyle : (Config Standard -> Config Standard) -> Card msg -> Card msg
withStyle fn (Card c) =
    Card { c | style = c.style >> fn }


view : Card msg -> Html msg
view (Card c) =
    let
        headerEl =
            case c.header of
                Just { title, subtitle } ->
                    [ Layout.stack None
                        [ Layout.box [ text title ]
                            |> Layout.withStyle (Typography.withFontSize Typography.Base >> Typography.withFontWeight Typography.Semibold >> Text.withText Text.Default)
                            |> Layout.view
                        , case subtitle of
                            Just s ->
                                Layout.box [ text s ]
                                    |> Layout.withStyle (Typography.withFontSize Typography.Xs >> Text.withText Text.Muted)
                                    |> Layout.view

                            Nothing ->
                                text ""
                        ]
                        |> Layout.withStyle (Spacing.withGap Space.Xxs)
                        |> Layout.view
                    ]

                Nothing ->
                    []

        footerEl =
            case c.footer of
                Just actions ->
                    [ Layout.box [ actions ]
                        |> Layout.withStyle
                            (Border.withBorder Border.Divider
                                >> Structure.withBorderSide Space.Top
                                >> Spacing.withPadding (Spacing.xy None Lg)
                            )
                        |> Layout.view
                    ]

                Nothing ->
                    []

        allChildren =
            headerEl ++ c.children ++ footerEl

        gap =
            if List.length allChildren > 1 then
                Xl

            else
                None

        hoverMod box_ =
            case c.hoverStyle of
                Just hoverStyle ->
                    box_ |> Layout.withHoverStyle hoverStyle

                Nothing ->
                    box_
    in
    Layout.stack gap allChildren
        |> Layout.withElement Layout.Section
        -- Compose (never replace): the stack constructor seeded the gap into
        -- this config, so a wholesale `always …` here would drop the gap class.
        |> Layout.withStyle c.style
        |> hoverMod
        |> Layout.view
