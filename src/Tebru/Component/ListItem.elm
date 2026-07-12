module Tebru.Component.ListItem exposing (ListItem, default, view, withStyle)

{-| Headless ListItem primitive — a bare, styled `<li>` wrapper.

Faithfully mirrors the original `Ui.ListItem`: it is just a `<li>` around
whatever content the caller supplies (a link, a button, a row with leading /
label / trailing slots, …). It bakes **no** default padding, border, hover, or
selected styling — those are the caller's responsibility, applied via
`withStyle`. Between-item dividers live on `Component.List` (`withDividers`),
not on the item, exactly as in the old design.

        -- Simple text item:
        ListItem.default [ Html.text "Item" ]
            |> ListItem.view

        -- Padded, hoverable row (caller supplies the chrome):
        ListItem.default
            [ Layout.row Sm [ leading, label, trailing ] |> Layout.view ]
            |> ListItem.withStyle (Spacing.withPadding (Spacing.xy Md Sm))
            |> ListItem.view

No variant enums — all styling overridable via `withStyle`.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)


type ListItem msg
    = ListItem
        { children : List (Html msg)
        , style : Config Standard
        }


{-| Bare `<li>` wrapping the given content — no baked styling.
-}
default : List (Html msg) -> ListItem msg
default children =
    ListItem { children = children, style = Config.default }


withStyle : (Config Standard -> Config Standard) -> ListItem msg -> ListItem msg
withStyle fn (ListItem item) =
    ListItem { item | style = fn item.style }


view : ListItem msg -> Html msg
view (ListItem item) =
    Html.li
        (Html.Attributes.class (Config.toClasses item.style) :: Config.toStyleAttributes item.style)
        item.children
