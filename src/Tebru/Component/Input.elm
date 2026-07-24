module Tebru.Component.Input exposing (Input, Type(..), chromeless, default, onBlur, onChange, onInput, onKeyDownPreventDefault, view, withAutofocus, withDisabled, withId, withLabel, withPlaceholder, withStyle, withType, withValue)

{-| Headless Input primitive.

    Input.default
        |> Input.withPlaceholder "Search…"
        |> Input.onInput GotInput
        |> Input.view

No variant enums — border, radius, padding are overridable via `withStyle`.

-}

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode
import Tebru.Box as Box
import Tebru.Component.Text as Text
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Text as TextColor
import Tebru.Theme.Transition as Transition
import Tebru.Theme.Typography as Typography


{-| Placeholder text color (legacy PlaceholderMuted). The `placeholder:` pseudo has
no token channel, so it stays raw behind this named constant (bespoke).
-}
placeholderColor : Config tag -> Config tag
placeholderColor =
    Config.addRaw "placeholder:text-fg-muted"


{-| App focus ring (legacy FocusDefault). The `focus:` pseudo has no token channel,
so it stays raw behind this named constant (bespoke).
-}
focusRing : Config tag -> Config tag
focusRing =
    Config.addRaw "focus:outline-none focus:ring-1 focus:ring-border-focus focus:border-border-focus"


{-| Suppress the browser default focus outline with no app ring (legacy FocusNone).
The `focus:` pseudo has no token channel, so it stays raw behind this named constant (bespoke).
-}
focusNone : Config tag -> Config tag
focusNone =
    Config.addRaw "focus:outline-none"


{-| Disabled treatment (legacy DisabledMuted). The `disabled:` pseudo has no token
channel, so it stays raw behind this named constant (bespoke).
-}
disabledMuted : Config tag -> Config tag
disabledMuted =
    Config.addRaw "disabled:bg-surface-disabled disabled:cursor-not-allowed"


{-| HTML input type. Deliberately minimal — variants are added on demand when
a consumer needs one (as `Color` was), not speculatively; see the
extend-on-demand policy in CLAUDE.md.
-}
type Type
    = Text
    | Email
    | Password
    | Color


type Input msg
    = Input
        { placeholder : Maybe String
        , value : Maybe String
        , inputType : Type
        , onInput : Maybe (String -> msg)
        , onChange : Maybe (String -> msg)
        , onKeyDown : Maybe (String -> Maybe msg)
        , onBlur : Maybe msg
        , style : Config Standard
        , disabled : Bool
        , id : Maybe String
        , autofocus : Bool
        , label : Maybe String
        }


{-| Input with default border, radius, and padding.
Override any part via `withStyle`.
-}
default : Input msg
default =
    Input { placeholder = Nothing, value = Nothing, inputType = Text, onInput = Nothing, onChange = Nothing, onKeyDown = Nothing, onBlur = Nothing, style = baseStyle, disabled = False, id = Nothing, autofocus = False, label = Nothing }


{-| Chromeless inline input — no Standard chrome (no border width, no fixed
height, no shadow, no focus ring, no placeholder color, no padding). Just a
transparent border, `text-sm`, and `grow` so it fills its container. Matches the
old `Ui.Input.Inline` variant used inside search boxes. Everything is still
overridable via `withStyle` — keeps the component headless.
-}
chromeless : Input msg
chromeless =
    Input { placeholder = Nothing, value = Nothing, inputType = Text, onInput = Nothing, onChange = Nothing, onKeyDown = Nothing, onBlur = Nothing, style = chromelessStyle, disabled = False, id = Nothing, autofocus = False, label = Nothing }


{-| Default Standard-input styling — value-identical to the old
`Ui.Input.default Ui.Input.Standard`. Token-backed where a token exists
(border color, radius, padding, font size); raw fragments for the parts the
theme has no token for (border width, block/full-width, focus ring, placeholder
color, disabled treatment, subtle shadow, transition, fixed 34px height).
All of it is overridable via `withStyle` — keeps the component headless.
-}
baseStyle : Config Standard
baseStyle =
    Config.default
        |> Border.withBorder Border.Default
        |> Radius.withRadius Radius.Md
        |> Spacing.withPadding (Spacing.xy Sm Xs)
        |> Typography.withFontSize Typography.Sm
        -- border WIDTH (Theme.Border emits color only); layout
        |> Structure.withBorderWidth Structure.BorderThin
        |> Structure.withDisplay Structure.Block
        |> Structure.withWidth Structure.SizeFull
        -- subtle elevation (old ShadowSubtle; Elevation.Xs resolves to the same value) + transition
        |> Elevation.withElevation Elevation.Xs
        |> Transition.withTransition Transition.TransitionShadow
        |> Transition.withDuration Transition.DurationNormal
        -- placeholder color (old PlaceholderMuted)
        |> placeholderColor
        -- focus ring (old FocusDefault)
        |> focusRing
        -- disabled treatment (old DisabledMuted)
        |> disabledMuted


{-| Minimal chromeless styling — value-identical to the old `Ui.Input.Inline`
variant: transparent border (no chrome), `text-sm`, `grow` to fill, no padding,
no fixed height, no shadow, no focus ring. Token-backed where a token exists
(transparent border, no padding, font size); `grow` is a raw fragment (layout,
no token).
-}
chromelessStyle : Config Standard
chromelessStyle =
    Config.default
        |> Border.withBorder Border.Transparent
        |> Spacing.withPadding (Spacing.all None)
        |> Typography.withFontSize Typography.Sm
        |> Structure.withGrow True
        -- suppress browser default focus ring, no app ring (old Ui.Input.Inline FocusNone)
        |> focusNone


