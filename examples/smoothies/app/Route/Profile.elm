module Route.Profile exposing (ActionData, Data, Model, Msg, route)

import Api.Scalar exposing (Uuid(..))
import Data.User as User exposing (User)
import DataSource exposing (DataSource)
import Dict exposing (Dict)
import Effect exposing (Effect)
import ErrorPage exposing (ErrorPage)
import Head
import Head.Seo as Seo
import Html exposing (Html)
import Html.Attributes as Attr
import MySession
import Pages.Form
import Pages.FormParser as FormParser
import Pages.Msg
import Pages.PageUrl exposing (PageUrl)
import Pages.Transition
import Pages.Url
import Path exposing (Path)
import Request.Hasura
import Route
import RouteBuilder exposing (StatefulRoute, StatelessRoute, StaticPayload)
import Server.Request as Request
import Server.Response as Response exposing (Response)
import Server.Session as Session
import Shared
import View exposing (View)


type alias Model =
    {}


type Msg
    = NoOp


type alias RouteParams =
    {}


route : StatefulRoute RouteParams Data ActionData Model Msg
route =
    RouteBuilder.serverRender
        { head = head
        , data = data
        , action = action
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
    -> StaticPayload Data ActionData RouteParams
    -> ( Model, Effect Msg )
init maybePageUrl sharedModel static =
    ( {}
    , Effect.SetField
        { formId = "test"
        , name = "name"
        , value = "Testintg"
        }
    )


update :
    PageUrl
    -> Shared.Model
    -> StaticPayload Data ActionData RouteParams
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


type alias Data =
    { user : User
    }


type alias ActionData =
    Result { fields : List ( String, String ), errors : Dict String (List String) } Action


data : RouteParams -> Request.Parser (DataSource (Response Data ErrorPage))
data routeParams =
    Request.requestTime
        |> MySession.expectSessionDataOrRedirect (Session.get "userId")
            (\userId requestTime session ->
                User.selection userId
                    |> Request.Hasura.dataSource requestTime
                    |> DataSource.map
                        (\user ->
                            user
                                |> Data
                                |> Response.render
                                |> Tuple.pair session
                        )
            )


type alias Action =
    { username : String
    , name : String
    }


actionFormDecoder : FormParser.Parser String Action
actionFormDecoder =
    FormParser.succeed Action
        |> andMap (FormParser.required "username" "First is required" |> FormParser.validate "username" validateUsername)
        |> andMap (FormParser.required "name" "First is required")


validateUsername : String -> Result String String
validateUsername rawUsername =
    if rawUsername |> String.contains "@" then
        Err "Username cannot include @"

    else
        Ok rawUsername


andMap : FormParser.Parser error a -> FormParser.Parser error (a -> b) -> FormParser.Parser error b
andMap =
    FormParser.map2 (|>)


action : RouteParams -> Request.Parser (DataSource (Response ActionData ErrorPage))
action routeParams =
    Request.map2 Tuple.pair
        (Request.formParserResult actionFormDecoder)
        Request.requestTime
        |> MySession.expectSessionDataOrRedirect (Session.get "userId" >> Maybe.map Uuid)
            (\userId ( parsedAction, requestTime ) session ->
                case parsedAction |> Debug.log "parsedAction" of
                    Ok { name } ->
                        User.updateUser { userId = userId, name = name |> Debug.log "Updating name mutation" }
                            |> Request.Hasura.mutationDataSource requestTime
                            |> DataSource.map
                                (\_ ->
                                    --Response.render parsedAction
                                    Route.redirectTo Route.Profile
                                )
                            |> DataSource.map (Tuple.pair session)

                    Err errors ->
                        DataSource.succeed
                            (Response.render parsedAction)
                            |> DataSource.map (Tuple.pair session)
            )


head :
    StaticPayload Data ActionData RouteParams
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
        , description = "Update your profile"
        , locale = Nothing
        , title = "Profile"
        }
        |> Seo.website


view :
    Maybe PageUrl
    -> Shared.Model
    -> Model
    -> StaticPayload Data ActionData RouteParams
    -> View (Pages.Msg.Msg Msg)
view maybeUrl sharedModel model app =
    { title = "Ctrl-R Smoothies"
    , body =
        [ Html.p []
            [ Html.text <| "Welcome " ++ app.data.user.name ++ "!"
            , Html.form
                [ Attr.method "POST"
                , Pages.Msg.onSubmit
                ]
                [ Html.button [ Attr.name "kind", Attr.value "signout" ] [ Html.text "Sign out" ] ]
            ]
        , Route.Profile__Edit
            |> Route.link []
                [ Html.text <|
                    "Edit"
                ]
        , nameFormView app.data.user app.transition
        , Html.pre []
            [ app.action
                |> Debug.toString
                |> Html.text
            ]
        ]
    }


nameFormView : User -> Maybe Pages.Transition.Transition -> Html (Pages.Msg.Msg userMsg)
nameFormView user maybeTransition =
    Html.form
        (Pages.Form.listeners "test"
            ++ [ Attr.method "POST"
               , Pages.Msg.onSubmit
               ]
        )
        [ Html.fieldset
            []
            [ Html.label []
                [ Html.text "Username: "
                , Html.input
                    [ Attr.name "username"
                    , Attr.readonly True
                    , Attr.value user.username
                    ]
                    []
                ]
            , Html.label []
                [ Html.text "Name: "
                , Html.input
                    [ Attr.name "name"
                    , Attr.readonly True
                    , Attr.value user.name
                    ]
                    []
                ]
            ]
        ]