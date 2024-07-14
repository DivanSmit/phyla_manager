%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 09. Jul 2024 17:03
%%%-------------------------------------------------------------------
-module(sensor_api_ap).
-author("LENOVO").
-behaviour(base_task_ap).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1]).


init(Pars, BH) ->


  case base_attributes:read(<<"attributes">>, <<"sensors">>, BH) of
    [] -> ok;
    _ -> analyse_data(BH)
  end
  ,
  ok.

stop(BH) ->
  erlang:error(not_implemented).

analyse_data(BH)->

  SQ = #task_shell_query{field = type, range = <<"sensor_api">>},
  Shells = base_biography:query_task_shells(SQ,BH),

  Map_Lists = lists:foldl(fun(Elem, Acc) ->

    Task = base_biography:get_task(Elem, BH),
    base_biography:take_task(Elem, BH),
    Data = Task#base_task.data3,
    Type = maps:get(<<"type">>, Data),
    Value = maps:get(<<"value">>, Data),

    case maps:get(Type, Acc, []) of
      [] -> maps:put(Type, [Value], Acc);
      List -> NewList = lists:append(List, [Value]),
        maps:update(Type, NewList, Acc)
    end
                          end, #{}, Shells),

  NewMap = maps:map(
    fun(_Key, Value) ->
      lists:sum(Value) / length(Value)
    end,
    Map_Lists
  ),


  case maps:size(NewMap) of
    0 ->
      % Handle the empty map case if needed
      ok; % or any appropriate action
    _ ->

      % Send data to parent
      MyBC = base:get_my_bc(BH),
      MyID = MyBC#business_card.identity,
      Tax = MyID#identity.taxonomy,
      ParentType = Tax#base_taxonomy.base_type_code,
      TaskHolons = bhive:discover_bases(#base_discover_query{name = ParentType}, BH),

      maps:fold(fun(Key, Value, Acc) ->
        base_signal:emit_signal(TaskHolons, <<"STORE_DATA">>,
          #{
            <<"name">> => myFuncs:myName(BH),
            <<"type">> => Key,
            <<"value">> => float_to_binary(Value, [{decimals, 2}]),
            <<"time">> => base:get_origo()
          },
          BH),
        Acc
                end, ok, NewMap)
  end,

  spawn(fun() ->
    timer:sleep(10000),% Every Two minutes
    analyse_data(BH)
        end),
  ok.