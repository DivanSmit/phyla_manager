%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Oct 2023 21:23
%%%-------------------------------------------------------------------
-module(coordinate_move_ep).
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
  io:format("~nCoordination of move fruit task beginning: ~n"),
  move_the_fruit(),
  {end_task, discard, movedFruit}.

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("~nThe coordination is complete~n"),
  ok.

handle_request(Tag, Payload, BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

move_the_fruit()->
  io:format("Coordinating~n").