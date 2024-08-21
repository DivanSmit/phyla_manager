%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. Jul 2024 13:01
%%%-------------------------------------------------------------------
-module(tru_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->

  %% TODO This is actually wrong and needs to be in the type
  base:wait_for_base_ready(BH),
  timer:sleep(100),
  TableName = "tru_history_table",
  Columns = [
    {"incoming", "text"},
    {"process", "text"},
    {"outgoing", "text"},
    {"date","numeric"}
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

  TableName1 = "all_trus",
  Columns1 = [
    {"tru", "text"},
    {"name", "text"},
    {"process", "text"},
    {"type", "text"},
    {"date","numeric"}
  ],
  try
    timer:sleep(100),
    postgresql_functions:create_new_table(TableName1, Columns1)
  catch
    _:_ ->
      try
        io:format("Trying to create ~p again~n", [TableName1])
      catch
        _:_ -> io:format("################POSTGRES ERROR###################~n~p cannot be opended~n~n",[TableName1])
      end
  end,

  base_variables:write(<<"barcodes">>, <<"map">>, #{}, BH),

  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_signal(<<"CompletedTask">>, {Name, Data}, BH) ->

  TRUS = tru:find_end_trus(Data),
  {Incoming, Outgoing} = maps:fold(fun(Key, Value, {In, Out})->
    {In++[Key], Out++Value}
  end, {[],[]}, TRUS),

  Data_map = #{
    <<"incoming">> =>jsx:encode(Incoming),
    <<"process">> => Name,
    <<"outgoing">> => jsx:encode(Outgoing),
    <<"date">> => integer_to_binary(base:get_origo())
  },

  Result = postgresql_functions:write_data_to_postgresql_database(Data_map, "tru_history_table"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB:~nData: ~p~n", [Data_map])
  end,

  ok.

handle_request(<<"NEW">>, Data, From, BH) ->
  % Need type [apple, other], process [Trial name], name [PS name], amount [number of trus to generate]
  Type = maps:get(<<"type">>, Data),
  {ok, List} = postgresql_functions:execute_combined_queries("all_trus", [{equal, "type", binary_to_list(Type)}]),
  N = maps:get(<<"barcodes">>,Data, []),
  TRUs = generate_trus(Data, List, length(N)),
  save_barcodes(N, TRUs, BH),
  {reply, TRUs};

handle_request(<<"GetTRUs">>, Barcodes, From, BH) ->
  Map = base_variables:read(<<"barcodes">>, <<"map">>, BH),
  TRUs = lists:foldl(fun(Code, Acc) ->
    case maps:get(Code, Map, none) of
      none -> Acc;
      TRU -> Acc ++ [TRU]
    end
                     end, [], Barcodes),
  {reply, TRUs}.

generate_trus(_Data, _List, 0) -> [];
generate_trus(Data, List, N) ->

  Type = maps:get(<<"type">>, Data),
  TRU = get_unique_TRU(Type, List),
  Name = maps:get(<<"name">>, Data),
  Type = maps:get(<<"type">>, Data),
  Process = maps:get(<<"process">>, Data),
  Date = integer_to_binary(base:get_origo()),

  Data_map = #{
    <<"name">>=>Name,
    <<"type">>=>Type,
    <<"process">>=> Process,
    <<"date">>=> Date,
    <<"tru">>=> TRU
  },

  Result = postgresql_functions:write_data_to_postgresql_database(Data_map, "all_trus"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB:~nData: ~p~n", [Data_map])
  end,
  [TRU| generate_trus(Data, List, N - 1)].

get_unique_TRU(Type, List) ->
  NewTRU = generate_code(Type),
  case lists:member(NewTRU, List) of
    true -> get_unique_TRU(Type, List);
    false -> NewTRU
  end.

% Function to generate Apple Code: Pattern AXX999
generate_code(<<"apple">>) ->
  Prefix = "A",
  Letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  Digits = "0123456789",
  Code = Prefix ++ generate_random_chars(2, Letters) ++ generate_random_chars(3, Digits),
  list_to_binary(Code);

% Function to generate Generic Code: Pattern PL999A
generate_code(<<"other">>) ->
  Prefix = "PL",
  Letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ",
  Digits = "0123456789",
  Code = Prefix ++ generate_random_chars(3, Digits) ++ generate_random_chars(1, Letters),
  list_to_binary(Code);

generate_code(_) ->
  error.

% Helper function to generate a random string of given length from the given character set
generate_random_chars(Length, Characters) ->
  generate_random_chars(Length, Characters, []).

generate_random_chars(0, _Characters, Acc) ->
  lists:reverse(Acc);
generate_random_chars(Length, Characters, Acc) ->
  ListLength = length(Characters),
  Index = crypto:rand_uniform(1, ListLength + 1),
  Char = lists:nth(Index, Characters),
  generate_random_chars(Length - 1, Characters, [Char | Acc]).

save_barcodes(Codes, TRUs, BH) ->
  Pairs = lists:zip(Codes, TRUs),
  Map = maps:from_list(Pairs),
  OldMap = base_variables:read(<<"barcodes">>, <<"map">>, BH),
  base_variables:write(<<"barcodes">>, <<"map">>, maps:merge(OldMap, Map), BH),
  io:format("The new barcode map is: ~p~n",[maps:merge(OldMap, Map)]).
