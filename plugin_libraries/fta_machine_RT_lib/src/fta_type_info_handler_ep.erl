%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:52
%%%-------------------------------------------------------------------
-module(fta_type_info_handler_ep).
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

handle_request(<<"SPAWN_FTA_MACHINE_INSTANCE">>,Payload, FROM, BH)->
  Name = maps:get(<<"name">>,Payload),
  io:format("Spawn request recieved of ~p~n",[Name]),
  ID = maps:get(<<"id">>,Payload),

  {ok, Recipe} = fta_machine_guardian_sp:generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo(),
  Data1 = no_data,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.
