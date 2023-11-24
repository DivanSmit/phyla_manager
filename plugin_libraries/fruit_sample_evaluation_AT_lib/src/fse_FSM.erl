%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Nov 2023 09:08
%%%-------------------------------------------------------------------
-module(fse_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_fta_machine/3, finish_state/3,
        waiting_for_task_start/3, task_in_execution/3, research_for_operator/3]).


init(Pars) ->
  io:format("~n *[STATE]*: FSM installed ~n"),
  {ok, searching_for_operator, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_operator(enter, OldState, State)->
  io:format("~n *[STATE]*: Searching for an operator ~n"),

  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSE_FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"fse_operator">>,BH)
      end),
  {keep_state, State};

searching_for_operator(cast, found_operator, State)->
  io:format("~n *[STATE]*: Found an operator ~n"),

  {next_state, searching_for_fta_machine, State};

searching_for_operator(cast, no_operator, State)->
  io:format("~n *[STATE]*: Did not find an operator ~n"),

  {next_state, finish_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_fta_machine(enter, OldState, State)->
  io:format("~n *[STATE]*: Searching for an fta machine ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSE_FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"fse_fta">>,BH)
        end),
  {keep_state, State};

searching_for_fta_machine(cast, found_fta_machine, State)->
  io:format("~n *[STATE]*: Found an fta machine ~n"),

  {next_state, waiting_for_task_start, State};

searching_for_fta_machine(cast, no_fta_available, State)->
  io:format("~n *[STATE]*: Found an fta machine ~n"),

  {next_state, research_for_operator, State};

searching_for_fta_machine(cast, no_fta, State)->
  io:format("~n *[STATE]*: Found an fta machine ~n"),

  {next_state, finish_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% TODO add a timeout function eg 10 min of no response then research for operator
waiting_for_task_start(enter, OldState, State)->
  io:format("~n *[STATE]*: Waiting for task to start ~n"),
  BH = maps:get(<<"BH">>,State),

  {keep_state, State};

waiting_for_task_start(cast, task_started, State)->
  io:format("~n *[STATE]*: The task has started ~n"),

  {next_state, task_in_execution, State};

waiting_for_task_start(cast, deadline_reached, State)->
  io:format("~n *[STATE]*: The task has started ~n"),

  {next_state, research_for_operator, State};

waiting_for_task_start(cast, task_finished, State)->
  io:format("~n *[STATE]*: The task has started ~n"),

  {next_state, finish_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_in_execution(enter, OldState, State)->
  io:format("~n *[STATE]*: Task is in execution ~n"),
  BH = maps:get(<<"BH">>,State),
  FTA_link_ExH = base_variables:read(<<"INFO">>,<<"FTA_LINK">>,BH),
  base_link_ep:start_link(FTA_link_ExH),
  {keep_state, State};

task_in_execution(cast, task_finished, State)->
  io:format("~n *[STATE]*: The task has finished ~n"),

  {next_state, finish_state, State};

task_in_execution(cast, task_canceled, State)->
  io:format("~n *[STATE]*: The task has finished ~n"),

  {next_state, finish_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

research_for_operator(enter, OldState, State)->
  io:format("~n *[STATE]*: Task is in execution ~n"),
  BH = maps:get(<<"BH">>,State),

  FTA_link_ExH = base_variables:read(<<"INFO">>,<<"FTA_LINK">>,BH),
  OP_link_ExH = base_variables:read(<<"INFO">>,<<"OPERATOR_LINK">>,BH),
  base_link_ep:end_link(FTA_link_ExH,done),
  base_link_ep:end_link(OP_link_ExH,done),

  StartTime = base_variables:read(<<"FSE_FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"fse_operator">>,BH)
        end),

  {keep_state, State};

research_for_operator(cast, found_operator, State)->
  io:format("~n *[STATE]*: The task has finished ~n"),

  {next_state, searching_for_fta_machine, State};

research_for_operator(cast, no_operator, State)->
  io:format("~n *[STATE]*: The task has finished ~n"),

  {next_state, finish_state, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish_state(enter, OldState, State)->
  io:format("~n *[STATE]*: Finished state ~n"),
  BH = maps:get(<<"BH">>,State),
  FTA_link_ExH = base_variables:read(<<"INFO">>,<<"FTA_LINK">>,BH),
  OP_link_ExH = base_variables:read(<<"INFO">>,<<"OPERATOR_LINK">>,BH),
  base_link_ep:end_link(FTA_link_ExH,done),
  base_link_ep:end_link(OP_link_ExH,done),

%% TODO end instance
  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),
  GH = base_guardian_ep:get_guardian_of_id(MyID,BH),
%%  io:format("BH: ~p~nID: ~p~nBC: ~p~n",[BH, MyID, MyBC]),
%%  base_guardian_ep:end_instance(GH,BH),

  {keep_state, State}.