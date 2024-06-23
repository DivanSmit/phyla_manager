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
-export([init/1, callback_mode/0, check_with_contracted_child/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[STATE]*: FSM installed ~n"),
  {ok, check_with_contracted_child, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_contracted_child(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Checking with Contracted Child ~n"),
  {keep_state, State};

check_with_contracted_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: All children contracted ~n"),

  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.