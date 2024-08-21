%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Jul 2024 09:50
%%%-------------------------------------------------------------------
-module(contracting_resource_servant_rp).
-author("LENOVO").
-behaviour(base_task_rp).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, request_reflection/2, start_reflection/3]).


init(Pars, BH) ->
  base_variables:write(<<"Maintenance">>, <<"TotalDuration">>, 0, BH),
  base_variables:write(<<"Maintenance">>, <<"Scheduled">>,false,BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_reflection(ReflectorHandle, BH) ->
  {start_reflection, state}.

start_reflection(PluginState, ReflectorHandle, BH) ->
  io:format("Starting a reflection for ~p~n",[myFuncs:myName(BH)]),

  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = Shell#task_shell.tstart,
  EndTime = Shell#task_shell.tend,
  Duration = EndTime - StartTime,

  {ok,Requirements} = base_task_rp:get_schedule_data(ReflectorHandle,BH),
  {ok, Execution} = base_task_rp:get_execution_data(ReflectorHandle,BH),
%%  io:format("Execution: ~p~n",[Execution]),

  % Send data to TYPE
  MyBC = base:get_my_bc(BH),
  MyID = MyBC#business_card.identity,
  Tax = MyID#identity.taxonomy,
  ParentType = Tax#base_taxonomy.base_type_code,
  TaskHolons = bhive:discover_bases(#base_discover_query{name = ParentType}, BH),

  Task = base_biography:get_task(Shell, BH),
  Meta = Task#base_task.meta,
  MasterBC = Meta#base_contract.master_bc,
  PartnerName = base_business_card:get_name(MasterBC),

  case maps:get(<<"TRU_Data">>, Execution, not_applicable) of
    not_applicable -> ok;
    TRU_Data when is_list(TRU_Data)->
%%      io:format("The TRU data is valid~n"),
      lists:foreach(fun(Elem) when is_map(Elem)->
        Map = maps:merge(#{
          <<"resource">>=>myFuncs:myName(BH),
          <<"process">>=>PartnerName,
          <<"unix">>=> integer_to_binary(base:get_origo())
        }, Elem),
        base_signal:emit_signal(TaskHolons, <<"TRU_Data">>, Map, BH)
      end, TRU_Data)
end,

%%  io:format("Requirements in RP: ~p~n",[Requirements]),
  Type = maps:get(<<"processType">>, Requirements),

  case base_variables:read(<<"TaskDurationList">>, Type, BH) of
    no_entry->
      FirstDuration = maps:get(<<"duration">>, Requirements, Duration),
      base_variables:write(<<"TaskDurations">>, Type, Duration, BH),
      base_variables:write(<<"TaskDurationList">>, Type, [FirstDuration,Duration], BH);

    List ->
      {Average, NewList} = myFuncs:update_list_and_average(List, Duration),
      base_variables:write(<<"TaskDurations">>, Type, Average, BH),
      base_variables:write(<<"TaskDurationList">>, Type, NewList, BH);
    _ ->
      error
  end,

  Data3 = #{
    <<"duration">>=>Duration
  },

  LastDuration = base_variables:read(<<"Maintenance">>, <<"TotalDuration">>, BH),
  base_variables:write(<<"Maintenance">>, <<"TotalDuration">>, LastDuration + Duration, BH),

  case Type of
    <<"Maintenance">> -> base_variables:write(<<"Maintenance">>, <<"TotalDuration">>, 0, BH),
      base_variables:write(<<"Maintenance">>, <<"Scheduled">>,false,BH);
    _ -> ok
  end,

  base_task_rp:write_reflection_data(Data3, ReflectorHandle, BH),
  ok.