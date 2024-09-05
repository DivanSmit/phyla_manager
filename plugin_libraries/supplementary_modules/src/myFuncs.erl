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
-export([extract_partner_names/2, myName/1, extract_partner_and_task_id/3, get_task_id_from_BH/1, get_task_type_from_BH/1,
  get_task_shell_element/2, get_partner_task_id/1, get_partner_names/2, get_task_shell_from_id/2, get_task_type/1,
  get_task_sort/1, get_task_id/1, check_if_my_task/2, convert_unix_time_to_normal/1, convert_unix_time_to_normal/2, check_availability/4,
  update_list_and_average/2, add_map_to_json_file/2, read_json_file/1, write_json_file/2, extract_partner_ids/2,
  csv_to_maps/1, get_task_metadata/1]).


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for extracting data
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

myName(BH)->
  base_business_card:get_name(base:get_my_bc(BH)).

get_task_metadata(BH)->
  SchedData = base_schedule:get_all_tasks(BH),
  SchedList = maps:values(SchedData),
  ScheduledTasks = lists:foldl(fun(X, Acc) ->

    Shell = X#base_task.task_shell,
    StartTime = Shell#task_shell.tsched,
    ID = Shell#task_shell.id,
    Requirements = X#base_task.data1,

    Meta = X#base_task.meta,
    BC = Meta#base_contract.master_bc,
    Name = base_business_card:get_name(BC),
    Data = #{
      <<"name">>=>Name,
      <<"time">>=>StartTime,
      <<"id">>=> ID,
      <<"sector">>=><<"S">>,
      <<"operator">>=> myName(BH)
    },
    [maps:merge(Data,Requirements) | Acc]
              end, [], SchedList),

  ExecutionData = base_execution:get_all_tasks(BH),
  ExecutionList = maps:values(ExecutionData),
  ExecutionTasks = lists:foldl(fun(X, Acc) ->

    Shell = X#base_task.task_shell,
    StartTime = Shell#task_shell.tsched,
    ID = Shell#task_shell.id,
    Requirements = X#base_task.data1,

    Meta = X#base_task.meta,
    BC = Meta#base_contract.master_bc,
    Name = base_business_card:get_name(BC),
    Data = #{
      <<"name">>=>Name,
      <<"time">>=>StartTime,
      <<"id">>=> ID,
      <<"sector">>=><<"E">>,
      <<"operator">>=> myName(BH)
    },
    [maps:merge(Data,Requirements) | Acc]
                               end, [], ExecutionList),

  lists:reverse(ScheduledTasks)++lists:reverse(ExecutionTasks).

extract_partner_names(Tasks, Type) ->
  Values = maps:values(Tasks),
  ListTasks = lists:foldl(fun(X, Acc) ->

    Meta = X#base_task.meta,
    BC = case Type of
           master ->
             Meta#base_contract.master_bc;
           servant ->
             Meta#base_contract.servant_bc
         end,
    Name = base_business_card:get_name(BC),
    [Name | Acc]
              end, [], Values),
  lists:reverse(ListTasks).

extract_partner_ids(Tasks, Type) ->
  Values = maps:values(Tasks),
  ListTasks = lists:foldl(fun(X, Acc) ->

    Meta = X#base_task.meta,
    BC = case Type of
           master ->
             Meta#base_contract.master_bc;
           servant ->
             Meta#base_contract.servant_bc
         end,
    ID = base_business_card:get_id(BC),
    [ID | Acc]
                          end, [], Values),
  lists:reverse(ListTasks).

