%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Jun 2024 19:17
%%%-------------------------------------------------------------------
-module(generate_report_ep).
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, task_cancel/4, request_resume/2, start_task/3, resume_task/3, base_variable_update/4, end_task/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start(ExecutorHandle, BH) ->
  erlang:error(not_implemented).

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

request_resume(ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

end_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).