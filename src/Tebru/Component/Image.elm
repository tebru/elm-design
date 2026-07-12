module Tebru.Component.Image exposing (Image, default, withStyle, view)

{-| Headless image primitive — a styled `<img>`.

    import Tebru.Component.Image as Image
    import Tebru.Theme.Structure as Structure

    Image.default { src = "/logo.svg", alt = "Logo" }
        |> Image.withStyle (Structure.withDisplay Structure.Block >> Structure.withHeight Structure.S6)
        |> Image.view

The `<img>` element and its `Config.default` base live here, so consumers (e.g.
the app logo) compose typed `Theme.*` modifiers via `withStyle` instead of
minting a `Config` of their own.

@docs Image, default, withStyle, view

-}

import Html exposing (Html)
import Html.Attributes
import Tebru.Theme.Config as Config exposing (Config, Standard)


{-| A styled image. Build with `default`, style with `withStyle`, render with `view`.
-}
type Image msg
    = Image
        { src : String
        , alt : String
        , style : Config Standard
        }


{-| Build an image from its source URL and alt text. No styling by default.
-}
default : { src : String, alt : String } -> Image msg
default opts =
    Image { src = opts.src, alt = opts.alt, style = Config.default }


{-| Override the image's Config (size, display, radius, …) with typed modifiers.
-}
withStyle : (Config Standard -> Config Standard) -> Image msg -> Image msg
withStyle fn (Image i) =
    Image { i | style = fn i.style }


{-| Render the `<img>`.
-}
view : Image msg -> Html msg
view (Image i) =
    Html.img
        (Html.Attributes.src i.src :: Html.Attributes.alt i.alt :: Config.toAttributes i.style Nothing)
        []
