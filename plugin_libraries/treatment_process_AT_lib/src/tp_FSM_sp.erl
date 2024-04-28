%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. Apr 2024 16:53
%%%-------------------------------------------------------------------
-module(tp_FSM_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API
-export([init/2, stop/1]).


init(Pars, BH) ->
  handle_task_request(Pars,BH),
  ok.

stop(BH) ->
  ok.

handle_task_request(Pars, BH) ->

  FSM_data = #{<<"BH">> => BH},
  {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))},tp_FSM_sched, FSM_data, []), % change name for new FSM

  base_variables:write(<<"FSM_INFO">>,<<"FSM_PID">>, StateMachinePID,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_status">>, start,BH),
  ok.
