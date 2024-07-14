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

      %Testing
      {ok, BinaryData} = file:read_file("C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/treatment_process_AT_lib/src/process_config_test.json"),
      JsonString = bason:json_to_map(BinaryData), %%%%%%%%%%%%%%%%%%%%%%%%%%%%% Remove once testing is done!

      io:format("Starting Testing from Operator Info Handler~n");
%%      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"manage_facility">>}, BH),
%%      io:format("TBC: ~p~n", [TaskHolons]);
%%      Reply1 = base_signal:emit_request(TaskHolons, <<"newConfig">>, JsonString, BH);
    _ ->
      H = 2
  end,
%%    handle_request(<<"INFO">>,<<"Test1">>, BH, BH);
  ok.

stop(BH) ->
  ok.

handle_signal(Tag, Data, BH) ->
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

handle_request(<<"INFO">>,<<"Test1">>, FROM, BH)->
  io:format("Received test1~n"),

  Elem = #{
    <<"name">> => <<"Trial_1">>,
    <<"childContract">>=><<"contracting_A">>,
%%    <<"pred">> => [],
    <<"children">> => [
      #{
        <<"name">> => <<"Process_1">>,
        <<"startTime">> => base:get_origo()+10000,
        <<"predecessor">> => [],
        <<"type">> => <<"SPAWN_PROCESS_TASK_INSTANCE">>,
        <<"children">> => [
            #{
            <<"name">> => <<"Move_1">>,
            <<"startTime">> => 0,
            <<"predecessor">> => [],
            <<"type">> => <<"SPAWN_PS_INSTANCE">>,
            <<"meta">> => #{
              <<"machine">> => #{}
            }
          },
          #{
            <<"name">> => <<"Step_1">>,
            <<"startTime">> => 0,
            <<"predecessor">> => [<<"Move_1">>],
            <<"type">> => <<"SPAWN_PS_INSTANCE">>,
            <<"meta">> => #{
              <<"machine">> => #{}
            }
          }
        ]}
    ,
    #{
      <<"name">> => <<"Process_2">>,
      <<"startTime">> => base:get_origo()+10000,
      <<"predecessor">> => [],
      <<"type">> => <<"SPAWN_PROCESS_TASK_INSTANCE">>,
      <<"children">> => [
        #{
          <<"name">> => <<"Move_2">>,
          <<"startTime">> => 0,
          <<"predecessor">> => [],
          <<"type">> => <<"SPAWN_PS_INSTANCE">>,
          <<"meta">> => #{
            <<"machine">> => #{}
          }
        },
        #{
          <<"name">> => <<"Step_2">>,
          <<"startTime">> => 0,
          <<"predecessor">> => [<<"Move_2">>],
          <<"type">> => <<"SPAWN_PS_INSTANCE">>,
          <<"meta">> => #{
            <<"machine">> => #{}
          }
        },
        #{
          <<"name">> => <<"Move_3">>,
          <<"startTime">> => 0,
          <<"predecessor">> => [<<"Step_2">>],
          <<"type">> => <<"SPAWN_PS_INSTANCE">>,
          <<"meta">> => #{
            <<"machine">> => #{}
          }
        }]
    }
 ]
  },

  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),

  Data_map = maps:merge(#{<<"parentID">> => MyID,<<"startTime">>=>base:get_origo()}, Elem),
%%  io:format("Data map: ~p~n",[Data_map]),
  Spawn_Tag = <<"SPAWN_PROCESS_TASK_INSTANCE">>,
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
  Name = base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
  Reply = #{<<"Reply">>=>Name},
  {reply, Reply};

handle_request(<<"INFO">>,<<"Test2">>, FROM, BH)->
  io:format("Received test2~n"),

  Elem = #{
    <<"name">> => <<"Trial_1">>,
    <<"childContract">> => <<"contracting_A">>,
    <<"predecessor">> => [],
    <<"children">> => [
      #{
        <<"name">> => <<"Process_1">>,
        <<"startTime">> => base:get_origo() + 10000,
        <<"predecessor">> => [],
        <<"type">> => <<"SPAWN_PROCESS_TASK_INSTANCE">>,
        <<"children">> => [
          #{
            <<"name">> => <<"Move_1">>,
            <<"startTime">> => 0,
            <<"predecessor">> => [],
            <<"type">> => <<"SPAWN_PS_INSTANCE">>,
            <<"children">>=>[
              #{<<"capeability">>=><<"COLD_STORE_FRUIT">>,
                <<"requirements">>=>{}}
            ]
          },
          #{
            <<"name">> => <<"Move_2">>,
            <<"startTime">> => 0,
            <<"predecessor">> => [],
            <<"type">> => <<"SPAWN_PS_INSTANCE">>,
            <<"meta">> => #{
              <<"machine">> => #{},
              <<"change">>=>60
            }
          }
        ]
      }

    ]
  },
  MyBC = base:get_my_bc(BH),
  MyID = base_business_card:get_id(MyBC),

  Data_map = maps:merge(#{<<"parentID">> => MyID,<<"startTime">>=>base:get_origo()}, Elem),
%%  io:format("Data map: ~p~n",[Data_map]),
  Spawn_Tag = <<"SPAWN_PROCESS_TASK_INSTANCE">>,
  TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = Spawn_Tag}, BH),
  Name = base_signal:emit_request(TaskHolons, Spawn_Tag, Data_map, BH),
  Reply = #{<<"Reply">>=>Name},
  {reply, Reply};

