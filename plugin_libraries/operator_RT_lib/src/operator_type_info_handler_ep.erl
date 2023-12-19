%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(operator_type_info_handler_ep).
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

handle_request(<<"SPAWN_OPERATOR_INSTANCE">>,Payload, FROM, BH)->
  Jsondata = maps:get(<<"param">>,Payload),

  Params =  bason:json_to_map(Jsondata),

  Name = list_to_binary(lists:concat([
    binary_to_list(maps:get(<<"name">>, Params)),
    " ",
    binary_to_list(maps:get(<<"surname">>, Params))
    ])),

  ID = maps:get(<<"workerID">>,Params),

  AttributesMap = #{
    <<"password">>=>maps:get(<<"password">>,Params),
    <<"BreakTime">>=>maps:get(<<"lunchTime">>,Params)
  },

  {ok, Recipe} = operator_guardian_sp:generate_instance_recipe(Name, ID, BH),
  io:format("Spawn request recieved of ~p~n",[Name]),
  Tsched = base:get_origo(),
  Data1 = AttributesMap,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.
