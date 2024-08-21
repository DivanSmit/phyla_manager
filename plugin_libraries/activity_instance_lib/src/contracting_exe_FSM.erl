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
  wait_for_operator_start/3, wait_for_operator_end/3, rescheduling/3,finish/3, terminate/3, handle_event/4]).


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
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH) - base:get_origo() +1000,
  timer:sleep(1000),
  if
    Delay<0 ->
      {next_state, check_with_parent, State};
    true ->
      {keep_state, {State,base:get_origo()}, Delay}

  end;

wait_for_scheduled_time(timeout, _EventContent, {State,_}) ->
  {next_state, check_with_parent, State};

wait_for_scheduled_time(cast, Cast, {State,OldTIme}) ->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Unsupported cast in waiting for sched ~p ~n",[myFuncs:myName(BH),Cast]),
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  RemainingTIme = Delay - base:get_origo() ,
  case RemainingTIme < 0 of
    true -> {next_state, check_with_parent, State};
    false -> {keep_state, {State, OldTIme}, RemainingTIme}
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_contracted_child(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_contracted_child(cast, internal_check, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Checking with Contracted Child ~n",[myFuncs:myName(BH)]),

  ChildrenTasks = base_schedule:get_all_tasks(BH),
  Children = myFuncs:extract_partner_names(ChildrenTasks,servant),
  MyName = myFuncs:myName(BH),

  Check = lists:foldl(fun(X, Acc) ->
    if
      X == MyName -> Acc; % Some of the tasks we are the servant for our parents. SKip those tasks
      true ->
        TaskHolons = bhive:discover_bases(#base_discover_query{name = X}, BH),
        log:message(myFuncs:myName(BH), base_business_card:get_name(hd(TaskHolons)), <<"Availability">>),
        [Reply] = base_signal:emit_request(TaskHolons, <<"CheckIn">>, MyName, BH),
        io:format("Reply from child ~p for ~p is ~p~n",[X,MyName, Reply]),
        case Reply of

          ready -> log:message(base_business_card:get_name(hd(TaskHolons)),myFuncs:myName(BH),  <<"Ready">>),Acc;

          not_ready -> log:message(myFuncs:myName(BH), base_business_card:get_name(hd(TaskHolons)), <<"Not Ready">>),false
        end
    end
                      end, true, Children),

  case Check of
    true ->
      OperatorType = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_OPERATOR_INSTANCE">>}, BH),
      [Operator_Capabilities] = base_signal:emit_request(OperatorType, <<"INFO">>, <<"InstanceCapabilities">>, BH),

      Resources = base_attributes:read(<<"meta">>, <<"resources">>, BH),
      HasOperator = lists:foldl(fun(Elem, Acc) ->
        Cap = maps:get(<<"capabilities">>, Elem),
        case lists:member(Cap, Operator_Capabilities) of
          true -> true;
          _ -> Acc
        end
                                end, false, Resources),

      case HasOperator of
        true -> {next_state, wait_for_operator_start, State};
        false ->
          io:format("~n *[CONTRACT E STATE | ~p]*: Parent is ready, Going to start Task from FSM [NO Operator] ~n",[myFuncs:myName(BH)]),
          % Start link with child
          Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>, BH),
          lists:foldl(fun(Elem, Acc) ->
            base_link_ep:start_link(Elem)
                      end, [], Handles),

          %% TODO THink about a solution to the problem where the parent Handel is not yet ready
          %Start link with parent
          Handle = base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>, BH),
          base_link_ep:start_link(Handle),

          {next_state, wait_for_operator_end, State}
      end;
    false -> {next_state, rescheduling, State}
  end;

check_with_contracted_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_parent(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_parent(cast, internal_check, State) ->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Checking with parent ~n",[myFuncs:myName(BH)]),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  log:message(myFuncs:myName(BH), base_business_card:get_name(hd(TaskHolons)), <<"Request to start">>),
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, {MyName,query}, BH),
  case Reply of
    not_ready ->
      log:message(base_business_card:get_name(hd(TaskHolons)), myFuncs:myName(BH),  <<"Not ready">>),
      {next_state, parent_not_yet_ready, State};
    {ready, TRU} ->
      io:format("~p received TRU list from parent: ~p~n",[myFuncs:myName(BH),TRU]),
      base_variables:write(<<"TRU">>, <<"List">>, TRU, BH),
      log:message( base_business_card:get_name(hd(TaskHolons)),myFuncs:myName(BH), <<"Ready">>),
      {next_state, check_with_contracted_child, State}
  end;

check_with_parent(cast, Cast, State) ->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Unsupported cast in check with parent of ~p ~n",[myFuncs:myName(BH), Cast]),
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parent_not_yet_ready(enter, _OldState, State) ->
  BH = maps:get(<<"BH">>,State),
  log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Waiting for parent">>),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  io:format("~n *[CONTRACT E STATE | ~p]*: Parent not yet ready, going to wait for ~ps ~n",[myFuncs:myName(BH),Delay/1000]),
  {keep_state, {State,base:get_origo()}, Delay};

parent_not_yet_ready(timeout, _EventContent, {State,_}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Timer expired, checking with parent again~n",[myFuncs:myName(BH)]),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, parent_ready, {State,_}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Parent said you can start~n",[myFuncs:myName(BH)]),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, Cast, {State,OldTIme}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Unsupported cast in parent not ready of ~p ~n",[myFuncs:myName(BH),Cast]),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  RemainingTIme = Delay-base:get_origo()+OldTIme,
  {keep_state, {State,OldTIme}, RemainingTIme}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_operator_start(enter, OldState, State)->
  BH = maps:get(<<"BH">>,State),
  log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Waiting for operator to start">>),
  io:format("~n *[CONTRACT E STATE | ~p]*: Waiting for operator to start ~n",[myFuncs:myName(BH)]),
  {keep_state, State};

wait_for_operator_start(cast, start, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Operator wants to start ~n",[myFuncs:myName(BH)]),
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:start_link(Elem)
  end, [], Handles),

  %Start link with parent
  Handle = base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>,BH),
  base_link_ep:start_link(Handle),
  %Start timer task

  {next_state, wait_for_operator_end, State};

