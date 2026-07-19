module Tebru.Box exposing
    ( Element(..)
    , GridCols
    , Layout
    , MousePosition
    , box
    , grid
    , mousePosition
    , row
    , stack
    , toClasses
    , view
    , withElement
    , withGridCols
    , withHoverStyle
    , withInlineStyle
    , withOn
    , withOnBlur
    , withOnClick
    , withOnClickStopPropagation
    , withOnContextMenu
    , withOnContextMenuPreventDefault
    , withOnDoubleClick
    , withOnFocus
    , withOnKeyDown
    , withOnKeyDownPreventDefault
    , withOnKeyUp
    , withOnMouseDown
    , withOnMouseDownPreventDefault
    , withOnMouseDownStopPropagation
    , withOnMouseEnter
    , withOnMouseLeave
    , withOnMouseMove
    , withOnMouseOut
    , withOnMouseOver
    , withOnMouseUp
    , withOnWheel
    , withOnWithOptions
    , withStyle
    , withTabIndex
    )

import Html exposing (Html)
import Html.Attributes
import Html.Events
import Json.Decode as Decode
import Tebru.Box.GridCols as GridColsMatrix
import Tebru.Theme.Config as Config exposing (Config, Hover, Standard)
import Tebru.Theme.Space as Space exposing (Space)
import Tebru.Theme.Spacing as Spacing
import Tebru.Theme.Structure as Structure



-- Phantom kind markers (module-internal; not exposed).


type Flex
    = Flex


type Grid
    = Grid


type Layout kind msg
    = Box (BoxConfig msg)


{-| The semantic tag a Box renders as (via `withElement`). Deliberately
minimal — tags are added on demand when a consumer needs one, not
speculatively; see the extend-on-demand policy in CLAUDE.md.
-}
type Element
    = Div
    | Span
    | Ul
    | Li
    | Nav
    | Section
    | Header


type alias GridCols =
    { sm : Int, md : Int, lg : Int, xl : Int }


type alias BoxConfig msg =
    { element : Element
    , container : List String
    , gridCols : Maybe GridCols
    , style : Config Standard
    , hoverStyle : Config Hover
    , attrs : List (Html.Attribute msg)
    , children : List (Html msg)
    }


