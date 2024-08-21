%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Apr 2024 11:26
%%%-------------------------------------------------------------------
-module(process_task_guardian_sp).
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

  {ok, Recipe} = generate_instance_recipe(Name, ID,<<"contracting_A">>, BH),
  Tsched = base:get_origo()+2000,
  Data1 = #{<<"startTime">>=>base:get_origo()},
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, ID, Contract,BH) ->

  RECIPE = case Contract of
             <<"contracting_A">> ->
               #{
                 <<"plugins">> => [
                   #{<<"name">> => <<"process_task_info_handler_ep">>, <<"lib">> => <<"process_task_AT_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"proTask_FSM_info_handler_ep">>, <<"lib">> => <<"process_task_AT_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_A_sp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_A_ep">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_A_rp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_A_ap">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_servant_link_B_sp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_servant_link_B_ep">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []}

                 ],
                 <<"bc">> => #{
                   <<"identity">> => #{
                     <<"id">> => ID,
                     <<"name">> => Name,
                     <<"taxonomy">> => #{<<"arti_class">> => <<"resource-instance">>, <<"base_type">> => <<"PROCESS_TASK_TYPE">>}
                   },
                   <<"capabilities">> => [],
                   <<"responsibilities">> => [],
                   <<"addresses">> => #{},
                   <<"meta">> => #{}

                 },
                 <<"disk_base">> => no_entry,
                 <<"cookie">> => <<"INSTANCE_COOK">>
               };
             <<"contracting_B">> ->
               #{
                 <<"plugins">> => [
                   #{<<"name">> => <<"process_task_info_handler_ep">>, <<"lib">> => <<"process_task_AT_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"proTask_FSM_info_handler_ep">>, <<"lib">> => <<"process_task_AT_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_servant_link_A_sp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_servant_link_A_ep">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_B_sp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_B_ap">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_B_rp">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []},
                   #{<<"name">> => <<"contracting_master_link_B_ep">>, <<"lib">> => <<"activity_instance_lib">>, <<"init_args">> => []}

                 ],
                 <<"bc">> => #{
                   <<"identity">> => #{
                     <<"id">> => ID,
                     <<"name">> => Name,
                     <<"taxonomy">> => #{<<"arti_class">> => <<"resource-instance">>, <<"base_type">> => <<"PROCESS_TASK_TYPE">>}
                   },
                   <<"capabilities">> => [],
                   <<"responsibilities">> => [],
                   <<"addresses">> => #{},
                   <<"meta">> => #{}

                 },
                 <<"disk_base">> => no_entry,
                 <<"cookie">> => <<"INSTANCE_COOK">>
               }
           end,
  {ok, RECIPE}.