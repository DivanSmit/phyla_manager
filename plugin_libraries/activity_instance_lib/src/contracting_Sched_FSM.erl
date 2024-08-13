%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 14:48
%%%-------------------------------------------------------------------
-module(contracting_Sched_FSM).
-author("LENOVO").
-behaviour(gen_statem).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, spawn_and_wait_for_child/3, contract_child/3, rescheduling/3, finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[CONTRACT S STATE]*: FSM installed ~n"),
  BH = maps:get(<<"BH">>,Pars),
  Children = base_attributes:read(<<"meta">>, <<"children">>, BH),

  {ok, spawn_and_wait_for_child, maps:merge(Pars, #{<<"children">>=>Children})}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

spawn_and_wait_for_child(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: Spawning and waiting for child ~n"),

  BH = maps:get(<<"BH">>,State),
  [Current|_] = maps:get(<<"children">>,State),

  io:format("Current: ~p~n",[Current]),

  case map_size(Current) of
    0 -> {next_state, task_not_possible, State};
    _ ->

      ProcessType = maps:get(<<"processType">>,Current),
      TargetBC = bhive:discover_bases(#base_discover_query{capabilities = <<"ACTIVITY_INFO">>}, BH),
      Replies = base_signal:emit_request(TargetBC, <<"INFO">>, ProcessType, BH),

      CurrentData = lists:foldl(fun(Elem, Acc)->
        case is_map(Elem) of
          true-> Elem;
          false-> Acc
        end
      end, #{}, Replies),

      ChildData = maps:merge(CurrentData,Current),

      Spawn_Tag = maps:get(<<"type">>,CurrentData),

      StartTime = case maps:get(<<"startTime">>, ChildData) of
                    0 -> % %If the startTime variable is 0, it means the system needs to assign a time
                      ChildPred = maps:get(<<"predecessor">>,ChildData),
                      case ChildPred of % It checks to see if there is a predecessor
                        <<>> -> % If not, it starts when the parent starts
                          base_attributes:read(<<"meta">>, <<"startTime">>, BH);
                        _ -> % If it does have a pred, the end time of the pred is now the start time for the next
                          case base_variables:read(ChildPred, <<"endTime">>, BH) of
                            no_entry -> % Just check to see that the pred has been spawned, if not, it takes the parents
                              base_attributes:read(<<"meta">>, <<"startTime">>, BH);
                            Time ->
                              Time
                          end
                      end;
                    Time ->
                      Time % If it has a time, that should be the start time. A Process Step should have a start time
                  end,

      MyBC = base:get_my_bc(BH),
      MyID = base_business_card:get_id(MyBC),


      Contract = base_attributes:read(<<"meta">>,<<"childContract">>,BH),
      NewCurrent = maps:remove(<<"startTime">>,ChildData), % We need to add the actual start time

      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
      [ChildName] = base_signal:emit_request(TaskHolons, Spawn_Tag,
        maps:merge(NewCurrent,
        #{<<"parentID">>=>MyID,
          <<"childContract">>=>Contract,
          <<"startTime">>=>StartTime}
      ), BH),

      base_variables:write(<<"predecessors">>,ChildName,maps:get(<<"predecessor">>,ChildData),BH),
      {keep_state, {State,ChildName}}
  end;

spawn_and_wait_for_child(cast, task_scheduled, {State,ChildName})->
  io:format("~n *[CONTRACT S STATE]*: Child spawned and scheduled ~n"),

  {next_state, contract_child , {State,ChildName}};

spawn_and_wait_for_child(cast, not_possible, {State,_})->
  io:format("~n *[CONTRACT S STATE]*: Error while scheduling the child ~n"),

  {next_state, rescheduling ,State};


spawn_and_wait_for_child(cast, _, {State,ChildName})->
  {keep_state, {State,ChildName}}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

contract_child(enter, OldState, {State,ChildName})->
  io:format("~n *[CONTRACT S STATE]*: Negotiating Contract with child ~n"),

  BH = maps:get(<<"BH">>,State),
  Base_Link = base_attributes:read(<<"meta">>,<<"childContract">>,BH),
  io:format("~p starting a negotiation with child: ~p~n",[myFuncs:myName(BH), ChildName]),


  base_link_master_sp:start_link_negotiation(#{<<"name">>=>ChildName,<<"type">>=>activity},Base_Link,BH),
  {keep_state, State};

contract_child(cast, contracted, State)->
  io:format("~n *[CONTRACT S STATE]*: Contract Made with child ~n"),
  BH = maps:get(<<"BH">>,State),

  [Child|Rest] = maps:get(<<"children">>,State),
  case Rest of
    [] ->
      {next_state, finish, State};
    _ ->
      {next_state, spawn_and_wait_for_child, #{<<"BH">> => BH, <<"children">> => Rest}}

  end;

contract_child(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

rescheduling(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: Contract needs rescheduling ~n"),
  % Send message to the parent
  {keep_state, State};

rescheduling(cast, NewSchedule, State)->
  % can be cancel, continue with current schedule, or a new schedule
  {keep_state, State};

rescheduling(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

finish(enter, OldState, State)->
  io:format("~n *[CONTRACT S STATE]*: All children contracted ~n"),
  BH = maps:get(<<"BH">>,State),

  % Start FSM
  PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>,BH),
  gen_statem:cast(PID, scheduled),

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

finish(cast, _, State)->
  {keep_state, State}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

terminate(Reason, _StateName, State) ->
  ok.

