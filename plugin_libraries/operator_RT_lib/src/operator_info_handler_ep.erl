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
  TaskTypes  = myFuncs:get_task_type_from_BH(BH),
  TaskTimes = myFuncs:get_task_shell_element(2,BH),
  TaskTimesC = lists:map(fun(Time) -> myFuncs:convert_unix_time_to_normal(Time) end, TaskTimes),
  Reply = #{<<"id">>=>TaskIDs,<<"time">>=>TaskTimesC, <<"type">>=>TaskTypes},
  {reply, Reply};

handle_request(<<"TASKS">>,Request, FROM, BH)->
  ID = maps:get(<<"taskID">>,Request),
  Param = maps:get(<<"param">>,Request),

  Shell = myFuncs:get_task_shell_from_id(ID,BH),
  case myFuncs:get_task_sort(Shell) of
    link ->
      PartnerID = myFuncs:get_partner_task_id(Shell),
      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"EXECUTABLE_TASK">>}, BH),
      Reply1 = base_signal:emit_signal(TaskHolons, Param, PartnerID, BH)
  end,

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply}.

