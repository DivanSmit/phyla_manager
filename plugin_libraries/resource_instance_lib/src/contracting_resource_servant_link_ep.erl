%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2024 14:39
%%%-------------------------------------------------------------------
-module(contracting_resource_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_start_link(PluginState, ExH, BH) ->

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  PartnerBC = base_link_ep:get_partner_bc(ExH),
  PartnerName = base_business_card:get_name(PartnerBC),
  CurrentTime = binary_to_list(myFuncs:convert_unix_time_to_normal(base:get_origo())),
  io:format("Servant contract: ~p with parent ~p ready to start at ~p~n",[MyName,PartnerName,CurrentTime]),

  {start, nostate}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  io:format("~nLINK TASK IS STARING SERVANT~n"),

  Name = myFuncs:myName(BH),
  {ok, Data1} = base_task_ep:get_schedule_data(ExH, BH),

  Action = maps:get(<<"truAction">>, Data1, none),
  case Action of
    % Based on the instructed action, something needs to happen and then send data to the partner if needed
    none ->
      io:format("No action in data1 for ~p: ~p~n", [Name, Data1]);
    <<"None">> ->
      io:format("No TRU action required for ~p~n", [Name]);
    <<"Store">>->
      io:format("~p needs to store the fruit. ~n", [Name]),
      %% TODO also needs to update the current capacity because values are entered

      FSM_data = #{
        <<"execution">>=>ExH,
        <<"BH">>= BH,
        <<"Data1">>=>Data1
      },
      {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))}, no_operator_task_FSM, FSM_data, []);
    _ ->
      io:format("Invalid TRU action of~p for ~p~n", [Action, Name])
  end,

  {ok, no_state}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call({<<"AVAILABILITY">>,nothing}, State, ExAgentHandle, BH) ->
  io:format("The servant link has recieved the partner call~n"),
  Reply = #{<<"AVAILABILITY">>=>false},
  {reply, Reply, nostate};

partner_call(Value, State, ExAgentHandle, BH) ->
  io:format("~n PARTNERCALL Value ~p ",[Value]),
  {reply, nothing, nothing}.

partner_signal(Cast, State, ExAgentHandle, BH) ->
  erlang:error(not_implemented).

link_end(Reason, State, ExAgentHandle, BH) ->
  %% TODO remember to act differently when a task is canceled
  reflect. %Change later to ensure that it also reflects the data for analysis

base_variable_update({<<"TaskStatus">>, Variable, Value}, PluginState, ExH, BH) ->
  io:format("~n The variable has been updated, ~p to ~p~n",[Variable,Value]),
  {ok, no_state}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
