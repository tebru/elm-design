module Tebru.Component.FormSection exposing (FormSection, default, view, withStyle)

{-| Headless FormSection primitive — a titled group of form rows.

    FormSection.default
        { title = "Profile"
        , rows = [ FormRow.view emailRow, FormRow.view nameRow ]
        }
        |> FormSection.view

Composes `Component.SectionHeader` + a `Layout.stack` of rows.
Override the section header style via `withStyle`.

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Component.SectionHeader as SectionHeader
import Tebru.Theme.Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography


type FormSection msg
    = FormSection
        { title : String
        , rows : List (Html msg)
        , headerStyle : Config Standard -> Config Standard
        }


{-| Default form section: section header above a stack of rows.
-}
default : { title : String, rows : List (Html msg) } -> FormSection msg
default opts =
    FormSection { title = opts.title, rows = opts.rows, headerStyle = identity }


{-| Override the section header's Config.
-}
withStyle : (Config Standard -> Config Standard) -> FormSection msg -> FormSection msg
withStyle fn (FormSection s) =
    FormSection { s | headerStyle = s.headerStyle >> fn }


{-| The OLD `Ui.FormSection` labelled its section with a small muted caption
(`text-sm`, `font-normal`, `text-muted`) — NOT the bolder default
`SectionHeader` title. We bake that caption style as the default header style
here, then let the caller's `headerStyle` override compose after it.
-}
captionStyle : Config Standard -> Config Standard
captionStyle =
    Typography.withFontSize Typography.Sm
        >> Typography.withFontWeight Typography.Normal
        >> Text.withText Text.Muted


view : FormSection msg -> Html msg
view (FormSection s) =
    let
        header =
            SectionHeader.default s.title
                |> SectionHeader.withStyle (captionStyle >> s.headerStyle)
                |> SectionHeader.view

        rowsGroup =
            Layout.stack Xl s.rows |> Layout.view
    in
    Layout.stack Sm [ header, rowsGroup ] |> Layout.view
