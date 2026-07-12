module Tebru.Component.Choice exposing (Choice, checkbox, radio, switch, view, withCheckedStyle, withHoverStyle, withStyle, withUncheckedStyle)

{-| Headless Choice primitive — consolidates Checkbox and Radio.

    Choice.checkbox { checked = True, onToggle = ToggleConsent, label = "I agree" }
        |> Choice.view

    Choice.radio { checked = False, onSelect = SelectOption, label = "Option A" }
        |> Choice.view

    Choice.switch { checked = model.enabled, onToggle = ToggleEnabled, label = "Notifications" }
        |> Choice.view

No variant enums. Checked state reflected via default styling.

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import Tebru.Icon as Icon
import Tebru.Icon.Geometry as Geometry
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Transition as Transition
import Tebru.Theme.Typography as Typography


type ChoiceKind
    = Checkbox
    | Radio
    | Switch


type Choice msg
    = Choice
        { kind : ChoiceKind
        , checked : Bool
        , onMsg : msg
        , label : String
        , style : Config Standard
        , checkedStyle : Config Standard -> Config Standard
        , uncheckedStyle : Config Standard -> Config Standard
        , hoverStyle : Config Hover
        }


{-| Checkbox: toggles between checked/unchecked.
-}
checkbox : { checked : Bool, onToggle : msg, label : String } -> Choice msg
checkbox opts =
    Choice
        { kind = Checkbox
        , checked = opts.checked
        , onMsg = opts.onToggle
        , label = opts.label
        , style = containerStyle
        , checkedStyle = identity
        , uncheckedStyle = identity
        , hoverStyle = borderHoverStyle
        }


{-| Radio: fires onSelect when clicked (always).
-}
radio : { checked : Bool, onSelect : msg, label : String } -> Choice msg
radio opts =
    Choice
        { kind = Radio
        , checked = opts.checked
        , onMsg = opts.onSelect
        , label = opts.label
        , style = containerStyle
        , checkedStyle = identity
        , uncheckedStyle = identity
        , hoverStyle = borderHoverStyle
        }


{-| Switch: a pill/track with a sliding knob. Toggles between checked/unchecked,
firing onToggle on each click — same wiring as `checkbox`.
-}
switch : { checked : Bool, onToggle : msg, label : String } -> Choice msg
switch opts =
    Choice
        { kind = Switch
        , checked = opts.checked
        , onMsg = opts.onToggle
        , label = opts.label
        , style = containerStyle
        , checkedStyle = identity
        , uncheckedStyle = identity
        , hoverStyle = switchHoverStyle
        }


containerStyle : Config Standard
containerStyle =
    Config.default
        |> Spacing.withPadding (Spacing.xy Sm Xs)


{-| Default hover for the checkbox box / radio circle: the indicator border
shifts to the hover border on hover. Emitted as `hover:border-border-hover` via
`Config.hoverToClasses`. Overridable with `withHoverStyle`.
-}
borderHoverStyle : Config Hover
borderHoverStyle =
    Config.defaultHover
        |> Border.withBorder Border.Hover


{-| Default hover for the switch track: the off-state fill shifts to the hover
surface on hover. There is no semantic Surface token resolving to
`bg-surface-hover`, so this single hover stays as a raw class on the hover
Config (emitted as `hover:bg-surface-hover`). Overridable with `withHoverStyle`.
-}
switchHoverStyle : Config Hover
switchHoverStyle =
    Config.defaultHover
        |> surfaceHover


{-| The switch track off-state hover fill. There is no semantic `Theme.Surface`
token resolving to `bg-surface-hover`, so this single raw class (bespoke) stays
behind a named constant; emitted as `hover:bg-surface-hover`.
-}
surfaceHover : Config Hover -> Config Hover
surfaceHover =
    Config.addRaw "bg-surface-hover"


{-| Fixed track geometry — bespoke per-component dimensions, not a global token.
A 28×16 pill (matching the legacy `Ui.Checkbox.switch`) with the knob inset 2px
on every side. The track is a flex row; justify-end slides the knob right when on.
The on/off fills use generic theme surfaces (`Surface.Brand` on, `Surface.Subtle`
off); the app overrides to its exact product color via withChecked/Unchecked.
-}
switchTrackStyle : Bool -> Config Standard
switchTrackStyle isChecked =
    Config.default
        |> Radius.withRadius Radius.Full
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withCursor Structure.CursorPointer
        |> Structure.withShrink False
        |> switchTrackSize
        |> switchTrackPad
        |> Transition.withTransition Transition.TransitionColors
        |> Transition.withDuration Transition.DurationNormal
        |> Transition.withEasing Transition.EaseInOut
        |> (if isChecked then
                Structure.withJustify Structure.JustifyEnd >> Surface.withSurface Surface.Brand

            else
                Structure.withJustify Structure.JustifyStart >> Surface.withSurface Surface.Subtle
           )


{-| Fixed 28×16 switch-track dimensions (`w-7 h-4`) — bespoke per-component
control geometry with no global token (bespoke).
-}
switchTrackSize : Config Standard -> Config Standard
switchTrackSize =
    Config.addRaw "w-7 h-4"


{-| The 2px track padding (`p-0.5`) that insets the knob on every side. The
nearest Space token emits `p-xxs`, a different class, so the exact geometry
class stays a named constant (bespoke).
-}
switchTrackPad : Config Standard -> Config Standard
switchTrackPad =
    Config.addRaw "p-0.5"


{-| The knob: a 12×12 round white chip with a subtle shadow, matching the legacy
switch. It slides via the track's justify (no absolute positioning), so the 2px
track padding gives the inset on every side.
-}
switchKnobStyle : Config Standard
switchKnobStyle =
    Config.default
        |> Radius.withRadius Radius.Full
        |> switchKnobSize
        |> knobSurface
        |> Transition.withTransition Transition.TransitionAll
        |> Transition.withDuration Transition.DurationNormal
        |> Transition.withEasing Transition.EaseInOut
        |> Elevation.withElevation Elevation.Xs


{-| Fixed 12×12 knob dimensions (`w-3 h-3`) — bespoke per-component control
geometry with no global token (bespoke).
-}
switchKnobSize : Config Standard -> Config Standard
switchKnobSize =
    Config.addRaw "w-3 h-3"


{-| The knob's white fill — `Surface.Card` (`bg-surface-card`, the white card
surface). Previously a raw `bg-surface`, but no `--color-surface` token exists,
so that class was never generated and the knob rendered invisible.
-}
knobSurface : Config Standard -> Config Standard
knobSurface =
    Surface.withSurface Surface.Card


