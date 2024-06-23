%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 14:48
%%%-------------------------------------------------------------------
-module(contracting_exe_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, check_with_contracted_child/3, check_with_parent/3, parent_not_yet_ready/3,
  wait_for_operator_start/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[CONTRACT E STATE]*: FSM installed ~n"),

  {ok, check_with_contracted_child, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_contracted_child(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Checking with Contracted Child ~n"),

  {keep_state, State};

check_with_contracted_child(cast, ready, State)->
  io:format("~n *[CONTRACT E STATE]*: Child ready ~n"),

  BH = maps:get(<<"BH">>,State),
  Numchild = base_variables:read(<<"FSM_INFO">>,<<"FSM_Count">>,BH),
  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Ready">>,BH),
%%  io:format("Count: ~p Child: ~p~n",[Count,Numchild]),
  if
    Numchild == Count ->
      io:format("~n *[CONTRACT E STATE]*: All children ready, checking with parent ~n"),
      {next_state, check_with_parent, State};
    true ->
      {keep_state, State}

  end;

check_with_contracted_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_parent(enter, _OldState, State) ->

  %% Send an internal cast to trigger the state check
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_parent(cast, internal_check, State) ->
  io:format("~n *[CONTRACT E STATE]*: Checking with parent ~n"),
  BH = maps:get(<<"BH">>, State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),

  %% Sending a request, because an answer is required if can continue or not
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, MyName, BH),
  io:format("Reply from parent: ~p~n", [Reply]),
  case Reply of
    ready ->
      {next_state, wait_for_operator_start, State};
    not_ready ->
      {next_state, parent_not_yet_ready, State}
  end;

check_with_parent(cast, _, State) ->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parent_not_yet_ready(enter, _OldState, State) ->
  BH = maps:get(<<"BH">>,State),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  io:format("~n *[CONTRACT E STATE]*: Parent not yet ready, going to wait for ~ps ~n",[Delay/1000]),

  {keep_state, State, Delay};

parent_not_yet_ready(timeout, _EventContent, State) ->
  io:format("~n *[CONTRACT E STATE]*: Timer expired, checking with parent again~n"),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, _, State) ->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),
  {keep_state, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_operator_start(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Waiting for operator ~n"),
  {keep_state, State};

wait_for_operator_start(cast, start, State)->
  io:format("~n *[CONTRACT E STATE]*: Operator wants to start ~n"),
  BH = maps:get(<<"BH">>,State),
  Handels = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:start_link(Elem)
  end, [], Handels),
  %Start timer task
  {keep_state, State};

wait_for_operator_start(cast, _, State)->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),

  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


finish(enter, OldState, State)->

  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.