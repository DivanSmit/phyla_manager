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
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_reflection(ReflectorHandle, BH) ->
  {start_reflection, state}.

start_reflection(PluginState, ReflectorHandle, BH) ->
  io:format("Starting a reflection~n"),

  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = Shell#task_shell.tstart,
  EndTime = Shell#task_shell.tend,
  Duration = EndTime - StartTime,

  {ok,Requirements} = base_task_rp:get_schedule_data(ReflectorHandle,BH),

  io:format("Requirements in RP: ~p~n",[Requirements]),
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

  base_task_rp:write_reflection_data(Data3, ReflectorHandle, BH),
  ok.