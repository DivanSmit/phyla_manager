%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Dec 2023 17:49
%%%-------------------------------------------------------------------
-module(facility_room_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  base:wait_for_base_ready(BH),
  TableName = "room_sensor_data",
  Columns = [
    {"unix", "bigint"},
    {"date", "date"},
    {"time", "time"},
    {"name", "text"},
    {"type", "text"},
    {"value", "numeric"}
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

handle_signal(<<"STORE_DATA">>, Data, BH) ->
  % Store the data
%%  io:format("Data_Map: ~p~n",[Data]),

  Time = maps:get(<<"time">>,Data),
  Unix = integer_to_binary(maps:get(<<"time">>, Data)),
  Data_1 = maps:update(<<"time">>,myFuncs:convert_unix_time_to_normal(Time),
    maps:put(<<"date">>,myFuncs:convert_unix_time_to_normal(Time), Data )),

  Data_map = maps:merge(Data_1, #{<<"unix">>=>Unix}),


  Result = postgresql_functions:write_data_to_postgresql_database(Data_map, "room_sensor_data"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB~nwith data -> Data: ~p~n", [Data_map])
  end,
  ok.

handle_request(<<"SPAWN_FACILITY_ROOM_INSTANCE">>,Payload, FROM, BH)->

  Jsondata = maps:get(<<"param">>,Payload),
  Params =  bason:json_to_map(Jsondata),

  Type = maps:get(<<"type">>,Params),
  Name = maps:get(<<"name">>, Params),

  AttributesMap = #{

  },

  {ok, Recipe} = facility_room_guardian_sp:generate_instance_recipe(Name, BH),
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

  Data = case maps:get(<<"action">>, Request, <<"facility_room">>) of
           <<"facility_room">> ->

             TableName = "room_sensor_data",
             AlLdata = maps:get(<<"allData">>, Request),

             if
               AlLdata == false ->
                 Start = integer_to_list(maps:get(<<"startTime">>, Request)),
                 End = integer_to_list(maps:get(<<"endTime">>, Request)),
                 case maps:get(<<"selected">>, Request) of
                   <<"All">> ->
                     TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"FACILITY_ROOM_INSTANCE_INFO">>}, BH),
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
                     TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"FACILITY_ROOM_INSTANCE_INFO">>}, BH),
                     lists:foldl(fun(Elem, Acc) ->
                       Name = base_business_card:get_name(Elem),
                       {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Name)}]),
                       maps:merge(Acc, #{Name => Rows})
                                 end, #{}, TargetBC);
                   Other ->
                     {ok, Rows} = postgresql_functions:execute_combined_queries(TableName, [{equal, "name", binary_to_list(Other)}]),
                     #{Other => Rows}
                 end
             end;
           <<"Store">> ->
             TableName1 = "room_sensor_data",

             Resource = maps:get(<<"resource">>, Request),

             Start = integer_to_list(maps:get(<<"start">>, Request)),
             End = integer_to_list(maps:get(<<"end">>, Request)),
             {ok, Rows} = postgresql_functions:execute_combined_queries(TableName1, [{equal, "name", binary_to_list(Resource)},
               {range, "unix", Start, End}]),
             #{Resource => Rows}
         end,
  {reply, Data}.
