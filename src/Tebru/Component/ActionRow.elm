module Tebru.Component.ActionRow exposing (ActionRow, default, split, view, withStyle)

{-| Headless ActionRow primitive — a horizontal row of action elements
(typically buttons).

`default`/`view` produce the **end** layout: one or more actions right-aligned
with no gap. Use for a single "Save"/"Submit" at the top or bottom of a form
section.

    ActionRow.default
        [ Button.default "Save" |> Button.withStyle (Surface.withSurface Surface.Brand) |> Button.view
        ]
        |> ActionRow.view

`split` produces the **split** layout: two actions at opposing ends
(justify-between) with an Sm gap — Cancel on the left, action on the right.
Standard for confirm/cancel pairs. The record makes the "two distinct slots"
semantics visible at the call site.

    ActionRow.split
        { left = Button.default "Cancel" |> Button.view
        , right = Button.default "Save" |> Button.withStyle (Surface.withSurface Surface.Brand) |> Button.view
        }
        |> ActionRow.view

Both are headless — override styling via `withStyle`.

-}

import Html exposing (Html)
import Tebru.Box as Layout
import Tebru.Theme.Config exposing (Config, Standard)
import Tebru.Theme.Space exposing (Space(..))
import Tebru.Theme.Structure as Structure


type ActionRow msg
    = End
        { actions : List (Html msg)
        , extraStyle : Config Standard -> Config Standard
        }
    | Split
        { left : Html msg
        , right : Html msg
        , extraStyle : Config Standard -> Config Standard
        }


{-| End layout: actions aligned to the end (justify-end) with no gap.
-}
default : List (Html msg) -> ActionRow msg
default actions =
    End { actions = actions, extraStyle = identity }


{-| Split layout: two actions at opposing ends (justify-between) with an Sm gap.
-}
split : { left : Html msg, right : Html msg } -> ActionRow msg
split { left, right } =
    Split { left = left, right = right, extraStyle = identity }


withStyle : (Config Standard -> Config Standard) -> ActionRow msg -> ActionRow msg
withStyle fn actionRow =
    case actionRow of
        End r ->
            End { r | extraStyle = r.extraStyle >> fn }

        Split r ->
            Split { r | extraStyle = r.extraStyle >> fn }


view : ActionRow msg -> Html msg
view actionRow =
    case actionRow of
        End r ->
            Layout.row None r.actions
                |> Layout.withStyle (Structure.withJustify Structure.JustifyEnd >> r.extraStyle)
                |> Layout.view

        Split r ->
            Layout.row Sm [ r.left, r.right ]
                |> Layout.withStyle (Structure.withJustify Structure.JustifyBetween >> r.extraStyle)
                |> Layout.view
