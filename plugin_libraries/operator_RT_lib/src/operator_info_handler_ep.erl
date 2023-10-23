%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(operator_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(<<"MOVE">>,<<"FRUIT">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  io:format("Info handler recieved request~n"),

  MyName = base_business_card:get_name(MyBC),
  spawn(fun()->
    move_fruit_sp:handle_task_request(FROM,BH)
    end),

  Reply = #{<<"Reply">>=>ok},
  {reply, Reply};

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};

handle_request(<<"SPAWN">>,Payload, FROM, BH)->
  Name = maps:get(<<"name">>,Payload),
  io:format("Spawn request recieved of ~p~n",[Name]),
  operator_guardian_sp:instance_spawn_request(Payload,BH),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.