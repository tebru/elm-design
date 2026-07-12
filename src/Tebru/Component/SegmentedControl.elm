module Tebru.Component.SegmentedControl exposing
    ( SegmentedControl
    , default
    , view
    , withLeadingOptions
    , withSelectedStyle
    , withStyle
    , withUnselectedHoverStyle
    , withUnselectedStyle
    )

{-| Headless SegmentedControl primitive.

    SegmentedControl.default
        { options = [ { label = "Day", value = Day }, { label = "Week", value = Week } ]
        , selected = Day
        , onSelect = SelectPeriod
        }
        |> SegmentedControl.view

Each option may carry an optional **leading slot** — an arbitrary `Html msg`
rendered before the label in a flex row (e.g. a color swatch, an icon). Use
`withLeadingOptions` to supply options that include a `leading : Maybe (Html msg)`
field:

    SegmentedControl.default
        { options = [ { label = "Day", value = Day } ]
        , selected = Day
        , onSelect = SelectPeriod
        }
        |> SegmentedControl.withLeadingOptions
            [ { label = "Red", value = Red, leading = Just swatch }
            , { label = "None", value = NoColor, leading = Nothing }
            ]
        |> SegmentedControl.view

The leading slot is generic and headless — no app-specific content is baked in.
When omitted (`default` only, or `leading = Nothing`), the option renders
label-only exactly as before.

No variant enums — selected styling overridable via `withStyle`.

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Transition as Transition
import Tebru.Theme.Typography as Typography


{-| A single option. `leading` is an optional element rendered before the label.
-}
type alias Option v msg =
    { label : String
    , value : v
    , leading : Maybe (Html msg)
    }


type SegmentedControl v msg
    = SegmentedControl
        { options : List (Option v msg)
        , selected : v
        , onSelect : v -> msg
        , style : Config Standard
        , selectedStyle : Config Standard -> Config Standard
        , unselectedStyle : Config Standard -> Config Standard
        , unselectedHoverStyle : Config Hover -> Config Hover
        }


{-| Default segmented control. Selected segment gets the Selected surface.
Override container styles via `withStyle`.

Options here are label-only; every option's leading slot defaults to `Nothing`.
Supply leading elements with `withLeadingOptions`.

-}
default :
    { options : List { label : String, value : v }
    , selected : v
    , onSelect : v -> msg
    }
    -> SegmentedControl v msg
default opts =
    SegmentedControl
        { options = List.map (\o -> { label = o.label, value = o.value, leading = Nothing }) opts.options
        , selected = opts.selected
        , onSelect = opts.onSelect
        , style = containerStyle
        , selectedStyle = identity
        , unselectedStyle = identity
        , unselectedHoverStyle = identity
        }


{-| Replace the options with a richer list whose entries each carry an optional
leading slot (`leading : Maybe (Html msg)`). Existing `selected`/`onSelect`/styles
are preserved.
-}
withLeadingOptions : List (Option v msg) -> SegmentedControl v msg -> SegmentedControl v msg
withLeadingOptions options (SegmentedControl s) =
    SegmentedControl { s | options = options }


{-| Soft cardAlt track: warm-white background, hairline default border, lg
radius, 4px inset padding, inline-flex row with a 4px gap between segments.
-}
containerStyle : Config Standard
containerStyle =
    Config.default
        |> Surface.withSurface Surface.CardAlt
        |> Border.withBorder Border.Default
        |> Radius.withRadius Radius.Lg
        |> Spacing.withPadding (Spacing.all Xs)
        |> Structure.withDisplay Structure.InlineFlex
        |> Structure.withBorderWidth Structure.BorderThin
        |> Spacing.withGap Xs


{-| Geometry shared by every segment regardless of selection: md radius,
px-2/py-1 padding, inline-flex centered row, 4px leading-gap, xs font, pointer
cursor, color transition.
-}
optionBaseStyle : Config Standard
optionBaseStyle =
    Config.default
        |> Radius.withRadius Radius.Md
        |> Spacing.withPadding (Spacing.xy Sm Xs)
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withCursor Structure.CursorPointer
        |> Typography.withFontSize Typography.Xs
        |> Spacing.withGap Xs
        |> Transition.withTransition Transition.TransitionColors
        |> Transition.withDuration Transition.DurationNormal


{-| Selected segment floats as a white sub-pill: white surface, subtle shadow,
semibold default-ink label.
-}
selectedOptionStyle : Config Standard
selectedOptionStyle =
    optionBaseStyle
        |> Surface.withSurface Surface.Card
        |> Text.withText Text.Default
        |> Typography.withFontWeight Typography.Semibold
        |> selectedPillShadow


{-| The selected sub-pill's bespoke two-layer drop shadow. This exact arbitrary
shadow is not on the Elevation scale (it is softer than `shadow-xs`), so it stays
as `addRaw` behind this named constant (bespoke).
-}
selectedPillShadow : Config Standard -> Config Standard
selectedPillShadow =
    Config.addRaw "shadow-[0_1px_2px_rgba(0,0,0,0.04),0_1px_4px_rgba(0,0,0,0.03)]"


{-| Unselected segment: medium-weight secondary-ink label, transparent track.
-}
unselectedOptionStyle : Config Standard
unselectedOptionStyle =
    optionBaseStyle
        |> Text.withText Text.Secondary
        |> Typography.withFontWeight Typography.Medium


{-| Unselected segment hover preview: shifts to the active pill (white card
surface, darkened default-ink label) so it reads as clickable — no
shadow/semibold. Emitted as `hover:`-prefixed classes via `Config.hoverToClasses`.
-}
unselectedOptionHoverStyle : Config Hover
unselectedOptionHoverStyle =
    Config.defaultHover
        |> Surface.withSurface Surface.Card
        |> Text.withText Text.Default


withStyle : (Config Standard -> Config Standard) -> SegmentedControl v msg -> SegmentedControl v msg
withStyle fn (SegmentedControl s) =
    SegmentedControl { s | style = fn s.style }


{-| Override the selected option item's style. Composes on top of the default selected style.
-}
withSelectedStyle : (Config Standard -> Config Standard) -> SegmentedControl v msg -> SegmentedControl v msg
withSelectedStyle fn (SegmentedControl s) =
    SegmentedControl { s | selectedStyle = s.selectedStyle >> fn }


{-| Override the unselected option item's style. Composes on top of the default unselected style.
-}
withUnselectedStyle : (Config Standard -> Config Standard) -> SegmentedControl v msg -> SegmentedControl v msg
withUnselectedStyle fn (SegmentedControl s) =
    SegmentedControl { s | unselectedStyle = s.unselectedStyle >> fn }


{-| Override the unselected option item's hover preview. Composes on top of the
default hover style; emitted as `hover:`-prefixed classes.
-}
withUnselectedHoverStyle : (Config Hover -> Config Hover) -> SegmentedControl v msg -> SegmentedControl v msg
withUnselectedHoverStyle fn (SegmentedControl s) =
    SegmentedControl { s | unselectedHoverStyle = s.unselectedHoverStyle >> fn }


view : SegmentedControl v msg -> Html msg
view (SegmentedControl s) =
    Html.div
        (Html.Attributes.class (Config.toClasses s.style) :: Config.toStyleAttributes s.style)
        (List.map (viewOption s.selected s.onSelect s.selectedStyle s.unselectedStyle s.unselectedHoverStyle) s.options)


viewOption :
    v
    -> (v -> msg)
    -> (Config Standard -> Config Standard)
    -> (Config Standard -> Config Standard)
    -> (Config Hover -> Config Hover)
    -> Option v msg
    -> Html msg
viewOption selected onSelect selectedOverride unselectedOverride unselectedHoverOverride opt =
    let
        isSelected =
            opt.value == selected

        style =
            if isSelected then
                selectedOverride selectedOptionStyle

            else
                unselectedOverride unselectedOptionStyle

        hoverClasses =
            if isSelected then
                ""

            else
                Config.hoverToClasses (unselectedHoverOverride unselectedOptionHoverStyle)

        label =
            Html.text opt.label

        -- The button is itself an inline-flex items-center gap-1 row, so the
        -- leading slot and label are direct flex children — matching the old
        -- single-row layout (no nested wrapper, swatch + label aligned on one
        -- baseline with a 4px gap).
        contents =
            case opt.leading of
                Just leading ->
                    [ leading, label ]

                Nothing ->
                    [ label ]
    in
    Html.button
        (Html.Attributes.class (String.join " " (List.filter (\c -> c /= "") [ Config.toClasses style, hoverClasses ]))
            :: Config.toStyleAttributes style
            -- type="button": a bare <button> defaults to type="submit", which
            -- would submit any enclosing <form> on every segment click.
            ++ [ Html.Attributes.type_ "button", Html.Events.onClick (onSelect opt.value) ]
        )
        contents
