%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Dec 2023 17:21
%%%-------------------------------------------------------------------
-module(move_FSM_sched).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, searching_for_operator/3, searching_for_target_storage/3, current_storage_confirmation/3,
          waiting_for_execution/3, task_not_possible/3, task_cancelled/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[MF STATE]*: FSM installed ~n"),
  {ok, searching_for_operator, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_target_storage(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Searching for an available storage ~n"),
  BH = maps:get(<<"BH">>,State),

  Target = base_attributes:read(<<"meta">>,<<"target">>,BH),
  Quantity = base_attributes:read(<<"meta">>,<<"quantity">>,BH),
  StartTime = base_attributes:read(<<"meta">>,<<"startTime">>,BH),
  spawn(fun()->
    % Change link tag
    base_link_master_sp:start_link_negotiation(#{

      <<"AVAILABILITY">>=>StartTime,
      <<"room">>=>Target,
      <<"function">>=>add,
      <<"quantity">>=>Quantity

    },<<"mfFindStorage">>,BH)
        end),
  {keep_state, State};

searching_for_target_storage(cast, storage_available, State)->
  io:format("~n *[MF STATE]*: Found available storage ~n"),
  BH = maps:get(<<"BH">>,State),
  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  {next_state, searching_for_operator, maps:merge(State,#{<<"startTime">>=>StartTime})};

searching_for_target_storage(cast, store_not_possible, State)->
  io:format("~n *[MF STATE]*: No storage available ~n"),

%%  TODO add functionality for no storage found

  {next_state, task_not_possible, State};

searching_for_target_storage(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

searching_for_operator(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Searching for an operator ~n"),

  BH = maps:get(<<"BH">>,State),
  Child = maps:get(<<"children">>,State),
  StartTime = maps:get(<<"startTime">>,Child),
  spawn(fun()->
    % Change the link tag
    base_link_master_sp:start_link_negotiation(#{<<"AVAILABILITY">>=>any,<<"type">>=>resource},<<"contractingOp">>,BH)
        end),
  {keep_state, State};

searching_for_operator(cast, contracted, State)->
  io:format("~n *[MF STATE]*: Found an operator ~n"),
  BH = maps:get(<<"BH">>,State),

  StartTime = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  NewState = maps:merge(State,#{<<"startTime">>=>StartTime}),

  {next_state, waiting_for_execution, NewState};

searching_for_operator(cast, no_operator_available, State)->
  io:format("~n *[MF STATE]*: Did not find an available operator ~n"),
%% TODO add functionality for no operator
  {next_state, searching_for_target_storage, State};

searching_for_operator(cast, no_operator, State)->
  io:format("~n *[MF STATE]*: Did not find an operator ~n"),

  {next_state, task_not_possible, State};

searching_for_operator(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

current_storage_confirmation(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Checking with current storage ~n"),

  BH = maps:get(<<"BH">>,State),

  Target = base_attributes:read(<<"meta">>,<<"from">>,BH),
  Quantity = base_attributes:read(<<"meta">>,<<"quantity">>,BH),
  StartTime = maps:get(<<"startTime">>,State),

  spawn(fun()->
    % Change link tag
    base_link_master_sp:start_link_negotiation(#{

      <<"AVAILABILITY">>=>StartTime,
      <<"room">>=>Target,
      <<"function">>=>remove,
      <<"quantity">>=>Quantity

    },<<"mfFindStorage">>,BH)
        end),

  {keep_state, State};

current_storage_confirmation(cast, storage_available, State)->
  io:format("~n *[MF STATE]*: Current storage confirmaed ~n"),

  {next_state, waiting_for_execution, State};

current_storage_confirmation(cast, alternative_time, State)->
  io:format("~n *[MF STATE]*: Current storage not available, looking for alternative time ~n"),
  %% TODO add functionality
  {next_state, searching_for_target_storage, State};

current_storage_confirmation(cast, error, State)->
  io:format("~n *[MF STATE]*: Current storage has problem ~n"),

%%  TODO add functionality for no storage found

  {next_state, task_not_possible, State};

current_storage_confirmation(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

waiting_for_execution(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task scheduled ~n"),

  BH = maps:get(<<"BH">>,State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  StartTime = maps:get(<<"startTime">>,State),
  EndTime = base_variables:read(<<"FSM_INFO">>,<<"endTime">>,BH),

  ProID = base_attributes:read(<<"meta">>,<<"parentID">>,BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  base_signal:emit_signal(TaskHolons, <<"taskScheduled">>, #{
    <<"endTime">>=>EndTime,
    <<"startTime">>=>StartTime,
    <<"taskName">>=>MyName
  }, BH),

  {stop, normal, State};

waiting_for_execution(cast, task_cancelled, State)->
  io:format("~n *[MF STATE]*: The task cancelled before execution ~n"),

%% TODO add cancellation functionality

  {next_state, task_cancelled, State};

waiting_for_execution(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_not_possible(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task not possible ~n"),

  %% Informing Execute Process that task is not possible
  BH = maps:get(<<"BH">>,State),
  ProID = base_attributes:read(<<"meta">>,<<"parentID">>,BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  base_signal:emit_signal(TaskHolons, <<"StateCast">>, not_possible, BH),

%% TODO add functionality
  {next_state, finish, State};

task_not_possible(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

task_cancelled(enter, OldState, State)->
  io:format("~n *[MF STATE]*: Task cancelled ~n"),

  %% Informing Execute Process that task is not possible
  BH = maps:get(<<"BH">>,State),
  ProID = base_attributes:read(<<"meta">>,<<"parentID">>,BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  base_signal:emit_signal(TaskHolons, <<"StateCast">>, task_cancelled, BH),

%% TODO add functionality
  {next_state, finish, State};

task_cancelled(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[PS STATE]*: All children contracted ~n"),

  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(_Reason, _StateName, _State) ->
  ok.