%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Oct 2023 12:43
%%%-------------------------------------------------------------------
-module(move_fruit_AT_rp).
-author("LENOVO").
-behaviour(base_task_rp).
%% API
-export([init/2, stop/1, start_reflection/2]).

init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

start_reflection(ReflectorHandle, BH) ->
  ok.