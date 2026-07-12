module Tebru.Component.FormRow exposing
    ( FormRow, default, withStyle, view
    , inputWithAction
    )

{-| Headless FormRow primitive — a label paired with a control.

    FormRow.default { label = "Email", control = Input.view emailInput }
        |> FormRow.view

Label is rendered above the control by default. Override spacing or layout
via `withStyle`.

@docs FormRow, default, withStyle, view


# Input + trailing action

@docs inputWithAction

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Box as Layout
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type FormRow msg
    = FormRow
        { label : String
        , control : Html msg
        , style : Config Standard
        }


{-| Default form row: label above, Sm gap between label and control.
-}
default : { label : String, control : Html msg } -> FormRow msg
default opts =
    FormRow { label = opts.label, control = opts.control, style = baseStyle }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Text.withText Text.Default
        |> Typography.withFontSize Typography.Sm
        |> Typography.withFontWeight Typography.Medium


withStyle : (Config Standard -> Config Standard) -> FormRow msg -> FormRow msg
withStyle fn (FormRow r) =
    FormRow { r | style = fn r.style }


{-| The whole row is one `<label>` wrapping caption and control, so the caption
implicitly labels the first labelable descendant (input/select/textarea) —
clicking the caption focuses the control and screen readers announce the
association. A sibling `<label>` with no `for` would associate with nothing.
The caption itself is a `<span>`; the control is opaque, so `for`/`id` wiring
is not possible here.
-}
view : FormRow msg -> Html msg
view (FormRow r) =
    Html.label []
        [ Layout.stack Xs
            [ Html.span (Html.Attributes.class (Config.toClasses r.style) :: Config.toStyleAttributes r.style) [ Html.text r.label ]
            , r.control
            ]
            |> Layout.view
        ]


{-| Input + trailing button row, where the input grows to fill space and the
button keeps its natural size on the right.

For email change ("[email field][Change]"), search-like rows, anywhere an input
needs an adjacent affordance. The row is bottom-aligned (`items-end`) so the
button lines up with the input even when the input has a label above it.

    FormRow.inputWithAction { input = Input.view emailInput, button = changeButton }

-}
inputWithAction : { input : Html msg, button : Html msg } -> Html msg
inputWithAction opts =
    Layout.row Md
        [ Layout.box [ opts.input ] |> Layout.withStyle (Structure.withGrow True) |> Layout.view
        , opts.button
        ]
        |> Layout.withStyle (Structure.withAlign Structure.AlignEnd)
        |> Layout.view
