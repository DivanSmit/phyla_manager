%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 17:11
%%%-------------------------------------------------------------------
-module(execute_process_type_info_handler_ep).
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

handle_request(<<"SPAWN_EXECUTE_PROCESS_INSTANCE">>,Payload, FROM, BH)->
  IDInt = rand:uniform(1000),
  ID = integer_to_binary(IDInt),
  Name = list_to_binary("ExePro_" ++ integer_to_list(IDInt)),

  Jsondata = maps:get(<<"param">>,Payload),
  Params =  bason:json_to_map(Jsondata),

  {ok, Recipe} = execute_process_guardian_sp:generate_instance_recipe(Name, ID,BH),
  Tsched = base:get_origo(),
  Data1 = Params,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.