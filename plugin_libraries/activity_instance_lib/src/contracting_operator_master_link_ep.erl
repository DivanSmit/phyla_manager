%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 09:48
%%%-------------------------------------------------------------------
-module(contracting_operator_master_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start_link(PluginState, ExH, BH) ->
  io:format("CONTRACT: Master request start~n"),
  {start, no_state}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  PartnerBC = base_link_ep:get_partner_bc(ExH),
  PartnerName = base_business_card:get_name(PartnerBC),
  io:format("Contract ~p with ----- ~p~n",[MyName,PartnerName]),
  {ok, no_state}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_signal(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

link_end(Reason, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).