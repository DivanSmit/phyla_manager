%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 22. Jan 2024 13:55
%%%-------------------------------------------------------------------
-module(move_storage_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).


init(Pars, BH) ->
  base_attributes:write(<<"TaskDurations">>,<<"mfFindStorage">>,1200000,BH),
  base_attributes:write(<<"TaskDurationList">>,<<"mfFindStorage">>,[1200000],BH),
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal(Requirements, PluginState, NegH, BH) ->
  MyBC = base:get_my_bc(BH),
  RoomName = base_business_card:get_name(MyBC),
  Target = maps:get(<<"room">>,lists:nth(1, Requirements)),
  TaskDuration = base_attributes:read(<<"TaskDurations">>, <<"mfFindStorage">>, BH),
  if
    RoomName == Target->
      %% TODO add the rest of the functionality to calculate the capacity and inventory stock of the
      StartTime = maps:get(<<"AVAILABILITY">>,lists:nth(1, Requirements)),
      {Result,AvailabilityTime} = case StartTime of
                                    any -> {ok,base:get_origo()};
                                    _ ->
                                      myFuncs:check_availability(StartTime, TaskDuration,earliest_from_now,BH)
                                  end;
    true ->
      Result = false,
      AvailabilityTime = none
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

  Tsched = PluginState,
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = nodata,
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________