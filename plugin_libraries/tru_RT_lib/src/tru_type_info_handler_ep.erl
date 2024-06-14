%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. May 2024 19:18
%%%-------------------------------------------------------------------
-module(tru_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  erlang:error(not_implemented).

stop(BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(<<"truList">>, ListOfTRU, From, BH) ->

  Tsched = base:get_origo(),
  Type = <<"create_TRU">>,
  ID = make_ref(),
  Data1 = ListOfTRU,
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),

  Reply = #{<<"Reply">>=>ok},
  {reply, Reply}.