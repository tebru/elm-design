module Theme.SpacingTest exposing (suite)

import Expect
import Tebru.Theme.Config as Config
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Test exposing (Test, describe, test)


suite : Test
suite =
    describe "Theme.Spacing"
        [ test "all renders base padding" <|
            \_ -> Spacing.render (Spacing.all Sm) |> Expect.equal "p-sm"
        , test "all then top overrides one edge" <|
            \_ -> Spacing.render (Spacing.all Sm |> Spacing.top Lg) |> Expect.equal "p-sm pt-lg"
        , test "xy renders px and py" <|
            \_ -> Spacing.render (Spacing.xy Sm Lg) |> Expect.equal "px-sm py-lg"
        , test "withPadding appends the rendered geometry to Config" <|
            \_ ->
                Config.default
                    |> Spacing.withPadding (Spacing.all Sm |> Spacing.top Lg)
                    |> Config.toClasses
                    |> Expect.equal "p-sm pt-lg"

        -- MIXED-KEY LAST-CALL-WINS: withPadding decomposes into the same keyed
        -- slots withPaddingX/Y write (and withGap clears gap-x/gap-y), so mixing
        -- the setters never emits two classes for the same axis with CSS source
        -- order deciding the winner. See the withPadding doc comment.
        , test "withPaddingX after withPadding replaces the x axis (never both px classes)" <|
            \_ ->
                Config.default
                    |> Spacing.withPadding (Spacing.xy Md Sm)
                    |> Spacing.withPaddingX Lg
                    |> Config.toClasses
                    |> Expect.equal "px-lg py-sm"
        , test "withPadding after withPaddingX replaces the earlier axis call" <|
            \_ ->
                Config.default
                    |> Spacing.withPaddingX Lg
                    |> Spacing.withPadding (Spacing.xy Md Sm)
                    |> Config.toClasses
                    |> Expect.equal "px-md py-sm"
        , test "withGap after withGapX clears the axis slot (the later shorthand wins)" <|
            \_ ->
                Config.default
                    |> Spacing.withGapX Lg
                    |> Spacing.withGap Sm
                    |> Config.toClasses
                    |> Expect.equal "gap-sm"
        , test "withGapX after withGap keeps both (axis refines the shorthand)" <|
            \_ ->
                Config.default
                    |> Spacing.withGap Sm
                    |> Spacing.withGapX Lg
                    |> Config.toClasses
                    |> Expect.equal "gap-sm gap-x-lg"
        ]
