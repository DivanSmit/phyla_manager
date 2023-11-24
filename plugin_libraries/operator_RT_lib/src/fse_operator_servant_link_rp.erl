%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 13. Nov 2023 20:30
%%%-------------------------------------------------------------------
-module(fse_operator_servant_link_rp).
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

%%  TODO Add the plugin analysis for the start and finish data

%%  {ok,Data2} = base_task_rp:get_execution_data(ReflectorHandle, BH),
%%  io:format("The servant Rp is starting a reflection with data: ~p~n",[Data2]),
  ok.