{-| The constructor gap AND display class are seeded into the style config
through the same setters `withStyle` modifiers use (`Spacing.withGap`'s "gap"
key, `Structure.withDisplay`'s "display" key), so each lives under the SAME
keyed-dict entry as a later `withStyle` override — last-wins holds across both
channels instead of both classes emitting (with the winner decided by CSS
source order). Only the flex direction (`flex-row`/`flex-col`) stays a raw
container class: no Config setter writes it, so it cannot collide.
`Space.None` seeds nothing, preserving "no gap class" for `box`/None
constructors.
-}
emptyBox : List String -> Maybe Structure.Display -> Space -> List (Html msg) -> BoxConfig msg
emptyBox container display gap children =
    { element = Div
    , container = container
    , gridCols = Nothing
    , style =
        Config.default
            |> (display |> Maybe.map Structure.withDisplay |> Maybe.withDefault identity)
            |> (if gap == Space.None then
                    identity

                else
                    Spacing.withGap gap
               )
    , hoverStyle = Config.defaultHover
    , attrs = []
    , children = children
    }


box : List (Html msg) -> Layout Flex msg
box children =
    Box (emptyBox [] Nothing Space.None children)


row : Space -> List (Html msg) -> Layout Flex msg
row gap children =
    Box (emptyBox [ "flex-row" ] (Just Structure.Flex) gap children)


stack : Space -> List (Html msg) -> Layout Flex msg
stack gap children =
    Box (emptyBox [ "flex-col" ] (Just Structure.Flex) gap children)


grid : Space -> List (Html msg) -> Layout Grid msg
grid gap children =
    Box (emptyBox [] (Just Structure.Grid) gap children)


{-| Resolve the responsive column counts to grid-cols classes, via the
generated `Tebru.Box.GridCols` matrix. Each breakpoint maps its count through a
CLOSED case (cols 1–12) that returns a LITERAL class INCLUDING its breakpoint
prefix (e.g. `"md:grid-cols-3"`) — because the prefix is part of the class, a
composed `"md:" ++ n` would be invisible to Tailwind's scanner. Literal arms
keep them generated straight from source (no safelist). Out of range falls back
to a single column.
-}
gridColsClasses : GridCols -> List String
gridColsClasses c =
    [ GridColsMatrix.smCols c.sm, GridColsMatrix.mdCols c.md, GridColsMatrix.lgCols c.lg, GridColsMatrix.xlCols c.xl ]


toClasses : Layout kind msg -> String
toClasses (Box b) =
    let
        cols =
            Maybe.map gridColsClasses b.gridCols |> Maybe.withDefault []
    in
    (b.container ++ cols ++ [ Config.toClasses b.style, Config.hoverToClasses b.hoverStyle ])
        |> List.filter (\s -> s /= "")
        |> String.join " "


elementFn : Element -> (List (Html.Attribute msg) -> List (Html msg) -> Html msg)
elementFn el =
    case el of
        Div ->
            Html.div

        Span ->
            Html.span

        Ul ->
            Html.ul

        Li ->
            Html.li

        Nav ->
            Html.nav

        Section ->
            Html.section

        Header ->
            Html.header


view : Layout kind msg -> Html msg
view (Box b) =
    elementFn b.element
        (Html.Attributes.class (toClasses (Box b)) :: Config.toStyleAttributes b.style ++ b.attrs)
        b.children


withStyle : (Config Standard -> Config Standard) -> Layout kind msg -> Layout kind msg
withStyle fn (Box b) =
    Box { b | style = fn b.style }


withHoverStyle : (Config Hover -> Config Hover) -> Layout kind msg -> Layout kind msg
withHoverStyle fn (Box b) =
    Box { b | hoverStyle = fn b.hoverStyle }


withElement : Element -> Layout kind msg -> Layout kind msg
withElement el (Box b) =
    Box { b | element = el }


withGridCols : GridCols -> Layout Grid msg -> Layout Grid msg
withGridCols cols (Box b) =
    Box { b | gridCols = Just cols }


appendAttr : Html.Attribute msg -> Layout kind msg -> Layout kind msg
appendAttr a (Box b) =
    Box { b | attrs = b.attrs ++ [ a ] }


{-| Apply runtime-computed inline CSS, as `[ ( property, value ) ]` pairs.

This is the SANCTIONED channel for **dynamic geometry only** — positions and
sizes derived from runtime data that Tailwind's JIT cannot generate (arbitrary
`top`/`height`/`left`/`width` px, computed `transform`, etc.). It exists at the
layout-primitive layer, NOT in app code: Pages/Views compose tokens via
`withStyle`; only components reach for this, and only for values that genuinely
cannot be a token or a static utility class.

Routes through the `Config` styles channel (`Config.withInlineStyle`), so pairs
are keyed by property with last-wins semantics — a later `withInlineStyle` or
`Config.setStyle` for the same property (via either entry point, in pipeline
order) overrides an earlier one. One channel, one semantics.

Do NOT use it for static styling that a `theme` token or `Config.addRaw`
arbitrary class can express — that belongs in `withStyle`.

-}
withInlineStyle : List ( String, String ) -> Layout kind msg -> Layout kind msg
withInlineStyle pairs =
    withStyle (Config.withInlineStyle pairs)


{-| Attach a listener for any DOM event. Root of Box's event-modifier family.

Naming convention: Box prefixes every event modifier `withOn*` because they are
layout **modifiers** in a `|>` pipeline alongside `withStyle`/`withElement`;
components name their event **slots** with bare verbs (`Button.onClick`,
`Input.onInput`, `Slider.onChange`) because those fill a semantic slot in the
component's config. Behavior-altering variants say so in the name:
`*PreventDefault` / `*StopPropagation`.

-}
withOn : String -> Decode.Decoder msg -> Layout kind msg -> Layout kind msg
withOn event decoder =
    appendAttr (Html.Events.on event decoder)


withOnWithOptions : String -> { stopPropagation : Bool, preventDefault : Bool } -> Decode.Decoder msg -> Layout kind msg -> Layout kind msg
withOnWithOptions event opts decoder =
    appendAttr
        (Html.Events.custom event
            (Decode.map (\m -> { message = m, stopPropagation = opts.stopPropagation, preventDefault = opts.preventDefault }) decoder)
        )


withOnClick : msg -> Layout kind msg -> Layout kind msg
withOnClick msg =
    withOn "click" (Decode.succeed msg)


withOnDoubleClick : msg -> Layout kind msg -> Layout kind msg
withOnDoubleClick msg =
    withOn "dblclick" (Decode.succeed msg)


