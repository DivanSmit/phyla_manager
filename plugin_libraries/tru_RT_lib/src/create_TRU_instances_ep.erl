%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. May 2024 19:52
%%%-------------------------------------------------------------------
-module(create_TRU_instances_ep).
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, task_cancel/4, request_resume/2, start_task/3, resume_task/3, base_variable_update/4, end_task/3]).


init(Parameters, BH) ->

  ok.

stop(BH) ->
  ok.

request_start(ExecutorHandle, BH) ->
  {start_task, {}}.

request_resume(ExecutorHandle, BH) ->
  {end_task, discard, no_state}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->

%%  TRUList = base_task_ep:get_schedule_data(ExecutorHandle, BH),
%%
%%  lists:foldl(fun(Elem, Acc) ->
%%
%%  case  of
%%      ->;
%%end
%%
%%    ID = maps:get(<<"id">>, Elem),
%%    Type = maps:get(<<"type">>, Elem),
%%    {ok, Recipe} = tru_guardian_sp:generate_instance_recipe(ID, Type, BH),
%%    Tsched = base:get_origo(),
%%    Data1 = #{
%%
%%    },
%%    spawn(fun() ->
%%      base_guardian_sp:schedule_instance_guardian(Tsched, Recipe, Data1, BH)
%%          end)
%%              end, [], TRUList),
  {end_task, discard, TaskState}.

end_task(TaskState, ExecutorHandle, BH) ->
  ok.

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->