wait_for_operator_start(cast, Cast, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Unsupported cast in waiting for op to start of ~p ~n",[myFuncs:myName(BH), Cast]),
  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_operator_end(enter, OldState, State)->
  BH = maps:get(<<"BH">>,State),
  log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Started">>),
  io:format("~n *[CONTRACT E STATE | ~p]*: Waiting for operator to complete the task~n",[myFuncs:myName(BH)]),
  {keep_state, State};

wait_for_operator_end(cast, end_task, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Operator completed the task ~n",[myFuncs:myName(BH)]),
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:end_link(Elem,completed)
              end, [], Handles),
  %Start timer task
  {next_state, finish, State};

wait_for_operator_end(cast, Cast, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: Unsupported cast in waiting for op to end of ~p~n",[myFuncs:myName(BH), Cast]),

  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rescheduling(enter, OldState, State)->
  BH = maps:get(<<"BH">>, State),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  io:format("~n *[CONTRACT E STATE | ~p]*: ~p needs rescheduling ~n",[MyName,MyName]),

  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, {MyName,query}, BH),
  case Reply of
    {ready, TRU} ->
      io:format("~p received TRU list from parent: ~p~n",[myFuncs:myName(BH),TRU]),
      base_variables:write(<<"TRU">>, <<"List">>, TRU, BH),
      {keep_state, State, 30000};
    not_ready ->
      {keep_state, State, 30000}
  end;


rescheduling(timeout, _EventContent, State) ->
  {next_state, check_with_parent, State};

rescheduling(cast, _, State)->

  {next_state, check_with_contracted_child, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


finish(enter, OldState, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[CONTRACT E STATE | ~p]*: FSM completed ~n",[myFuncs:myName(BH)]),

  % Ending link with parent, if it has one
  case base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>, BH) of
    no_entry -> true;
    Handle ->
      base_link_ep:end_link(Handle,completed)
  end,

  contracting_master_link_ap:analysis(BH),
  log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Completed">>),

  io:format("~n### ~p IS COMPLETE WITH ITS TASKS ###~n~n",[myFuncs:myName(BH)]),
  {stop, normal, State};

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.

% Handle custom events, including state query
handle_event(info, {get_state, From}, StateName, StateData) ->
  From ! {state, StateName},
  {keep_state, StateName, StateData};

handle_event(_Type, _Event, StateName, StateData) ->
  {keep_state, StateName, StateData}.