%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:12
%%%-------------------------------------------------------------------
-module(execute_process_info_handler_ep).
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
  % Remember to update .json file of any changes to the subject
  ok.