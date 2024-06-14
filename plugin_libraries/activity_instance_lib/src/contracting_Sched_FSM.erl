%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 14:48
%%%-------------------------------------------------------------------
-module(contracting_Sched_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, spawn_and_wait_for_child/3, contract_child/3, rescheduling/3, finish/3]).


init(Pars) ->
  io:format("~n *[CONTRACT S STATE]*: FSM installed ~n"),

  {ok, spawn_and_wait_for_child, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spawn_and_wait_for_child(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: Spawning and waiting for child ~n"),

  BH = maps:get(<<"BH">>,State),
  [Current|_] = maps:get(<<"children">>,State),

  case map_size(Current) of
    0 -> {next_state, task_not_possible, State};
    _ ->
      Spawn_Tag = maps:get(<<"type">>,Current),
      MyBC = base:get_my_bc(BH),
      MyID = base_business_card:get_id(MyBC),
      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
      [ChildName] = base_signal:emit_request(TaskHolons, Spawn_Tag, maps:merge(Current,#{<<"parentID">>=>MyID}), BH),
      {keep_state, maps:merge(State,#{<<"child">>=>ChildName})}
  end;


spawn_and_wait_for_child(cast, task_scheduled, State)->
  io:format("~n *[CONTRACT S STATE]*: Child spawned and scheduled ~n"),
  Child = maps:get(<<"child">>,State),
  BH = maps:get(<<"BH">>,State),
  Base_Link = base_attributes:read(<<"meta">>,<<"childContract">>,BH),

  base_link_master_sp:start_link_negotiation(#{<<"name">>=>Child,<<"type">>=>activity},Base_Link,BH),
  {next_state, contract_child ,State};

spawn_and_wait_for_child(cast, not_possible, State)->
  io:format("~n *[CONTRACT S STATE]*: Error while scheduling the child ~n"),

  {next_state, rescheduling ,State};


spawn_and_wait_for_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

contract_child(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: Negotiating Contract with child ~n"),
  BH = maps:get(<<"BH">>,State),
  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),
  {keep_state, State};

contract_child(cast, contracted, State)->
  io:format("~n *[CONTRACT S STATE]*: Contract Made with child ~n"),
  [Child|Rest] = maps:get(<<"children">>,State),
  BH = maps:get(<<"BH">>,State),
  case Rest of
     [] ->
       {next_state, finish ,State};
    _->
      {next_state, spawn_and_wait_for_child ,#{<<"BH">>=>BH,<<"children">>=>Rest}}

end;

contract_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rescheduling(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: Contract needs rescheduling ~n"),

  {keep_state, State};

rescheduling(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: All children contracted ~n"),

  {keep_state, State};

finish(cast, _, State)->
  {keep_state, State}.


