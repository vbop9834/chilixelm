module App exposing (..)

import Bootstrap.Grid exposing (..)
import Html exposing (Html, h1, text)
import Html.App


type alias Model = String

init : ( Model, Cmd Msg )
init =
  ( "Hello", Cmd.none )

type Msg =
    SomethingNew


view : Model -> Html Msg
view model =
  containerFluid
   [
    row
     [
      h1 [] [ text model ]
     ]
   ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SomethingNew ->
      ( "1111", Cmd.none )

subscriptions : Model -> Sub Msg
subscriptions model =
  Sub.none

main : Program Never
main =
    Html.App.program
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
