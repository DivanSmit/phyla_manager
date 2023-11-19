%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(move_fruit_type_info_handler_ep).
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

handle_request(<<"SPAWN_MOVE_FRUIT_INSTANCE">>,Payload, FROM, BH)->
  IDInt = rand:uniform(1000),
  ID = integer_to_binary(IDInt),
  Name = list_to_binary("move_fruit_" ++ integer_to_list(IDInt)),
  io:format("Spawn request recieved of ~p~n",[Name]),

  {ok, Recipe} = move_fruit_guardian_sp:generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo(),
  Data1 = no_data,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
  end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.
