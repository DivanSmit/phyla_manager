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

  StartTime = maps:get(<<"startTime">>,Pars),
  base_variables:write(<<"FSE_FSM_INFO">>,<<"startTime">>, StartTime,BH),

  FSM_data = #{<<"BH">> => BH},
  {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))},fse_sched_FSM, FSM_data, []),

  base_variables:write(<<"FSE_FSM_INFO">>,<<"FSE_FSM_PID">>, StateMachinePID,BH),
  base_variables:write(<<"FSE_FSM_INFO">>,<<"FSE_FSM_status">>, start,BH),
  ok.

