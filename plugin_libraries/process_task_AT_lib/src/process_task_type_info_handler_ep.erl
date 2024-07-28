%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 17:11
%%%-------------------------------------------------------------------
-module(process_task_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  FilePath = "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/process_task_AT_lib/src/process_task_data.json",
  base_variables:write(<<"TypesOfPS">>, <<"FilePath">>, FilePath, BH),

  base:wait_for_base_ready(BH),
  TableName = "process_tasks",
  Columns = [
    {"name", "text"},
    {"type", "text"},
    {"parent", "text"},
    {"startunix", "bigint"},
    {"endunix", "bigint"},
    {"duration","numeric"},
    {"resource", "text"}, %% Remember to update functions at the bottom if indexes are changed
    {"trus","text"} %% Remember to update functions at the bottom if indexes are changed
  ],
  try
    timer:sleep(100),
    postgresql_functions:create_new_table(TableName, Columns)
  catch
    _:_ ->
      try
        io:format("Trying to create ~p again~n", [TableName])
      catch
        _:_ -> io:format("################POSTGRES ERROR###################~n~p cannot be opended~n~n",[TableName])
      end
  end,



  ok.

stop(BH) ->
  ok.

handle_signal(<<"END">>, ID, BH) ->
%%  TODO end instance call
  GH = base_guardian_ep:get_guardian_of_id(ID,BH),
  base_guardian_ep:end_instance(GH,BH),
  ok;

handle_signal(<<"STORE_DATA">>, Data, BH) ->

%%  io:format("Data in PS Type: ~p~n",[Data]),
  Result = postgresql_functions:write_data_to_postgresql_database(Data, "process_tasks"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB~nwith data -> Data: ~p~n", [Data])
  end,
  ok.


handle_request(<<"INFO">>, Tag, From, BH) ->
  case Tag of
    <<"query_create">> ->
      % Get Types of Process Steps
      TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_PS_INSTANCE">>}, BH),
      [Replies] = base_signal:emit_request(TargetBC, <<"INFO">>, <<"typesOfPS">>, BH),
      io:format("Replies: ~p~n", [Replies]),

      % get current Process Tasks
      FilePath = base_variables:read(<<"TypesOfPS">>, <<"FilePath">>, BH),
      {ok, Data} = myFuncs:read_json_file(FilePath),
      CurrentData = maps:get(<<"list">>, Data),
      ListOFNames = lists:foldl(
        fun(Map, Acc) ->
          [maps:get(<<"processType">>, Map) | Acc]
        end, [], CurrentData),
      io:format("List of names: ~p~n", [ListOFNames]),

      FinalList = Replies ++ ListOFNames,
      {reply, FinalList};

    <<"query_options">> ->
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
      MyMap = get_full_hierarchy(ProcessName, CurrentData),
      {reply, MyMap};
    _->
      {reply, error}
  end;

handle_request(<<"SPAWN_PROCESS_TASK_INSTANCE">>, Payload, FROM, BH) ->
  IDInt = rand:uniform(1000),
  ID =   ID = maps:get(<<"processID">>, Payload,integer_to_binary(IDInt)),

  Name = case maps:get(<<"name">>, Payload, <<"no_entry">>) of
           <<"no_entry">> -> list_to_binary("PT_" ++ integer_to_list(IDInt));
           <<>> -> list_to_binary("PT_" ++ integer_to_list(IDInt));
           Something -> Something
         end,

  StartTime = maps:get(<<"startTime">>, Payload, 0),
  NewPayload = case StartTime of
                 0 -> maps:put(<<"startTime">>, base:get_origo(), Payload);
                 _ -> Payload
               end,

  Contract = maps:get(<<"childContract">>, NewPayload, <<"contracting_A">>),
  ChildContract = case Contract of
                    <<"contracting_A">> -> <<"contracting_B">>;
                    <<"contracting_B">> -> <<"contracting_A">>
                  end,

  {ok, Recipe} = process_task_guardian_sp:generate_instance_recipe(Name, ID, ChildContract, BH),

  SchedData1 = maps:put(<<"childContract">>, ChildContract, NewPayload),
  SchedData = update_with(<<"parentID">>,
    fun(_) -> base_business_card:get_id(base:get_my_bc(BH)) end,
    base_business_card:get_id(base:get_my_bc(BH)),
    SchedData1),

  Tsched = base:get_origo(),
  Data1 = SchedData,
  spawn(fun() -> base_guardian_sp:schedule_instance_guardian(Tsched, Recipe, Data1, BH) end),

  Reply = Name,
  {reply, Reply};

handle_request(<<"Update">>, From, _, BH) ->
  % This because for the top activity holon their parent is the operator!
  {reply, {ready,#{}}};


handle_request(<<"newComponent">>,Payload, FROM, BH)->
  io:format("Received a message that looks like: ~p~n", [Payload]),
%% TODO add checks to see if the data is legit and correct
  Data = maps:merge(Payload, #{<<"type">>=><<"SPAWN_PROCESS_TASK_INSTANCE">>}),
  FilePath = base_variables:read(<<"TypesOfPS">>, <<"FilePath">>, BH),
  myFuncs:add_map_to_json_file(FilePath, Data),
  {reply, ok};

handle_request(<<"requestForData">>,Layout, FROM, BH)->

  io:format("P Task received a request for data with layout: ~p~n",[Layout]),
  Actions = maps:get(<<"actions">>, Layout),
  Name = maps:get(<<"process">>,Layout),
  {ok, Entry} = postgresql_functions:execute_combined_queries("process_tasks", [{equal, "name", binary_to_list(Name)}]),

  case Entry of
    [] -> {reply, no_entry};
    [Trial] ->
      TRUs = element(9, Trial),
      {Incoming, _} = tru:in_and_out(jsx:decode(TRUs)),
      Structure = get_root_structure(Name, Actions, Incoming, BH),
      FinalList = flatten_lists(Structure),
      {reply, FinalList}

  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% External functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_full_hierarchy(Name, CurrentData) ->
  find_map_and_children(Name, CurrentData, CurrentData).

find_map_and_children(Name, MainList, CurrentData) ->
  ParentMap = find_map_by_name(Name, CurrentData),
  ChildrenMap = maps:get(<<"children">>, ParentMap, []),
  ChildrenNames = extract_names(ChildrenMap),
  case lists:all(fun(ChildName) -> lists:any(fun(Map) -> maps:get(<<"processType">>, Map) == ChildName end, MainList) end, ChildrenNames) of
    true ->
      ChildrenMaps = [find_map_and_children(ChildName, MainList, CurrentData) || ChildName <- ChildrenNames],
      maps:put(<<"children">>, ChildrenMaps, ParentMap);
    false ->

      ParentMap  % This is a leaf node with no children in MainList
  end.

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

extract_names(ListChildren)->
  lists:foldl(
    fun(Map, Acc) ->
      [maps:get(<<"processType">>, Map) | Acc]
    end, [], ListChildren).

% Helper function to simplify maps:update_with
update_with(Key, Fun, Default, Map) ->
  case maps:get(Key, Map, none) of
    none -> maps:put(Key, Default, Map);
    _ -> maps:update(Key, Fun, Map)
  end.

get_root_structure(Name, Actions, TRUs, BH) ->

  {ok, [Entry]} = postgresql_functions:execute_combined_queries("process_tasks", [{equal, "name", binary_to_list(Name)}]),

  Resources = jsx:decode(element(8, Entry)),
  lists:foldl(fun(Child, Acc) ->
    {ok, ChildData} = postgresql_functions:execute_combined_queries("process_tasks", [{equal, "name", binary_to_list(Child)}]),
    case ChildData of
      [] -> io:format("The child: ~p is a PS~n", [Child]),
        TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_PS_INSTANCE">>}, BH),
        [Reply] = base_signal:emit_request(TargetBC, <<"requestForData">>, {Child, Actions}, BH),
        case Reply of
          none -> Acc;
          _ -> Acc ++ [Reply]
        end;
      % Need to contact the
      [List] ->
        {MyTRUs, _} = tru:in_and_out(jsx:decode(element(9, List))),
        Common_TRUs = [X || X <- MyTRUs, lists:member(X, TRUs)],
        case Common_TRUs of
          [] -> no_trus;
          _ ->
            Response = get_root_structure(Child, Actions, Common_TRUs, BH),
            io:format("Response from child ~p of ~p: ~p~n", [Child, Name, Response]),
            case is_map(Response) of
              true -> Acc ++ [Response];
              false -> Acc
            end
        end

    end
                         end, [], Resources).

flatten_lists(ListOfLists) -> % First time calling this
  flatten_lists(ListOfLists, []).
flatten_lists([], Acc) ->
  lists:reverse(Acc); % Reverse the accumulator at the end to maintain order
flatten_lists([H | T], Acc) when is_list(H) ->
  flatten_lists(T, flatten_lists(H, Acc)); % Recursively flatten the head and continue with the tail
flatten_lists([H | T], Acc) ->
  flatten_lists(T, [H | Acc]). % Add the head to the accumulator and continue with the tail







