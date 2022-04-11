module Route.Feed__ exposing (Data, Model, Msg, route)

import DataSource exposing (DataSource)
import DataSource.Http
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import Head
import Head.Seo as Seo
import Html
import Html.Attributes as Attr
import Json.Decode exposing (Decoder)
import Json.Decode.Pipeline exposing (required)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Path exposing (Path)
import RouteBuilder exposing (StatefulRoute, StatelessRoute, StaticPayload)
import Server.Request as Request
import Server.Response as Response exposing (Response)
import Shared
import Story exposing (Item)
import Url.Builder
import View exposing (View)


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    { feed : Maybe String }


route : StatefulRoute RouteParams Data Model Msg
route =
    RouteBuilder.serverRender
        { head = head
        , data = data
        }
        |> RouteBuilder.buildWithLocalState
            { view = view
            , update = update
            , subscriptions = subscriptions
            , init = init
            }


init :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> ( Model, Effect Msg )
init maybePageUrl sharedModel static =
    ( {}, Effect.none )


update :
    PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> Msg
    -> Model
    -> ( Model, Effect Msg )
update pageUrl sharedModel static msg model =
    case msg of
        NoOp ->
            ( model, Effect.none )


subscriptions : Maybe PageUrl -> RouteParams -> Path -> Shared.Model -> Model -> Sub Msg
subscriptions maybePageUrl routeParams path sharedModel model =
    Sub.none


pages : DataSource (List RouteParams)
pages =
    DataSource.succeed []


type alias Data =
    { stories : List Item }


data : RouteParams -> Request.Parser (DataSource (Response Data ErrorPage))
data routeParams =
    Request.queryParam "page"
        |> Request.map
            (\maybePage ->
                let
                    feed : String
                    feed =
                        --const type = Astro.params.stories || "top";
                        case routeParams.feed |> Maybe.withDefault "top" of
                            "top" ->
                                "news"

                            "new" ->
                                "newest"

                            "show" ->
                                "show"

                            "ask" ->
                                "ask"

                            "job" ->
                                "jobs"

                            _ ->
                                "not-found"

                    getStoriesUrl : String
                    getStoriesUrl =
                        Url.Builder.crossOrigin "https://node-hnapi.herokuapp.com"
                            [ feed ]
                            [ Url.Builder.string "page" (maybePage |> Maybe.withDefault "1")
                            ]

                    getStories : DataSource (List Item)
                    getStories =
                        DataSource.Http.get getStoriesUrl
                            (Story.decoder |> Json.Decode.list)

                    --("https://node-hnapi.herokuapp.com/"
                    --    ++ feed
                    --    ++ "?page="
                    --)
                    --get(`https://node-hnapi.herokuapp.com/${l}?page=${page}`);
                in
                getStories |> DataSource.map (\stories -> Response.render { stories = stories })
            )


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel model static =
    { title = "News"
    , body =
        [ Html.main_
            [ Attr.class "news-list"
            ]
            [ static.data.stories
                |> List.map Story.view
                |> Html.ul []

            --, Html.text <| "Count: " ++ String.fromInt (static.data.stories |> List.length)
            ]
        ]
    }
