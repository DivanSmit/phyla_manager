%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 28. Apr 2024 14:46
%%%-------------------------------------------------------------------
-module(manage_process_configuration_ep).
-author("LENOVO").
-behaviour(base_task_ep).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start/2, task_cancel/4, request_resume/2, start_task/3, resume_task/3, base_variable_update/4, end_task/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start(ExecutorHandle, BH) ->
  {start_task, none}.

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  io:format("Cancelling Task~n"),
  ok.

request_resume(ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->

  %Read the current configurations


  Data_map = #{
    % Some important data
  },

  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_CONFIG_PROCESS_INSTANCE">>}, BH),
  base_signal:emit_request(TaskHolons, <<"SPAWN_CONFIG_PROCESS_INSTANCE">>, Data_map, BH),

  {ok, TaskState}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

end_task(TaskState, ExecutorHandle, BH) ->
  ok.