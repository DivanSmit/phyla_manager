%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Nov 2023 09:08
%%%-------------------------------------------------------------------
-module(ps_exe_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, finish_state/3,
  waiting_for_operator_to_end_task/3]).


init(Pars) ->
  io:format("~n *[STATE]*: FSM installed ~n"),
  {ok, waiting_for_operator_to_end_task, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% TODO add a timeout function eg 10 min of no response then research for operator
waiting_for_operator_to_end_task(enter, OldState, State)->
  io:format("~n *[STATE]*: Waiting for task to end ~n"),
  BH = maps:get(<<"BH">>,State),
  FTA_link_ExH = base_variables:read(<<"INFO">>,<<"FTA_LINK">>,BH),
  OP_link_ExH = base_variables:read(<<"INFO">>,<<"OPERATOR_LINK">>,BH),
  base_link_ep:start_link(FTA_link_ExH),
  base_link_ep:start_link(OP_link_ExH),

  {keep_state, State};

waiting_for_operator_to_end_task(cast, task_finished, State)->
  io:format("~n *[STATE]*: The task has finished ~n"),

  {next_state, finish_state, State};

waiting_for_operator_to_end_task(cast, _, State)->
  {keep_state, State}.


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

  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"END_PS_INSTANCE">>}, BH),
  base_signal:emit_signal(TaskHolons, <<"END">>, MyID, BH),

  {stop, normal, State};

finish_state(cast, _, State)->
  {keep_state, State}.