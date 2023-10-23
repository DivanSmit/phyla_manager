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
%%  {ok, ListenSocket} = gen_tcp:listen(9910, [{active, true}]),
%%  accept_connections(ListenSocket),
  ResultList = call_and_accumulate( [], 6, []),
  storedata(ResultList),
  io:format("The list of numbers is ~p~n", [ResultList]),
  {end_task, discard, measured}.                                     %% Why is this measured

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("~nThe Recieve data task is complete~n"),
  ok.

handle_request(Tag, Payload, BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

call_and_accumulate(Acc, 0, ResultList) ->
  ResultList;
call_and_accumulate(Acc, N, ResultList) ->
  timer:sleep(1000), % Prints a number every second
  RandomNumber = rand:uniform(10),
  io:format("~p: ~p~n",[N, RandomNumber]),
  call_and_accumulate(Acc, N - 1, [RandomNumber | ResultList]).

storedata(Data)->
  io:format("Data stored~n"),
  ok.

%%accept_connections(ListenSocket) ->
%%  {ok, Socket} = gen_tcp:accept(ListenSocket),
%%  spawn(fun() -> handle_connection(Socket) end),
%%  accept_connections(ListenSocket).
%%
%%handle_connection(Socket) ->
%%  case gen_tcp:recv(Socket, 0) of
%%    {ok, Data} ->
%%      io:format("Received: ~s~n", [Data]),
%%      gen_tcp:send(Socket, "Hello, World!\n"),
%%      handle_connection(Socket);
%%    {error, closed} ->
%%      io:format("Connection closed~n");
%%    {error, Reason} ->
%%      io:format("Error: ~p~n", [Reason])
%%  end,
%%  gen_tcp:close(Socket).