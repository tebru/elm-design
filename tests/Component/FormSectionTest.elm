module Component.FormSectionTest exposing (suite)

import Html
import Tebru.Component.FormSection as FormSection
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.FormSection"
        [ test "renders the title text" <|
            \_ ->
                FormSection.default { title = "Profile", rows = [] }
                    |> FormSection.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Profile" ]
        , test "renders rows" <|
            \_ ->
                FormSection.default
                    { title = "Profile"
                    , rows = [ Html.div [] [ Html.text "Row A" ], Html.div [] [ Html.text "Row B" ] ]
                    }
                    |> FormSection.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.text "Row A", Selector.text "Row B" ]
        , test "withStyle overrides the section header style" <|
            \_ ->
                FormSection.default { title = "Profile", rows = [] }
                    |> FormSection.withStyle (Text.withText Text.Muted)
                    |> FormSection.view
                    |> Query.fromHtml
                    |> Query.has [ Selector.class "text-fg-muted" ]
        ]
