%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 17:11
%%%-------------------------------------------------------------------
-module(ps_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  FilePath = "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/process_step_AT_lib/src/process_step_data.json",
  base_variables:write(<<"TypesOfPS">>, <<"FilePath">>, FilePath, BH),

  base:wait_for_base_ready(BH),
  timer:sleep(100),
  TableName = "process_steps",
  Columns = [
    {"name", "text"},
    {"type", "text"},
    {"parent", "text"},
    {"startUnix", "bigint"},
    {"endUnix", "bigint"},
    {"duration","numeric"},
    {"resource", "text"}
  ],
  postgresql_functions:create_new_table(TableName, Columns),

  timer:sleep(2000),
  Data = #{<<"duration">> => <<"2.69">>,
    <<"name">> => <<"MT1">>,<<"parent">> => <<"Trial 1">>,
    <<"resource">> => jsx:encode([<<"FM1">>,<<"MT1">>]),
    <<"startunix">> => <<"1720992428837">>,
    <<"endunix">> => <<"1720992431531">>,
    <<"type">> => <<"measure_temp">>},
  handle_signal(<<"STORE_DATA">>, Data, BH),

  ok.

stop(BH) ->
  ok.

handle_signal(<<"END">>, ID, BH) ->
%%  TODO end instance call
  GH = base_guardian_ep:get_guardian_of_id(ID,BH),
  base_guardian_ep:end_instance(GH,BH),
  ok;

handle_signal(<<"STORE_DATA">>, Data, BH) ->

  io:format("Data in PS Type: ~p~n",[Data]),

  Result = postgresql_functions:write_data_to_postgresql_database(Data, "process_steps"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB~nwith data -> Data: ~p~n", [Data])
  end,
  ok.

handle_request(<<"SPAWN_PS_INSTANCE">>,Payload, FROM, BH)->

  IDInt = rand:uniform(10000),
  ID = integer_to_binary(IDInt),

  Name = case maps:get(<<"name">>, Payload) of
           no_entry -> list_to_binary("PS_" ++ integer_to_list(IDInt));
           Something -> case Something of
                          <<>> ->
                            list_to_binary("PS_" ++ integer_to_list(IDInt));
                          _ -> maps:get(<<"name">>, Payload)
                        end

         end,
  Contract = maps:get(<<"childContract">>,Payload),
  {ok, Recipe} = ps_guardian_sp:generate_instance_recipe(Name, ID, Contract, BH),
  Tsched = base:get_origo(),
  Data1 = maps:remove(<<"childContract">>,Payload),
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = Name,
  {reply, Reply};

handle_request(<<"INFO">>,Tag, FROM, BH)->
  case Tag of
     <<"ALL_CAP">> ->
       TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"RESOURCE_INFO">>}, BH),
       Replies = base_signal:emit_request(TargetBC, <<"INFO">>, <<"InstanceCapabilities">>, BH),
       FlattenedList = lists:flatten(Replies),
       UniqueList = lists:usort(FlattenedList),
       {reply, UniqueList};
    <<"typesOfPS">>->
      FilePath = base_variables:read(<<"TypesOfPS">>, <<"FilePath">>, BH),
      {ok, Data} = myFuncs:read_json_file(FilePath),
      CurrentData = maps:get(<<"list">>, Data),
      ListOFNames = lists:foldl(
        fun(Map, Acc) ->
          [maps:get(<<"processType">>, Map) | Acc]
        end, [], CurrentData),
      {reply, ListOFNames};
    ProcessName -> % This is for when you want the children for a specific map
      FilePath = base_variables:read(<<"TypesOfPS">>, <<"FilePath">>, BH),
      {ok, Data} = myFuncs:read_json_file(FilePath),
      CurrentData = maps:get(<<"list">>, Data),
      MyMap = find_map_by_name(ProcessName, CurrentData),
      {reply, MyMap};
    _->
      {reply,no_info}
end;

handle_request(<<"newComponent">>,Payload, FROM, BH)->
  io:format("Received a message that looks like: ~p~n",[Payload]),

  %Sort the map here
  FSM = maps:get(<<"FSM">>, Payload),
  case binary_to_existing_atom(FSM, utf8) of
    undefined -> % If the atom doesn't exist
      {reply, fsm_not_atom_error};
    Atom ->
      NewMap = maps:update(<<"FSM">>, Atom, Payload),
      Data = maps:merge(NewMap, #{<<"type">>=><<"SPAWN_PS_INSTANCE">>}),
      FilePath = base_variables:read(<<"TypesOfPS">>, <<"FilePath">>, BH),
      myFuncs:add_map_to_json_file(FilePath, Data),
      {reply, ok}
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% External functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


find_map_by_name(Name, CurrentData) ->
  lists:foldl(
    fun(Map, Acc) ->
      case maps:get(<<"processType">>, Map) of
        Name ->
          Map;
        _ ->
          Acc
      end
    end, undefined, CurrentData).






