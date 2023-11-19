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
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_fta_machine/3]).


init(Pars) ->
  {ok, scheduling_fruit_procurement, Pars}.

callback_mode() ->
  [state_functions, state_enter].

searching_for_operator(enter, OldState, State)->
  io:format("~n *[STATE]*: Searching for an operator ~n"),

  BH = maps:get(<<"BH">>,State),
  StartTime = maps:get(<<"startTime">>,State),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"fse_operator">>,BH)
      end),
  {keep_state, State};

searching_for_operator(cast, found_operator, State)->
  io:format("~n *[STATE]*: Found an operator ~n"),

  {next_state, searching_for_fta_machine, State}.

searching_for_fta_machine(enter, OldState, State)->
  io:format("~n *[STATE]*: Searching for an operator ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = maps:get(<<"startTime">>,State),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"fse_fta">>,BH)
        end),
  {keep_state, State};

searching_for_fta_machine(cast, found_fta_machine, State)->
  io:format("~n *[STATE]*: Found an operator ~n"),

  {next_state, informing_fruit_evaluation_lab_to_start_fruit_preparation, State}.