%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(move_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{},
  {reply, Reply}.

handle_signal(<<"StartTask">>,ID, BH)->

  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, task_started),
      base_variables:write(<<"FSM_INFO">>, <<"FSM_status">>, task_started, BH);
    _ ->
      true
  end,
  ok;

handle_signal(<<"EndTask">>,ID, BH)->
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, task_finished),
      base_variables:write(<<"FSM_INFO">>, <<"FSM_status">>, task_finished, BH);
    _ ->
      true
  end,
  ok.