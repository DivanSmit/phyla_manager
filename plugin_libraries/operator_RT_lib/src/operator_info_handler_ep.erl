%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:47
%%%-------------------------------------------------------------------
-module(operator_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

handle_signal(Tag, Signal, BH) ->
  erlang:error(not_implemented).

handle_request(<<"MOVE">>,<<"FRUIT">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  io:format("Info handler recieved request~n"),

  MyName = base_business_card:get_name(MyBC),
  spawn(fun()->
    move_fruit_sp:handle_task_request(FROM,BH)
    end),

  Reply = #{<<"Reply">>=>ok},
  {reply, Reply};

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};

handle_request(<<"INFO">>,<<"TASKSID">>, FROM, BH)->
  TaskIDs = myFuncs:get_task_id_from_BH(BH),
  TaskTimes = myFuncs:get_task_shell_element(2,BH),
  io:format("Times are: ~p~n",[TaskTimes]),
  TaskTimesC = lists:map(fun(Time) -> myFuncs:convert_unix_time_to_normal(Time) end, TaskTimes),
  Reply = #{<<"id">>=>TaskIDs,<<"time">>=>TaskTimesC},
  {reply, Reply};

handle_request(<<"TASKS">>,Request, FROM, BH)->
  ID = maps:get(<<"taskID">>,Request),
  Param = maps:get(<<"param">>,Request),
%%  TODO ExH needs to be received once task is scheduled and not only when request starts link starts.
%% Possible solution is variable update
  Exe = base_variables:read(<<"TaskStatus">>,ID,BH),

  % TODO change the manner in which a task starts.
  % It should only be changed if the FSM is in waiting for task start

  case Param of
    <<"StartTask">> ->
      io:format("~nSTARTING TASK FROM RECEPTOR~n"),
      base_link_ep:start_link(Exe);
    <<"EndTask">> ->
      io:format("~nEnding TASK FROM RECEPTOR~n"),
      base_link_ep:end_link(Exe,no_state)
  end,

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply}.