extract_partner_and_task_id(ID, Type, BH) ->
  QueryS = base_schedule:query_task_shells(#task_shell_query{field = id, range = ID}, BH),
  Shell = case QueryS of
            [] ->
              QueryE = base_execution:query_task_shells(#task_shell_query{field = id, range = ID}, BH),

              case QueryE of
                [] ->
                  error;
                _ ->
                  base_execution:get_task(lists:nth(1,QueryE), BH)

              end;
            _ ->
              base_schedule:get_task(lists:nth(1,QueryS), BH)
          end,

  % Now we can extract the Shell
  case Shell of
    error ->
      {error,task_completed};
    _ ->

      Meta = Shell#base_task.meta,
      Promise = case Type of
                  master ->
                    Meta#base_contract.master_promise;
                  servant ->
                    Meta#base_contract.servant_promise
                end,

      PartnerBC = Promise#link_promise.bc,
      PartnerShell = Promise#link_promise.shell,

      {PartnerShell#task_shell.id, base_business_card:get_name(PartnerBC)}
  end.

get_task_id_from_BH(BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
%%  io:format("All tasks: ~p~n",[TasksExe]),

  TaskKeys = maps:keys(TasksExe),

  lists:map(fun(Tuple) -> element(5, Tuple) end, TaskKeys).

get_task_type_from_BH(BH) ->
  TasksExe = base_schedule:get_all_tasks(BH),
  TaskKeys = maps:keys(TasksExe),
  lists:map(fun(Tuple) -> element(6, Tuple) end, TaskKeys).

get_partner_names(BH,Type)->
  Data = base_schedule:get_all_tasks(BH),
  extract_partner_names(Data,Type).



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
% Functions for writing to files
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

read_json_file(FilePath) ->
  {ok, BinaryData} = file:read_file(FilePath),
  case jsx:decode(BinaryData) of
    JsonData -> {ok, JsonData};
    {error, Reason} -> {error, Reason}
  end.

write_json_file(FilePath, Data) ->
  JsonData = jsx:encode(Data),
  PrettyJsonData = jsx:prettify(JsonData),
  file:write_file(FilePath, PrettyJsonData).

add_map_to_json_file(FilePath, NewMap) ->
  case read_json_file(FilePath) of
    {ok, CurrentData} ->
      List = maps:get(<<"list">>, CurrentData, []),
      UpdatedList = [NewMap | List],
      UpdatedData = maps:put(<<"list">>, UpdatedList, CurrentData),
      write_json_file(FilePath, UpdatedData);
    {error, Reason} ->
      {error, Reason}
  end.

% Reads the CSV file and converts each row into a map
csv_to_maps(File) ->
  {ok, Binary} = file:read_file(File),
  Lines = binary:split(remove_bom(Binary), <<"\n">>, [global]),
  [Header | Rows] = Lines,
  HeaderList = binary:split(trim(Header), <<",">>, [global]),
  lists:map(fun(Row) ->
    Values = binary:split(trim(Row), <<",">>, [global]),
    RowMap = lists:zip(HeaderList, Values),
    maps:from_list(RowMap)
            end, lists:filter(fun(Row) -> Row =/= <<>> end, Rows)).

% Removes BOM if present
remove_bom(<<239, 187, 191, Rest/binary>>) -> Rest; % UTF-8 BOM
remove_bom(Binary) -> Binary.

% Trims leading and trailing whitespace/newline characters
trim(Bin) when is_binary(Bin) ->
  re:replace(re:replace(Bin,
    <<"^[\\s\\n\\r\\t]+">>, <<>>, [global, {return, binary}]),
    <<"[\\s\\n\\r\\t]+$">>, <<>>, [global, {return, binary}]).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for conversions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%  TODO fix the calendar time issue where higher more than 12 o'clock it should be the next day
convert_unix_time_to_normal(Time) ->

  {{Y, M, D}, {Hour, Min, Sec}} = calendar:system_time_to_universal_time(Time, 1000),
  LocalTime = calendar:universal_time_to_local_time({{Y, M, D}, {Hour, Min, Sec}}),
  {{LocalY, LocalM, LocalD}, {LocalHour, LocalMin, LocalSec}} = LocalTime,
  String = io_lib:format("~4..0B-~2..0B-~2..0B ~2..0B:~2..0B:~2..0B", [LocalY, LocalM, LocalD, LocalHour, LocalMin, LocalSec]),
  list_to_binary(String).

convert_unix_time_to_normal(Time, Return) ->

  BIN = convert_unix_time_to_normal(Time),
  case Return of
    binary -> BIN;
    string -> binary_to_list(BIN)
  end.

update_list_and_average(List, Value) ->

  UpdatedList =
    case length(List) >= 10 of
      true -> tl(List);
      false -> List
    end,

  NewList = [Value | UpdatedList],
  Sum = lists:sum(NewList),

  Average =
    case length(NewList) of
      0 -> 0; % Avoid division by zero
      Length ->
        RoundedAverage = math:ceil(Sum / Length / 60000) * 60000,
        round(RoundedAverage)
    end,
  {Average, NewList}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Functions for calculating the availability of a resource at a time
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_availability(StartTimeTarget, DurationTarget, _Type, BH) ->
  % Get all tasks from the system
  All_tasks = maps:values(base_schedule:get_all_tasks(BH))++maps:values(base_execution:get_all_tasks(BH)),

  % Fold through tasks to find the first available start time
  {ok, AvailableStart} =
    lists:foldl(fun(Elem, {ok, Tstart}) ->
      Data1 = Elem#base_task.data1,
      Shell = Elem#base_task.task_shell,
      TaskDuration = maps:get(<<"duration">>, Data1, 0),
      TaskStart = if
                    Shell#task_shell.tstart == undefined -> Shell#task_shell.tsched;
                    true -> Shell#task_shell.tstart
                  end,

      TaskFinish = TaskStart + TaskDuration,

      if
      % Check if the task overlaps with the current start time and duration
        (Tstart >= TaskStart andalso Tstart < TaskFinish) orelse
          (Tstart + DurationTarget > TaskStart andalso Tstart + DurationTarget =< TaskFinish) ->
          {ok, TaskFinish}; % If it does, set the start time to just after the task's finish time
        true ->
          {ok, Tstart} % Otherwise, keep the current start time
      end
                end, {ok, StartTimeTarget}, All_tasks),

  {ok, AvailableStart}.

%%check_availability(StartTime, Duration, Type, BH) ->
%%
%%  ListSced = extract_sched_time(BH),
%%  ListExe = extract_exe_time(BH),
%%  TaskList = ListSced ++ ListExe,
%%
%%  case check_if_possible(TaskList, StartTime, Duration, BH) of
%%    {ok, Time} ->
%%      {ok, Time};
%%    {not_possible, Time} ->
%%      case Type of
%%        now ->
%%          {not_possible, Time};
%%        earliest_from_now ->
%%          check_availability(Time, Duration, Type,BH)
%%      end
%%
%%  end.

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


