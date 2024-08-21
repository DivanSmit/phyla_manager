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
-include("../../../base_include_libs/base_terms.hrl").
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

handle_signal(<<"Update">>, {From, Value}, BH)->

  % This function needs to receive the ready messages from the child and save it
  % THen it should check if the FSM PID has been created or not. If it has then cast, else do not
  % When the state machine starts up it should check how many are ready, and if all then next, else normal wait state
  % That state should then have a timer to wait for children ready. If not then reschedule on the children

  FSM_PID = base_variables:read(<<"FSM_EXE">>, <<"FSM_PID">>, BH),
  case Value of
    parent_ready ->
      gen_statem:cast(FSM_PID, ready);
    completed ->
      gen_statem:cast(FSM_PID, completed)
  end,
  ok;

handle_signal(<<"taskScheduled">>, {Name,Start,End}, BH) ->
  io:format("taskScheduled: ~p~n",[{Name,Start,End}]),
  OldStart = base_variables:read(<<"FSM_INFO">>,<<"startTime">>,BH),
  OldEnd = base_variables:read(<<"FSM_INFO">>,<<"endTime">>,BH),

  if
    OldStart > Start -> base_variables:write(<<"FSM_INFO">>,<<"startTime">>,Start,BH);
    true -> true
  end,
  if
    OldEnd < End -> base_variables:write(<<"FSM_INFO">>,<<"endTime">>,End,BH);
    true -> true
  end,

  FSM_PID = base_variables:read(<<"FSM_INFO">>,<<"FSM_PID">>,BH),
  gen_statem:cast(FSM_PID,task_scheduled).

handle_request(<<"Update">>, {From, Value}, _, BH) ->

  Execution = base_variables:read(<<"FSM_EXE">>,<<"execution">>,BH),
  io:format("Execution for ~p: ~p~n",[myFuncs:myName(BH), Execution]),
  case Value of
    query when Execution == true ->
      Pred = base_variables:read(<<"predecessors">>, From, BH), %Pred can only be one
      io:format("Predecessor for ~p: ~p~n", [From, Pred]),
      case Pred of
        <<>> ->
          TRU = base_variables:read(<<"TRU">>, <<"List">>, BH),
          {reply, {ready, TRU}};
        _ ->
          CompletedTasksShells = base_biography:get_all_tasks(BH),
          CompletedTasks = case is_map(CompletedTasksShells) of
                             true -> % Will always be a map
                               myFuncs:extract_partner_ids(CompletedTasksShells, servant)
                           end,
          case lists:member(Pred, CompletedTasks) of
            true ->
              TRU = base_variables:read(<<"TRU">>, <<"List">>, BH),
              {reply, {ready, TRU}};
            false ->
              {reply, not_ready}
          end
      end;
    query when Execution == false ->
      List = base_variables:read(<<"FSM_EXE">>, <<"waiting">>, BH),
      base_variables:write(<<"FSM_EXE">>, <<"waiting">>, List ++ [From], BH),
      {reply, not_ready};
    _ ->
      {reply, not_ready}
  end.


