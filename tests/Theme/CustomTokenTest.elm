module Theme.CustomTokenTest exposing (suite)

import Expect
import Tebru.Theme.Config as Config
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Surface as Surface
import Test exposing (Test, describe, test)


{-| App-side custom color type, simulating how an app extends the theme.
-}
type AppColor
    = AvailGreen
    | AvailMuted


appColorClass : AppColor -> String
appColorClass c =
    case c of
        AvailGreen ->
            "bg-avail-green"

        AvailMuted ->
            "bg-avail-muted"


type AppRadius
    = Sharp


appRadiusClass : AppRadius -> String
appRadiusClass r =
    case r of
        Sharp ->
            "rounded-none"


suite : Test
suite =
    describe "extensible token Custom a"
        [ describe "Surface"
            [ test "withSurface Card still resolves to the library class" <|
                \_ ->
                    Config.default
                        |> Surface.withSurface Surface.Card
                        |> Config.toClasses
                        |> Expect.equal "bg-surface-card"
            , test "withSurfaceCustom (Custom AvailGreen) resolves via the handler" <|
                \_ ->
                    Config.default
                        |> Surface.withSurfaceCustom appColorClass (Surface.Custom AvailGreen)
                        |> Config.toClasses
                        |> Expect.equal "bg-avail-green"
            , test "withSurfaceCustom (Custom AvailMuted) resolves via the handler" <|
                \_ ->
                    Config.default
                        |> Surface.withSurfaceCustom appColorClass (Surface.Custom AvailMuted)
                        |> Config.toClasses
                        |> Expect.equal "bg-avail-muted"
            , test "withSurfaceCustom with a library role ignores the handler" <|
                \_ ->
                    Config.default
                        |> Surface.withSurfaceCustom appColorClass Surface.Brand
                        |> Config.toClasses
                        |> Expect.equal "bg-surface-brand"
            ]
        , describe "Radius"
            [ test "withRadius Lg still resolves to the library class" <|
                \_ ->
                    Config.default
                        |> Radius.withRadius Radius.Lg
                        |> Config.toClasses
                        |> Expect.equal "rounded-lg"
            , test "withRadiusCustom (Custom Sharp) resolves via the handler" <|
                \_ ->
                    Config.default
                        |> Radius.withRadiusCustom appRadiusClass (Radius.Custom Sharp)
                        |> Config.toClasses
                        |> Expect.equal "rounded-none"
            ]
        ]
