%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jun 2024 09:48
%%%-------------------------------------------------------------------
-module(contracting_master_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
  FSM = base_attributes:read(<<"meta">>,<<"FSM_Execute">>,BH),
  FSM_Data = #{
    <<"BH">>=>BH,
    <<"children">>=>base_attributes:read(<<"meta">>,<<"children">>,BH)
  },
  {ok, StateMachinePID} = gen_statem:start_link({global, make_ref()}, FSM, FSM_Data, []),
  io:format("Execution FSM Started~n"),
  base_variables:write(<<"FSM_EXE">>, <<"FSM_PID">>, StateMachinePID, BH),
  base_variables:write(<<"FSM_EXE">>, <<"ExecutionHandels">>,[],BH),
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start_link(PluginState, ExH, BH) ->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  PartnerBC = base_link_ep:get_partner_bc(ExH),
  PartnerName = base_business_card:get_name(PartnerBC),
  CurrentTime = binary_to_list(myFuncs:convert_unix_time_to_normal(base:get_origo())),
  io:format("Master contract: ~p with child ~p ready to start at ~p~n",[MyName,PartnerName,CurrentTime]),

  Handels = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  base_variables:write(<<"FSM_EXE">>, <<"ExecutionHandels">>,[ExH|Handels],BH),
  %Start timer for checking up on child

  {wait, no_state}.

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

partner_call(Payload, PluginState, ExH, BH) ->
  io:format("Received partner call: ~p~n",[Payload]),
  {reply, ok, PluginState}.

partner_signal({<<"SIGNAL">>,Payload}, PluginState, ExH, BH) ->
  io:format("Received partner signal: ~p~n",[Payload]),
  {ok,PluginState}.

link_end(Reason, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, PluginState, ExH, BH) ->
  {ok,PluginState}.