%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Oct 2023 21:22
%%%-------------------------------------------------------------------
-module(move_fruit_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API
-export([init/2, stop/1, handle_task_request/2]).


init(Pars, BH) ->
  base:wait_for_base_ready(BH),
%%  handle_task_request(Pars,BH),          %% Does not call the function initially. Needs to be called
  ok.

stop(BH) ->
  ok.

handle_task_request(Pars, BH) ->
  Tsched = base:get_origo(),
  {{Y,D,M},{Hour,Min,Sec}} = calendar:system_time_to_universal_time(Tsched, 1000),
  io:format("Scheduled time:~p-~p-~p, ~p:~p:~p~n", [Y,D,M,Hour,Min,Sec]),
  Type = <<"moveFruit">>,
  ID = make_ref(),
  Data1 =#{},
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH).