%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 04. Oct 2023 21:23
%%%-------------------------------------------------------------------
-module(scanner_task_sp).
-behaviour(base_task_sp).
-export([init/2, stop/1, handle_task_request/2]).

%% ============================================================================================%%
%%                                    BASE TASK CALLBACKS
%% ============================================================================================%%

init(Pars, BH) ->
  base:wait_for_base_ready(BH),
  handle_task_request(nothing, BH),
  ListTask = base_schedule:get_all_tasks(BH),
  io:format("This is the tasks ~p",[ListTask]),
  ok.

stop(BH) ->
  ok.

handle_task_request(Pars, BH) ->
  io:format("Handeling scanner task~n"),
  Tsched = base:get_origo(),
  Type = <<"scan">>,
  ID = make_ref(),
  Data1 =#{},
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH).