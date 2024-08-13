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
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/1, callback_mode/0, negotiate_with_resource/3, task_scheduled/3 ,finish/3, terminate/3]).


init(Pars) ->
  io:format("~n *[PS STATE]*: FSM installed ~n"),

  BH = maps:get(<<"BH">>,Pars),
  Resources = base_attributes:read(<<"meta">>,<<"resources">>,BH),

  Negotiating = maps:get(<<"resources">>,Pars, none),
  State = case Negotiating of
            none -> maps:merge(#{<<"resources">> => Resources}, Pars);
            _ -> Pars
          end,

  {ok, negotiate_with_resource, State}.

callback_mode() ->
  [state_functions, state_enter].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Entry function for negotiating with resources
negotiate_with_resource(enter, _OldState, State) ->
  io:format("~n *[PS STATE]*: Entering negotiate_with_resource state ~n"),
  case maps:get(<<"resources">>, State, []) of
    [] ->
      io:format("No resources found.~n"),
      {keep_state, State};
    [Resource | Rest] ->
      NewState = process_resource(State, Resource, Rest),
      {keep_state, NewState}
  end;

% Cast function for handling different events
negotiate_with_resource(cast, contracted, State) ->
  io:format("~n *[PS STATE]*: Found an operator ~n"),
  % TODO Look at the scheduled time and see if there is a difference. Might need to reschedule.
  case maps:get(<<"resources">>, State, []) of
    [] ->
      {next_state, task_scheduled, State};
    [Resource | Rest] ->
      NewState = process_resource(State, Resource, Rest),
      {keep_state, NewState}
  end;

negotiate_with_resource(cast, no_operator, State) ->
  io:format("~n *[PS STATE]*: No operator found ~n"),
  {next_state, task_not_possible, State};

negotiate_with_resource(cast, _, State) ->
  {keep_state, State}.

% Function to process a single resource
process_resource(State, Resource, Rest) ->
  BH = maps:get(<<"BH">>, State),
  Base_Link = base_attributes:read(<<"meta">>, <<"childContract">>, BH),
  StartTime = base_attributes:read(<<"meta">>, <<"startTime">>, BH),

  Change = 10,
  Requirements = #{
    <<"AVAILABILITY">> => StartTime,
    <<"action">> => Change,
    <<"type">> => resource,
    <<"capabilities">> => maps:get(<<"capabilities">>, Resource),
    <<"processType">> => base_attributes:read(<<"meta">>, <<"processType">>, BH),
    <<"description">> => base_attributes:read(<<"meta">>, <<"description">>, BH),
    <<"duration">> => base_attributes:read(<<"meta">>, <<"duration">>, BH),
    <<"truAction">> => base_attributes:read(<<"meta">>, <<"truAction">>, BH)
  },

  spawn(fun() ->
    base_link_master_sp:start_link_negotiation(Requirements, Base_Link, BH)
        end),

  maps:update(<<"resources">>, Rest, State).

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

task_scheduled(cast, _, State)->
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
