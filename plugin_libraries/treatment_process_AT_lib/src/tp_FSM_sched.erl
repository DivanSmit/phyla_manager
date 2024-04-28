%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 26. Apr 2024 16:44
%%%-------------------------------------------------------------------
-module(tp_FSM_sched).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, scheduling_tasks/3, task_not_possible/3, finish/3]).


init(Pars) ->
  io:format("~n *[EXE PRO S STATE]*: FSM installed ~n"),
  {ok, scheduling_tasks, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

get_planned_dat(enter, OldState, State)->
  io:format("~n *[TREATMENT STATE]*: Scheduling tasks ~n"),

  BH = maps:get(<<"BH">>,State),

  Tsched = base:get_origo(),
  Type = <<"spawn_process_tasks">>,
  ID = make_ref(),
  Data1 =#{},
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),
  {keep_state, State};

scheduling_tasks(cast, task_scheduled, State)->
  io:format("~n *[TREATMENT STATE]*: All Task scheduled ~n"),

  {next_state, tasks_scheduled ,State};

scheduling_tasks(cast, not_possible, State)->
  io:format("~n *[TREATMENT STATE]*: Error while scheduling tasks ~n"),

  {next_state, task_not_possible ,State};


scheduling_tasks(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[TREATMENT STATE]*: Task is not possible ~n"),

  {keep_state, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[TREATMENT STATE]*: Task is not possible ~n"),

  {keep_state, State};

finish(cast, _, State)->
  {keep_state, State}.