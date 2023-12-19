%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Dec 2023 17:05
%%%-------------------------------------------------------------------
-module(move_fruit_FSM_sp).
-author("LENOVO").

%% API
-export([init/2, stop/1, handle_task_request/2]).


init(Pars, BH) ->
  handle_task_request(Pars,BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_task_request(Pars, BH) ->

  StartTime = maps:get(<<"startTime">>,Pars),
  base_variables:write(<<"MF_FSM_INFO">>,<<"startTime">>, StartTime,BH),

  FSM_data = #{<<"BH">> => BH},
  {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))},move_fruit_FSM_sched, FSM_data, []),

  base_variables:write(<<"MF_FSM_INFO">>,<<"MF_FSM_PID">>, StateMachinePID,BH),
  base_variables:write(<<"MF_FSM_INFO">>,<<"MF_FSM_status">>, start,BH),
  ok.
