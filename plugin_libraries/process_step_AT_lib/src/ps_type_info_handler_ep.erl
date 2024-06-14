%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 17:11
%%%-------------------------------------------------------------------
-module(ps_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"END">>, ID, BH) ->
%%  TODO end instance call
  GH = base_guardian_ep:get_guardian_of_id(ID,BH),
  base_guardian_ep:end_instance(GH,BH),
  ok.

handle_request(<<"SPAWN_PS_INSTANCE">>,Payload, FROM, BH)->
  io:format("received~n"),
  IDInt = rand:uniform(10000),
  ID = integer_to_binary(IDInt),
  Name = list_to_binary("PS_" ++ integer_to_list(IDInt)),

  {ok, Recipe} = ps_guardian_sp:generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo(),
  Data1 = Payload,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = Name,
  {reply, Reply}.