{-| The checkbox box: a 20×20 outlined rounded square that holds a check glyph
when checked, mirroring the legacy `Ui.Checkbox.checkbox`. The 2px border turns to
the focus/brand border when checked; the box itself stays transparent (the check
carries the state). Uses generic theme tokens (`Border.Focus`, `Text.Success`);
the app overrides to its exact product color via withChecked/UncheckedStyle.
-}
checkboxBoxStyle : Bool -> Config Standard
checkboxBoxStyle isChecked =
    Config.default
        |> Radius.withRadius Radius.Md
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withJustify Structure.JustifyCenter
        |> Structure.withCursor Structure.CursorPointer
        |> Structure.withShrink False
        |> Structure.withBorderWidth Structure.BorderThick
        |> checkboxBoxSize
        |> Typography.withFontSize Typography.Sm
        |> Text.withText Text.Success
        |> indicatorBorder isChecked


{-| Fixed 20×20 checkbox-box dimensions (`w-5 h-5`) — bespoke control geometry
with no global token (bespoke).
-}
checkboxBoxSize : Config Standard -> Config Standard
checkboxBoxSize =
    Config.addRaw "w-5 h-5"


{-| Shared indicator border-color rule: the generic focus/brand border when
checked (`Border.Focus`), the default theme border when not (`Border.Default`).
The app overrides to its exact product color via withChecked/UncheckedStyle.
-}
indicatorBorder : Bool -> Config Standard -> Config Standard
indicatorBorder isChecked =
    if isChecked then
        Border.withBorder Border.Focus

    else
        Border.withBorder Border.Default


