%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 20. Sep 2023 16:50
%%%-------------------------------------------------------------------
-module(operator_guardian_sp).
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
  Role = maps:get(<<"role">>,Pars),

  {ok, Recipe} = generate_instance_recipe(Name, ID, Role, BH),
  Tsched = base:get_origo(),
  Data1 = Pars,
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, ID, Role, BH) ->
  Capabilities = case Role of
                   <<"facility_manager">> -> [
                     <<"manage_facility">>,
                     <<"MoveFruit">>,
                     <<"OPERATOR_INSTANCE_INFO">>,
                     <<"TAKE_MEASUREMENT">>
                   ];
                   <<"operator">> -> [
                     <<"MoveFruit">>,
                     <<"OPERATOR_INSTANCE_INFO">>,
                     <<"TAKE_MEASUREMENT">>
                   ]
                 end,
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"contracting_operator_servant_link_sp">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"contracting_operator_servant_link_ep">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"ps_operator_servant_link_rp">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_operator_servant_link_sp">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"move_operator_servant_link_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"operator_info_handler_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"facility_manager_info_handler_ep">>,<<"lib">>=><<"operator_RT_lib">>,<<"init_args">>=>[]}

    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"OPERATOR_TYPE">>}
      },
      <<"capabilities">>=>Capabilities,
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.
