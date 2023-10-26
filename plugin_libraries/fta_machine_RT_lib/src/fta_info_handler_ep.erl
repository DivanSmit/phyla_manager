%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:52
%%%-------------------------------------------------------------------
-module(fta_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  io:format("Info handler plugin installed~n"),
  ok.

stop(BH) ->
  ok.

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  Values = base_variables:read(<<"MEASUREMENTS">>,<<"values">>,BH),
  Reply = #{<<"content">>=>Values},
  {reply, Reply}.