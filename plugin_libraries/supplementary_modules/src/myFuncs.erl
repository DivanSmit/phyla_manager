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
-export([get_task_id_from_BH/1, get_task_type_from_BH/1, get_task_shell_element/2, get_partner_task_id/1, get_partner_names/1, get_task_shell_from_id/2, get_task_type/1,
  get_task_sort/1, get_task_id/1, check_if_my_task/2, convert_unix_time_to_normal/1, check_availability/4, update_list_and_average/2]).

get_task_id_from_BH(BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
%%  io:format("All tasks: ~p~n",[TasksExe]),

  TaskKeys = maps:keys(TasksExe),

  lists:map(fun(Tuple) -> element(5, Tuple) end, TaskKeys).

get_task_type_from_BH(BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
  TaskKeys = maps:keys(TasksExe),
  lists:map(fun(Tuple) -> element(6, Tuple) end, TaskKeys).

get_partner_names(BH)->
  Data = base_schedule:get_all_tasks(BH),
%%  io:format("Data = ~p~n",[Data]),
  maps:fold(fun(X, Acc)->
    io:format("Exe: ~p~n",[base_execution:get_executor_handle(X,BH)])
  end, [],Data).
%%  extract_values(Data). %GPT generated function


get_task_shell_element(Element, BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
  TaskKeys = maps:keys(TasksExe),
  lists:map(fun(Tuple) -> element(Element, Tuple) end, TaskKeys).

get_partner_task_id(TaskShell)->
  [Keys] = maps:keys(TaskShell),
  Tasks = maps:get(Keys,TaskShell),
  Contract = element(3, Tasks),
  Promise = element(3, Contract),
  Shell = element(2,Promise),
  element(5,Shell).

get_task_shell_from_id(ID,BH)->

  try
    Tasklist = base_schedule:get_all_tasks(BH), %% This is a map
    TaskKeys = maps:keys(Tasklist), %% This is a list
    [Shell] = lists:filter(fun(Tuple) -> %% This is a tuple
      element(5, Tuple) == ID
                           end, TaskKeys),
    BaseTask = base_schedule:get_task(Shell,BH),
    #{Shell=>BaseTask}
  catch
      error:{badmatch, _} ->
        Tasklist1 = base_execution:get_all_tasks(BH), %% This is a map
        TaskKeys1 = maps:keys(Tasklist1), %% This is a list
        [Shell1] = lists:filter(fun(Tuple1) -> %% This is a tuple
        element(5, Tuple1) == ID
        end, TaskKeys1),
        BaseTask1 = base_execution:get_task(Shell1,BH),
        #{Shell1=>BaseTask1}
  end.

check_if_my_task(ID,BH)->
  try
    Tasklist = base_schedule:get_all_tasks(BH), %% This is a map
    TaskKeys = maps:keys(Tasklist), %% This is a list
    [Shell] = lists:filter(fun(Tuple) -> %% This is a tuple
      element(5, Tuple) == ID
                           end, TaskKeys),
    BaseTask = base_schedule:get_task(Shell,BH),
    case Shell of
      [] ->
        not_my_task;
      _ ->
        my_task
    end
  catch
    error:{badmatch, _} ->
      Tasklist1 = base_execution:get_all_tasks(BH), %% This is a map
      TaskKeys1 = maps:keys(Tasklist1), %% This is a list
      [Shell1] = lists:filter(fun(Tuple1) -> %% This is a tuple
        element(5, Tuple1) == ID
                              end, TaskKeys1),
      BaseTask1 = base_execution:get_task(Shell1,BH),
      case Shell1 of
        [] ->
          not_my_task;
        _ ->
          my_task
      end
  end.

get_task_id(Shell)->
  element(5,Shell).

get_task_type(Shell)->
  [TaskKeys] = maps:keys(Shell),
  element(6,TaskKeys).

get_task_sort(Shell)->
  [TaskKeys] = maps:keys(Shell),
  element(7,TaskKeys).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for conversions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

convert_unix_time_to_normal(Time) ->

%%  TODO fix the calendar time issue

  {{Y, D, M}, {Hour, Min, Sec}} = calendar:system_time_to_universal_time(Time, 1000),
  String = lists:concat([Y, "-", D, "-", M, " ", Hour + 2, ":", Min, ":", Sec]),
  list_to_binary(String).

update_list_and_average(List,Value)->
  UpdatedList =
    case length(List) > 10 of
      true ->
        tl(List);
      false ->
        List
    end,

  NewList = [Value | UpdatedList],

  Average = case lists:sum(NewList) of
              0 -> 0;
              Sum -> round(math:ceil((Sum / length(NewList))/60000))*60000
            end,
  {Average,NewList}.

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
  TaskDuration = base_attributes:read(<<"TaskDurations">>, TaskType, BH),
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



extract_values(Data) ->
  Values = extract_values_recursive(Data),
  lists:flatten(Values).

extract_values_recursive([]) ->
  [];
extract_values_recursive([{_, _, {base_contract, _,
  {link_promise, _,
    {business_card, _,
      {identity, _, Value, _},
      _, _, _, _},
    _, _}, _, _},
  _, _, _} | T]) ->
  [Value | extract_values_recursive(T)];
extract_values_recursive([_ | T]) ->
  extract_values_recursive(T).