withPlaceholder : String -> Input msg -> Input msg
withPlaceholder ph (Input i) =
    Input { i | placeholder = Just ph }


{-| Bind a controlled value to the input.
-}
withValue : String -> Input msg -> Input msg
withValue val (Input i) =
    Input { i | value = Just val }


{-| Set the HTML input type (Text, Email, or Password).
-}
withType : Type -> Input msg -> Input msg
withType t (Input i) =
    Input { i | inputType = t }


{-| Disable the input. Applies the HTML `disabled` attribute.
-}
withDisabled : Bool -> Input msg -> Input msg
withDisabled isDisabled (Input i) =
    Input { i | disabled = isDisabled }


{-| Set the HTML `id` attribute on the rendered `<input>`.
-}
withId : String -> Input msg -> Input msg
withId id (Input i) =
    Input { i | id = Just id }


{-| Autofocus the input on mount. Applies the HTML `autofocus` attribute when True.
-}
withAutofocus : Bool -> Input msg -> Input msg
withAutofocus isAutofocus (Input i) =
    Input { i | autofocus = isAutofocus }


{-| Render a caption above the input, wrapped in a `<label>` so clicking the
caption focuses the field. The caption is `text-sm` muted, stacked above the
input with an `Xs` gap.
-}
withLabel : String -> Input msg -> Input msg
withLabel labelText (Input i) =
    Input { i | label = Just labelText }


onInput : (String -> msg) -> Input msg -> Input msg
onInput handler (Input i) =
    Input { i | onInput = Just handler }


{-| Fire on the `change` event — when the value is COMMITTED (field blurred,
Enter, or a native picker dialog dismissed) rather than on every keystroke/
drag. The native color input fires `input` continuously while dragging in
the OS dialog; `onChange` is the hook for callers that persist the value.
-}
onChange : (String -> msg) -> Input msg -> Input msg
onChange handler (Input i) =
    Input { i | onChange = Just handler }


{-| Handle keydown by key name (`event.key`: `"Enter"`, `","`, `"Backspace"`,
…). Returning `Just msg` fires it AND preventDefaults that keypress — so a
committing Enter doesn't submit a wrapping form and a committing comma isn't
typed; returning `Nothing` leaves the key completely untouched. Only the keys
you handle are affected, hence the name.

    Input.onKeyDownPreventDefault
        (\key ->
            if key == "Enter" || key == "," then
                Just CommitChip

            else
                Nothing
        )

-}
onKeyDownPreventDefault : (String -> Maybe msg) -> Input msg -> Input msg
onKeyDownPreventDefault handler (Input i) =
    Input { i | onKeyDown = Just handler }


{-| Fire when the input loses focus.
-}
onBlur : msg -> Input msg -> Input msg
onBlur msg (Input i) =
    Input { i | onBlur = Just msg }


withStyle : (Config Standard -> Config Standard) -> Input msg -> Input msg
withStyle fn (Input i) =
    Input { i | style = fn i.style }


typeToString : Type -> String
typeToString t =
    case t of
        Text ->
            "text"

        Email ->
            "email"

        Password ->
            "password"

        Color ->
            "color"


view : Input msg -> Html msg
view (Input i) =
    let
        classAttr =
            Html.Attributes.class (Config.toClasses i.style)

        typeAttr =
            Html.Attributes.type_ (typeToString i.inputType)

        placeholderAttr =
            case i.placeholder of
                Just ph ->
                    [ Html.Attributes.placeholder ph ]

                Nothing ->
                    []

        valueAttr =
            case i.value of
                Just val ->
                    [ Html.Attributes.value val ]

                Nothing ->
                    []

        onInputAttr =
            case i.onInput of
                Just handler ->
                    [ Html.Events.onInput handler ]

                Nothing ->
                    []

        onChangeAttr =
            case i.onChange of
                Just handler ->
                    [ Html.Events.on "change" (Json.Decode.map handler Html.Events.targetValue) ]

                Nothing ->
                    []

        onBlurAttr =
            case i.onBlur of
                Just msg ->
                    [ Html.Events.onBlur msg ]

                Nothing ->
                    []

        onKeyDownAttr =
            case i.onKeyDown of
                Just handler ->
                    [ Html.Events.preventDefaultOn "keydown"
                        (Json.Decode.field "key" Json.Decode.string
                            |> Json.Decode.andThen
                                (\key ->
                                    case handler key of
                                        Just msg ->
                                            Json.Decode.succeed ( msg, True )

                                        Nothing ->
                                            Json.Decode.fail "unhandled key"
                                )
                        )
                    ]

                Nothing ->
                    []

        disabledAttr =
            [ Html.Attributes.disabled i.disabled ]

        idAttr =
            case i.id of
                Just id ->
                    [ Html.Attributes.id id ]

                Nothing ->
                    []

        autofocusAttr =
            [ Html.Attributes.autofocus i.autofocus ]

        inputEl =
            Html.input
                (classAttr :: Config.toStyleAttributes i.style ++ typeAttr :: disabledAttr ++ idAttr ++ autofocusAttr ++ placeholderAttr ++ valueAttr ++ onInputAttr ++ onChangeAttr ++ onBlurAttr ++ onKeyDownAttr)
                []
    in
    case i.label of
        Nothing ->
            inputEl

        Just labelText ->
            Html.label [] [ Box.stack Xs [ labelCaption labelText, inputEl ] |> Box.view ]


{-| The caption rendered by `withLabel` — `text-sm`, normal weight, muted.
-}
labelCaption : String -> Html msg
labelCaption labelText =
    Text.body labelText
        |> Text.withStyle (Typography.withFontSize Typography.Sm >> Typography.withFontWeight Typography.Normal >> TextColor.withText TextColor.Muted)
        |> Text.view
