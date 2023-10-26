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
  Name = maps:get(<<"name">>,Payload),
  ID = maps:get(<<"id">>,Payload),
  {ok, Recipe} = generate_instance_recipe(Name, ID, BH),
  io:format("Spawn request recieved of ~p~n",[Name]),
  Tsched = base:get_origo(),
  Data1 = no_data,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply}.

generate_instance_recipe(Name, ID, BH) ->
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"move_fruit_sp">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_fruit_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_fruit_servant_link_sp">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_fruit_servant_link_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"operator_info_handler_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]}

    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"OPERATOR_TYPE">>}
      },
      <<"capabilities">>=>[<<"MoveFruit">>,<<"OPERATOR_INSTANCE_INFO">>],
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.

