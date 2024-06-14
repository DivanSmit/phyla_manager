%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. Apr 2024 16:37
%%%-------------------------------------------------------------------
-module(treatment_process_type_info_handler_ep).
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
  ok;

handle_signal(<<"ProcessData">>, Data, BH) ->
%% TODO add checks to see if the data is legit and correct
  base_attributes:write_page(<<"processData">>,Data,BH),
  ok.

handle_request(<<"currentConfig">>,Payload, FROM, BH)->
  %Testing
  {ok,BinaryData} = file:read_file("C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/process_task_AT_lib/src/test_config.json"),
  JsonString = bason:json_to_map(BinaryData), %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Remove once testing is done!

  Reply = #{<<"Reply">>=>JsonString},
  {reply, Reply};

handle_request(<<"SPAWN_TREATMENT_PROCESS_INSTANCE">>,Payload, FROM, BH)->
  IDInt = rand:uniform(1000),
  ID = integer_to_binary(IDInt),
  Name = list_to_binary("TreatmentProcess_" ++ integer_to_list(IDInt)),

  Params = #{
    <<"processPlan">>=>Payload
  },

  {ok, Recipe} = treatment_process_guardian_sp:generate_instance_recipe(Name, ID,BH),
  Tsched = base:get_origo(),
  Data1 = Params,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = ID,
  {reply, Reply}.