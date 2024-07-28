%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 21. Jul 2024 13:51
%%%-------------------------------------------------------------------
-module(tru).
-author("LENOVO").

%% API
-export([change_tru/3, current/1, find_end_trus/1, add_new/2, in_and_out/1]).

change_tru(Incoming, Outgoing, TRUs) ->
  New = lists:foldl(fun(In, Out) ->
    maps:put(In, Outgoing, Out)
                    end, #{}, Incoming),

  AddedMaps = maps:fold(fun(Key, Value, Map) ->
    case maps:get(Key, TRUs, new) of
      new -> maps:put(Key, Value, Map);
      List -> maps:update(Key, List ++ Value, Map)
    end
                        end, TRUs, New),

  OutMap = lists:foldl(fun(Elem, Acc) ->
    maps:put(Elem, [], Acc)
                       end, #{}, Outgoing),

  maps:merge(AddedMaps, OutMap).

current(TRUs)->

  maps:fold(fun(Key, Value, Acc)->
    if
      Value==[] -> Acc++[Key];
      true -> Acc
    end
  end, [], TRUs).

% Find the end TRUs for each original TRU
find_end_trus(Map) ->
  InitialTRUs = find_initial_trus(Map),
  lists:foldl(fun(Key, Acc) ->
    EndTRUs = trace_to_final_trus(Key, Map),
    case EndTRUs of
      [] -> Acc;
      _ -> maps:put(Key, lists:usort(EndTRUs), Acc)
    end
              end, #{}, InitialTRUs).

% Find initial TRUs (those that do not appear in any list of values)
find_initial_trus(Map) ->
  AllKeys = sets:from_list(maps:keys(Map)),
  AllValues = sets:from_list(lists:flatmap(fun(X) -> X end, maps:values(Map))),
  sets:to_list(sets:subtract(AllKeys, AllValues)).

% Trace to final TRUs
trace_to_final_trus(TRU, Map) ->
  case maps:get(TRU, Map, []) of
    [] -> [TRU]; % It's an end TRU
    OutgoingTRUs ->
      lists:flatmap(fun(O) -> trace_to_final_trus(O, Map) end, OutgoingTRUs)
  end.

in_and_out(Data)->
  TRUS = tru:find_end_trus(Data),
  maps:fold(fun(Key, Value, {In, Out})->
    {In++[Key], Out++Value}
                                   end, {[],[]}, TRUS).

add_new(ChildMap, OldMap)->
  maps:fold(fun(Key, Value, Acc)->
    change_tru([Key], Value, Acc)
  end, OldMap, ChildMap).
