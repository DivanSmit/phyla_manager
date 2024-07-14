%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 02. Jul 2024 14:46
%%%-------------------------------------------------------------------
-module(process_step_sched_FSM).
-author("LENOVO").
-behaviour(gen_statem).
%% API
-export([init/1, callback_mode/0, negotiate_with_resource/3]).


init(Pars) ->
  io:format("~n *[PS STATE]*: FSM installed ~n"),
  {ok, searching_for_operator, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
negotiate_with_resource(enter, OldState, State)->
  io:format("~n *[PS STATE]*: Resource found ~n"),

%% TODO check that the negotiating has all the correct requirements, including the PS type
  {keep_state, State};

negotiate_with_resource(cast, no_operator, State)->
  io:format("~n *[PS STATE]*: Resource found ~n"),

  {next_state, task_not_possible, State};

negotiate_with_resource(cast, _, State)->
  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
