%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 18. Apr 2024 09:15
%%%-------------------------------------------------------------------
-module(proTask_FSM_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(<<"StateCast">>, Cast, BH) ->
  io:format("~nReceived Cast: ~p~n",[Cast]),
  FSM_PID = base_variables:read(<<"FSM_INFO">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, Cast);

handle_signal(<<"Update">>,Value, BH)->

  Count = base_variables:read(<<"FSM_INFO">>,<<"FSM_Ready">>,BH),
  base_variables:write(<<"FSM_INFO">>,<<"FSM_Ready">>,Count+1,BH),
  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  gen_statem:cast(FSM_PID, ready),

  ok;

handle_signal(<<"taskScheduled">>, Time, BH) ->
%%  io:format("Received taskScheduled: ~p~n",[Time]),
  FSM_PID = base_variables:read(<<"FSM_INFO">>,<<"FSM_PID">>,BH),
  gen_statem:cast(FSM_PID,task_scheduled).
%%  base_variables:write(<<"tasks">>, <<"newStart">>, Time,BH).

handle_request(<<"Update">>,Value, From, BH)->
  io:format("received update request from ~p~n",[Value]),
  PredList = base_variables:read(<<"predecessors">>, Value, BH),
  io:format("Predecessor for ~p: ~p~n",[Value, PredList]),
  case length(PredList) of
                  0 ->
                    {reply, ready};
                  _ ->
                    CompletedTasksShells = base_biography:get_all_tasks(BH),
                    CompletedTasks = case is_map(CompletedTasksShells) of
                                       true ->
                                         [];
                                       _ ->
                                         lists:foldl(fun(Elem, Acc) ->
                                           maps:keys(Elem) ++ Acc
                                                     end, [], CompletedTasksShells)
                                     end,

                    case lists:member(lists:nth(1,PredList), CompletedTasks) of
                      true ->
                        {reply, ready};
                      false ->
                        {reply, not_ready}
                    end
                end.

