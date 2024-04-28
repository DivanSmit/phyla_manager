%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 23. Apr 2024 21:41
%%%-------------------------------------------------------------------
-module(execute_process_sched_tasks_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API
-export([init/2, stop/1]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.