%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 25. Jun 2024 13:08
%%%-------------------------------------------------------------------
-module(activity_exe_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/1, callback_mode/0, wait_for_schedule/3, wait_for_scheduled_time/3, executing_tasks/3, check_with_parent/3,
  parent_not_yet_ready/3,finish/3, terminate/3]).

init(Pars) ->
  io:format("~n *[ACTIVITY E STATE]*: FSM installed ~n"),

  {ok, wait_for_schedule, Pars}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_schedule(enter, OldState, State)->
  io:format("~n *[ACTIVITY E STATE]*: Waiting for schedule ~n"),

  {keep_state, State};

wait_for_schedule(cast, scheduled, State)->
  {next_state, wait_for_scheduled_time, State};


wait_for_schedule(cast, Cast, State)->
  io:format("~n *[ACTIVITY E STATE]*: Unsupported cast in waiting for sched ~p ~n",[Cast]),
  {keep_state, State}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

wait_for_scheduled_time(enter, _OldState, State) ->
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

wait_for_scheduled_time(cast, internal_check, State)->
  BH = maps:get(<<"BH">>,State),
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH) - base:get_origo()+1000,
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
  io:format("~n *[ACTIVITY E STATE]*: Unsupported cast in waiting for sched ~p ~n",[Cast]),
  BH = maps:get(<<"BH">>,State),
  Delay = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  RemainingTIme = Delay - base:get_origo() ,

  case RemainingTIme < 0 of
    true -> {next_state, check_with_parent, State};
    false -> {keep_state, {State, OldTIme}, RemainingTIme}
  end.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

executing_tasks(enter, OldState, State)->
  BH = maps:get(<<"BH">>,State),

  io:format("~n *[ACTIVITY E STATE | ~p]*: executing tasks ~n",[myFuncs:myName(BH)]),
  base_variables:write(<<"FSM_EXE">>,<<"execution">>,true,BH),

  % Notify waiting list of ready
  List = base_variables:read(<<"FSM_EXE">>, <<"waiting">>, BH),
  lists:foreach(fun(Elem)->
    TaskHolons = bhive:discover_bases(#base_discover_query{name = Elem}, BH),
    base_signal:emit_signal(TaskHolons, <<"Update">>, {parent, parent_ready}, BH)
  end, List),

  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
% Check if Handles is not an empty list
  case Handles of
    [] -> ok;  % Do nothing if Handles is empty
    _ -> lists:foreach(fun(Elem) -> base_link_ep:start_link(Elem) end, Handles)
  end,

  % Starting link with parent, if it has one
  case base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>, BH) of
    no_entry -> true;
    Handle ->
      base_link_ep:start_link(Handle)
  end,

  {keep_state, State};

executing_tasks(cast, scheduled_time_arrived, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: tasks schedule time arrived ~n",[myFuncs:myName(BH)]),
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  lists:foldl(fun(Elem,Acc)->
    base_link_ep:start_link(Elem)
              end, [], Handles),
  {keep_state, State};

executing_tasks(cast, completed, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Task completed ~n",[myFuncs:myName(BH)]),
  Tasks = base_biography:get_all_tasks(BH),
  CompletedChildren = myFuncs:extract_partner_ids(Tasks,servant),

  Children = base_attributes:read(<<"meta">>,<<"children">>,BH),

  Check = lists:foldl(fun(X, Acc) -> % This list goes through the children to see if they are complete or not
    ID = maps:get(<<"processID">>, X),
    Name = maps:get(<<"processID">>,X),
    case lists:member(ID, CompletedChildren) of
      true -> % If All children are in the completed list, then it Check = true
        Acc;
      _ -> % If a single child is not in the list, Acc = false will be for the rest of the list
        Pred = base_variables:read(<<"predecessors">>, Name, BH), % Quickly just checks if a predecessor is complete
        case Pred of
          <<>> ->
            false;
          _ -> case lists:member(Pred, CompletedChildren) of % If it does have a pred that is complete, it will send a message
                 true ->
                   TaskHolons = bhive:discover_bases(#base_discover_query{id = ID}, BH),
                   base_signal:emit_signal(TaskHolons, <<"Update">>, {parent, parent_ready}, BH);
                 false->
                   false
               end
        end,
        false
    end
                      end, true, Children),

  case Check of
    true ->
      io:format("All Tasks completed"),
      {next_state, finish, State};
    false ->
      {keep_state, State}
  end;

executing_tasks(cast, Cast, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Unsupported cast in executing task ~p ~n",[myFuncs:myName(BH),Cast]),

  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

check_with_parent(enter, _OldState, State) ->

  %% Send an internal cast to trigger the state check
  gen_statem:cast(self(), internal_check),
  {keep_state, State};

check_with_parent(cast, internal_check, State) ->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Checking with parent ~n",[myFuncs:myName(BH)]),

  MyName = myFuncs:myName(BH),
  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),

  %% Sending a request, because an answer is required if can continue or not
  [Reply] = base_signal:emit_request(TaskHolons, <<"Update">>, {MyName,query}, BH),
  io:format("Reply from the parent of ~p: ~p~n", [MyName,Reply]),
  case Reply of
    not_ready ->
      {next_state, parent_not_yet_ready, State};
    {ready, TRU} ->
      base_variables:write(<<"TRU">>, <<"List">>, TRU, BH),
      {next_state, executing_tasks, State}
  end;

check_with_parent(cast, Cast, State)->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Unsupported cast in check with parent ~p ~n",[myFuncs:myName(BH),Cast]),

  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

parent_not_yet_ready(enter, _OldState, State) ->
  BH = maps:get(<<"BH">>,State),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Parent not yet ready, going to wait for ~ps ~n",[myFuncs:myName(BH),Delay/1000]),

  {keep_state, {State,base:get_origo()}, Delay};

parent_not_yet_ready(timeout, _EventContent, {State,_}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Timer expired, checking with parent again~n",[myFuncs:myName(BH)]),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, ready, {State,_}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Parent said you can start~n",[myFuncs:myName(BH)]),
  {next_state, check_with_parent, State};

parent_not_yet_ready(cast, Cast, {State,OldTIme}) ->
  BH = maps:get(<<"BH">>, State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Unsupported cast in parent not ready ~p ~n",[myFuncs:myName(BH),Cast]),
  Delay = base_attributes:read(<<"meta">>,<<"FSM_WAIT_FOR_PARENTS_DELAY">>,BH),
  RemainingTIme = Delay-base:get_origo()+OldTIme,
  {keep_state, {State,OldTIme}, RemainingTIme}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: FSM completed ~n",[myFuncs:myName(BH)]),

  % Ending link with parent, if it has one
  case base_variables:read(<<"FSM_EXE">>, <<"parentExecutionHandel">>, BH) of
    no_entry -> true;
    Handle ->
      base_link_ep:end_link(Handle,completed)
  end,

  contracting_master_link_ap:analysis(BH),

  io:format("~n### ~p IS COMPLETE WITH ITS TASKS ###~n~n",[myFuncs:myName(BH)]),

  {stop, normal, State};


finish(cast, Cast, State)->
  BH = maps:get(<<"BH">>,State),
  io:format("~n *[ACTIVITY E STATE | ~p]*: Unsupported cast in finish ~p ~n",[myFuncs:myName(BH),Cast]),
  {keep_state, State}.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.