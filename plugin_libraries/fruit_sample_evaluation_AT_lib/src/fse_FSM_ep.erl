%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Nov 2023 13:42
%%%-------------------------------------------------------------------
-module(fse_FSM_ep).
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, task_cancel/4, request_resume/2, start_task/3, resume_task/3, base_variable_update/4, end_task/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start(ExecutorHandle, BH) ->
  {start_task, #{}}.

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

request_resume(ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->
  io:format("FSM task starting~n"),

  Data1 = base_task_ep:get_schedule_data(ExecutorHandle,BH),
  Pars = #{<<"BH">> => BH, <<"ExecutorHandle">> => ExecutorHandle},
  {ok, StateMachinePID} = gen_statem:start_link({global, base_business_card:get_id(base:get_my_bc(BH))},fse_FSM, maps:merge(Data1,Pars), []),
  base_variables:write(<<"FSE_FSM_INFO">>,<<"FSE_FSM_PID">>, StateMachinePID,BH),
  base_variables:write(<<"FSE_FSM_INFO">>,<<"FSE_FSM_status">>, start,BH),
  base_variables:subscribe(<<"FSE_FSM_INFO">>,<<"FSE_FSM_status">>,self(),BH),
  {ok, TaskState}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update({<<"FSE_FSM_INFO">>,<<"FSE_FSM_status">>,Status}, TaskState, ExecutorHandle, BH) ->

  case Status of
    found_operator ->

      %CAST FSM TO NEW STATE
      FSM_PID = base_variables:read(<<"FSE_FSM_INFO">>,<<"FSE_FSM_PID">>,BH),
      gen_statem:cast(FSM_PID,found_operator);

    found_fta_machine->

      %CAST FSM TO NEW STATE
      FSM_PID = base_variables:read(<<"FSE_FSM_INFO">>,<<"FSE_FSM_PID">>,BH),
      gen_statem:cast(FSM_PID,found_fta_machine)

  end,

  {ok, TaskState}.

end_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).