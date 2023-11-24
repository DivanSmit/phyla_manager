%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:10
%%%-------------------------------------------------------------------
-module(fse_operator_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).


init(Pars, BH) ->
  base_variables:write(<<"TaskDurations">>,<<"fse_operator">>,1800000,BH),
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal(Requirements, PluginState, NegH, BH) ->

  StartTime = maps:get(<<"AVAILABILITY">>,lists:nth(1, Requirements)),
  {Result,AvailabilityTime} = case StartTime of
                       any -> {ok,base:get_origo()};
                       _ ->
                         TaskDuration = base_variables:read(<<"TaskDurations">>, <<"fse_operator">>, BH),
                         myFuncs:check_availability(StartTime, TaskDuration,earliest_from_now,BH)
                     end,

  case Result of
    ok->
      Proposal = #{<<"proposal">>=>accept,<<"TIME">>=>AvailabilityTime},
      {proposal,Proposal,AvailabilityTime};
    not_possible->
      Proposal = #{<<"proposal">>=>not_possible,<<"TIME">>=>AvailabilityTime},
      {proposal,Proposal,AvailabilityTime};
    false-> {refuse,not_qualified}
  end.

proposal_accepted(PluginState, NegH, BH) ->

  Tsched = PluginState,
%%  Tsched = base:get_origo(),
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = #{<<"LinkID">>=>LinkID},
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________


