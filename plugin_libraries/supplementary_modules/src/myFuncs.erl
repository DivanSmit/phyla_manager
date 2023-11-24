%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 07. Nov 2023 21:07
%%%-------------------------------------------------------------------
-module(myFuncs).
-author("LENOVO").
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([get_task_id_from_BH/1, get_task_shell_element/2, convert_unix_time_to_normal/1, check_availability/4]).

get_task_id_from_BH(BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
  TaskKeys = maps:keys(TasksExe),
  lists:map(fun(Tuple) -> element(5, Tuple) end, TaskKeys).

get_task_shell_element(Element, BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
  TaskKeys = maps:keys(TasksExe),
  lists:map(fun(Tuple) -> element(Element, Tuple) end, TaskKeys).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for conversions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

convert_unix_time_to_normal(Time) ->

%%  TODO fix the calendar time issue

  {{Y, D, M}, {Hour, Min, Sec}} = calendar:system_time_to_universal_time(Time, 1000),
  String = lists:concat([Y, "-", D, "-", M, " ", Hour + 2, ":", Min, ":", Sec]),
  list_to_binary(String).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for calculating the availability of a resource at a time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_availability(StartTime, Duration, Type, BH) ->

  ListSced = extract_sched_time(BH),
  ListExe = extract_exe_time(BH),
  TaskList = ListSced ++ ListExe,

  case check_if_possible(TaskList, StartTime, Duration, BH) of
    {ok, Time} ->
      {ok, Time};
    {not_possible, Time} ->
      case Type of
        now ->
          {not_possible, Time};
        earliest_from_now ->
          check_availability(Time, Duration, Type,BH)
      end

  end.

check_if_possible([], Tstart, _, _) ->
  {ok, Tstart};

check_if_possible([Head | Tail], Tstart, Duration, BH) -> %% First call
  TaskStart = maps:get(<<"startTime">>, Head),
  TaskType = maps:get(<<"taskType">>, Head),
  TaskDuration = base_variables:read(<<"TaskDurations">>, TaskType, BH),
  TaskFinish = TaskStart + TaskDuration,

  if (Tstart >= TaskStart andalso Tstart < TaskFinish) orelse  (Tstart+Duration > TaskStart andalso Tstart+Duration =< TaskFinish)->
    {not_possible, TaskFinish};
    true->
      check_if_possible(Tail, Tstart, Duration, BH)
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Extra internal functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

extract_sched_time(BH) ->
  TasksSched = base_schedule:get_all_tasks(BH),
  Keys = maps:keys(TasksSched),

  lists:map(fun(Tuple) ->
    #{<<"startTime">> => element(2, Tuple), <<"taskType">> => element(6, Tuple)}
            end, Keys).

extract_exe_time(BH) ->
  TasksExe = base_execution:get_all_tasks(BH),
  Keys = maps:keys(TasksExe),

  lists:map(fun(Tuple) ->
    #{<<"startTime">> => element(3, Tuple), <<"taskType">> => element(6, Tuple)}
            end, Keys).
