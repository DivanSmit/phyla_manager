%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Dec 2023 15:01
%%%-------------------------------------------------------------------
-module(facility_room_guardian_sp).
-author("LENOVO").
-behaviour(base_guardian_sp).
%% API
-export([init/2, stop/1, instance_spawn_request/2, generate_instance_recipe/2]).


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
  Cap = maps:get(<<"capacity">>,Pars),
  Name = maps:get(<<"name">>,Pars),

  {ok, Recipe} = generate_instance_recipe(Name, BH),
  Tsched = base:get_origo(),
  Data1 = #{
    <<"capacity">>=>Cap
  },
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, BH) ->

    RECIPE = #{
      <<"plugins">> => [
        #{<<"name">>=><<"move_storage_servant_link_ep">>,<<"lib">>=><<"facility_room_RT_lib">>,<<"init_args">>=>[]},
        #{<<"name">>=><<"move_storage_servant_link_sp">>,<<"lib">>=><<"facility_room_RT_lib">>,<<"init_args">>=>[]},
        #{<<"name">>=><<"facility_room_info_handler_ep">>,<<"lib">>=><<"facility_room_RT_lib">>,<<"init_args">>=>[]}
      ],
      <<"bc">> => #{
        <<"identity">> => #{
          <<"id">> => integer_to_binary(rand:uniform(1000)),
          <<"name">> => Name,
          <<"taxonomy">> => #{<<"arti_class">> => <<"resource-instance">>, <<"base_type">> => <<"FACILITY_ROOM_TYPE">>}
        },
        <<"capabilities">> => [
          <<"FACILITY_ROOM_INSTANCE_INFO">>,
          <<"COLD_STORE_FRUIT">>
        ],
        <<"responsibilities">> => [],
        <<"addresses">> => #{},
        <<"meta">> => #{}
      },
      <<"disk_base">> => no_entry,
      <<"cookie">> => <<"INSTANCE_COOK">>
    },

  {ok, RECIPE}.