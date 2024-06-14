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


%% TODO the case where a task cannot spawn and state needs to go to not_possible
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
%%  io:format("Starting with the sched_task task~n"),
  Json = base_attributes:read(<<"meta">>,<<"processPlan">>,BH),
%%  io:format("ProcessPlan:  ~p~n",Json),
  List_of_processes = maps:get(<<"processes">>,Json),

  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),
  Elem = lists:nth(1,List_of_processes),

  Data_map = maps:merge(
    #{<<"treatmentID">> => MyID},
    Elem
  ),

  Spawn_Tag = <<"SPAWN_PROCESS_TASK_INSTANCE">>,
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
  base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),

  base_variables:subscribe(<<"process">>, <<"newStart">>,self(),BH),
  base_variables:write(<<"ProcessList">>,<<"process">>,[],BH),

  {ok,1}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update({<<"process">>, <<"newStart">>, Times}, TaskState, ExecutorHandle, BH) ->
%%  io:format("Variable updated, newtime: ~p~n",[Times]),
  Json = base_attributes:read(<<"meta">>,<<"processPlan">>,BH),

  List_of_processes = maps:get(<<"processes">>,Json),

  CurrentList = base_variables:read(<<"ProcessList">>,<<"process">>,BH),
  base_variables:write(<<"ProcessList">>,<<"process">>,CurrentList++[Times],BH),

  if
    TaskState==length(List_of_processes)->
      io:format("All Processes Schedueled~n"),
      {end_task,discard, TaskState};
    true ->

      MyBC = base:get_my_bc(BH),
      MyID = base_business_card:get_id(MyBC),
      Elem = lists:nth(TaskState+1,List_of_processes),

      Data_map = maps:merge(
        #{<<"treatmentID">> => MyID},
        Elem
      ),

      Spawn_Tag = <<"SPAWN_PROCESS_TASK_INSTANCE">>,
      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
      base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
      {ok,TaskState+1}
  end.

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("Ending manage_process_config Task~n"),

  io:format("ProcessList: ~p~n",[base_variables:read(<<"ProcessList">>,<<"process">>,BH)]),

  FSM_PID = base_variables:read(<<"FSM_INFO">>,<<"FSM_PID">>,BH),
  gen_statem:cast(FSM_PID,process_scheduled),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_status">>, process_scheduled,BH),
  ok.