%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2024 14:37
%%%-------------------------------------------------------------------
-module(contracting_operator_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).

init(Pars, BH) ->
  base_attributes:write(<<"TaskDurations">>,<<"contractingOp">>,60000,BH),
  base_attributes:write(<<"TaskDurationList">>,<<"contractingOp">>,[60000],BH),
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal([Requirements], PluginState, NegH, BH) ->
  %% TODO get the correct requirements, and decode them accordingly
%%  TaskDuration = base_attributes:read(<<"TaskDurations">>, <<"contractingOp">>, BH),
  TaskDuration = maps:get(<<"duration">>, Requirements),
  MyName = myFuncs:myName(BH),
  Resource = maps:get(<<"resourceName">>, Requirements, none),
  io:format("Resource: ~p~n",[Resource]),
  StartTime = maps:get(<<"AVAILABILITY">>,Requirements),
  {Result,AvailabilityTime} = case StartTime of
                                now ->
                                  case Resource of
                                     MyName ->  io:format("MY name is ~p~n",[MyName]),
                                       {ok,base:get_origo()+20000};
                                    _-> Tasks = base_execution:get_all_tasks(BH),
                                      case map_size(Tasks) of
                                         0 -> io:format("Not my name, but not busy: ~p~n",[MyName]),
                                         {ok,base:get_origo()+20000};
                                        _-> myFuncs:check_availability(base:get_origo(), TaskDuration,earliest_from_now,BH)
                                      end
                                  end;
                                _ ->
                                  {ok, Best} = myFuncs:check_availability(StartTime, TaskDuration,earliest_from_now,BH),

                                  % Giving a preference to the facility manager to not be picked
                                  MyBC = base:get_my_bc(BH),
                                  Cap = MyBC#business_card.capabilities,
                                  Ans = lists:member(<<"manage_facility">>, Cap),
                                  if Ans==true->{ok,Best};
                                    true-> {ok,Best}
                                  end
                              end,


  case Result of
    ok->
      Proposal = #{<<"proposal">>=>accept,<<"startTime">>=>AvailabilityTime,<<"endTime">>=>AvailabilityTime+TaskDuration},
      log:message(myFuncs:myName(BH), <<"Master">>, <<"Proposal">>),
      {proposal,Proposal, {AvailabilityTime,Requirements}};
    not_possible->
      Proposal = #{<<"proposal">>=>not_possible,<<"TIME">>=>AvailabilityTime},
      {proposal,Proposal,AvailabilityTime};
    false-> {refuse,not_qualified}
  end.

proposal_accepted({PluginState, Requirements}, NegH, BH) ->
  log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Proposal accepted">>),
  Tsched = PluginState,
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = Requirements,
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________

