module Tebru.Component.List exposing (Items, default, view, withDividers, withStyle)

{-| Headless List container primitive — a semantic `<ul>` that vertically stacks
its items with a gap, with optional between-item dividers.

Faithfully mirrors the original `Ui.List`:

  - element is a `<ul>` (`list-none m-0 p-0`), not a wrapping `<div>`
  - default layout is a vertical flex stack with `gap-sm` (0.5rem, the old
    `Vertical StackS`)
  - no baked surface / border / radius — the container is transparent; callers
    add chrome via `withStyle`
  - dividers are off by default and, when enabled, draw a bottom border on every
    child except the last (the old `DividerBetween`), keyed off the list, not the
    item

```
    import Tebru.Component.List as CList
    import Tebru.Component.ListItem as ListItem

    CList.default
        [ ListItem.default [ Html.text "Item one" ] |> ListItem.view
        , ListItem.default [ Html.text "Item two" ] |> ListItem.view
        ]
        |> CList.withDividers True
        |> CList.view
```

No variant enums — container style overridable via `withStyle`.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure


type Items msg
    = Items
        { items : List (Html msg)
        , dividers : Bool
        , style : Config Standard
        }


{-| Vertical list with `gap-sm`, transparent container, dividers off.
-}
default : List (Html msg) -> Items msg
default items =
    Items { items = items, dividers = False, style = baseStyle }


{-| The old `Vertical StackS`: `flex flex-col gap-sm`. No surface/border/radius.
-}
baseStyle : Config Standard
baseStyle =
    Config.default
        |> Structure.withDisplay Structure.Flex
        |> Config.addRaw listReset
        |> Spacing.withGap Sm


{-| The vertical flex direction plus the `<ul>` reset (`list-none m-0 p-0`).
`flex-col` has no flex-direction token in this library, and the list reset has
no token channel, so both stay as raw utilities behind this named constant.
-}
listReset : String
listReset =
    "flex-col list-none m-0 p-0"


{-| Toggle between-item dividers (bottom border on every child but the last).
Matches the old `DividerBetween`; the divider draws in the engine's default
border hairline (`border-border-default`, the `--border-default` contract var).
-}
withDividers : Bool -> Items msg -> Items msg
withDividers on (Items l) =
    Items { l | dividers = on }


withStyle : (Config Standard -> Config Standard) -> Items msg -> Items msg
withStyle fn (Items l) =
    Items { l | style = fn l.style }


{-| The old `DividerBetween` selector pair. The width/side (`border-b`) is a raw
util since the theme `Border` token emits color only; the color is the engine
`Border.Default` hairline (`border-border-default`, variant-wrapped so it hits
the children). The old `border-border` token no longer exists anywhere — it
emitted no CSS, so dividers silently fell back to currentColor.
-}
dividerClass : String
dividerClass =
    "[&>*:not(:last-child)]:border-b [&>*:not(:last-child)]:border-border-default"


view : Items msg -> Html msg
view (Items l) =
    let
        styled =
            if l.dividers then
                Config.addRaw dividerClass l.style

            else
                l.style
    in
    Html.ul
        (Html.Attributes.class (Config.toClasses styled) :: Config.toStyleAttributes styled)
        l.items
