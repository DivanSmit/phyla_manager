%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Sep 2023 16:50
%%%-------------------------------------------------------------------
-module(move_fruit_guardian_sp).
-author("LENOVO").
-behaviour(base_guardian_sp).
%% API
-export([init/2, stop/1, instance_spawn_request/2, generate_instance_recipe/4]).


init(Pars, BH) ->
  %% we want to create an instance
  base:wait_for_base_ready(BH),
  lists:foldl(fun(Elem,Acc)->
    instance_spawn_request(Elem,BH)
              end, [], Pars),
  ok.

stop(BH) ->
  ok.

instance_spawn_request(Pars, BH) ->
  Name = maps:get(<<"name">>,Pars),
  ID = maps:get(<<"id">>,Pars),

  {ok, Recipe} = generate_instance_recipe(Name, ID, base:get_origo(),BH),
  Tsched = base:get_origo(),
  Data1 = no_data,
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, ID, TStart, BH) ->
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"mf_storage_master_link_ep">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"mf_storage_master_link_sp">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"mf_operator_master_link_ep">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"mf_operator_master_link_sp">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_fruit_FSM_sp">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>
        #{<<"startTime">>=>TStart}
      },
      #{<<"name">>=><<"move_fruit_info_handler_ep">>,<<"lib">>=><<"move_fruit_AT_lib">>,<<"init_args">>=>[]}
    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"MOVE_FRUIT_TYPE">>}
      },
      <<"capabilities">>=>[<<"MOVEFRUIT_INSTANCE_INFO">>,<<"EXECUTABLE_TASK">>],
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.