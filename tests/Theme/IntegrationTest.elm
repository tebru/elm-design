module Theme.IntegrationTest exposing (suite)

import Expect
import Tebru.Theme.Config as Config
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space as Space
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Surface as Surface exposing (Surface(..))
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "theme integration"
        [ test "a full config chain emits exactly the expected classes (order-independent)" <|
            \_ ->
                Config.default
                    |> Surface.withSurface Card
                    |> Spacing.withPadding (Spacing.all Space.Md)
                    |> Radius.withRadius Radius.Lg
                    |> Config.toClasses
                    |> String.split " "
                    |> List.sort
                    |> Expect.equal (List.sort [ "bg-surface-card", "p-md", "rounded-lg" ])
        , test "last withSurface wins — only the final surface class appears" <|
            \_ ->
                Config.default
                    |> Surface.withSurface Card
                    |> Surface.withSurface Brand
                    |> Config.toClasses
                    |> Expect.equal "bg-surface-brand"
        ]
