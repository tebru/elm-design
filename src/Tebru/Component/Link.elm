module Tebru.Component.Link exposing (Link, block, default, view, withHoverStyle, withStyle)

{-| Headless Link primitive.

    Link.default { href = "/home", content = Html.text "Home" }
        |> Link.view

Accepts arbitrary `Html msg` content so icons, badges, or styled nodes can be
embedded alongside text. Tonal overrides via withStyle:

    Link.default { href = "/home", content = Html.text "Home" }
        |> Link.withStyle (Text.withText Text.Secondary)
        |> Link.view

`default` bakes the link text color plus a pointer cursor, and a hover treatment
that shifts to the link-hover color. Tweak the hover treatment with
`withHoverStyle`:

    Link.default { href = "/home", content = Html.text "Home" }
        |> Link.withHoverStyle (Text.withText Text.Default)
        |> Link.view

`block` is the full-width display-block variant (e.g. a clickable card or list
row): pointer cursor, no inherited text color, no hover color shift.

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Structure as Structure
import Tebru.Theme.Text as Text


type Link msg
    = Link
        { href : String
        , content : Html msg
        , style : Config Standard
        , hoverStyle : Config Hover
        }


{-| Text-styled link: link color, pointer cursor, and a hover shift to the
link-hover color.
-}
default : { href : String, content : Html msg } -> Link msg
default opts =
    Link
        { href = opts.href
        , content = opts.content
        , style = baseStyle
        , hoverStyle = baseHoverStyle
        }


{-| Display-block link variant for clickable cards/rows: pointer cursor only,
no baked text or hover color.
-}
block : { href : String, content : Html msg } -> Link msg
block opts =
    Link
        { href = opts.href
        , content = opts.content
        , style = blockStyle
        , hoverStyle = Config.defaultHover
        }


baseStyle : Config Standard
baseStyle =
    Config.default
        |> Text.withText Text.Link
        |> Structure.withCursor Structure.CursorPointer


baseHoverStyle : Config Hover
baseHoverStyle =
    Config.defaultHover
        |> Text.withText Text.LinkHover


blockStyle : Config Standard
blockStyle =
    Config.default
        |> Structure.withDisplay Structure.Block
        |> Structure.withCursor Structure.CursorPointer


withStyle : (Config Standard -> Config Standard) -> Link msg -> Link msg
withStyle fn (Link l) =
    Link { l | style = fn l.style }


{-| Modify the hover style config — emitted as `hover:`-prefixed classes.
-}
withHoverStyle : (Config Hover -> Config Hover) -> Link msg -> Link msg
withHoverStyle fn (Link l) =
    Link { l | hoverStyle = fn l.hoverStyle }


view : Link msg -> Html msg
view (Link l) =
    Html.a
        (Html.Attributes.href l.href
            :: Html.Attributes.class (String.join " " (List.filter (\s -> s /= "") [ Config.toClasses l.style, Config.hoverToClasses l.hoverStyle ]))
            :: Config.toStyleAttributes l.style
        )
        [ l.content ]
