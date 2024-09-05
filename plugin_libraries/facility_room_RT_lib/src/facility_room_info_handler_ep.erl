%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jan 2024 13:48
%%%-------------------------------------------------------------------
-module(facility_room_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  base_variables:write(<<"current_Capacity">>,<<"value">>,0, BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

handle_signal(<<"REMOVE_TASK">>, Data, BH) ->
  Values = base_schedule:get_all_tasks(BH),
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
  Tasks = base_execution:get_all_tasks(BH),
%%  io:format("Tasks for ~p : ~p~n",[myFuncs:myName(BH), Tasks]),
  case Tasks of
    #{} ->
      {reply, ready};
    _ ->
      {reply, not_ready}
  end.