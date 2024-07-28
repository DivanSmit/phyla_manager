%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 16. Nov 2023 09:08
%%%-------------------------------------------------------------------
-module(ps_sched_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_fta_machine/3,
  task_scheduled/3, task_not_possible/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[PS STATE]*: FSM installed ~n"),
  {ok, searching_for_operator, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_operator(enter, OldState, State)->
  io:format("~n *[PS STATE]*: Searching for an operator ~n"),
  BH = maps:get(<<"BH">>,State),

  Base_Link = base_attributes:read(<<"meta">>,<<"childContract">>,BH),

  StartTime = base_attributes:read(<<"meta">>,<<"startTime">>,BH),
%%  spawn(fun()->
%%    base_link_master_sp:start_link_negotiation(#{
%%      <<"AVAILABILITY">>=>StartTime,
%%      <<"type">>=>resource,
%%      <<"capabilities">>=><<"TAKE_MEASUREMENT">>
%%    },Base_Link,BH)
%%      end),

%%  MetaData = base_attributes:read(<<"meta">>, <<"resources">>,BH),




  Change = 10,

  Requirements =#{
    <<"AVAILABILITY">>=>StartTime,
    <<"action">>=>Change,
    <<"type">>=>resource,
    <<"capabilities">>=><<"OPERATOR_INSTANCE_INFO">>,
    <<"processType">>=> base_attributes:read(<<"meta">>, <<"processType">>,BH),
    <<"description">>=> base_attributes:read(<<"meta">>, <<"description">>,BH),
    <<"duration">>=> base_attributes:read(<<"meta">>, <<"duration">>,BH),
    <<"truAction">> => base_attributes:read(<<"meta">>, <<"truAction">>, BH)
  } ,

%% TODO Implement the correct requirements in a robust manner
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(Requirements,Base_Link,BH)
        end),
  {keep_state, State};

searching_for_operator(cast, contracted, State)->
  io:format("~n *[PS STATE]*: Found an operator ~n"),

%%  Child = maps:get(<<"children">>,State),
%%  Machine = maps:get(<<"machine">>,Child),
%%
%%  case map_size(Machine) of
%%    0 ->
%%      io:format("Operator only task~n"),
%%
%%    _ ->
%%      {next_state, searching_for_fta_machine, State}
%%  end;
  {next_state, task_scheduled, State};

searching_for_operator(cast, no_operator, State)->
  io:format("~n *[PS STATE]*: Did not find an operator ~n"),

  {next_state, task_not_possible, State};

searching_for_operator(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_fta_machine(enter, OldState, State)->
  io:format("~n *[PS STATE]*: Searching for an fta machine ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  spawn(fun()->
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>StartTime},<<"ps_fta">>,BH)
        end),
  {keep_state, State};

searching_for_fta_machine(cast, found_fta_machine, State)->
  io:format("~n *[PS STATE]*: Found an fta machine ~n"),

  {next_state, task_scheduled, State};

searching_for_fta_machine(cast, no_fta_available, State)->
  io:format("~n *[PS STATE]*: Found an fta machine ~n"),

  {next_state, searching_for_operator, State};

searching_for_fta_machine(cast, no_fta_machine, State)->
  io:format("~n *[PS STATE]*: Did not find an fta machine ~n"),

  {next_state, task_not_possible, State};

searching_for_fta_machine(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_scheduled(enter, OldState, State)->
  io:format("~n *[PS STATE]*: Task scheduled ~n"),
  BH = maps:get(<<"BH">>,State),

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  EndTime = base_variables:read(<<"FSM_INFO">>,<<"endTime">>,BH),


  ProID = base_attributes:read(<<"meta">>,<<"parentID">>,BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  base_signal:emit_signal(TaskHolons, <<"taskScheduled">>,
    {MyName,StartTime,EndTime}
    , BH),

  {stop, normal, State};

task_scheduled(cast, timeout_reached, State)->
  io:format("~n *[PS STATE]*: The task timed-out ~n"),
%% TODO add time out functionality
  {next_state, searching_for_operator, State};

task_scheduled(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[PS STATE]*: Task not possible ~n"),
%% TODO add functionality
  {keep_state, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->


  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(_Reason, _StateName, State) ->
  io:format("~n *[PS STATE]*: All children contracted ~n"),
  BH = maps:get(<<"BH">>,State),

  % Start FSM
  PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>,BH),
  gen_statem:cast(PID, scheduled),
  ok.