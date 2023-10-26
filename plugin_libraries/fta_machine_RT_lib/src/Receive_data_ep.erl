%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. Sep 2023 14:27
%%%-------------------------------------------------------------------
-module('Receive_data_ep').
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, start_task_error/3, request_resume/2, resume_task/3, start_task/3, end_task/3, handle_request/3, handle_signal/3]).


init(Parameters, BH) ->
  io:format("Recieve data plugin installed~n"),
  ok.

stop(BH) ->
  ok.

request_start(ExecutorHandle, BH) ->
  {start_task, {}}.

start_task_error(Reason, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

request_resume(ExecutorHandle, BH) ->
  {end_task, discard, no_state}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->
  io:format("~nData receive task beginning: ~n"),
  Port = 9910,
  {ok, ListenSocket} = gen_tcp:listen(Port, [{active, false}, {reuseaddr, true}]),
  io:format("Server listening on port ~p~n", [Port]),
  accept_connections(ListenSocket, [], BH),
%%  io:format("The list of numbers is ~p~n", [ResultList]),
  {end_task, discard, measured}.                                     %% Why is this measured

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("~nThe Recieve data task is complete~n"),
  ok.

handle_request(Tag, Payload, BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

accept_connections(ListenSocket, Values, BH) when length(Values) < 6 ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  spawn(fun() -> handle_connection(Socket, Values, BH) end),
  accept_connections(ListenSocket, Values, BH);
accept_connections(ListenSocket, Values, BH) ->
  io:format("Received 6 TCP calls. Server is now closing.~n"),
  gen_tcp:close(ListenSocket),
  lists:foreach(fun(Value) -> io:format("Received: ~s~n", [Value]) end, Values).

handle_connection(Socket, Values, BH) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, Data} ->
      io:format("Received: ~s~n", [Data]),
      base_variables:write(<<"MEASUREMENTS">>,<<"values">>,[Data|Values],BH),
      accept_connections(Socket, [Data | Values], BH);
    {error, closed} ->
      io:format("Connection closed~n");
    {error, Reason} ->
      io:format("Error: ~p~n", [Reason])
  end,
  gen_tcp:close(Socket).