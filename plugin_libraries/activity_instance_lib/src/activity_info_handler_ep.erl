%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:12
%%%-------------------------------------------------------------------
-module(activity_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_request(Tag, Signal, FROM, BH) ->
  erlang:error(not_implemented);

handle_request(<<"INFO">>,<<"INFO">>, FROM ,BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{},
  {reply, Reply}.

handle_signal(<<"StartTask">>,ID, BH)->
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, start);
    _ ->
      true
  end,
  ok;

handle_signal(<<"EndTask">>,ID, BH)->
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, end_task);
    _ ->
      true
  end,
  ok;

handle_signal(<<"Update">>,Value, BH)->
%%  io:format("Received message from: ~p~n",[Value]),
  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Ready">>,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Ready">>,Count+1,BH),
  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, ready),
  ok.