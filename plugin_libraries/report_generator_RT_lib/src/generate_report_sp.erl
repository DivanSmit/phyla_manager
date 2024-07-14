%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 30. Jun 2024 19:16
%%%-------------------------------------------------------------------
-module(generate_report_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API

-export([init/2, stop/1]).

init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).