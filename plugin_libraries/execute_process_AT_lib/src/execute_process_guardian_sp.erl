%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 11. Apr 2024 11:26
%%%-------------------------------------------------------------------
-module(execute_process_guardian_sp).
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
  {ok,BinaryData} = file:read_file("C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/execute_process_AT_lib/src/test_config.json"),
  JsonString = bason:json_to_map(BinaryData), %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Remove once testing is done!

  {ok, Recipe} = generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo()+2000,
  Data1 = #{<<"startTime">>=>1713963600,
            <<"json">>=>JsonString},
  base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH),
  ok.

generate_instance_recipe(Name, ID,BH) ->
  RECIPE = #{
    <<"plugins">>=> [
      #{<<"name">>=><<"execute_process_info_handler_ep">>,<<"lib">>=><<"execute_process_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"exePro_FSM_info_handler_ep">>,<<"lib">>=><<"execute_process_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"execute_process_sched_tasks_sp">>,<<"lib">>=><<"execute_process_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"execute_process_sched_tasks_ep">>,<<"lib">>=><<"execute_process_AT_lib">>,<<"init_args">>=>[]},
      #{<<"name">>=><<"exePro_FSM_sp">>,<<"lib">>=><<"execute_process_AT_lib">>,<<"init_args">>=>[]}
    ],
    <<"bc">> => #{
      <<"identity">>=>#{
        <<"id">>=>ID,
        <<"name">>=>Name,
        <<"taxonomy">>=>#{<<"arti_class">>=><<"resource-instance">>,<<"base_type">>=><<"PROCESS_TASK_TYPE">>}
      },
      <<"capabilities">>=>[<<"PT_INSTANCE_INFO">>,<<"EXECUTABLE_TASK">>],
      <<"responsibilities">>=>[],
      <<"addresses">>=>#{},
      <<"meta">>=>#{}

    },
    <<"disk_base">>=>no_entry,
    <<"cookie">>=><<"INSTANCE_COOK">>
  },
  {ok, RECIPE}.