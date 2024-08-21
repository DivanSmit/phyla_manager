%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:52
%%%-------------------------------------------------------------------
-module(fta_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"REMOVE_TASK">>, Data, BH) ->
  Values = base_schedule:get_all_tasks(BH),io:format("~p removing task: ~p~n",[myFuncs:myName(BH), Data]),
  lists:foreach(fun(X) ->
    Task = maps:get(X, Values),
    Meta = Task#base_task.meta,
    BC = Meta#base_contract.master_bc,
    Name = base_business_card:get_name(BC),
    if
      Name == Data -> base_schedule:take_task(X, BH);
      true -> ok
    end
                end, maps:keys(Values)),
  ok.

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};

handle_request(<<"CheckIn">>, From, _, BH) ->
  case base_execution:get_all_tasks(BH) of
    #{} ->
      Tasks = base_schedule:get_all_tasks(BH),
      Masters = myFuncs:extract_partner_names(Tasks, master),
      case lists:nth(1, Masters) of % If there is nothing on the execution and the next task on sched is with parent
        From ->
          {reply, ready};
        _ ->
          {reply, not_ready}
      end;
    _ ->
      {reply, not_ready}
  end.