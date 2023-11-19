%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:06
%%%-------------------------------------------------------------------
-module(fse_operator_master_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, handle_call/4, base_variable_update/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_start_link(State, ExAgentHandle, BH) ->
  io:format("The master link has requested to start ~n "),
  {start,no_state}.

request_resume_link(State, ExAgentHandle, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExAgentHandle, BH) ->
  io:format("~nLINK TASK IS STARING MASTER~n"),

  spawn(fun()->
    MyBC = base:get_my_bc(BH),
    MyName = base_business_card:get_name(MyBC),
    PartnerBC = base_link_ep:get_partner_bc(ExAgentHandle),
    PartnerName = base_business_card:get_name(PartnerBC),
    io:format("~n [Activity: ~p] >>------------------------>>--------------------------->> [Operator: ~p] ~n", [MyName, PartnerName])
        end),

%%  ReplyData = base_link_ep:call_partner(<<"AVAILABILITY">>,nothing,ExAgentHandle),
  {ok, no_state}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call({<<"Busy">>,nothing},State, ExAgentHandle, BH)->
  io:format("Servant is busy until: sometime~n"),
  {reply, ok, nostate};

partner_call(Value, State, ExAgentHandle, BH) ->
  io:format("~n PARTNERCALL Value ~p ",[Value]),
  {reply, nothing, nothing}.

partner_signal(Value, PluginState, ExH, BH) ->
  io:format("Servant is busy until: Signal~n"),
  ok.

link_end(Reason, PluginState, ExH, BH) ->
%%  io:format("The link is finished~n"),
%%  Tasks = #task_shell_query{field = type, range = <<"fse_operator">>},
%%%%  io:format("Tasks in exe: ~p~n",[Tasks]),
%%  Task = case base_execution:query_task_shells(Tasks, BH) of
%%           [LastTask | _] ->
%%             LastTask;
%%           _ -> do_nothing
%%         end,
%%  TaskEx = base_execution:get_executor_handle(Task,BH),
%%%%  io:format("~n The TASKE is: ~p~n",[TaskEx]),
%%  base_link_ep:end_link(TaskEx,done),
  io:format("The link has ended~n"),
  discard.

handle_call(Value, PluginState, ExH, BH) ->
  ok.

base_variable_update(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).