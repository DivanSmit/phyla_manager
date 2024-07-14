%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. May 2024 14:01
%%%-------------------------------------------------------------------
-module(report_generator_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(<<"RequestForList">>, Tag, From, BH) ->

  TargetBC = bhive:discover_bases(#base_discover_query{capabilities = Tag}, BH),
  ListOfnames = lists:foldl(fun(Elem, Acc)->
    Name = base_business_card:get_name(Elem),
    Acc++[Name]
  end, [<<"All">>], TargetBC),
  {reply, ListOfnames};

handle_request(<<"generateReport">>, Data, From, BH) ->

%%  io:format("Data: ~p~n",[Data]),
  TypeCap = maps:get(<<"type">>, Data),
  TargetBC = bhive:discover_bases(#base_discover_query{capabilities = TypeCap}, BH),
  [RowsMap] = base_signal:emit_request(TargetBC, <<"requestForData">>, Data, BH),

  Rows = maps:map(fun(_Key, Value)->
    tuple_list_to_list_of_lists(Value)
  end, RowsMap),

  Summary = case TypeCap of
              <<"SPAWN_FACILITY_ROOM_INSTANCE">> ->
                maps:fold(fun(Key, Value, Acc) ->

                  NewValue = lists:foldl(fun(X, Acc)->
                    Acc++[[list_to_integer(lists:nth(2,X)), list_to_binary(lists:nth(6,X)), list_to_float(lists:nth(7,X))]]
                  end, [], Value),
                  Acc ++ [#{<<"name">> => Key, <<"data">>=>NewValue}]
                          end, [], Rows);
              <<"SPAWN_OPERATOR_INSTANCE">> ->
                maps:fold(fun(Key, Value, Acc) ->
                  Total = sum_of_numbers(Value, 7),
                  Efficiency = average_of_numbers(Value, 8),
                  Acc ++ [#{<<"name">> => Key, <<"total">> => Total, <<"efficiency">> => Efficiency}]
                          end, [], Rows)
            end,

  case maps:get(<<"exportFile">>, Data) of
    true ->
      FileName = binary_to_list(maps:get(<<"fileName">>, Data)),
      FilePath = "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/report_generator_RT_lib/src/" ++ FileName ++ ".csv",
      RawData = maps:fold(fun(_Key, Value, Acc)->
        Acc++Value
      end, [],RowsMap),
      write_rows_to_csv(FilePath, RawData);
    _ ->
      ok
  end,


%%  Sum = average_of_numbers(Lists, 6),
%%  io:format("sum: ~p~n",[Rows]),

  {reply, Summary}.


%%FilePath = "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/report_generator_RT_lib/src/testData.csv",
%%CSV = write_rows_to_csv(FilePath, Rows),

write_rows_to_csv(FilePath, Rows) ->
  % Open or create the file for writing in binary mode
  case file:open(FilePath, [write, binary]) of
    {ok, File} ->
      % Write each row to the file
      lists:foreach(fun(Row) ->
        RowStr = string:join([binary_to_list(Value) || Value <- tuple_to_list(Row)], ",") ++ "\n",
        file:write(File, RowStr)
                    end, Rows),
      % Close the file
      file:close(File),
      ok;
    {error, Reason} ->
      {error, Reason}
  end.

tuple_list_to_list_of_lists(Tuples) ->
  lists:map(fun(Tuple) ->
    [binary_to_list(Value) || Value <- tuple_to_list(Tuple)]
            end, Tuples).

sum_of_numbers(List, Index)->
  lists:foldl(fun(Elem, Acc)->

    Nth = list_to_float(lists:nth(Index, Elem)),
    case is_float(Nth) of
      true -> Acc + Nth;
      false -> Acc
    end
  end, 0.0, List).

average_of_numbers(List, Index) ->
  {S, C} = lists:foldl(fun(Elem, Acc) ->
    {Sum, Count} = Acc,
    Nth = list_to_float(lists:nth(Index, Elem)),
    case is_float(Nth) of
      true -> {Sum + Nth, Count + 1};
      false -> Acc
    end

                       end, {0.0, 0}, List),
  case C of
    0 -> 0;
    _ -> S / C
  end.
