%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:12
%%%-------------------------------------------------------------------
-module(ps_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_request(<<"INFO">>,<<"INFO">>, FROM ,BH)->
  Schedule = maps:keys(base_schedule:get_all_tasks(BH)),
  Execution = maps:keys(base_execution:get_all_tasks(BH)),
  {Status, Time} = case Schedule of
                     [] -> case Execution of
                             [] -> {<<"completed">>, base:get_origo()};
                             _ -> Task = hd(Execution),
                               End = Task#task_shell.tstart,
                               {<<"execution">>, End}
                           end;
                     _ -> Task = hd(Schedule),
                       Start = Task#task_shell.tsched,
                       {<<"scheduled">>, Start}
                   end,
  Reply = #{<<"time">> => Time, <<"name">> => myFuncs:myName(BH), <<"status">> => Status},
  {reply, Reply}.

handle_signal(<<"StartTask">>,ID, BH)->

  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, task_started),
      base_variables:write(<<"FSM_INFO">>, <<"FSM_status">>, task_started, BH);
    _ ->
      true
  end,
  ok;

handle_signal(<<"EndTask">>,ID, BH)->
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, task_finished),
      base_variables:write(<<"FSM_INFO">>, <<"FSM_status">>, task_finished, BH);
    _ ->
      true
  end,
  ok;

% Update signal is sent by child INFORMING of a an update
handle_signal(<<"Update">>,Value, BH)->

  case Value of
    {parent, parent_ready} ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, parent_ready);
    _ ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, ready)
  end,

  ok.