module App exposing (..)

import Bootstrap.Grid exposing (..)
import Bootstrap.ListGroup exposing (..)
import Bootstrap.Forms exposing (..)
import Bootstrap.Buttons exposing (..)

import Html exposing (Html, h1, h3, span, text)
import Html.App
import Html.Events exposing (onClick, onSubmit, onInput)

import Phoenix.Socket
import Phoenix.Channel
import Phoenix.Push

import Json.Encode as JsEncode
import Json.Decode as JsDecode exposing ((:=))

type alias ChatMessage =
  {
    user : String,
    body : String
  }

type alias Model =
  {
   user : String,
   messageInProgress : String,
   messages : List ChatMessage,
   phxSocket : Phoenix.Socket.Socket Msg
  }

type Msg =
    SomethingNew
  | PhoenixMsg (Phoenix.Socket.Msg Msg)
  | ReceiveChatMessage JsEncode.Value
  | CraftMessage String
  | SendMessage
  | JoinChannel
  | LeaveChannel
  | ShowJoinedMessage
  | ShowLeftMessage
  | HandleSendError JsEncode.Value
  | CraftUsername String

init : ( Model, Cmd Msg )
init =
  let
   initSocket =
     Phoenix.Socket.init "ws://localhost:4000/socket/websocket"
     |> Phoenix.Socket.withDebug
     |> Phoenix.Socket.on "new:msg" "room:lobby" ReceiveChatMessage
   model =
     {
       user = "",
       messageInProgress = "",
       messages = [],
       phxSocket = initSocket
     }
  in
   ( model, Cmd.none )

drawMessage : ChatMessage -> Html Msg
drawMessage message =
  listGroupItem []
    [
     span []
      [
       h3 [] [ text message.user ],
       text message.body
      ]
    ]

view : Model -> Html Msg
view model =
  let
   drawMessages messages = messages |> List.map drawMessage
  in
    containerFluid
     [
      row
       [
        h1 [] [ text "Welcome!" ]
       ],
      row
       [
        btn BtnDefault [] [ onClick JoinChannel ] [ text "Join" ]
       ],
      row
       [
        btn BtnDanger [] [ onClick LeaveChannel ] [ text "Leave" ]
       ],
      row
       [
        listGroup <| drawMessages model.messages
       ],
      row
       [
        form FormInline [ onSubmit SendMessage ]
         [
          formGroup FormGroupDefault
           [
            formLabel [] [ text "Username" ],
            formInput [ onInput CraftUsername ] []
           ],
          formGroup FormGroupDefault
           [
            formLabel [] [ text "Message" ],
            formInput [ onInput CraftMessage ] []
           ],
          formGroup FormGroupDefault
           [
            btn BtnPrimary [] [] [ text "Submit" ]
           ]
         ]
       ]
     ]

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
  case msg of
    SomethingNew ->
      ( model, Cmd.none )
    PhoenixMsg msg ->
      let
        ( phxSocket, phxCmd ) = Phoenix.Socket.update msg model.phxSocket
      in
        (
         { model | phxSocket = phxSocket },
         Cmd.map PhoenixMsg phxCmd
        )
    CraftMessage message ->
      let
       model = { model | messageInProgress = message }
      in
       (model, Cmd.none)
    CraftUsername user ->
      let
       model = { model | user = user }
      in
       (model, Cmd.none)
    ReceiveChatMessage raw ->
      let
       chatMessageDecoder =
         JsDecode.object2 ChatMessage
           ("user" := JsDecode.string)
           ("body" := JsDecode.string)
       someMessage = JsDecode.decodeValue chatMessageDecoder raw
      in
        case someMessage of
          Ok chatMessage ->
            (
             { model | messages = chatMessage :: model.messages },
             Cmd.none
            )
          Err error ->
            ( model, Cmd.none )
    SendMessage ->
      let
       user =
         case (model.user == "") of
           True -> "Anonymous"
           False -> model.user
       payload =
         JsEncode.object
          [
           ("user", JsEncode.string user),
           ("body", JsEncode.string model.messageInProgress)
          ]
       phxPush =
         Phoenix.Push.init "new:msg" "room:lobby"
           |> Phoenix.Push.withPayload payload
           |> Phoenix.Push.onOk ReceiveChatMessage
           |> Phoenix.Push.onError HandleSendError
       (phxSocket, phxCmd) = Phoenix.Socket.push phxPush model.phxSocket
      in
       (
        {
          model |
           messageInProgress = "",
           phxSocket = phxSocket
        },
        Cmd.map PhoenixMsg phxCmd
       )
    HandleSendError _ ->
     let
      message = { user = "System", body = "Failed To Send Msg" }
     in
      (
       { model | messages = message :: model.messages },
       Cmd.none
      )
    JoinChannel ->
     let
      channel =
        Phoenix.Channel.init "room:lobby"
        |> Phoenix.Channel.withPayload (JsEncode.object [ ("user_id", JsEncode.string "123") ])
        |> Phoenix.Channel.onJoin (always ShowJoinedMessage)
        |> Phoenix.Channel.onClose (always ShowLeftMessage)
      (phxSocket, phxCmd) =
        Phoenix.Socket.join channel model.phxSocket
     in
      (
       { model | phxSocket = phxSocket },
       Cmd.map PhoenixMsg phxCmd
      )
    LeaveChannel ->
     let
      (phxSocket, phxCmd) = Phoenix.Socket.leave "room:lobby" model.phxSocket
     in
      (
       { model | phxSocket = phxSocket },
       Cmd.map PhoenixMsg phxCmd
      )
    ShowJoinedMessage ->
     let
      message = { user = "System", body = "Joined the channel" }
     in
      (
       { model | messages = message :: model.messages },
       Cmd.none
      )
    ShowLeftMessage ->
     let
      message = { user = "System", body = "Left the channel" }
     in
      (
       { model | messages = message :: model.messages },
       Cmd.none
      )


subscriptions : Model -> Sub Msg
subscriptions model =
  Phoenix.Socket.listen model.phxSocket PhoenixMsg

main : Program Never
main =
  Html.App.program
      { init = init
      , view = view
      , update = update
      , subscriptions = subscriptions
      }