{-| The radio circle: a 16×16 outlined round indicator that fills with a small
dot when selected, mirroring the legacy `Ui.Radio`. The border turns to the
focus/brand border when on. Override via withChecked/UncheckedStyle.
-}
radioCircleStyle : Bool -> Config Standard
radioCircleStyle isChecked =
    Config.default
        |> Radius.withRadius Radius.Full
        |> Structure.withDisplay Structure.Flex
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withJustify Structure.JustifyCenter
        |> Structure.withCursor Structure.CursorPointer
        |> Structure.withShrink False
        |> Structure.withBorderWidth Structure.BorderThin
        |> radioCircleSize
        |> indicatorBorder isChecked


{-| Fixed 16×16 radio-circle dimensions (`w-4 h-4`) — bespoke control geometry
with no global token (bespoke).
-}
radioCircleSize : Config Standard -> Config Standard
radioCircleSize =
    Config.addRaw "w-4 h-4"


{-| The 6px dot inside a selected radio (legacy `Ui.Dot` at `DotXs`), filled with
the generic `Surface.Brand`; the app overrides to its exact product color.
-}
radioDotStyle : Config Standard
radioDotStyle =
    Config.default
        |> Radius.withRadius Radius.Full
        |> Structure.withShrink False
        |> radioDotSize
        |> Surface.withSurface Surface.Brand


{-| Fixed 6px sage-dot dimensions (`w-1.5 h-1.5`) — bespoke control geometry
with no global token (bespoke).
-}
radioDotSize : Config Standard -> Config Standard
radioDotSize =
    Config.addRaw "w-1.5 h-1.5"


{-| The check glyph shown inside a checked checkbox, sized to fill the box.
-}
checkGlyph : Html msg
checkGlyph =
    Icon.default Geometry.check
        |> Icon.withStyle (Typography.withFontSize Typography.Base)
        |> Icon.view


withStyle : (Config Standard -> Config Standard) -> Choice msg -> Choice msg
withStyle fn (Choice c) =
    Choice { c | style = fn c.style }


{-| Override the indicator style when checked. Composes on top of the default checked style.
-}
withCheckedStyle : (Config Standard -> Config Standard) -> Choice msg -> Choice msg
withCheckedStyle fn (Choice c) =
    Choice { c | checkedStyle = c.checkedStyle >> fn }


{-| Override the indicator style when unchecked. Composes on top of the default unchecked style.
-}
withUncheckedStyle : (Config Standard -> Config Standard) -> Choice msg -> Choice msg
withUncheckedStyle fn (Choice c) =
    Choice { c | uncheckedStyle = c.uncheckedStyle >> fn }


