%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(operator_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  base:wait_for_base_ready(BH),
  timer:sleep(100), % Buffer to allow functions to be compiled or something like that
  TableName = "operator_work_schedule", %% TODO add the table value as a base_variable
  Columns = [
    {"unix", "bigint"},
    {"date", "date"},
    {"name", "text"},
    {"time_start", "time"},
    {"time_end", "time"},
    {"duration", "numeric"},
    {"efficiency", "numeric"}
  ],
  postgresql_functions:create_new_table(TableName, Columns),
  ok.

stop(BH) ->
  ok.

handle_signal(<<"RESOURCE_USAGE">>, Data, BH) ->
  % Store the data

  Unix = integer_to_binary(maps:get(<<"date">>, Data)),

  Keys = [<<"time_start">>, <<"time_end">>, <<"date">>],
  ConvertFun = fun(Key, Map) ->
    case maps:is_key(Key, Map) of
      true -> maps:update(Key, myFuncs:convert_unix_time_to_normal(maps:get(Key, Map)), Map);
      false -> Map
    end
               end,

  Data_1 = lists:foldl(ConvertFun, Data, Keys),
  Data_map = maps:merge(Data_1,#{
    <<"unix">>=> Unix
  }),
  io:format("Data map: ~p~n",[Data_map]),

  Result = postgresql_functions:write_data_to_postgresql_database(Data_map, "operator_work_schedule"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB:~nData: ~p~n", [Data_map])
  end,
  ok.

handle_request(<<"SPAWN_OPERATOR_INSTANCE">>,Payload, FROM, BH)->
  Jsondata = maps:get(<<"param">>,Payload),

  Params =  bason:json_to_map(Jsondata),

  Name = list_to_binary(lists:concat([
    binary_to_list(maps:get(<<"name">>, Params)),
    " ",
    binary_to_list(maps:get(<<"surname">>, Params))
    ])),

  ID = maps:get(<<"workerID">>,Params),

  AttributesMap = #{
    <<"password">>=>maps:get(<<"password">>,Params),
    <<"BreakTime">>=>maps:get(<<"lunchTime">>,Params)
  },

  {ok, Recipe} = operator_guardian_sp:generate_instance_recipe(Name, ID, BH),
  io:format("Spawn request recieved of ~p~n",[Name]),
  Tsched = base:get_origo(),
  Data1 = AttributesMap,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply};

handle_request(<<"INFO">>, <<"InstanceCapabilities">>, From, BH)->
  Capabilities = base_attributes:read(<<"INSTANCE">>,<<"CAPABILITIES">>,BH),
  {reply,Capabilities};

handle_request(<<"requestForData">>,Request, FROM, BH)->

%%  {equal, "name", "John"},
%%  {range, "age", "20", "30"}


  TableName = "operator_work_schedule",
  AlLdata = maps:get(<<"allData">>, Request),

  Data = if
           AlLdata == false ->
             Start = integer_to_list(maps:get(<<"startTime">>, Request)),
             End = integer_to_list(maps:get(<<"endTime">>, Request)),
             case maps:get(<<"selected">>, Request) of
               <<"All">> ->
                 TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"OPERATOR_INSTANCE_INFO">>}, BH),
                 lists:foldl(fun(Elem, Acc) ->
                   Name = base_business_card:get_name(Elem),
                   {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Name)}, {range, "unix", Start, End}]),
                   maps:merge(Acc, #{Name => Rows})
                             end, #{}, TargetBC);
               Other ->
                 {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Other)},
                   {range, "unix", Start, End}]),
                 #{Other => Rows}
             end;

           true ->
             case maps:get(<<"selected">>, Request) of
               <<"All">> ->
                 TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"OPERATOR_INSTANCE_INFO">>}, BH),
                 lists:foldl(fun(Elem, Acc) ->
                   Name = base_business_card:get_name(Elem),
                   {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Name)}]),
                   maps:merge(Acc, #{Name => Rows})
                             end, #{}, TargetBC);
               Other ->
                 {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Other)}]),
                 #{Other => Rows}
             end
         end,

  {reply, Data}.
