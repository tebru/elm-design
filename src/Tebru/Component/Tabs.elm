module Tebru.Component.Tabs exposing
    ( ActiveIndicator(..)
    , Tabs
    , default
    , detailed
    , view
    , withActiveIndicator
    , withActiveStyle
    , withBadgeStyle
    , withHoverStyle
    , withInactiveStyle
    , withStyle
    )

{-| Headless Tabs primitive.

    Tabs.default { tabs = [ { label = "Overview", onSelect = SelectTab 0 }, { label = "Members", onSelect = SelectTab 1 } ], active = 0 }
        |> Tabs.view

Each tab may carry an optional trailing badge (e.g. a count) rendered after the
label. The simple `default` constructor takes badge-less `{ label, onSelect }`
records; `detailed` takes `{ label, onSelect, badge }` records where `badge` is
an optional `Html msg`.

The active indicator is selectable — `Underline` (the default, a 1px sage bottom
border under the active tab, matching the original group-page tab strip) or
`Pill` (an accented surface behind the active tab). Choose it with
`withActiveIndicator`.

No closed product styling — defaults come from `Theme.*` and are overridable via
`withStyle` (container), `withActiveStyle` / `withInactiveStyle` (per item) and
`withBadgeStyle` (per-tab badge).

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space as Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Transition as Transition
import Tebru.Theme.Typography as Typography


{-| How the active tab is marked. `Pill` fills the active tab with the Selected
surface (the original behavior). `Underline` draws an accent bottom border under
the active tab and a transparent one under the rest so widths stay stable.
-}
type ActiveIndicator
    = Pill
    | Underline


{-| A single tab. `badge` is an optional trailing element (e.g. a count chip).
The `default` constructor fills it with `Nothing`.
-}
type alias Tab msg =
    { label : String
    , onSelect : msg
    , badge : Maybe (Html msg)
    }


type Tabs msg
    = Tabs
        { tabs : List (Tab msg)
        , active : Int
        , indicator : ActiveIndicator
        , style : Config Standard
        , activeStyle : Config Standard -> Config Standard
        , inactiveStyle : Config Standard -> Config Standard
        , badgeStyle : Config Standard -> Config Standard
        , hoverStyle : Config Hover -> Config Hover
        }


{-| Default tab row from simple `{ label, onSelect }` records (no badges). The
active tab is marked with an `Underline` (sage bottom border). Override container
styles via `withStyle`, per-item styles via `withActiveStyle` / `withInactiveStyle`,
and the indicator via `withActiveIndicator`.
-}
default : { tabs : List { label : String, onSelect : msg }, active : Int } -> Tabs msg
default opts =
    detailed
        { tabs = List.map (\t -> { label = t.label, onSelect = t.onSelect, badge = Nothing }) opts.tabs
        , active = opts.active
        }


{-| Like `default`, but each tab carries an optional trailing `badge : Maybe (Html msg)`
rendered after the label (e.g. a count chip).
-}
detailed : { tabs : List (Tab msg), active : Int } -> Tabs msg
detailed opts =
    Tabs
        { tabs = opts.tabs
        , active = opts.active
        , indicator = Underline
        , style = containerStyle
        , activeStyle = identity
        , inactiveStyle = identity
        , badgeStyle = identity
        , hoverStyle = identity
        }


{-| Container: a flex row of tabs with a 1px bottom divider and `px-md py-sm`
padding, matching the original group-page tab strip. No surface fill.
-}
containerStyle : Config Standard
containerStyle =
    Config.default
        |> Border.withBorder Border.Default
        |> Spacing.withPadding (Spacing.xy Md Sm)
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Spacing.withGap Xs
        |> Structure.withBorderSide Space.Bottom


itemPadding : Config Standard -> Config Standard
itemPadding =
    Spacing.withPadding (Spacing.xy Md Sm)


{-| Shared per-tab geometry: `px-md py-sm` padding, small text, pointer cursor,
a color transition, and centered flex layout for the label + optional badge with
a `gap-2` between them.
-}
itemBase : Config Standard -> Config Standard
itemBase =
    itemPadding
        >> Typography.withFontSize Typography.Sm
        >> Structure.withDisplay Structure.Flex
        >> Structure.withAlign Structure.AlignCenter
        >> Spacing.withGap Sm
        >> Structure.withCursor Structure.CursorPointer
        >> Transition.withTransition Transition.TransitionColors


{-| Active item style for the `Pill` indicator: Selected surface behind the tab.
-}
pillActiveStyle : Config Standard
pillActiveStyle =
    Config.default
        |> Surface.withSurface Surface.Selected
        |> Text.withText Text.Default
        |> Typography.withFontWeight Typography.Semibold
        |> itemBase


{-| Active item style for the `Underline` indicator: a 1px saturated-sage bottom
border (the original used `border-focus` sage, not the pale success border), no
fill, semibold default-color text.
-}
underlineActiveStyle : Config Standard
underlineActiveStyle =
    Config.default
        |> Text.withText Text.Default
        |> Typography.withFontWeight Typography.Semibold
        |> Border.withBorder Border.Focus
        |> Structure.withBorderSide Space.Bottom
        |> itemBase


inactiveTabStyle : ActiveIndicator -> Config Standard
inactiveTabStyle indicator =
    let
        base =
            Config.default
                |> Text.withText Text.Secondary
                |> Typography.withFontWeight Typography.Medium
                |> itemBase
    in
    case indicator of
        Pill ->
            base

        Underline ->
            -- Keep a 1px transparent bottom border so inactive tabs sit at the
            -- same height as the underlined active one (no layout shift), and so
            -- the hover preview only transitions the border COLOR in.
            base
                |> Border.withBorder Border.Transparent
                |> Structure.withBorderSide Space.Bottom


activeTabStyle : ActiveIndicator -> Config Standard
activeTabStyle indicator =
    case indicator of
        Pill ->
            pillActiveStyle

        Underline ->
            underlineActiveStyle


{-| Hover preview for inactive `Underline` tabs: darken the label to the default
foreground (`hover:text-fg-default`) and preview a pale-sage underline where the
active tab's full sage one sits (`hover:border-border-success`), so inactive tabs
read as clickable. Routed through a typed `Config Hover` and emitted via
`Config.hoverToClasses`. Active tabs and `Pill` mode skip this.
-}
inactiveUnderlineHoverStyle : Config Hover
inactiveUnderlineHoverStyle =
    Config.defaultHover
        |> Text.withText Text.Default
        |> Border.withBorder Border.Success


{-| Default count-chip badge geometry: `px-2 py-1`, `rounded-md`, `text-[0.625rem]`,
semibold. On the active tab it sits on a pale-sage Selected surface with sage-ink
text; on inactive tabs it uses the Subtle surface with muted text — matching the
original `countChip`.
-}
defaultBadgeStyle : Bool -> Config Standard
defaultBadgeStyle isActive =
    let
        surfaceMod =
            if isActive then
                Surface.withSurface Surface.Selected >> Text.withText Text.Success

            else
                Surface.withSurface Surface.Subtle >> Text.withText Text.Muted
    in
    Config.default
        |> surfaceMod
        |> Spacing.withPadding (Spacing.xy Sm Xs)
        |> Radius.withRadius Radius.Md
        |> Typography.withFontSize Typography.Xxs
        |> Typography.withFontWeight Typography.Semibold


withStyle : (Config Standard -> Config Standard) -> Tabs msg -> Tabs msg
withStyle fn (Tabs t) =
    Tabs { t | style = fn t.style }


{-| Override the active tab item's style. Composes on top of the default active style.
-}
withActiveStyle : (Config Standard -> Config Standard) -> Tabs msg -> Tabs msg
withActiveStyle fn (Tabs t) =
    Tabs { t | activeStyle = t.activeStyle >> fn }


{-| Override the inactive tab item's style. Composes on top of the default inactive style.
-}
withInactiveStyle : (Config Standard -> Config Standard) -> Tabs msg -> Tabs msg
withInactiveStyle fn (Tabs t) =
    Tabs { t | inactiveStyle = t.inactiveStyle >> fn }


{-| Choose how the active tab is marked: `Underline` (the default) or `Pill`.
-}
withActiveIndicator : ActiveIndicator -> Tabs msg -> Tabs msg
withActiveIndicator indicator (Tabs t) =
    Tabs { t | indicator = indicator }


{-| Override the per-tab badge style. Composes on top of the default badge style.
-}
withBadgeStyle : (Config Standard -> Config Standard) -> Tabs msg -> Tabs msg
withBadgeStyle fn (Tabs t) =
    Tabs { t | badgeStyle = t.badgeStyle >> fn }


{-| Modify the inactive-tab hover style — emitted as `hover:`-prefixed classes.
Composes on top of the default inactive `Underline` hover preview.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Tabs msg -> Tabs msg
withHoverStyle fn (Tabs t) =
    Tabs { t | hoverStyle = t.hoverStyle >> fn }


view : Tabs msg -> Html msg
view (Tabs t) =
    Html.div
        (Html.Attributes.class (Config.toClasses t.style) :: Config.toStyleAttributes t.style)
        (List.indexedMap (viewTab t) t.tabs)


viewTab : { a | active : Int, indicator : ActiveIndicator, activeStyle : Config Standard -> Config Standard, inactiveStyle : Config Standard -> Config Standard, badgeStyle : Config Standard -> Config Standard, hoverStyle : Config Hover -> Config Hover } -> Int -> Tab msg -> Html msg
viewTab t index tab =
    let
        isActive =
            index == t.active

        style =
            if isActive then
                t.activeStyle (activeTabStyle t.indicator)

            else
                t.inactiveStyle (inactiveTabStyle t.indicator)

        -- Inactive Underline tabs darken on hover and preview a pale-sage
        -- underline where the active tab's full sage one sits, so they read as
        -- clickable. Active tabs already sit at full contrast; Pill mode has no
        -- preview. Routed through a typed `Config Hover` and emitted via
        -- `Config.hoverToClasses`.
        hoverClass =
            if isActive || t.indicator /= Underline then
                ""

            else
                Config.hoverToClasses (t.hoverStyle inactiveUnderlineHoverStyle)

        label =
            Html.text tab.label

        children =
            case tab.badge of
                Nothing ->
                    [ label ]

                Just badge ->
                    [ label, viewBadge isActive t.badgeStyle badge ]
    in
    Html.button
        (Html.Attributes.class (String.join " " (List.filter (\s -> s /= "") [ Config.toClasses style, hoverClass ]))
            :: Config.toStyleAttributes style
            -- type="button": a bare <button> defaults to type="submit", which
            -- would submit any enclosing <form> on every tab click.
            ++ [ Html.Attributes.type_ "button", Html.Events.onClick tab.onSelect ]
        )
        children


viewBadge : Bool -> (Config Standard -> Config Standard) -> Html msg -> Html msg
viewBadge isActive override content =
    let
        style =
            override (defaultBadgeStyle isActive)
    in
    Html.span
        (Html.Attributes.class (Config.toClasses style) :: Config.toStyleAttributes style)
        [ content ]
