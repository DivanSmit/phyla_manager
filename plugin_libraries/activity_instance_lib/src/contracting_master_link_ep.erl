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
  base:wait_for_base_ready(BH),

  % Starting the Exe FSM
  spawn(fun()->
    FSM = base_attributes:read(<<"meta">>,<<"FSM_Execute">>,BH),
    FSM_Data = #{
      <<"BH">>=>BH,
      <<"children">>=>base_attributes:read(<<"meta">>,<<"children">>,BH)
    },
    {ok, StateMachinePID} = gen_statem:start_link({global, make_ref()}, FSM, FSM_Data, []),
    base_variables:write(<<"FSM_EXE">>, <<"FSM_PID">>, StateMachinePID, BH)
%%    io:format("Master EP INSTALLED FOR ~p with FSM: ~p~n",[myFuncs:myName(BH), FSM])
  end),

  base_variables:write(<<"FSM_EXE">>, <<"ExecutionHandels">>,[],BH),
  base_variables:write(<<"TRU">>,<<"List">>, #{}, BH),
  base_variables:write(<<"TRU">>, <<"Data">>,[],BH),
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

  % Add handles to execute later
  Handles = base_variables:read(<<"FSM_EXE">>, <<"ExecutionHandels">>,BH),
  base_variables:write(<<"FSM_EXE">>, <<"ExecutionHandels">>,[ExH|Handles],BH),

  % Start the FSM, if it is required. Otherwise FSM will just ignore
  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, scheduled_time_arrived),

  {wait, no_state}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  spawn(fun()->
    MyBC = base:get_my_bc(BH),
    MyName = base_business_card:get_name(MyBC),
    PartnerBC = base_link_ep:get_partner_bc(ExH),
    PartnerName = base_business_card:get_name(PartnerBC),
    io:format("Contract ~p with <-----> ~p started.~n",[MyName,PartnerName])
  end),
  {ok, started}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

% This is requesting for TRU data
partner_call({<<"TRU_LIST">>, Payload}, PluginState, ExH, BH) ->
  io:format("~p received partner call of request~n",[myFuncs:myName(BH)]),
  TRU = base_variables:read(<<"TRU">>,<<"List">>,BH),
  List = tru:current(TRU),
  {reply, List, PluginState};

partner_call({<<"END_Task">>, <<"Request">>}, PluginState, ExH, BH) ->
  % This request is for if a resource requests to end the task
  %% TODO potentially do more with this task than just a finish reply
  %% TODO This needs to reflect in the FSM as well that the task is finished
  % You need to check what state the fsm is in and what cast is required
  % You need to update the exe FSM to accommodate that no operator is present
  {reply_end, finish, completed, PluginState}.

partner_signal({<<"TRU_DATA">>, Data}, PluginState, ExH, BH) ->
  io:format("~p received partner call with Data~n",[myFuncs:myName(BH)]),
  PreviousData = base_variables:read(<<"TRU">>, <<"Data">>,BH),
  fun() when is_list(Data) -> base_variables:write(<<"TRU">>, <<"Data">>, PreviousData++Data, BH) end(),
  {ok, PluginState};

partner_signal({<<"Update_TRU">>, Payload}, PluginState, ExH, BH) ->
  TRU = base_variables:read(<<"TRU">>,<<"List">>, BH),
  NewTRU = tru:add_new(Payload, TRU),
  base_variables:write(<<"TRU">>,<<"List">>, NewTRU, BH),
%%  io:format("New TRU: ~p for ~p~n",[NewTRU, myFuncs:myName(BH)]),
  {ok, PluginState};


% This is informing the master on the current TRU List/ A New List
partner_signal({<<"New_TRUs">>,Payload}, PluginState, ExH, BH) ->
  io:format("~p received partner signal: ~p~n",[myFuncs:myName(BH),Payload]),
  TRU = base_variables:read(<<"TRU">>,<<"List">>, BH),
  NewTRU = tru:change_tru(Payload, [], TRU),
  base_variables:write(<<"TRU">>,<<"List">>, NewTRU, BH),
%%  io:format("New TRU for ~p: ~p~n",[myFuncs:myName(BH), NewTRU]),
  {ok,PluginState}.

link_end(Reason, PluginState, ExH, BH) ->
  io:format("The link is finished~n"),
  % TODO process task needs to reflect on the affected TRUs that form part of it in a DB
  reflect.

base_variable_update(_, PluginState, ExH, BH) ->
  {ok,PluginState}.