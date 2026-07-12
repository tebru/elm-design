module Tebru.Component.Skeleton exposing
    ( Shimmer(..)
    , Skeleton
    , bigBox
    , bigBoxHeight
    , box
    , card
    , cardHeight
    , eventRow
    , header
    , iconText
    , iconTextDark
    , line
    , view
    , withShimmer
    , withStyle
    )

{-| Headless Skeleton placeholder primitive + composed loading patterns.

    Skeleton.line |> Skeleton.view -- single-line shimmer

    Skeleton.box |> Skeleton.view -- block shimmer

Override dimensions or additional classes via withStyle.


## Composed variants — the sanctioned preset tier

Higher-level shimmer placeholders that reproduce the legacy `Ui.Skeleton`
composed shapes so screens use them directly instead of hand-rebuilding the
layout/shimmer footprint. Unlike the `box`/`line` builders these are
deliberately pre-rendered `Html msg` values with no styling slots: they are
fixed loading footprints, not composable primitives. Need a different shape?
Compose one from `box`/`line` + `withStyle` instead of extending this tier.

    Skeleton.card -- tall rounded bordered card: 3 varied-width lines + footer bar

    Skeleton.eventRow -- icon circle + two stacked lines + chevron tail

    Skeleton.iconText -- icon circle + single text line (light)

    Skeleton.iconTextDark -- icon circle + single text line (dark shimmer, larger circle)

    Skeleton.header c -- header row wrapping content (e.g. iconText)

    Skeleton.bigBox -- single rounded surface block (heatmap-card sized)

These intentionally use the `skeleton` / `skeleton-dark` CSS shimmer class
(a moving gradient, shipped by the package's own theme.css alongside its
`shimmer` keyframes) rather than a static surface color. Dimensions that have
no semantic token (fixed px heights, the shimmer class, varied-width line
modifiers) are applied as raw classes.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Box as Layout
import Tebru.Theme.Border as Border
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Radius as Radius
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Surface as Surface


type SkeletonKind
    = Box
    | Line


type Skeleton msg
    = Skeleton
        { kind : SkeletonKind
        , style : Config Standard
        }


box : Skeleton msg
box =
    Skeleton { kind = Box, style = boxStyle }


line : Skeleton msg
line =
    Skeleton { kind = Line, style = lineStyle }


boxStyle : Config Standard
boxStyle =
    Config.default
        |> Surface.withSurface Surface.Subtle
        |> Radius.withRadius Radius.Md


lineStyle : Config Standard
lineStyle =
    Config.default
        |> Surface.withSurface Surface.Subtle
        |> Radius.withRadius Radius.Sm


withStyle : (Config Standard -> Config Standard) -> Skeleton msg -> Skeleton msg
withStyle fn (Skeleton s) =
    Skeleton { s | style = fn s.style }


view : Skeleton msg -> Html msg
view (Skeleton s) =
    Html.span
        (Html.Attributes.class ("skeleton " ++ Config.toClasses s.style) :: Config.toStyleAttributes s.style)
        []



-- COMPOSED VARIANTS (rendered Html, matching legacy Ui.Skeleton)
--
-- The shimmer is the `skeleton` / `skeleton-dark` CSS class (a moving
-- linear-gradient shipped by the package's theme.css, colored through engine
-- contract vars). Composed shapes derive their line heights from padding on
-- an otherwise-empty box, exactly as the old module did:
--   PadSm  (p-2 / 0.5rem) -> standard text line
--   PadXs  (p-1 / 0.25rem) -> secondary / tight text line
--   PadMd  (p-3 / 0.75rem) -> footer / chevron bar, and the small avatar circle
--   PadLg  (p-4 / 1rem) -> the larger (dark) avatar circle
-- Varied line widths reuse the legacy width modifiers `skeleton-narrow/medium/wide`.


{-| The two shimmer gradients: `Light` for regular surfaces, `Dark` for dark
surface/navigation areas (e.g. the rail).
-}
type Shimmer
    = Light
    | Dark


{-| The shimmer CSS class for a variant (bespoke: moving-gradient classes with
no design token, shipped by the package's own components.css).
-}
shimmerClass : Shimmer -> String
shimmerClass shimmer =
    case shimmer of
        Light ->
            "skeleton"

        Dark ->
            "skeleton-dark"


{-| Apply a shimmer variant's moving-gradient class.
-}
withShimmer : Shimmer -> Config Standard -> Config Standard
withShimmer shimmer =
    Config.addRaw (shimmerClass shimmer)


{-| Fixed-percentage line-width modifiers (bespoke CSS classes that cap a shimmer
line's width). No design token — module-private named constants.
-}
shimmerWide : Config Standard -> Config Standard
shimmerWide =
    Config.addRaw "skeleton-wide"


shimmerMedium : Config Standard -> Config Standard
shimmerMedium =
    Config.addRaw "skeleton-medium"


shimmerNarrow : Config Standard -> Config Standard
shimmerNarrow =
    Config.addRaw "skeleton-narrow"


{-| Card skeleton fixed height (h-[140px]) — bespoke px, no token.
-}
cardHeight : Config Standard -> Config Standard
cardHeight =
    Config.addRaw "h-[140px]"


{-| Big-box skeleton fixed height (h-[120px]) — bespoke px, no token.
-}
bigBoxHeight : Config Standard -> Config Standard
bigBoxHeight =
    Config.addRaw "h-[120px]"


{-| Card outline color. The old `border-border` class referenced a color token
that no longer exists anywhere (it silently emitted no CSS, so the outline fell
back to the preflight default) — `Border.Default` is the intended hairline.
-}
cardBorderColor : Config Standard -> Config Standard
cardBorderColor =
    Border.withBorder Border.Default


{-| A shimmer "line": empty box whose height comes from its padding, with an
optional fixed-percentage width modifier. `widthMod` is `identity` (fill) or a
`skeleton-*` width modifier.
-}
shimmerLine : Shimmer -> Space -> (Config Standard -> Config Standard) -> Html msg
shimmerLine shimmer pad widthMod =
    Layout.box []
        |> Layout.withStyle (withShimmer shimmer >> Spacing.withPadding (Spacing.all pad) >> widthMod)
        |> Layout.view


{-| Avatar circle skeleton: a rounded-full shimmer block sized by its padding,
that does not shrink in a flex row.
-}
shimmerAvatar : Shimmer -> Space -> Html msg
shimmerAvatar shimmer pad =
    Layout.box []
        |> Layout.withStyle
            (withShimmer shimmer
                >> Spacing.withPadding (Spacing.all pad)
                >> Radius.withRadius Radius.Full
                >> Structure.withShrink False
            )
        |> Layout.view


{-| Card skeleton. Approximates an ActionCard: rounded bordered box (h-[140px])
with 3 text lines of varying width (wide / medium / narrow) plus a footer bar.
-}
card : Html msg
card =
    let
        lines =
            Layout.stack Sm
                [ shimmerLine Light Sm shimmerWide
                , shimmerLine Light Sm shimmerMedium
                , shimmerLine Light Sm shimmerNarrow
                ]
                |> Layout.withStyle (Structure.withFlex Structure.Flex1)
                |> Layout.view

        footer =
            shimmerLine Light Md shimmerMedium
    in
    Layout.stack Lg [ lines, footer ]
        |> Layout.withStyle
            (cardHeight
                >> Radius.withRadius Radius.Lg
                >> Spacing.withPadding (Spacing.all Lg)
                >> Surface.withSurface Surface.Card
                -- Theme.Border emits color only; add the 1px width utility (matches legacy Border.all).
                >> Structure.withBorderWidth Structure.BorderThin
                >> cardBorderColor
            )
        |> Layout.view


{-| Event row skeleton. Approximates an upcoming-section row: icon circle + two
stacked text lines + a small chevron-shaped bar on the trailing edge.
-}
eventRow : Html msg
eventRow =
    let
        titleLine =
            shimmerLine Light Sm shimmerWide

        secondaryLine =
            shimmerLine Light Xs shimmerNarrow

        chevronBar =
            Layout.box []
                |> Layout.withStyle (withShimmer Light >> Spacing.withPadding (Spacing.all Sm) >> Radius.withRadius Radius.Md)
                |> Layout.view
    in
    Layout.row Md
        [ shimmerAvatar Light Md
        , Layout.stack Xs [ titleLine, secondaryLine ] |> Layout.withStyle (Structure.withFlex Structure.Flex1) |> Layout.view
        , chevronBar
        ]
        |> Layout.withStyle (Structure.withAlign Structure.AlignCenter >> Spacing.withPadding (Spacing.xy Lg Md))
        |> Layout.view


{-| Icon + text skeleton. Common pattern for list items: a circle + single text
line that fills available space. Light shimmer, small (PadMd) circle.
-}
iconText : Html msg
iconText =
    iconTextInternal Light Md


{-| Dark theme icon + text skeleton for sidebar/navigation. Dark shimmer,
larger (PadLg) circle.
-}
iconTextDark : Html msg
iconTextDark =
    iconTextInternal Dark Lg


iconTextInternal : Shimmer -> Space -> Html msg
iconTextInternal shimmer avatarPad =
    Layout.row Md
        [ shimmerAvatar shimmer avatarPad
        , Layout.box [ shimmerLine shimmer Sm identity ] |> Layout.withStyle (Structure.withFlex Structure.Flex1) |> Layout.view
        ]
        |> Layout.withStyle (Structure.withAlign Structure.AlignCenter >> Structure.withFlex Structure.Flex1)
        |> Layout.view


{-| Header skeleton wrapping arbitrary content (e.g. `Skeleton.iconText`),
vertically centered. Mirrors the legacy `header` container.
-}
header : Html msg -> Html msg
header content =
    Layout.row None [ content ]
        |> Layout.withStyle (Structure.withAlign Structure.AlignCenter)
        |> Layout.view


{-| Big box skeleton. A single rounded surface block (h-[120px]) approximating
the MiniAvailability heatmap card size.
-}
bigBox : Html msg
bigBox =
    Layout.box []
        |> Layout.withStyle (withShimmer Light >> bigBoxHeight >> Radius.withRadius Radius.Lg)
        |> Layout.view
