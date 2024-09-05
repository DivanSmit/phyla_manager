%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 09:49
%%%-------------------------------------------------------------------
-module(contracting_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start_link(PluginState, ExH, BH) ->

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  PartnerBC = base_link_ep:get_partner_bc(ExH),
  PartnerName = base_business_card:get_name(PartnerBC),
  CurrentTime = binary_to_list(myFuncs:convert_unix_time_to_normal(base:get_origo())),
  io:format("Servant contract: ~p with parent ~p ready to start at ~p~n",[MyName,PartnerName,CurrentTime]),

  base_variables:write(<<"FSM_EXE">>, <<"parentExecutionHandel">>,ExH,BH),

  base_variables:subscribe(<<"TRU">>,<<"List">>, self(), BH),

  {wait, no_state}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  io:format("Servant ~p started task ~n",[myFuncs:myName(BH)]),
  {ok, no_state}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_signal(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

link_end(Reason, PluginState, ExH, BH) ->
%%  MyBC = base:get_my_bc(BH),
%%  MyName = base_business_card:get_name(MyBC),
%%  ProID = base_attributes:read(<<"meta">>, <<"parentID">>, BH),
%%  TaskHolons = bhive:discover_bases(#base_discover_query{id = ProID}, BH),
%%  base_signal:emit_signal(TaskHolons, <<"Update">>, {MyName,completed}, BH),
  io:format("~p finished task~n",[myFuncs:myName(BH)]),
  archive.

base_variable_update({<<"TRU">>,<<"List">>, Value}, PluginState, ExH, BH) ->
  io:format("TRU List updated: ~p~n",[Value]),
  ChangedTru = tru:find_end_trus(Value),
  io:format("Changed TRUs: ~p~n",[ChangedTru]),
  base_link_ep:signal_partner(<<"Update_TRU">>, ChangedTru, ExH),
  {ok, PluginState}.