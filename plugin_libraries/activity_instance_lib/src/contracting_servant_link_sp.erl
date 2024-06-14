%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 09:49
%%%-------------------------------------------------------------------
-module(contracting_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).


init(Pars, BH) ->
  io:format("INSTALLED~n"),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal(Requirements, PluginState, NegH, BH) ->
  io:format("Received requirements~n"),
  Name = maps:get(<<"name">>,lists:nth(1,Requirements)),
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),

  case Name of
    MyName ->
      {proposal, accept, nostate};
    _ ->
      {refuse, not_qualified}
  end.

proposal_accepted(PluginState, NegH, BH) ->
  io:format("Proposal accepted~n"),
  Tsched = base:get_origo(),
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = #{<<"LinkID">>=>LinkID},
  {promise, Tsched, LinkID,Data1, no_state}.