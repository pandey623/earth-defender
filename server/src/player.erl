-module(player).

-export([start/1, loop/1]).

-record(state, {id, websocket}).

start(WebSocket) ->
  spawn(player, loop, [#state{websocket = WebSocket}]).

loop(State) ->
  receive
    {player_id, PlayerId} ->
      State#state.websocket ! {player_id, PlayerId},
      loop(State#state{id = PlayerId});
    {websocket, WebSocket} ->
      loop(State#state{websocket = WebSocket});
    {room_players_number, Players_number} ->
      State#state.websocket ! {room_players_number, Players_number};
    stop ->
      stop()
  end.

stop() -> exit(self(), normal).