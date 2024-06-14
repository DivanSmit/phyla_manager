%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Nov 2023 09:08
%%%-------------------------------------------------------------------
-module(proTask_FSM_sched).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, scheduling_tasks/3, tasks_scheduled/3, task_not_possible/3, task_in_execution/3, finish/3]).


init(Pars) ->
  io:format("~n *[EXE PRO S STATE]*: FSM installed ~n"),

  {ok, scheduling_tasks, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

scheduling_tasks(enter, OldState, State)->
  io:format("~n *[EXE PRO S STATE]*: Scheduling tasks ~n"),

  BH = maps:get(<<"BH">>,State),

  Tsched = base:get_origo(),
  Type = <<"spawn_process_steps">>,
  ID = make_ref(),
  Data1 =#{},
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),
  {keep_state, State};

scheduling_tasks(cast, task_scheduled, State)->
  io:format("~n *[EXE PRO S STATE]*: All Task scheduled ~n"),

  {next_state, tasks_scheduled ,State};

scheduling_tasks(cast, not_possible, State)->
  io:format("~n *[EXE PRO S STATE]*: Error while scheduling tasks ~n"),

  {next_state, task_not_possible ,State};


scheduling_tasks(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

tasks_scheduled(enter, OldState, State)->
  io:format("~n *[EXE PRO S STATE]*: All tasks scheduled ~n"),

  BH = maps:get(<<"BH">>,State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),

  TreatmentID = base_attributes:read(<<"meta">>,<<"treatmentID">>,BH),
  Data_map = #{
      <<"processName">>=>MyName
  },
  TaskHolons = bhive:discover_bases(#base_discover_query{id = TreatmentID}, BH),
  base_signal:emit_signal(TaskHolons, <<"processScheduled">>, Data_map, BH),

  {keep_state, State};

tasks_scheduled(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_in_execution(enter, OldState, State)->
  io:format("~n *[EXE PRO S STATE]*: Tasks scheduled ~n"),

  {keep_state, State};

task_in_execution(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[EXE PRO S STATE]*: Task is not possible ~n"),

  {keep_state, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[EXE PRO S STATE]*: Task is not possible ~n"),

  {keep_state, State};

finish(cast, _, State)->
  {keep_state, State}.

