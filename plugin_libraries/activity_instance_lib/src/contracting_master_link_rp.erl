%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Jul 2024 10:38
%%%-------------------------------------------------------------------
-module(contracting_master_link_rp).
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
  io:format("Starting a activity master reflection for ~p~n",[myFuncs:myName(BH)]),

  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = Shell#task_shell.tstart,
  EndTime = Shell#task_shell.tend,
  Duration = EndTime - StartTime,

  ok.