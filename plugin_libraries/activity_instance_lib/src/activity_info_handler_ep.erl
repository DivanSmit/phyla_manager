%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:12
%%%-------------------------------------------------------------------
-module(activity_info_handler_ep).
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
  Bio = maps:keys(base_biography:get_all_tasks(BH)),

  {Status, Time} = case Schedule of
                     [] -> case Execution of
                             [] ->
                               Task = hd(Bio),
                               End = Task#task_shell.tend,
                               {<<"Completed">>, End};
                             _ -> Task = hd(Execution),
                               RealStart = Task#task_shell.tstart,
                               {<<"Execution">>, RealStart}
                           end;
                     _ -> Task = hd(Schedule),
                       Start = Task#task_shell.tsched,
                       {<<"Scheduled">>, Start}
                   end,

  Reply = #{<<"time">> => Time, <<"name">> => myFuncs:myName(BH), <<"status">> => Status},
  {reply, Reply}.

handle_signal(<<"StartTask">>,ID, BH)->

  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, start);
    _ ->
      true
  end,
  ok;

handle_signal(<<"EndTask">>,ID, BH)->
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, end_task);
    _ ->
      true
  end,
  ok;

% TODO Add this functionality if time
handle_signal(<<"CancelTask">>,ID, BH)-> %Not yet implemented but does work. Only works if task is on schedule
  case myFuncs:check_if_my_task(ID, BH) of
    my_task ->
%%      io:format("All tasks: ~p~n",[base_schedule:get_all_tasks(BH)]),
      [Shell] = maps:keys(myFuncs:get_task_shell_from_id(ID,BH)),
%%      io:format("Shell: ~p~n",[Shell]),
      base_schedule:take_task(Shell,BH), % Remember to send message to other resources to also remove the task
%%      base_execution:take_task(Shell,BH) This will also work for in execution, but most likely need to cancel or end the link with another reason
      FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
      gen_statem:cast(FSM_PID, start); % Remember to also end the FSM correctly!!
%%      io:format("All tasks: ~p~n",[base_schedule:get_all_tasks(BH)]);
    _ ->
      true
  end,
  ok;

handle_signal(<<"Update">>, {parent,Update}, BH)->
%%  io:format("Received message from: ~p~n",[Value]),

  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, Update),
  ok;

handle_signal(<<"Update">>,Value, BH)->
%%  io:format("Received message from: ~p~n",[Value]),
  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Ready">>,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Ready">>,Count+1,BH),
  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, ready),
  ok.