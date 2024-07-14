%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. May 2024 13:51
%%%-------------------------------------------------------------------
-module(report_generator_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(Tag, Signal, From, BH) ->
  erlang:error(not_implemented).