{-| Plain mousedown listener — no default suppression. For drag interactions
you almost certainly want `withOnMouseDownPreventDefault` instead.
-}
withOnMouseDown : msg -> Layout kind msg -> Layout kind msg
withOnMouseDown msg =
    withOn "mousedown" (Decode.succeed msg)


{-| Mousedown handler that also `preventDefault`s — this suppresses the browser's
native text-selection (and drag-image) behavior that otherwise hijacks a custom
drag. Without it, Firefox starts a text selection on mousedown and then stops
firing `mouseenter` for the duration, breaking drag-to-paint / move / resize
(Chrome is lenient; Firefox is not). Matches the old `Ui.Layout` behavior, which
used `preventDefaultOn "mousedown"` on every mousedown.
-}
withOnMouseDownPreventDefault : msg -> Layout kind msg -> Layout kind msg
withOnMouseDownPreventDefault msg =
    withOnWithOptions "mousedown" { stopPropagation = False, preventDefault = True } (Decode.succeed msg)


withOnMouseUp : msg -> Layout kind msg -> Layout kind msg
withOnMouseUp msg =
    withOn "mouseup" (Decode.succeed msg)


withOnMouseEnter : msg -> Layout kind msg -> Layout kind msg
withOnMouseEnter msg =
    withOn "mouseenter" (Decode.succeed msg)


withOnMouseLeave : msg -> Layout kind msg -> Layout kind msg
withOnMouseLeave msg =
    withOn "mouseleave" (Decode.succeed msg)


withOnMouseOver : msg -> Layout kind msg -> Layout kind msg
withOnMouseOver msg =
    withOn "mouseover" (Decode.succeed msg)


withOnMouseOut : msg -> Layout kind msg -> Layout kind msg
withOnMouseOut msg =
    withOn "mouseout" (Decode.succeed msg)


withOnMouseMove : msg -> Layout kind msg -> Layout kind msg
withOnMouseMove msg =
    withOn "mousemove" (Decode.succeed msg)


withOnContextMenu : msg -> Layout kind msg -> Layout kind msg
withOnContextMenu msg =
    withOn "contextmenu" (Decode.succeed msg)


withOnWheel : msg -> Layout kind msg -> Layout kind msg
withOnWheel msg =
    withOn "wheel" (Decode.succeed msg)


withOnKeyDown : (String -> msg) -> Layout kind msg -> Layout kind msg
withOnKeyDown toMsg =
    withOn "keydown" (Decode.map toMsg (Decode.field "key" Decode.string))


withOnKeyUp : (String -> msg) -> Layout kind msg -> Layout kind msg
withOnKeyUp toMsg =
    withOn "keyup" (Decode.map toMsg (Decode.field "key" Decode.string))


withOnFocus : msg -> Layout kind msg -> Layout kind msg
withOnFocus msg =
    withOn "focus" (Decode.succeed msg)


withOnBlur : msg -> Layout kind msg -> Layout kind msg
withOnBlur msg =
    withOn "blur" (Decode.succeed msg)


withOnClickStopPropagation : msg -> Layout kind msg -> Layout kind msg
withOnClickStopPropagation msg =
    withOnWithOptions "click" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)


withOnMouseDownStopPropagation : msg -> Layout kind msg -> Layout kind msg
withOnMouseDownStopPropagation msg =
    withOnWithOptions "mousedown" { stopPropagation = True, preventDefault = False } (Decode.succeed msg)


withOnContextMenuPreventDefault : msg -> Layout kind msg -> Layout kind msg
withOnContextMenuPreventDefault msg =
    withOnWithOptions "contextmenu" { stopPropagation = False, preventDefault = True } (Decode.succeed msg)


withOnKeyDownPreventDefault : (String -> msg) -> Layout kind msg -> Layout kind msg
withOnKeyDownPreventDefault toMsg =
    withOnWithOptions "keydown" { stopPropagation = False, preventDefault = True } (Decode.map toMsg (Decode.field "key" Decode.string))


withTabIndex : Int -> Layout kind msg -> Layout kind msg
withTabIndex i =
    appendAttr (Html.Attributes.tabindex i)


type alias MousePosition =
    { clientX : Float, clientY : Float }


mousePosition : Decode.Decoder MousePosition
mousePosition =
    Decode.map2 MousePosition (Decode.field "clientX" Decode.float) (Decode.field "clientY" Decode.float)
