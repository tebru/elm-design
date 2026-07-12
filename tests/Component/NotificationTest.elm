module Component.NotificationTest exposing (suite)

import Html
import Tebru.Component.Notification as Notification
import Tebru.Icon.Geometry as Geometry
import Tebru.Theme.Border as Border
import Tebru.Theme.Surface as Surface
import Tebru.Theme.Text as Text
import Test exposing (Test, describe, test)
import Test.Html.Event as Event
import Test.Html.Query as Query
import Test.Html.Selector as Selector


suite : Test
suite =
    describe "Component.Notification"
        [ describe "banner"
            [ test "renders content" <|
                \_ ->
                    Notification.banner
                        { content = Html.text "Settings saved."
                        , onDismiss = Nothing
                        }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Settings saved." ]
            , test "has default subtle surface class" <|
                \_ ->
                    Notification.banner { content = Html.text "", onDismiss = Nothing }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-subtle" ]
            , test "no dismiss button when onDismiss is Nothing" <|
                \_ ->
                    Notification.banner { content = Html.text "Hi", onDismiss = Nothing }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.hasNot [ Selector.class "lucide-icon" ]
            , test "dismiss button appears when onDismiss is Just" <|
                \_ ->
                    Notification.banner { content = Html.text "Hi", onDismiss = Just () }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "lucide-icon" ]
            , test "clicking dismiss fires the msg" <|
                \_ ->
                    Notification.banner { content = Html.text "Hi", onDismiss = Just "dismissed" }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.findAll [ Selector.tag "div" ]
                        |> Query.index 0
                        |> Event.simulate Event.click
                        |> Event.expect "dismissed"
            , test "withStyle overrides the surface" <|
                \_ ->
                    Notification.banner { content = Html.text "", onDismiss = Nothing }
                        |> Notification.withStyle (Surface.withSurface Surface.Warning)
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-warning" ]
            , test "keeps the constructor row gap (gap-lg) alongside its own style" <|
                \_ ->
                    Notification.banner { content = Html.text "", onDismiss = Nothing }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "gap-lg", Selector.class "bg-surface-subtle" ]
            ]
        , describe "toast"
            [ test "renders content" <|
                \_ ->
                    Notification.toast
                        { content = Html.text "Upload complete."
                        , onDismiss = Nothing
                        }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Upload complete." ]
            , test "has default inverse surface class" <|
                \_ ->
                    Notification.toast { content = Html.text "", onDismiss = Nothing }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-inverse" ]
            , test "clicking dismiss fires the msg" <|
                \_ ->
                    Notification.toast { content = Html.text "Done", onDismiss = Just "dismissed" }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.findAll [ Selector.tag "div" ]
                        |> Query.index 0
                        |> Event.simulate Event.click
                        |> Event.expect "dismissed"
            , test "withStyle overrides the surface" <|
                \_ ->
                    Notification.toast { content = Html.text "", onDismiss = Nothing }
                        |> Notification.withStyle (Surface.withSurface Surface.Danger)
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-danger" ]
            , test "keeps the constructor row gap (gap-md) alongside its own style" <|
                \_ ->
                    Notification.toast { content = Html.text "", onDismiss = Nothing }
                        |> Notification.view
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "gap-md", Selector.class "bg-surface-inverse" ]
            ]
        , describe "toastOverlay"
            [ test "renders content, icon and the entry animation" <|
                \_ ->
                    Notification.toastOverlay
                        { icon = Geometry.circleCheck
                        , style = identity
                        , content = Html.text "Saved."
                        , onDismiss = ()
                        }
                        |> Query.fromHtml
                        |> Query.has [ Selector.text "Saved.", Selector.class "lucide-icon", Selector.class "animate-slide-down" ]
            , test "the style slot supplies the level colors" <|
                \_ ->
                    Notification.toastOverlay
                        { icon = Geometry.circleAlert
                        , style = Surface.withSurface Surface.Error >> Text.withText Text.Error >> Border.withBorder Border.Error
                        , content = Html.text "Failed."
                        , onDismiss = ()
                        }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "bg-surface-error", Selector.class "text-fg-error", Selector.class "border-border-error" ]
            , test "the toast card keeps its gap-md through the chrome replacement" <|
                \_ ->
                    Notification.toastOverlay
                        { icon = Geometry.circleCheck
                        , style = identity
                        , content = Html.text "Saved."
                        , onDismiss = ()
                        }
                        |> Query.fromHtml
                        |> Query.has [ Selector.class "gap-md", Selector.class "shadow-xl" ]
            ]
        ]
