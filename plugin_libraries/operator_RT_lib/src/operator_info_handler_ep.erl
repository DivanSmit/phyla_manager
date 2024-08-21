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
  timer:sleep(2500),
  Role = base_attributes:read(<<"attributes">>, <<"role">>, BH),

  case Role of
    <<"operator">> ->

      io:format("Starting Testing from Operator Info Handler~n");
%%      handle_request(<<"INFO">>, <<"Test2">>, BH, BH);
%%      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"manage_facility">>}, BH),
%%      io:format("TBC: ~p~n", [TaskHolons]);
%%      Reply1 = base_signal:emit_request(TaskHolons, <<"newConfig">>, JsonString, BH);
    _ ->
      H = 2
  end,


  ok.

stop(BH) ->
  ok.

handle_signal(<<"REMOVE_TASK">>, Data, BH) ->
  io:format("~p removing task: ~p~n",[myFuncs:myName(BH), Data]),
  Values = base_schedule:get_all_tasks(BH),
  lists:foreach(fun(X) ->
    Task = maps:get(X, Values),
    Meta = Task#base_task.meta,
    BC = Meta#base_contract.master_bc,
    Name = base_business_card:get_name(BC),
    if
      Name == Data -> base_schedule:take_task(X, BH);
      true -> ok
    end
                end, maps:keys(Values)),
  ok.

handle_request(<<"INFO">>,<<"Test">>, FROM, BH)->
  io:format("Received test~n"),

  Elem = #{
    <<"meta">>=>#{
      <<"machine">>=>#{}
    }
  },

  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),

  Data_map = maps:merge(#{<<"parentID">> => MyID,<<"startTime">>=>base:get_origo()}, maps:get(<<"meta">>, Elem)),

  Spawn_Tag = <<"SPAWN_PS_INSTANCE">>,
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
  base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
  Reply = #{<<"Reply">>=>ok},
  {reply, Reply};

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};


handle_request(<<"INFO">>,<<"TASKSID">>, FROM, BH)->
  Reply = myFuncs:get_task_metadata(BH),
  {reply, Reply};

handle_request(<<"TASKS">>, Request, FROM, BH) ->
  MyBC = base:get_my_bc(BH),

  TaskData = maps:get(<<"taskID">>, Request),
  Param = maps:get(<<"param">>, Request),

  case Param of
    <<"LOGIN">> ->
      Pass = base_attributes:read(<<"attributes">>, <<"password">>, BH),
      io:format("The Password is: ~p~n",[Pass]),
      if
        Pass == TaskData ->
          Role = base_attributes:read(<<"attributes">>,<<"role">>,BH),
          {reply, #{<<"reply">>=><<"OK">>,<<"role">>=>Role}};
        true -> {reply,#{<<"reply">>=><<"error">>}}
      end;
    <<"TRU">>->
      % Confirm task
      % Conform TRUs
      % Update variables
      % Reply with answer
      ID = maps:get(<<"id">>, TaskData),
      Barcodes = maps:get(<<"tru">>, TaskData),

      Tasks = base_execution:get_all_tasks(BH),
      Is_in_execution = maps:fold(fun(Shell,_Value, Acc) ->
        ElemId = Shell#task_shell.id,
        if
          ID == ElemId ->
            io:format("TRUS: ~p~n", [Barcodes]),
            log:message(<<"EVENT">>, myFuncs:myName(BH), <<"Scanned TRUs">>),
            base_variables:write(<<"TaskStatus">>, <<"TRU">>,Barcodes,BH),
            true;
          true -> Acc
        end
                                    end, false, Tasks),
      io:format("Is in execution: ~p~n",[Is_in_execution]),
      {reply, ok};
    _ ->
      {PartnerID, PartnerName} = myFuncs:extract_partner_and_task_id(TaskData, master, BH),

      case PartnerName of
        task_completed ->
          {reply, task_completed};
        _ ->
          TaskHolons = bhive:discover_bases(#base_discover_query{name = PartnerName}, BH),
          log:message(myFuncs:myName(BH), base_business_card:get_name(hd(TaskHolons)), Param),
          base_signal:emit_signal(TaskHolons, Param, PartnerID, BH),

          MyBC = base:get_my_bc(BH),
          MyName = base_business_card:get_name(MyBC),
          Reply = #{<<"name">> => MyName},
          {reply, Reply}
      end
  end;

handle_request(<<"Update">>, From, _, BH) ->
  % This because for the top activity holon their parent is the operator!
  {reply, {ready, #{}}};

handle_request(<<"CheckIn">>, From, _, BH) ->
  %% TODO this function should also change such that it check for the next task on sched according to time and not in list order
  case base_execution:get_all_tasks(BH) of
    #{} ->
      Tasks = base_schedule:get_all_tasks(BH),
      Masters = myFuncs:extract_partner_names(Tasks, master),
      case lists:nth(1, Masters) of % If there is nothing on the execution and the next task on sched is with parent
        From ->

          {reply, ready};
        _ ->
          {reply, not_ready}
      end;
    _ ->
      {reply, not_ready}
  end.



