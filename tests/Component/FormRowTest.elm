module Component.FormRowTest exposing (suite)

import Html
import Tebru.Component.FormRow as FormRow
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.FormRow"
        [ test "renders the label text" <|
            \_ ->
                FormRow.default { label = "Email", control = Html.text "" }
                    |> FormRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Email" ]
        , test "renders the control" <|
            \_ ->
                FormRow.default { label = "Email", control = Html.input [] [] }
                    |> FormRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "input" ]
        , test "label is rendered in a label element" <|
            \_ ->
                FormRow.default { label = "Email", control = Html.text "" }
                    |> FormRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.tag "label" ]

        -- The <label> must WRAP the control (implicit association): a sibling
        -- label with no `for` labels nothing — clicking it wouldn't focus the
        -- field and screen readers would announce an unlabeled input. The view
        -- is wrapped in a div because Query.find only searches descendants.
        , test "the label element wraps both the caption and the control" <|
            \_ ->
                Html.div []
                    [ FormRow.default { label = "Email", control = Html.input [] [] }
                        |> FormRow.view
                    ]
                    |> Query.fromHtml
                    |> Query.find [ Selector.tag "label" ]
                    |> Query.has [ Selector.text "Email", Selector.tag "input" ]
        , test "withStyle overrides label style" <|
            \_ ->
                FormRow.default { label = "Email", control = Html.text "" }
                    |> FormRow.withStyle (Text.withText Text.Muted)
                    |> FormRow.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-muted" ]
        ]
