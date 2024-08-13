%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Jul 2024 10:38
%%%-------------------------------------------------------------------
-module(contracting_master_link_ap).
-author("LENOVO").
-behaviour(base_task_ap).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, analysis/1]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

analysis(BH) ->

  Schedule = base_schedule:get_all_tasks(BH),
  Execution = base_execution:get_all_tasks(BH),

  try
    fun() ->
      io:format("Analysis starting for ~p~n", [myFuncs:myName(BH)]),

      AllTasks = base_biography:get_all_tasks(BH),
      [FirstTask|_] = maps:keys(AllTasks),

      {StartTime, EndTime} = lists:foldl(fun(Elem, {EarliestStart, LatestEnd}) ->
        ElemStart = Elem#task_shell.tstart,
        ElemEnd = Elem#task_shell.tend,

        % Find the earliest start
        NewEarliestStart = case ElemStart < EarliestStart of
                             true -> ElemStart;
                             false -> EarliestStart
                           end,

        % Find the latest end
        NewLatestEnd = case ElemEnd > LatestEnd of
                         true -> ElemEnd;
                         false -> LatestEnd
                       end,

        {NewEarliestStart, NewLatestEnd}
                                         end, {FirstTask#task_shell.tstart, FirstTask#task_shell.tend}, maps:keys(AllTasks)),
      Duration = EndTime - StartTime,

      ParentID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
      [ParentBC] = bhive:discover_bases(#base_discover_query{id = ParentID}, BH),
      ParentName = base_business_card:get_name(ParentBC),

      Type = base_attributes:read(<<"meta">>,<<"processType">>,BH),

      ChildrenNamesBIN = myFuncs:extract_partner_names(AllTasks, servant),
      ChildrenNames = lists:delete(myFuncs:myName(BH), ChildrenNamesBIN),

      TRUs = base_variables:read(<<"TRU">>, <<"List">>, BH),
      if
        map_size(TRUs) > 0 ->
          TRUBC = bhive:discover_bases(#base_discover_query{name = <<"TRU_Representative">>}, BH),
          base_signal:emit_signal(TRUBC, <<"CompletedTask">>, {myFuncs:myName(BH), TRUs}, BH);
        true ->
          ok % or any other action when map_size(TRUs) is 0
      end,

      % Send data to Type
      MyBC = base:get_my_bc(BH),
      MyID = MyBC#business_card.identity,
      Tax = MyID#identity.taxonomy,
      TypeType = Tax#base_taxonomy.base_type_code,
      TaskHolons = bhive:discover_bases(#base_discover_query{name = TypeType}, BH),


      StoreData = case TypeType of
                    <<"PROCESS_STEP_TYPE">> ->
                      Action = base_attributes:read(<<"meta">>, <<"truAction">>, BH),
                      #{
                        <<"name">> => myFuncs:myName(BH),
                        <<"type">> => Type,
                        <<"parent">> => ParentName,
                        <<"startunix">> => integer_to_binary(StartTime),
                        <<"endunix">> => integer_to_binary(EndTime),
                        <<"duration">> => float_to_binary(Duration / 1000, [{decimals, 2}]),
                        <<"resource">> => jsx:encode(ChildrenNames),
                        <<"action">> => Action,
                        <<"trus">> => jsx:encode(TRUs)
                      };
                    <<"PROCESS_TASK_TYPE">> ->
                      #{
                        <<"name">> => myFuncs:myName(BH),
                        <<"type">> => Type,
                        <<"parent">> => ParentName,
                        <<"startunix">> => integer_to_binary(StartTime),
                        <<"endunix">> => integer_to_binary(EndTime),
                        <<"duration">> => float_to_binary(Duration / 1000, [{decimals, 2}]),
                        <<"resource">> => jsx:encode(ChildrenNames),
                        <<"trus">> => jsx:encode(TRUs)
                      }
                  end,

%%      io:format("StoreData for ~p: ~p~n",[myFuncs:myName(BH), StoreData]),
      base_signal:emit_signal(TaskHolons, <<"STORE_DATA">>, StoreData, BH),
      ok
    end()
  catch
    _:Error ->
      io:format("~p: Error in Master AP~n",[myFuncs:myName(BH)])
  end,

  ok.