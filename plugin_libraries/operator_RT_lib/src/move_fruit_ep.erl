%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Oct 2023 21:23
%%%-------------------------------------------------------------------
-module(move_fruit_ep).
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, start_task_error/3, request_resume/2, resume_task/3, start_task/3, end_task/3, handle_request/3, handle_signal/3, task_cancel/4, base_variable_update/4]).


init(Parameters, BH) ->
%%  print_sched(BH,2),
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
  io:format("~n Move fruit task beginning: ~n"),
%%  move_fruit_rp:start_time(BH),
  move_the_fruit(),
  {end_task, discard, movedFruit}.

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("~n The move fruit task is complete~n"),
  ok.

handle_request(Tag, Payload, BH) ->
  {start_task, {}}.

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

move_the_fruit()->
  io:format("Moving the fruit~n").
%%  timer:sleep(10000). %%The fruit is being moved for 5s
print_sched(BH,0)->ok;
print_sched(BH,Count)->
  Tasks = base_schedule:get_all_tasks(BH),
  io:format("The sched is: ~p~n",[Tasks]),
  timer:sleep(500),
  print_sched(BH,Count-1).

