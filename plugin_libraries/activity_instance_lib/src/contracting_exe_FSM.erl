%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 14:48
%%%-------------------------------------------------------------------
-module(contracting_exe_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, wait_for_schedule/3, wait_for_scheduled_time/3, check_with_contracted_child/3, check_with_parent/3, parent_not_yet_ready/3,
  wait_for_operator_start/3, wait_for_operator_end/3, rescheduling/3,finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[CONTRACT E STATE]*: FSM installed ~n"),

  {ok, wait_for_schedule, Pars}.


callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_schedule(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Waiting for schedule ~n"),

  {keep_state, State};

wait_for_schedule(cast, scheduled, State)->
  {next_state, wait_for_scheduled_time, State};


wait_for_schedule(cast, _, State)->
  {keep_state, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_scheduled_time(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

wait_for_scheduled_time(cast, internal_check, State)->
  BH = maps:get(<<"BH">>,State),
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH) - base:get_origo(),

  if
    Delay<0 -> {next_state, check_with_contracted_child, State};
    true ->
      {keep_state, {State,base:get_origo()}, Delay}

  end;

wait_for_scheduled_time(timeout, _EventContent, {State,_}) ->
  {next_state, check_with_contracted_child, State};

wait_for_scheduled_time(cast, _, {State,OldTIme}) ->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),
  BH = maps:get(<<"BH">>,State),
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH) - base:get_origo(),
  {keep_state, {State,OldTIme}, Delay}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_contracted_child(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_contracted_child(cast, internal_check, State)->
  io:format("~n *[CONTRACT E STATE]*: Checking with Contracted Child ~n"),

  BH = maps:get(<<"BH">>,State),
  ChildrenTasks = base_schedule:get_all_tasks(BH),
  Children = myFuncs:extract_partner_names(ChildrenTasks,servant),
  MyName = myFuncs:myName(BH),

  Check = lists:foldl(fun(X, Acc) ->
    if
      X == MyName -> Acc; % Some of the tasks we are the servant for our parents. SKip those tasks
      true ->
        TaskHolons = bhive:discover_bases(#base_discover_query{name = X}, BH),
        [Reply] = base_signal:emit_request(TaskHolons, <<"CheckIn">>, MyName, BH),
        io:format("Reply from child ~p for ~p is ~p~n",[X,MyName, Reply]),
        case Reply of
          ready -> Acc;
          not_ready -> false
        end
    end

                      end, true, Children),

  case Check of
    true -> {next_state, check_with_parent, State};
    false -> {next_state, rescheduling, State}
  end;

% Remember to remove the FSM count stuff

%%check_with_contracted_child(cast, ready, State)->
%%  io:format("~n *[CONTRACT E STATE]*: Child ready ~n"),
%%
%%  BH = maps:get(<<"BH">>,State),
%%  Numchild = base_variables:read(<<"FSM_INFO">>,<<"FSM_Count">>,BH),
%%  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Ready">>,BH),
%%  if
%%    Numchild == Count ->
%%      io:format("~n *[CONTRACT E STATE]*: All children ready, checking with parent ~n"),
%%      {next_state, check_with_parent, State};
%%    true ->
%%      {keep_state, State}
%%  end;

check_with_contracted_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_parent(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_parent(cast, internal_check, State) ->
  io:format("~n *[CONTRACT E STATE]*: Checking with parent ~n"),
  BH = maps:get(<<"BH">>, State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, {MyName,query}, BH),
  case Reply of
    not_ready ->
      {next_state, parent_not_yet_ready, State};
    {ready, TRU} ->
      io:format("~p received TRU list from parent: ~p~n",[myFuncs:myName(BH),TRU]),
      base_variables:write(<<"TRU">>, <<"List">>, TRU, BH),
      {next_state, wait_for_operator_start, State}
  end;

check_with_parent(cast, _, State) ->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parent_not_yet_ready(enter, _OldState, State) ->
  BH = maps:get(<<"BH">>,State),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  io:format("~n *[CONTRACT E STATE]*: Parent not yet ready, going to wait for ~ps ~n",[Delay/1000]),
  {keep_state, {State,base:get_origo()}, Delay};

parent_not_yet_ready(timeout, _EventContent, {State,_}) ->
  io:format("~n *[CONTRACT E STATE]*: Timer expired, checking with parent again~n"),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, parent_ready, {State,_}) ->
  io:format("~n *[CONTRACT E STATE]*: Parent said you can start~n"),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, _, {State,OldTIme}) ->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),
  BH = maps:get(<<"BH">>,State),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  RemainingTIme = Delay-base:get_origo()+OldTIme,
  {keep_state, {State,OldTIme}, RemainingTIme}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_operator_start(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Waiting for operator ~n"),
  {keep_state, State};

wait_for_operator_start(cast, start, State)->
  io:format("~n *[CONTRACT E STATE]*: Operator wants to start ~n"),
  BH = maps:get(<<"BH">>,State),
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:start_link(Elem)
  end, [], Handles),

  %Start link with parent
  Handle = base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>,BH),
  base_link_ep:start_link(Handle),
  %Start timer task

  {next_state, wait_for_operator_end, State};

wait_for_operator_start(cast, _, State)->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),

  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_operator_end(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: Waiting for operator to complete the task~n"),
  {keep_state, State};

wait_for_operator_end(cast, end_task, State)->
  io:format("~n *[CONTRACT E STATE]*: Operator completed the task ~n"),
  BH = maps:get(<<"BH">>,State),
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:end_link(Elem,completed)
              end, [], Handles),
  %Start timer task
  {next_state, finish, State};

wait_for_operator_end(cast, _, State)->
  io:format("~n *[CONTRACT E STATE]*: Unsupported cast ~n"),

  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rescheduling(enter, OldState, State)->
  BH = maps:get(<<"BH">>, State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  io:format("~n *[CONTRACT E STATE]*: ~p needs rescheduling ~n",[MyName]),

  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, {MyName,query}, BH),
  case Reply of
    ready ->
      io:format("~p needs serious rescheduling ~n", [MyName]),
      {keep_state, State};
    not_ready ->
      {keep_state, State, 30000}
  end;


rescheduling(timeout, _EventContent, State) ->
  {next_state, check_with_contracted_child, State};

rescheduling(cast, _, State)->

  {next_state, check_with_contracted_child, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


finish(enter, OldState, State)->
  io:format("~n *[CONTRACT E STATE]*: FSM completed ~n"),
  BH = maps:get(<<"BH">>,State),

  % Ending link with parent, if it has one
  case base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>, BH) of
    no_entry -> true;
    Handle ->
      base_link_ep:end_link(Handle,completed)
  end,

  % TODO needs to reflect on the data that it generated from TRUs and write it to a DB,
  % if it is required if. Most likely only store and measure.
  % If stored, then it needs to ask the room for information on what the values were for the period
  % All values need to got to the TYPE

  contracting_master_link_ap:analysis(BH),

  io:format("~n### ~p IS COMPLETE WITH ITS TASKS ###~n~n",[myFuncs:myName(BH)]),
  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.