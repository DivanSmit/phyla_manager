%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Dec 2023 17:49
%%%-------------------------------------------------------------------
-module(facility_room_type_info_handler).
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

handle_request(<<"SPAWN_FACILITY_ROOM_INSTANCE">>,Payload, FROM, BH)->
  Jsondata = maps:get(<<"param">>,Payload),
  Params =  bason:json_to_map(Jsondata),

  Type = maps:get(<<"type">>,Params),
  Name = maps:get(<<"name">>, Params),

  AttributesMap = #{

  },

  {ok, Recipe} = facility_room_guardian_sp:generate_instance_recipe(Type, Name, BH),
  io:format("Spawn request recieved of ~p~n",[Name]),

  Tsched = base:get_origo(),
  Data1 = AttributesMap,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),

  Reply = #{<<"name">>=>Name},
  {reply, Reply}.