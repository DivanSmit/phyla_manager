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

%%,
%%{
%%"name": "Test2",
%%"id": "2",
%%"role": "operator",
%%"password": "",
%%"BreakTime": "12:00"
%%}


init(Pars, BH) ->
  base:wait_for_base_ready(BH),
  TableName = "operator_work_schedule",
  Columns = [
    {"unix", "bigint"},
    {"date", "date"},
    {"name", "text"},
    {"time_start", "time"},
    {"time_end", "time"},
    {"duration", "numeric"},
    {"efficiency", "numeric"}
  ],
  base_variables:write(list_to_binary(TableName), <<"columns">>, Columns, BH),
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
%%  io:format("Data map: ~p~n",[Data_map]),

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

  Data = case maps:get(<<"action">>, Request, <<"operator_schedule">>) of
           <<"operator_schedule">> ->
             TableName = "operator_work_schedule",
             AlLdata = maps:get(<<"allData">>, Request),

             if
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
             end;
           <<"Measure">> ->
             TableName1 = "tru_measurements",
             TRUs = maps:get(<<"TRUs">>, Request, []),
             Process = maps:get(<<"process">>, Request),

             Map = lists:foldl(fun(Elem, Acc) ->
               {ok, [Rows|_]} = postgresql_functions:execute_combined_queries(TableName1, [{equal, "name", binary_to_list(Elem)}, {equal, "process", binary_to_list(Process)}]),
               maps:put(Elem,Rows, Acc)
                               end, #{}, TRUs),


             lists:foldl(fun(Val, Acc)->
                maps:merge(Acc, get_values(Val, Map, BH))
             end, #{},maps:get(<<"values">>, Request, []));
           _->
             #{}

         end,


  {reply, Data}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% External functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


get_values(Value, Data,BH)->

  Columns = base_variables:read(<<"tru_measurements">>, <<"columns">>, BH),
  Val = binary_to_list(Value),

  {Index, _} = lists:foldl(
    fun({Elem,_}, {I, Acc}) ->
      if
        Val == Elem -> {I, I};
        true -> {I + 1, Acc}
      end
    end, {1, 0}, Columns),

  {Sum, Count} = maps:fold(fun(_Key, Tuple, {AccSum, AccCount}) ->
    Elem = element(Index, Tuple),
    {AccSum + binary_to_integer(Elem), AccCount + 1}
                           end, {0, 0}, Data),

  % Calculate the average
   Return = case Count of
            0 -> 0; % If there are no elements, return 0 to avoid division by zero
            _ -> Sum / Count
          end,

  #{Value => Return}.