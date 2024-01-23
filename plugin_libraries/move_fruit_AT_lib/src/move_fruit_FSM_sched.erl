%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Dec 2023 17:21
%%%-------------------------------------------------------------------
-module(move_fruit_FSM_sched).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_storage/3,
  task_in_execution/3, task_scheduled/3, task_not_possible/3]).


init(Pars) ->
  io:format("~n *[MF STATE]*: FSM installed ~n"),
  {ok, searching_for_storage, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_storage(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Searching for an available storage ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"MF_FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    % Change link tag
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"mfFindStorage">>,BH)
        end),
  {keep_state, State};

searching_for_storage(cast, found_storage, State)->
  io:format("~n *[MF STATE]*: Found available storage ~n"),

  {next_state, searching_for_operator, State};

searching_for_storage(cast, no_storage, State)->
  io:format("~n *[MF STATE]*: No storage available ~n"),

%%  TODO add functionality for no storage found

  {next_state, task_not_possible, State};

searching_for_storage(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_operator(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Searching for an operator ~n"),

  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"MF_FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    % Change the link tag
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"mf_operator">>,BH)
        end),
  {keep_state, State};

searching_for_operator(cast, found_operator, State)->
  io:format("~n *[MF STATE]*: Found an operator ~n"),

  {next_state, searching_for_fta_machine, State};

searching_for_operator(cast, no_operator_available, State)->
  io:format("~n *[MF STATE]*: Did not find an available operator ~n"),
%% TODO add functionality for no operator
  {next_state, task_not_possible, State};

searching_for_operator(cast, no_operator, State)->
  io:format("~n *[MF STATE]*: Did not find an operator ~n"),

  {next_state, task_not_possible, State};

searching_for_operator(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_scheduled(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task scheduled ~n"),

  {keep_state, State};

task_scheduled(cast, task_started, State)->
  io:format("~n *[MF STATE]*: The task started ~n"),

  {next_state, task_in_execution, State};

task_scheduled(cast, timeout_reached, State)->
  io:format("~n *[MF STATE]*: The task timed-out ~n"),
%% TODO add time out functionality
  {next_state, searching_for_operator, State};

task_scheduled(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task not possible ~n"),
%% TODO add functionality
  {keep_state, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_in_execution(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task in execution ~n"),

  BH = maps:get(<<"BH">>,State),
  Tsched = base:get_origo(),
  Type = <<"fse_FSM">>,
  ID = make_ref(),
  Data1 =State,
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),

  {keep_state, State};

task_in_execution(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

