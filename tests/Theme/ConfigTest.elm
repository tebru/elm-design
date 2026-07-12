module Theme.ConfigTest exposing (suite)

import Expect
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config
import Tebru.Theme.Elevation as Elevation
import Tebru.Theme.MaxWidth as MaxWidth
import Tebru.Theme.Space as Space
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Tebru.Theme.Typography as Typography
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Theme.Config"
        [ test "default resolves to no classes" <|
            \_ -> Config.toClasses Config.default |> Expect.equal ""
        , test "withDisplay Flex resolves to 'flex'" <|
            \_ ->
                Config.default
                    |> Structure.withDisplay Structure.Flex
                    |> Config.toClasses
                    |> Expect.equal "flex"

        -- CROSS-MODULE LAST-WINS: Structure.withMaxWidth and MaxWidth.withMaxWidth
        -- target the same CSS property, so they MUST share one keyed-dict entry
        -- ("max-width", pinned in tokens.js withX.key + structure-def.js). If the
        -- keys ever diverge, both max-w-* classes emit and CSS source order — not
        -- pipeline order — picks the winner. Expect.equal on the full class string
        -- asserts exactly ONE max-w-* token survives.
        , test "MaxWidth.withMaxWidth overrides an earlier Structure.withMaxWidth" <|
            \_ ->
                Config.default
                    |> Structure.withMaxWidth Structure.SizeFull
                    |> MaxWidth.withMaxWidth MaxWidth.Md
                    |> Config.toClasses
                    |> Expect.equal "max-w-md"
        , test "Structure.withMaxWidth overrides an earlier MaxWidth.withMaxWidth" <|
            \_ ->
                Config.default
                    |> MaxWidth.withMaxWidth MaxWidth.Md
                    |> Structure.withMaxWidth Structure.SizeFull
                    |> Config.toClasses
                    |> Expect.equal "max-w-full"

        -- THE HOVER BOUNDARY (see the Config module doc): the hover channel is
        -- type-closed to the `hoverable: true` families. Elm has no
        -- should-not-compile tests, so the negative half of the boundary
        -- (e.g. `Config.defaultHover |> Structure.withDisplay Structure.Flex`
        -- or `|> Radius.withRadius Radius.Md` MUST NOT type-check — those
        -- setters accept only `Config Standard`) is documented here and
        -- enforced by the generated signatures. The positive half below pins
        -- every hoverable family, so a generator regression that stopped a
        -- policy family from accepting the Hover tag fails THIS file's compile.
        , test "every hoverable family composes on a hover config and prefixes hover:" <|
            \_ ->
                Config.defaultHover
                    |> Surface.withSurface Surface.Card
                    |> Text.withText Text.Default
                    |> Border.withBorder Border.Hover
                    |> Elevation.withElevation Elevation.Md
                    |> Typography.withDecoration Typography.Underline
                    |> Structure.withBorderWidth Structure.BorderThin
                    |> Structure.withBorderStyle Structure.BorderDashed
                    |> Structure.withBorderSide Space.Top
                    |> Config.hoverToClasses
                    |> String.split " "
                    |> List.sort
                    |> Expect.equal
                        [ "hover:bg-surface-card"
                        , "hover:border"
                        , "hover:border-border-hover"
                        , "hover:border-dashed"
                        , "hover:border-t"
                        , "hover:shadow-md"
                        , "hover:text-fg-default"
                        , "hover:underline"
                        ]
        ]
