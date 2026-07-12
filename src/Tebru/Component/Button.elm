module Tebru.Component.Button exposing (Button, asSubmit, default, onClick, view, withDisabled, withHoverStyle, withIcon, withStyle)

{-| Headless Button primitive.

    Button.default "Save"
        |> Button.withStyle (Surface.withSurface Surface.Brand)
        |> Button.view

No variant enums — app "variants" are presets:

    primaryButton label =
        Button.default label |> Button.withStyle brandStyle

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


type Button msg
    = Button
        { label : String
        , onClick : Maybe msg
        , icon : Maybe (Html msg)
        , style : Config Standard
        , hoverStyle : Config Hover
        , disabled : Bool
        , isSubmit : Bool
        }


{-| Sensible default; every part overridable via `withStyle`.
Brand/danger/etc. are app presets, not library variants.
-}
default : String -> Button msg
default label =
    Button { label = label, onClick = Nothing, icon = Nothing, style = baseStyle, hoverStyle = Config.defaultHover, disabled = False, isSubmit = False }


{-| The default look reproduces the legacy Button base + neutral (secondary)
variant: a `h-[34px]` `inline-flex` control with `px-3 py-1` padding,
`text-sm` `font-medium` text, `rounded-lg` corners, a hairline default
border on a card surface, a `transition-colors` and `cursor-pointer`, and
the standard disabled treatment.

App color variants (brand/danger/ghost/link/…) override surface/text/border
via `withStyle` at the call site — they are not baked in here.

`Border.withBorder` emits only the border _color_ class; the visible width is
the `Structure.withBorderWidth BorderThin` (`border`) utility. The `h-[34px]`
control height and the `disabled:*` pseudo-utilities have no token channel, so
they stay as `addRaw` behind named module constants.

-}
baseStyle : Config Standard
baseStyle =
    Config.default
        |> Surface.withSurface Surface.Card
        |> Border.withBorder Border.Default
        |> Structure.withBorderWidth Structure.BorderThin
        |> Text.withText Text.Default
        |> Radius.withRadius Radius.Lg
        |> Typography.withFontSize Typography.Sm
        |> Typography.withFontWeight Typography.Medium
        |> Spacing.withPadding (Spacing.xy Md Xs)
        |> Structure.withAlign Structure.AlignCenter
        |> Structure.withJustify Structure.JustifyCenter
        |> Structure.withCursor Structure.CursorPointer
        |> Structure.withDisplay Structure.InlineFlex
        |> controlHeight
        |> Spacing.withGap Sm
        |> Transition.withTransition Transition.TransitionColors
        |> Transition.withDuration Transition.DurationNormal
        |> disabledTreatment


{-| Standard control height. `h-[34px]` is an off-scale fixed pixel size with no
token channel. Set under the keyed `"height"` channel (not `addRaw`) so a preset
can override it — e.g. taller form controls, or `h-auto` for a link-styled
button.
-}
controlHeight : Config Standard -> Config Standard
controlHeight =
    Config.set "height" "h-[34px]"


{-| Standard disabled treatment: dim, ignore pointer events, default cursor.
`disabled:` is a pseudo-state with no token channel (bespoke), so it stays as
`addRaw` behind this named constant.
-}
disabledTreatment : Config Standard -> Config Standard
disabledTreatment =
    Config.addRaw "disabled:opacity-50 disabled:pointer-events-none disabled:cursor-default"


onClick : msg -> Button msg -> Button msg
onClick msg (Button b) =
    Button { b | onClick = Just msg }


withIcon : Html msg -> Button msg -> Button msg
withIcon icon (Button b) =
    Button { b | icon = Just icon }


withStyle : (Config Standard -> Config Standard) -> Button msg -> Button msg
withStyle fn (Button b) =
    Button { b | style = fn b.style }


{-| Modify the hover style config — emitted as `hover:`-prefixed classes.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Button msg -> Button msg
withHoverStyle fn (Button b) =
    Button { b | hoverStyle = fn b.hoverStyle }


{-| Disable the button. Applies the HTML `disabled` attribute.
-}
withDisabled : Bool -> Button msg -> Button msg
withDisabled isDisabled (Button b) =
    Button { b | disabled = isDisabled }


{-| Render as `type="submit"` so the button submits its enclosing `<form>`.
No `onClick` handler needed when using this — the form's `onSubmit` fires instead.
-}
asSubmit : Button msg -> Button msg
asSubmit (Button b) =
    Button { b | isSubmit = True }


view : Button msg -> Html msg
view (Button b) =
    let
        typeAttr =
            Html.Attributes.type_
                (if b.isSubmit then
                    "submit"

                 else
                    "button"
                )

        baseAttrs =
            Html.Attributes.class (String.join " " (List.filter (\s -> s /= "") [ Config.toClasses b.style, Config.hoverToClasses b.hoverStyle ]))
                :: Config.toStyleAttributes b.style
                ++ [ typeAttr
                   , Html.Attributes.disabled b.disabled
                   ]

        clickAttrs =
            case b.onClick of
                Just m ->
                    [ Html.Events.onClick m ]

                Nothing ->
                    []
    in
    Html.button
        (baseAttrs ++ clickAttrs)
        (case b.icon of
            Just i ->
                [ i, Html.text b.label ]

            Nothing ->
                [ Html.text b.label ]
        )
