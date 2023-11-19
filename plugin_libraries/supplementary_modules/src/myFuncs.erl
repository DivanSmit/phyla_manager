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
-export([get_task_id_from_BH/1, get_task_shell_element/2, convert_unix_time_to_normal/1, check_availability/2]).

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
  {{Y, D, M}, {Hour, Min, Sec}} = calendar:system_time_to_universal_time(Time, 1000),
  String = lists:concat([Y, "-", D, "-", M, " ", Hour + 2, ":", Min, ":", Sec]),
  io:format("String: ~p~n", [String]),
  list_to_binary(String).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for calculating the availability of a resource at a time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_availability(StartTime, BH) ->
%%  MyBC = base:get_my_bc(BH),
%%  MyName = base_business_card:get_name(MyBC),

  TasksExe = base_execution:get_all_tasks(BH),
%%  io:format("~p Sched:~p~n",[MyName,TasksSched]),
%%  io:format("~p Exe:~p~n",[MyName,TasksExe]),
  KeyE = maps:keys(TasksExe),
  ListSced = extract_sched_time(BH),
  ListExe = extract_exe_time(BH),

  TaskList = ListSced ++ ListExe,
  case check_if_possible(TaskList, StartTime, BH) of
    {ok, Time} ->
      {ok, Time};
    {not_possible, Time} ->
      check_if_possible(TaskList, Time, BH)
  end.

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

check_if_possible([], Tstart, _) ->
  {ok, Tstart};

check_if_possible([Head | Tail], Tstart, BH) -> %% First call
  TaskStart = maps:get(<<"startTime">>, Head),
  TaskType = maps:get(<<"taskType">>, Head),
  Duration = base_variables:read(<<"TaskDurations">>, TaskType, BH),
  io:format("The task type: ~p will take ~p long ~n", [TaskType, Duration]),
  TaskFinish = TaskStart + Duration,

  if Tstart >= TaskStart andalso Tstart =< TaskFinish ->
    {not_possible, TaskFinish};
    true ->
      check_if_possible(Tail, Tstart, BH)
  end.

check_if_possible([], Tstart, Response, _) -> %% Last call
  {Response, Tstart};

check_if_possible([Head | Tail], Tstart, Response, BH) ->
  TaskStart = maps:get(<<"startTime">>, Head),
  TaskType = maps:get(<<"taskType">>, Head),
  Duration = base_variables:read(<<"TaskDurations">>, TaskType, BH),
%%  io:format("The task type: ~p will take ~p long ~n",[TaskType,Duration]),
  TaskFinish = TaskStart + Duration,

  case Response of
    not_possible ->
      if Tstart >= TaskStart andalso Tstart =< TaskFinish ->
        check_if_possible(Tail, TaskFinish, not_possible, BH);
        true ->
          check_if_possible([], Tstart, not_possible, BH)
      end;
    ok ->
      if Tstart >= TaskStart andalso Tstart =< TaskFinish ->
        check_if_possible(Tail, TaskFinish, not_possible, BH);
        true ->
          check_if_possible(Tail, Tstart, ok, BH)
      end
  end.
