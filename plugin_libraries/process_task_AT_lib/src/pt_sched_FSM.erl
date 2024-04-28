%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Nov 2023 09:08
%%%-------------------------------------------------------------------
-module(pt_sched_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_fta_machine/3,
        task_in_execution/3, task_scheduled/3, task_not_possible/3]).


init(Pars) ->
  io:format("~n *[PT STATE]*: FSM installed ~n"),
  {ok, searching_for_operator, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_operator(enter, OldState, State)->
  io:format("~n *[PT STATE]*: Searching for an operator ~n"),
  BH = maps:get(<<"BH">>,State),

  StartTime = base_attributes:read(<<"meta">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"pt_operator">>,BH)
      end),
  {keep_state, State};

searching_for_operator(cast, found_operator, State)->
  io:format("~n *[PT STATE]*: Found an operator ~n"),

  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  NewState = maps:merge(State,#{<<"startTime">>=>StartTime}),

  Machine = base_attributes:read(<<"meta">>,<<"machine">>,BH),

  case map_size(Machine) of
    0 ->
      io:format("Operator only task~n"),
      {next_state, task_scheduled, NewState};
    _ ->
      {next_state, searching_for_fta_machine, NewState}
  end;

searching_for_operator(cast, no_operator, State)->
  io:format("~n *[PT STATE]*: Did not find an operator ~n"),

  {next_state, task_not_possible, State};

searching_for_operator(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_fta_machine(enter, OldState, State)->
  io:format("~n *[PT STATE]*: Searching for an fta machine ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"pt_fta">>,BH)
        end),
  {keep_state, State};

searching_for_fta_machine(cast, found_fta_machine, State)->
  io:format("~n *[PT STATE]*: Found an fta machine ~n"),

  {next_state, task_scheduled, State};

searching_for_fta_machine(cast, no_fta_available, State)->
  io:format("~n *[PT STATE]*: Found an fta machine ~n"),

%%  TODO add functionality for no fta machine found

  {next_state, searching_for_operator, State};

searching_for_fta_machine(cast, no_fta_machine, State)->
  io:format("~n *[PT STATE]*: Did not find an fta machine ~n"),

  {next_state, task_not_possible, State};

searching_for_fta_machine(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_scheduled(enter, OldState, State)->
  io:format("~n *[PT STATE]*: Task scheduled ~n"),

  BH = maps:get(<<"BH">>,State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  StartTime = maps:get(<<"startTime">>,State),
  EndTime = base_variables:read(<<"FSM_INFO">>,<<"endTime">>,BH),

  ProID = base_attributes:read(<<"meta">>,<<"executeID">>,BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  base_signal:emit_signal(TaskHolons, <<"taskScheduled">>, #{
    <<"endTime">>=>EndTime,
    <<"startTime">>=>StartTime,
    <<"taskName">>=>MyName
  }, BH),

  {keep_state, State};

task_scheduled(cast, task_started, State)->
  io:format("~n *[PT STATE]*: The task started ~n"),

  {next_state, task_in_execution, State};

task_scheduled(cast, timeout_reached, State)->
  io:format("~n *[PT STATE]*: The task timed-out ~n"),
%% TODO add time out functionality
  {next_state, searching_for_operator, State};

task_scheduled(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[PT STATE]*: Task not possible ~n"),
%% TODO add functionality
  {keep_state, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_in_execution(enter, OldState, State)->
  io:format("~n *[PT STATE]*: Task in execution ~n"),

  BH = maps:get(<<"BH">>,State),
  Tsched = base:get_origo(),
  Type = <<"pt_FSM">>,
  ID = make_ref(),
  Data1 =State,
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),

  {keep_state, State};

task_in_execution(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