{-| Modify the hover style config for the indicator (checkbox box / radio circle)
or switch track — emitted as `hover:`-prefixed classes.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Choice msg -> Choice msg
withHoverStyle fn (Choice c) =
    Choice { c | hoverStyle = fn c.hoverStyle }


{-| Click handler that fires the toggle msg on EVERY click (checked and
unchecked alike) and stops propagation so a control nested in a clickable parent
row doesn't double-fire — mirroring the legacy `Layout.withOnClickStopProp`. The
control renders as a `div`, not a `label`: a `<label>` re-dispatches a synthetic
click for its descendants, firing `onMsg` twice (toggle on then off) so a checked
control never actually changes.
-}
onClickStopProp : msg -> Html.Attribute msg
onClickStopProp msg =
    Html.Events.stopPropagationOn "click" (Json.Decode.succeed ( msg, True ))


{-| The semantics a non-native control owes assistive tech and the keyboard:
because the control is a `div` (see `onClickStopProp` for why not a `<label>`
or native `<input>`), it must carry the role, checked state, focusability, and
Space/Enter activation the native element would provide for free.
-}
controlSemantics : ChoiceKind -> Bool -> msg -> List (Html.Attribute msg)
controlSemantics kind checked msg =
    [ Html.Attributes.attribute "role"
        (case kind of
            Checkbox ->
                "checkbox"

            Radio ->
                "radio"

            Switch ->
                "switch"
        )
    , Html.Attributes.attribute "aria-checked"
        (if checked then
            "true"

         else
            "false"
        )
    , Html.Attributes.tabindex 0
    , onActivateKey msg
    ]


{-| Space/Enter fire the same msg as click. `preventDefault` on Space is
required — otherwise a focused control scrolls the page instead of toggling.
-}
onActivateKey : msg -> Html.Attribute msg
onActivateKey msg =
    Html.Events.preventDefaultOn "keydown"
        (Json.Decode.field "key" Json.Decode.string
            |> Json.Decode.andThen
                (\key ->
                    if key == " " || key == "Enter" then
                        Json.Decode.succeed ( msg, True )

                    else
                        Json.Decode.fail "not an activation key"
                )
        )


view : Choice msg -> Html msg
view (Choice c) =
    case c.kind of
        Switch ->
            switchView c

        _ ->
            inputView c


inputView :
    { kind : ChoiceKind
    , checked : Bool
    , onMsg : msg
    , label : String
    , style : Config Standard
    , checkedStyle : Config Standard -> Config Standard
    , uncheckedStyle : Config Standard -> Config Standard
    , hoverStyle : Config Hover
    }
    -> Html msg
inputView c =
    let
        baseIndicatorStyle =
            case c.kind of
                Radio ->
                    radioCircleStyle c.checked

                _ ->
                    checkboxBoxStyle c.checked

        indicatorStyle =
            if c.checked then
                c.checkedStyle baseIndicatorStyle

            else
                c.uncheckedStyle baseIndicatorStyle

        indicatorHoverClasses =
            if c.checked then
                ""

            else
                Config.hoverToClasses c.hoverStyle

        innerMark =
            case ( c.kind, c.checked ) of
                ( Radio, True ) ->
                    [ Html.span
                        (Html.Attributes.class (Config.toClasses radioDotStyle) :: Config.toStyleAttributes radioDotStyle)
                        []
                    ]

                ( _, True ) ->
                    [ checkGlyph ]

                _ ->
                    []
    in
    Html.div
        (Html.Attributes.class (Config.toClasses c.style)
            :: onClickStopProp c.onMsg
            :: controlSemantics c.kind c.checked c.onMsg
            ++ Config.toStyleAttributes c.style
        )
        [ Html.span
            (Html.Attributes.class (String.join " " (List.filter (\s -> s /= "") [ Config.toClasses indicatorStyle, indicatorHoverClasses ]))
                :: Config.toStyleAttributes indicatorStyle
            )
            innerMark
        , Html.text c.label
        ]


switchView :
    { kind : ChoiceKind
    , checked : Bool
    , onMsg : msg
    , label : String
    , style : Config Standard
    , checkedStyle : Config Standard -> Config Standard
    , uncheckedStyle : Config Standard -> Config Standard
    , hoverStyle : Config Hover
    }
    -> Html msg
switchView c =
    let
        trackStyle =
            if c.checked then
                c.checkedStyle (switchTrackStyle True)

            else
                c.uncheckedStyle (switchTrackStyle False)

        trackHoverClasses =
            if c.checked then
                ""

            else
                Config.hoverToClasses c.hoverStyle

        knobStyle =
            switchKnobStyle

        track =
            Html.span
                (Html.Attributes.class (String.join " " (List.filter (\s -> s /= "") [ Config.toClasses trackStyle, trackHoverClasses ]))
                    :: Config.toStyleAttributes trackStyle
                )
                [ Html.span
                    (Html.Attributes.class (Config.toClasses knobStyle) :: Config.toStyleAttributes knobStyle)
                    []
                ]
    in
    Html.div
        (Html.Attributes.class (Config.toClasses c.style)
            :: onClickStopProp c.onMsg
            :: controlSemantics c.kind c.checked c.onMsg
            ++ Config.toStyleAttributes c.style
        )
        [ track
        , Html.text c.label
        ]
