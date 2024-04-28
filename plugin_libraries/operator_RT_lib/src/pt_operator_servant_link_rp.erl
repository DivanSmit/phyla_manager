%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Nov 2023 20:30
%%%-------------------------------------------------------------------
-module(pt_operator_servant_link_rp).
-author("LENOVO").
-behaviour(base_task_rp).
%% API
-export([init/2, stop/1, request_reflection/2, start_reflection/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_reflection(ReflectorHandle, BH) ->
  {start_reflection, state}.

start_reflection(PluginState, ReflectorHandle, BH) ->
  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = element(3,Shell),
  EndTime = element(4,Shell),

  Duration = EndTime-StartTime,

  TaskList = base_attributes:read(<<"TaskDurationList">>,<<"pt_operator">>,BH),

  {Average,NewList} = myFuncs:update_list_and_average(TaskList,Duration),

  base_attributes:write(<<"TaskDurations">>,<<"pt_operator">>,Average,BH),
  base_attributes:write(<<"TaskDurationList">>,<<"pt_operator">>,NewList,BH),

  ok.