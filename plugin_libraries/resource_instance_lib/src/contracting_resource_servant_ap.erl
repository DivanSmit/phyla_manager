%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jul 2024 17:54
%%%-------------------------------------------------------------------
-module(contracting_resource_servant_ap).
-author("LENOVO").
-behaviour(base_task_ap).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1]).


init(Pars, BH) ->
  timer:sleep(3000),
%%  analysis(BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

analysis(BH)->

  Frequency = 120000,
  StartOfWork = base:get_origo()-Frequency,
  EndOfWork = base:get_origo(),

  SQ = #task_shell_query{field = tend, range = {StartOfWork,EndOfWork}},
  {ok, Shells} = base_biography:query_task_shells(SQ,BH),
  io:format("Shells: ~p~n",[Shells]),

  TotalTime = lists:foldl(fun(Elem, Acc)->
    Task = base_biography:get_task(Elem, BH),
    Data = Task#base_task.data3,
    Duration = maps:get(<<"duration">>, Data, 0),
    Acc+Duration

  end, 0, Shells),

%%  TotalTime = rand:uniform()*Frequency,

  %% TODO this needs to be improved with tasks that take more than a day and breaks in-between
  Efficiency = TotalTime/Frequency*100,

  % Send data to parent
  MyBC = base:get_my_bc(BH),
  MyID = MyBC#business_card.identity,
  Tax = MyID#identity.taxonomy,
  ParentType = Tax#base_taxonomy.base_type_code,
  TaskHolons = bhive:discover_bases(#base_discover_query{name = ParentType}, BH),

  base_signal:emit_signal(TaskHolons, <<"RESOURCE_USAGE">>,
    #{
      <<"name">> => myFuncs:myName(BH),
      <<"time_start">>=> StartOfWork,
      <<"time_end">>=> EndOfWork,
      <<"efficiency">>=>float_to_binary(Efficiency, [{decimals, 2}]),
      <<"duration">> => float_to_binary(TotalTime/1000, [{decimals, 2}]),
      <<"date">> => base:get_origo()
    },
    BH),

  spawn(fun() ->
    timer:sleep(Frequency),% Every Two minutes
    analysis(BH)
        end),
  ok.
