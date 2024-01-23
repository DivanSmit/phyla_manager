%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jan 2024 13:48
%%%-------------------------------------------------------------------
-module(facility_room_info_handler_ep).
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

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply}.