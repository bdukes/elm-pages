module Pages.FormParser exposing (..)

import Dict exposing (Dict)
import Pages.Form as Form


type
    ParseResult error decoded
    -- TODO parse into both errors AND a decoded value
    = Success decoded
    | DecodedWithErrors (Dict String (List error)) decoded
    | DecodeFailure (Dict String (List error))


type Parser error decoded
    = Parser (Dict String (List error) -> Form.FormState -> ( Maybe decoded, Dict String (List error) ))


optional : String -> Parser error (Maybe String)
optional name =
    (\errors form ->
        ( Just (form |> Dict.get name |> Maybe.map .value), errors )
    )
        |> Parser


init =
    Debug.todo ""


string : error -> FieldThing error String
string error =
    --Debug.todo ""
    FieldThing (\formState -> ( Just "TODO real value", [] ))


andThenNew : a -> CombinedParser String a
andThenNew fn =
    CombinedParser []
        (\formState ->
            ( Just fn, Dict.empty )
        )



--CombinedParser
--    []
--    (\formState ->
--        --let
--        --    something =
--        --        fn
--        --in
--        -- TODO use fn
--        ( Nothing, Dict.empty )
--    )


field :
    String
    -> FieldThing error parsed
    -> CombinedParser error (ParsedField error parsed -> a)
    -> CombinedParser error a
field name (FieldThing fieldParser) (CombinedParser definitions parseFn) =
    --let
    --    --myFn :
    --    --    ( Maybe ((ParsedField error parsed -> a) -> b)
    --    --    , Dict String (List error)
    --    --    )
    --    --    -> ( Maybe b, Dict String (List error) )
    --    --myFn ( fieldThings, errorsSoFar ) =
    --    --    --Debug.todo ""
    --    --    ( Nothing, errorsSoFar )
    --    fieldParser : Form.FormState -> ( Maybe parsed, List error )
    --    fieldParser formState =
    --        Debug.todo ""
    --in
    CombinedParser
        (( name, FieldDefinition )
            :: definitions
        )
        (\formState ->
            let
                --something : ( Maybe parsed, List error )
                ( maybeParsed, errors ) =
                    fieldParser formState

                parsedField : ParsedField error parsed
                parsedField =
                    { name = name
                    , value = maybeParsed
                    , errors = errors
                    }

                myFn :
                    ( Maybe (ParsedField error parsed -> a)
                    , Dict String (List error)
                    )
                    -> ( Maybe a, Dict String (List error) )
                myFn ( fieldThings, errorsSoFar ) =
                    ( --Nothing
                      --Maybe.map2 (|>) fieldThings (Just parsedField)
                      case fieldThings of
                        Just fieldPipelineFn ->
                            fieldPipelineFn parsedField
                                |> Just

                        Nothing ->
                            Nothing
                    , errorsSoFar
                        |> addErrors name errors
                    )
            in
            formState
                |> parseFn
                |> myFn
        )



--field :
--    String
--    -> FieldThing error parsed
--    -> CombinedParser error ((ParsedField error parsed -> a) -> b)
--    -> CombinedParser error b
--field name fieldThing (CombinedParser definitions parseFn) =
--    --Debug.todo ""
--    let
--        myFn :
--            ( Maybe ((ParsedField error parsed -> a) -> b)
--            , Dict String (List error)
--            )
--            -> ( Maybe b, Dict String (List error) )
--        myFn ( fieldThings, errorsSoFar ) =
--            --Debug.todo ""
--            ( Nothing, errorsSoFar )
--    in
--    CombinedParser definitions
--        (\formState ->
--            formState
--                |> parseFn
--                |> myFn
--        )
--(List ( String, FieldDefinition )) (Form.FormState -> ( Maybe parsed, Dict String (List error) ))


type ParsingResult a
    = ParsingResult


type CompleteParser error parsed
    = CompleteParser


runNew : Form.FormState -> CombinedParser error parsed -> ( Maybe parsed, Dict String (List error) )
runNew formState (CombinedParser fieldDefinitions parser) =
    --Debug.todo ""
    parser formState


type CombinedParser error parsed
    = CombinedParser (List ( String, FieldDefinition )) (Form.FormState -> ( Maybe parsed, Dict String (List error) ))



--String
--  -> (a -> v)
--  -> Codec a
--  -> CustomCodec ((a -> Value) -> b) v
--  -> CustomCodec b v


type FieldThing error parsed
    = FieldThing (Form.FormState -> ( Maybe parsed, List error ))


type FieldDefinition
    = FieldDefinition


type FullFieldThing error parsed
    = FullFieldThing { name : String } (Form.FormState -> parsed)



---> a1
---> a2
--field :
--    String
--    -> FieldThing error parsed
--    -> CombinedParser error ((FullFieldThing error parsed -> a) -> b)
--    -> CombinedParser error b
--field name fieldThing (CombinedParser definitions parseFn) =
--    --Debug.todo ""
--    let
--        myFn :
--            ( Maybe ((FullFieldThing error parsed -> a) -> b)
--            , Dict String (List error)
--            )
--            -> ( Maybe b, Dict String (List error) )
--        myFn ( fieldThings, errorsSoFar ) =
--            --Debug.todo ""
--            ( Nothing, errorsSoFar )
--    in
--    CombinedParser definitions
--        (\formState ->
--            formState
--                |> parseFn
--                |> myFn
--        )


