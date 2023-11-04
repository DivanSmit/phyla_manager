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
  spawn(fun()->
    Port = 9910,
    {ok, ListenSocket} = gen_tcp:listen(Port, [{active, false}, {reuseaddr, true}]),
    io:format("Server listening on port ~p~n", [Port]),
    accept_connections(ListenSocket, [], ExecutorHandle,BH)
  end),

%%  io:format("Received data from all connections: ~s~n", [lists:flatten(DataAcc)]),
  {ok, measured}.                                     %% Why is this measured

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("~nThe Recieve data task is complete~n"),
  ok.

handle_request(Tag, Payload, BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

accept_connections(ListenSocket, Values,Ex, BH) when length(Values) < 6 ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  io:format("Accepted a new connection~n"),
  spawn(fun() -> handle_connection(Socket, Values, Ex, BH) end),
  accept_connections(ListenSocket, Values, Ex,BH);

accept_connections(_, Values,Ex, BH) when length(Values) == 6 ->
  io:format("All six values received: ~p~n", [lists:flatten(Values)]).

handle_connection(Socket, Values, Ex, BH) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, ReceivedData} ->
      add_to_BASE_variable(ReceivedData,Ex, BH),
      io:format("Received: ~s~n", [ReceivedData]),
      spawn(fun()->
        DataMap = #{<<"id">>=>length(Values)+1,<<"sugar_content">>=>ReceivedData,<<"time">>=>base:get_origo()},
        io:format("Data ~p~n",[DataMap]),
        postgresql_functions:write_data_to_postgresql_database(DataMap,"Test1")
      end),
      NewValues = Values ++ [ReceivedData],

      handle_connection(Socket, NewValues,Ex, BH);
    {error, closed} ->
      io:format("Connection closed~n");
    {error, Reason} ->
      io:format("Error: ~p~n", [Reason])
  end.

add_to_BASE_variable(Value, Ex,BH)->
  OldValues = base_variables:read(<<"MEASUREMENTS">>, <<"values">>, BH),
  case OldValues of
    no_entry ->
      io:format("First entry~n"),
      base_variables:write(<<"MEASUREMENTS">>, <<"values">>, [Value], BH);
    _ ->
      NewList = [Value | OldValues],
      io:format("Values: ~p~n", [NewList]),
      base_variables:write(<<"MEASUREMENTS">>, <<"values">>, NewList, BH)
  end,

  if
    length(OldValues) >= 5 ->
      io:format("Ending the task~n"),
    base_task_ep:end_task(Ex, end_task, BH);
    true -> ok
  end.