handle_request(<<"INFO">>,<<"INFO">>, FROM, BH)->
  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  Reply = #{<<"name">>=>MyName},
  {reply, Reply};


handle_request(<<"INFO">>,<<"TASKSID">>, FROM, BH)->
  TaskNames = myFuncs:get_partner_names(BH,master),
  TaskIDs = myFuncs:get_task_id_from_BH(BH),
  TaskTypes  = myFuncs:get_task_type_from_BH(BH),
  TaskTimes = myFuncs:get_task_shell_element(2,BH),
  TaskTimesC = lists:map(fun(Time) -> myFuncs:convert_unix_time_to_normal(Time) end, TaskTimes),
  Reply = #{<<"id">>=>TaskIDs,<<"time">>=>TaskTimesC, <<"type">>=>TaskTypes,<<"names">>=>TaskNames},
  {reply, Reply};

handle_request(<<"TASKS">>, Request, FROM, BH) ->
  MyBC = base:get_my_bc(BH),

  ID = maps:get(<<"taskID">>, Request),
  Param = maps:get(<<"param">>, Request),

  case Param of
    <<"LOGIN">> ->
      Pass = base_attributes:read(<<"attributes">>, <<"password">>, BH),
      io:format("The Password is: ~p~n",[Pass]),
      if
        Pass == ID ->
          Role = base_attributes:read(<<"attributes">>,<<"role">>,BH),
          {reply, #{<<"reply">>=><<"OK">>,<<"role">>=>Role}};
        true -> {reply,#{<<"reply">>=><<"error">>}}
      end;
    _ ->
      {PartnerID, PartnerName} = myFuncs:extract_partner_and_task_id(ID, master, BH),

      case PartnerName of
        task_completed ->
          {reply, task_completed};
        _ ->
          TaskHolons = bhive:discover_bases(#base_discover_query{name = PartnerName}, BH),
          base_signal:emit_signal(TaskHolons, Param, PartnerID, BH),

          MyBC = base:get_my_bc(BH),
          MyName = base_business_card:get_name(MyBC),
          Reply = #{<<"name">> => MyName},
          {reply, Reply}
      end
  end;

handle_request(<<"Update">>, From, _, BH) ->
  % This because for the top activity holon their parent is the operator!
  {reply, ready};

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