type alias ParsedField error parsed =
    { name : String
    , value : Maybe parsed
    , errors : List error
    }


value : FullFieldThing error parsed -> parsed
value =
    Debug.todo ""



--ok : parsed -> FullFieldThing error parsed
--ok okValue =
--    --Debug.todo ""
--    FullFieldThing { name = "TODO" } (\_ -> okValue)


ok =
    ()


withError : error -> ParsedField error parsed -> ()
withError _ _ =
    --Debug.todo ""
    ()


required : String -> error -> Parser error String
required name error =
    (\errors form ->
        case form |> Dict.get name |> Maybe.map .value of
            Just "" ->
                ( Just "", errors |> addError name error )

            Just nonEmptyValue ->
                ( Just nonEmptyValue, errors )

            Nothing ->
                ( Just "", errors |> addError name error )
    )
        |> Parser


int : String -> error -> Parser error Int
int name error =
    (\errors form ->
        case form |> Dict.get name |> Maybe.map .value of
            Just "" ->
                ( Nothing, errors |> addError name error )

            Just nonEmptyValue ->
                case nonEmptyValue |> String.toInt of
                    Just parsedInt ->
                        ( Just parsedInt, errors )

                    Nothing ->
                        ( Nothing, errors |> addError name error )

            Nothing ->
                ( Nothing, errors |> addError name error )
    )
        |> Parser


map2 : (value1 -> value2 -> combined) -> Parser error value1 -> Parser error value2 -> Parser error combined
map2 combineFn (Parser parser1) (Parser parser2) =
    (\errors form ->
        let
            ( combined1, allErrors1 ) =
                parser1 errors form

            ( combined2, allErrors2 ) =
                parser2 errors form
        in
        ( Maybe.map2 combineFn combined1 combined2
        , Dict.merge (\name errors1 dict -> ( name, errors1 ) :: dict)
            (\name errors1 errors2 dict -> ( name, errors1 ++ errors2 ) :: dict)
            (\name errors2 dict -> ( name, errors2 ) :: dict)
            allErrors1
            allErrors2
            []
            |> Dict.fromList
        )
    )
        |> Parser


map : (original -> mapped) -> Parser error original -> Parser error mapped
map mapFn (Parser parser) =
    (\errors form ->
        let
            ( combined1, allErrors1 ) =
                parser errors form
        in
        ( Maybe.map mapFn combined1
        , allErrors1
        )
    )
        |> Parser


validate : String -> (original -> Result error mapped) -> Parser error original -> Parser error mapped
validate name mapFn (Parser parser) =
    (\errors form ->
        let
            ( combined1, allErrors1 ) =
                parser errors form
        in
        case combined1 |> Maybe.map mapFn of
            Just (Ok okResult) ->
                ( Just okResult
                , allErrors1
                )

            Just (Err error) ->
                ( Nothing
                , allErrors1 |> addError name error
                )

            Nothing ->
                ( Nothing
                , allErrors1
                )
    )
        |> Parser


succeed : value -> Parser error value
succeed value_ =
    Parser (\errors form -> ( Just value_, Dict.empty ))


fail : error -> Parser error value
fail error =
    Parser (\errors form -> ( Nothing, Dict.fromList [ ( "global", [ error ] ) ] ))


andThen : (value1 -> Parser error value2) -> Parser error value1 -> Parser error value2
andThen andThenFn (Parser parser1) =
    (\errors form ->
        let
            ( combined1, allErrors1 ) =
                parser1 errors form

            foo : Maybe (Parser error value2)
            foo =
                Maybe.map andThenFn combined1
        in
        case foo of
            Just (Parser parser2) ->
                let
                    ( combined2, allErrors2 ) =
                        parser2 errors form
                in
                ( combined2
                , Dict.merge (\name errors1 dict -> ( name, errors1 ) :: dict)
                    (\name errors1 errors2 dict -> ( name, errors1 ++ errors2 ) :: dict)
                    (\name errors2 dict -> ( name, errors2 ) :: dict)
                    allErrors1
                    allErrors2
                    []
                    |> Dict.fromList
                )

            Nothing ->
                ( Nothing, allErrors1 )
    )
        |> Parser


run : Form.FormState -> Parser error decoded -> ( Maybe decoded, Dict String (List error) )
run formState (Parser parser) =
    parser Dict.empty formState


runOnList : List ( String, String ) -> Parser error decoded -> ( Maybe decoded, Dict String (List error) )
runOnList rawFormData (Parser parser) =
    (rawFormData
        |> List.map
            (Tuple.mapSecond (\value_ -> { value = value_, status = Form.NotVisited }))
        |> Dict.fromList
    )
        |> parser Dict.empty


addError : String -> error -> Dict String (List error) -> Dict String (List error)
addError name error allErrors =
    allErrors
        |> Dict.update name
            (\errors ->
                Just (error :: (errors |> Maybe.withDefault []))
            )


addErrors : String -> List error -> Dict String (List error) -> Dict String (List error)
addErrors name newErrors allErrors =
    allErrors
        |> Dict.update name
            (\errors ->
                Just (newErrors ++ (errors |> Maybe.withDefault []))
            )
