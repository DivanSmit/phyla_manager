%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:10
%%%-------------------------------------------------------------------
-module(fse_operator_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, handle_call/4, base_variable_update/4]).


init(Pars, BH) ->

  ok.

stop(BH) ->
  ok.

request_start_link(PluginState, ExH, BH) ->
  io:format("The operator servant link has requested to start ~n"),
  ID = myFuncs:get_task_id_from_BH(BH),
  base_variables:write(<<"TaskStatus">>,lists:nth(1,ID),ExH,BH),
  {wait, lists:nth(1,ID)}.


request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  io:format("~nLINK TASK IS STARING SERVANT~n"),
  base_variables:write(<<"TaskStatus">>,PluginState,ExH,BH),
  Shell = base_task_ep:get_shell(ExH),
  base_execution:put_task_data(#{<<"StartTime">>=>base:get_origo()},Shell,BH),

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
  io:format("The link is finished~n"),
  Shell = base_task_ep:get_shell(ExAgentHandle),
  {ok,ExecutionMap} = base_execution:get_task_execution_data(Shell,BH),
  base_execution:put_task_data(maps:put(<<"EndTime">>,base:get_origo(),ExecutionMap),Shell,BH),
  reflect.

handle_call(Call, TaskState, ExAgentHandle, BH) ->
  erlang:error(not_implemented).

handle_message(Cast, TaskState, ExAgentHandle, BH) ->
  io:format("~n MESSAGE Value ~p ",[Cast]),
  {ok, nothing}.

base_variable_update({<<"TaskStatus">>, Variable, Value}, PluginState, ExH, BH) ->
  io:format("~n The variable has been updated, ~p to ~p~n",[Variable,Value]),
  {ok, no_state}.