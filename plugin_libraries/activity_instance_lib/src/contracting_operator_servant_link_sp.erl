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
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).

init(Pars, BH) ->
  base_attributes:write(<<"TaskDurations">>,<<"ps_operator">>,1800000,BH),
  base_attributes:write(<<"TaskDurationList">>,<<"ps_operator">>,[1800000],BH),
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal(Requirements, PluginState, NegH, BH) ->
  io:format("Operator received requirements~n"),
  TaskDuration = base_attributes:read(<<"TaskDurations">>, <<"ps_operator">>, BH),
  StartTime = maps:get(<<"AVAILABILITY">>,lists:nth(1, Requirements)),
  {Result,AvailabilityTime} = case StartTime of
                                any -> {ok,base:get_origo()};
                                _ ->

                                  myFuncs:check_availability(StartTime, TaskDuration,earliest_from_now,BH)
                              end,

  case Result of
    ok->
      Proposal = #{<<"proposal">>=>accept,<<"TIME">>=>AvailabilityTime,<<"endTime">>=>AvailabilityTime+TaskDuration},
      {proposal,Proposal,AvailabilityTime};
    not_possible->
      Proposal = #{<<"proposal">>=>not_possible,<<"TIME">>=>AvailabilityTime},
      {proposal,Proposal,AvailabilityTime};
    false-> {refuse,not_qualified}
  end.

proposal_accepted(PluginState, NegH, BH) ->
  io:format("Proposal Accepted~n"),
  Tsched = PluginState,
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = #{<<"LinkID">>=>LinkID},
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________

