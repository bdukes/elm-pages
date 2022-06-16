module Pages.FieldRenderer exposing (..)

{-| -}

import Html exposing (Html)
import Html.Attributes as Attr
import Json.Encode as Encode


type InputType
    = Text
    | Number
    | Range
    | Radio
      -- TODO should submit be a special type, or an Input type?
      -- TODO have an option for a submit with a name/value?
    | Date
    | Checkbox
    | Tel
    | Search
    | Password
    | Email
    | Url


inputTypeToString : InputType -> String
inputTypeToString inputType =
    case inputType of
        Text ->
            "text"

        Number ->
            "number"

        Range ->
            "range"

        Radio ->
            "radio"

        Date ->
            "date"

        Checkbox ->
            "checkbox"

        Tel ->
            "tel"

        Search ->
            "search"

        Password ->
            "password"

        Email ->
            "email"

        Url ->
            "url"


type Input
    = Input InputType


type Select a
    = Select (String -> Maybe a) (List String)


{-| -}
input :
    List (Html.Attribute msg)
    ->
        { input
            | value : Maybe String
            , name : String
            , kind : ( Input, List ( String, Encode.Value ) )
        }
    -> Html msg
input attrs rawField =
    case rawField.kind of
        ( Input inputType, properties ) ->
            Html.input
                (attrs
                    ++ toHtmlProperties properties
                    ++ [ (case inputType of
                            Checkbox ->
                                Attr.checked ((rawField.value |> Maybe.withDefault "") == "on")

                            _ ->
                                Attr.value (rawField.value |> Maybe.withDefault "")
                          -- TODO is this an okay default?
                         )
                       , Attr.name rawField.name
                       , inputType |> inputTypeToString |> Attr.type_
                       ]
                )
                []


{-| -}
select :
    List (Html.Attribute msg)
    ->
        (parsed
         ->
            ( List (Html.Attribute msg)
            , List (Html.Html msg)
            )
        )
    ->
        { input
            | value : Maybe String
            , name : String
            , kind : ( Select parsed, List ( String, Encode.Value ) )
        }
    -> Html msg
select selectAttrs enumToOption rawField =
    let
        (Select parseValue possibleValues) =
            rawField.kind |> Tuple.first
    in
    Html.select
        (selectAttrs
            -- TODO need to handle other input types like checkbox
            ++ [ Attr.value (rawField.value |> Maybe.withDefault "") -- TODO is this an okay default?
               , Attr.name rawField.name
               ]
        )
        (possibleValues
            |> List.filterMap
                (\possibleValue ->
                    let
                        parsed : Maybe parsed
                        parsed =
                            possibleValue
                                |> parseValue
                    in
                    case parsed of
                        Just justParsed ->
                            let
                                ( optionAttrs, children ) =
                                    enumToOption justParsed
                            in
                            Html.option (Attr.value possibleValue :: optionAttrs) children
                                |> Just

                        Nothing ->
                            Nothing
                )
        )


toHtmlProperties : List ( String, Encode.Value ) -> List (Html.Attribute msg)
toHtmlProperties properties =
    properties
        |> List.map
            (\( key, value ) ->
                Attr.property key value
            )