-module(global_rooms_state).
-behavior(gen_server).

-export([handle_info/2, start_link/0, init/1, handle_call/3, handle_cast/2, code_change/3, terminate/2]).
-export([get_room_pid/1, get_rooms_list/0, add_room/2]).

% Data in #state.rooms saved as: {room_id, room_pid}
-record(state, {rooms = []}).

start_link() ->
  gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

init(_Args) ->
  {ok, #state{}}.

handle_info(Info, State) ->
  case Info of
    {room_remove, Room_id} ->
      New_state = State#state{rooms = room_remove(State#state.rooms, Room_id)},
      {noreply, New_state};
    Unknown ->
      io:format("Warning: unknown message received in 'global_room_state', message: ~p~n", [Unknown]),
      {noreply, State}
  end.

code_change(_OldVsn, State, _Extra) ->
  {ok, State}.

% synchronous messages
handle_call(_Request, _From, State) ->
  case _Request of
    {room_add, {Room_id, Room_pid}} ->
      New_state = State#state{rooms = [{Room_id, Room_pid} | State#state.rooms]},
      {reply, ok, New_state};
    get_rooms_list ->
      Rooms_list = lists:flatmap(fun(Room) -> {Id, _} = Room, [Id] end, State#state.rooms),
      io:format("Rooms list: ~p~n", [Rooms_list]),
      {reply, Rooms_list, State};
    {get_room_pid, Room_id} ->
      {reply, search_room_pid(Room_id, State#state.rooms), State};
    Unknown ->
      io:format("Warning: unknown message received in 'global_room_state:handle_cast', message: ~p~n", [Unknown]),
      {reply, ok, State}
  end.

% asynchronous messages
handle_cast(_Request, State) ->
  {noreply, State}.

terminate(_Reason, _State) ->
  ok.

add_room(Room_id, Room_pid) ->
  gen_server:call(whereis(global_rooms_state), {room_add, {Room_id, Room_pid}}).

get_room_pid(Room_id) ->
  gen_server:call(whereis(global_rooms_state), {get_room_pid, Room_id}).

get_rooms_list() ->
  gen_server:call(whereis(global_rooms_state), get_rooms_list).

search_room_pid(Room_id, [{Room_id, Room_pid} | _]) -> Room_pid;
search_room_pid(Room_id, [_ | XS]) -> search_room_pid(Room_id, XS);
search_room_pid(Room_id, []) ->
  io:format("Warning: there is no such a room of id: ~p~n", [Room_id]).

room_remove([{Room_id, Room_pid} | XS], Room_id) ->
  Room_pid ! stop,
  XS;
room_remove([X | XS], R) -> lists:append([X], room_remove(XS, R));
room_remove([], _) -> [].
