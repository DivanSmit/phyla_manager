%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. May 2024 19:03
%%%-------------------------------------------------------------------
-module(tru_guardian_sp).
-author("LENOVO").
-behaviour(base_guardian_sp).
%% API
-export([init/2, stop/1, instance_spawn_request/2, generate_instance_recipe/3]).


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
  ID = maps:get(<<"id">>,Pars),
  Name = maps:get(<<"name">>,Pars),

  {ok, Recipe} = generate_instance_recipe(ID, Name, BH),
  Tsched = base:get_origo(),
  Data1 = #{},
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(ID, Name, BH) ->
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"tru_info_handler_ep">>,<<"lib">>=><<"tru_RT_lib">>,<<"init_args">>=>[]}

    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"OPERATOR_TYPE">>}
      },
      <<"capabilities">>=>[<<"TRU_INSTANCE">>],
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.