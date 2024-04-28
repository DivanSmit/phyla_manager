%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Apr 2024 09:15
%%%-------------------------------------------------------------------
-module(exePro_FSM_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"StateCast">>, Cast, BH) ->
  io:format("~nReceived Cast: ~p~n",[Cast]),
  FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, Cast);

handle_signal(<<"taskScheduled">>, Time, BH) ->
  io:format("Received taskScheduled: ~p~n",[Time]),
  base_variables:write(<<"tasks">>, <<"newStart">>, Time,BH).

handle_request(<<"State">>, <<"Status">>, From, BH) ->

  %% TODO add functionality to see the status

  FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH).