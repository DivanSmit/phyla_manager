%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 17:05
%%%-------------------------------------------------------------------
-module(ps_guardian_sp).
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
  Name = maps:get(<<"name">>,Pars),
  ID = maps:get(<<"id">>,Pars),

  {ok, Recipe} = generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo(),
  Data1 = no_data,
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, ID, BH) ->
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"ps_fta_machine_master_link_sp">>,<<"lib">>=><<"process_step_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"ps_fta_machine_master_link_ep">>,<<"lib">>=><<"process_step_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"contracting_operator_master_link_sp">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"contracting_operator_master_link_ep">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"ps_info_handler_ep">>,<<"lib">>=><<"process_step_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"ps_FSM_sp">>,<<"lib">>=><<"process_step_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"contracting_servant_link_sp">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"contracting_servant_link_ep">>,<<"lib">>=><<"activity_instance_lib">>,<<"init_args">>=>[]}

    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"PS_TYPE">>}
      },
      <<"capabilities">>=>[<<"PS_INSTANCE_INFO">>,<<"EXECUTABLE_TASK">>],
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.