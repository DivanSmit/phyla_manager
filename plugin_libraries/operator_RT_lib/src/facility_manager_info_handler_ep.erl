%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. May 2024 11:06
%%%-------------------------------------------------------------------
-module(facility_manager_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"ConfigID">>, Inform, BH) -> %% Most likely useless
%%  TreatmentID = maps:get(<<"treatmentID">>,Inform),
%%  ConfigID = maps:get(<<"configID">>,Inform),
%%  base_variables:write(<<"treatmentProcess">>,TreatmentID,ConfigID,BH),
%%
%%
%%  TaskHolons = bhive:discover_bases(#base_discover_query{id = ConfigID}, BH),
%%  Treatment_ID = base_signal:emit_signal(TaskHolons, <<"newConfig">>, JsonString, BH),
%%
%%  %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ok.
handle_request(<<"TEST">>,Data, FROM, BH)->

  Reply = #{<<"Reply">>=>ok},
  {reply, Reply};

handle_request(<<"SPAWN">>,<<"currentConfig">>, FROM, BH)->
%%  io:format("FM received request to create new Treatment Process~n"),
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>}, BH),
  CurrentConfig = base_signal:emit_request(TaskHolons, <<"currentConfig">>, none, BH),

  % The UI needs to remember the Treatment ID to know what the corresponding Treatment Process is.
  Reply = #{<<"Reply">>=>CurrentConfig},
  {reply, Reply};

handle_request(<<"newConfig">>,Configurations, FROM, BH)->
%%  io:format("FM received request to create new Treatment Process~n"),
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>}, BH),
  TreatmentID = base_signal:emit_request(TaskHolons, <<"SPAWN_TREATMENT_PROCESS_INSTANCE">>,Configurations, BH),

  % The UI needs to remember the Treatment ID to know what the corresponding Treatment Process is.
  Reply = #{<<"Reply">>=>TreatmentID},
  {reply, Reply};

%Potentially Delete
handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};

% Potentially Delete
handle_request(<<"INFO">>,<<"TASKSID">>, FROM, BH)->
  TaskIDs = myFuncs:get_task_id_from_BH(BH),
  TaskTypes  = myFuncs:get_task_type_from_BH(BH),
  TaskTimes = myFuncs:get_task_shell_element(2,BH),
  TaskTimesC = lists:map(fun(Time) -> myFuncs:convert_unix_time_to_normal(Time) end, TaskTimes),
  Reply = #{<<"id">>=>TaskIDs,<<"time">>=>TaskTimesC, <<"type">>=>TaskTypes},
  {reply, Reply}.

%%%Potentially Delete
%%handle_request(<<"TASKS">>,Request, FROM, BH)->
%%
%%  ID = maps:get(<<"taskID">>,Request),
%%  Param = maps:get(<<"param">>,Request),
%%
%%  Shell = myFuncs:get_task_shell_from_id(ID,BH),
%%  case myFuncs:get_task_sort(Shell) of
%%    link ->
%%      PartnerID = myFuncs:get_partner_task_id(Shell),
%%      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"EXECUTABLE_TASK">>}, BH),
%%      Reply1 = base_signal:emit_signal(TaskHolons, Param, PartnerID, BH)
%%  end,
%%
%%  MyBC = base:get_my_bc(BH),
%%  MyName = base_business_card:get_name(MyBC),
%%  Reply = #{<<"name">>=>MyName},
%%  {reply, Reply}.

