%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. Apr 2024 21:42
%%%-------------------------------------------------------------------
-module(execute_process_sched_tasks_ep).
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
  io:format("Starting with the sched_task task~n"),
  Json = base_attributes:read(<<"meta">>,<<"json">>,BH),
  List_of_activities = maps:get(<<"activities">>,Json),

  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),
  Elem = lists:nth(1,List_of_activities),
  StartTime = base_attributes:read(<<"meta">>,<<"startTime">>,BH),
  io:format("First task start: ~p~n",[StartTime]),
  Data_map = maps:merge(#{<<"executeID">> => MyID,<<"startTime">>=>StartTime}, maps:get(<<"meta">>, Elem)),

  case maps:get(<<"type">>, Elem) of
    <<"move_AT">> ->
      io:format("Case is a  Move Act~n"),
      Spawn_Tag = <<"SPAWN_MOVE_INSTANCE">>;
    <<"process_task_AT">> ->
      Spawn_Tag = <<"SPAWN_PT_INSTANCE">>,
      io:format("Case is a  Trial Act~n")
  end,

  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
  base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
  base_variables:subscribe(<<"tasks">>, <<"newStart">>,self(),BH),
  base_variables:write(<<"TaskList">>,<<"tasks">>,[],BH),

  {ok,1}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update({<<"tasks">>, <<"newStart">>, Times}, TaskState, ExecutorHandle, BH) ->
  io:format("Variable updated, newtime: ~p~n",[Times]),
  Json = base_attributes:read(<<"meta">>,<<"json">>,BH),
  List_of_activities = maps:get(<<"activities">>,Json),
  Previous_End_Time = maps:get(<<"endTime">>,Times),

  CurrentList = base_variables:read(<<"TaskList">>,<<"tasks">>,BH),
  base_variables:write(<<"TaskList">>,<<"tasks">>,CurrentList++[Times],BH),

  if
    TaskState==length(List_of_activities)->
      {end_task,discard, TaskState};
    true ->

      MyBC = base:get_my_bc(BH),
      MyID = base_business_card:get_id(MyBC),
      Elem = lists:nth(TaskState+1,List_of_activities),
      Data_map = maps:merge(#{<<"executeID">> => MyID,<<"startTime">>=>Previous_End_Time}, maps:get(<<"meta">>, Elem)),

      case maps:get(<<"type">>, Elem) of
        <<"move_AT">> ->
          io:format("Case is a  Move Act~n"),
          Spawn_Tag = <<"SPAWN_MOVE_INSTANCE">>;
        <<"process_task_AT">> ->
          Spawn_Tag = <<"SPAWN_PT_INSTANCE">>,
          io:format("Case is a  Trial Act~n")
      end,

      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
      base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
      {ok,TaskState+1}
  end.

end_task(TaskState, ExecutorHandle, BH) ->
  io:format("Ending sched_task Task~n"),

  io:format("TaskList: ~p~n",[base_variables:read(<<"TaskList">>,<<"tasks">>,BH)]),

  FSM_PID = base_variables:read(<<"FSM_INFO">>,<<"FSM_PID">>,BH),
  gen_statem:cast(FSM_PID,task_scheduled),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_status">>, task_scheduled,BH),
  ok.