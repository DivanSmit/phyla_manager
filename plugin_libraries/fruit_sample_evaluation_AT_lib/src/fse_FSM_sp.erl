%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Nov 2023 13:42
%%%-------------------------------------------------------------------
-module(fse_FSM_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API
-export([init/2, stop/1, handle_task_request/2]).


init(Pars, BH) ->
  handle_task_request(Pars,BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_task_request(Pars, BH) ->
  Tsched = base:get_origo(),
  Type = <<"fse_FSM">>,
  ID = make_ref(),
  Data1 =Pars,
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH).