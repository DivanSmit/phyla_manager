%%%-------------------------------------------------------------------
%%% @author azhar
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Jul 2023 16:38
%%%-------------------------------------------------------------------
-module(supplementary_functions).
-author("azhar").
-include("../../../base_include_libs/base_records.hrl").

%% API
-export([extract_map_from_signal/1, get_my_id/1, get_my_tasks/1, cycle_schedule_sector_backup_tuple_list/3,
  reference_to_string/1, string_to_reference/1, shell_from_task_id/2,
  convert_data_to_database_format/1, generate_task_id/0, task_id_from_executor_handle/1,
  get_holon_id_from_promise/1, generate_move_request_for_fruit_pre_trial/1, get_trial_data/3,
  generate_move_request_for_trial/1, convert_to_room_id_binary_to_integer/1, task_type_from_executor_handle/1,
  convert_controlled_atmosphere_data_to_database_format/3, reverse_list/1, reverse_list/2]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% BC FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_my_id(BH) ->
  BC = base:get_my_bc(BH),
  MAP_BC = bason:base_term_to_map(BC),
  IDENTITY = maps:get(<<"identity">>,MAP_BC),
  ID = maps:get(<<"id">>, IDENTITY),
  ID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TASK FUNCTIONS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_my_tasks(BH) ->
  %GET SCHEDULE SECTOR BACKUP
  Schedule_Sector_Backup = base_schedule:get_sector_backup(BH),
%%  io:format("~n SCHEDULE SECTOR BACKUP: ~p ~n", [Schedule_Sector_Backup]), %Only print for debugging

  %CONVERT SCHEDULE SECTOR BACKUP FROM A MAP TO A LIST OF TUPLES
  Schedule_Sector_Backup_Tuple_List = maps:to_list(Schedule_Sector_Backup),
%%  io:format("~n SCHEDULE SECTOR BACKUP TUPLE LIST: ~p ~n", [Schedule_Sector_Backup_Tuple_List]), %Only print for debugging


  case Schedule_Sector_Backup_Tuple_List of
    [] ->
      %IF THE LIST IS EMPTY RETURN THE EMPTY LIST
      Schedule_Sector_Backup_Tuple_List;
    [_|_] ->
      %IF THE LIST IS NOT EMPTY EXTRACT TASK LIST FROM SCHEDULE SECTOR BACKUP TUPLE LIST
      Task_List = cycle_schedule_sector_backup_tuple_list(Schedule_Sector_Backup_Tuple_List,[],BH),
%%      io:format("~n TASK LIST: ~n ~p ~n", [Task_List]),

      %CREATE A MAP CONTAINING TASK LIST
      Tasks = #{<<"Tasks">> => Task_List},
%%      io:format("~n TASKS HAVE BEEN SUCCESFULLY RETRIEVED : ~n ~p ~n", [Tasks]),
      Tasks
  end.



cycle_schedule_sector_backup_tuple_list([Task_Tuple|Rest],Task_List, BH) ->
%%  io:format("~n TASK TUPLE: ~p ~n",[Task_Tuple]), %only print for debugging

  %EXTRACT TASK SHELL FROM TASK TUPLE
  {Task_Shell, _} = Task_Tuple,
%%  io:format("~n TASK SHELL: ~p ~n",[Task_Shell]),

  %EXTRACT TASK ID FROM TASK SHELL
  Task_ID_Reference = element(5,Task_Shell),
  Task_ID_String = supplementary_functions:reference_to_string(Task_ID_Reference),
%%  io:format("~n TASK ID REFERENCE: ~p TASK ID STRING: ~p ~n",[Task_ID_Reference, Task_ID_String]),

  %EXTRACT TASK TYPE FROM TASK SHELL
  Task_Type = element(6, Task_Shell),
%%  io:format("~n TASK TYPE: ~p ~n",[Task_Type]),

  %%GET TRIAL ID FROM DATA 1 USING TASK SHELL
  {_, Data1} = base_schedule:task_data_request(Task_Shell, 1, BH),
%%  io:format("~n DATA1: ~p ~n",[Data1]),

  %CREATE A TASK MAP CONTAINING TASK ID, TASK TYPE AND DATA1
  Task_Map = #{<<"task_id">> => Task_ID_String, <<"task_type">> => Task_Type, <<"data_1">> => Data1},
%%  io:format("~n TASK MAP: ~p ~n",[Task_Map]),

  %ADD TASK MAP TO THE TASK LIST
  Task_List_New = lists:append(Task_List,[Task_Map]),

  %RECURSIVELY CALL FUNCTION UNTIL ALL TUPLES ARE HANDLED
  case Rest == [] of
    %BREAK OUT OF RECURSIVE FUNCTION
    true ->
      Task_List_New;
    %CALL FUNCTION AGAIN
    false->
      cycle_schedule_sector_backup_tuple_list(Rest,Task_List_New, BH)
  end.

task_type_from_executor_handle(ExecutorHandle)->
  Task_Shell = base_task_ep:get_shell(ExecutorHandle),
  Task_Type = element(6, Task_Shell),
  io:format("~n TASK TYPE: ~p ~n RETRIEVED FROM EXECUTOR HANDLE: ~p ~n",[Task_Type,ExecutorHandle]),
  Task_Type.

shell_from_task_id(Task_ID,BH) ->
  SQ = #task_shell_query{field = id, range = Task_ID},
  [Task_Shell] = base_schedule:query_task_shells(SQ, BH),
  io:format("~n TASK SHELL: ~p ~n RETRIEVED FROM TASK ID: ~p ~n",[Task_Shell,Task_ID]),
  Task_Shell.

convert_data_to_database_format(DataMap)->
  %REMOVE TASK ID
  DataMap_1 = maps:remove(<<"task_id">>, DataMap),

  %REMOVE TASK TYPE
  DataMap_2 = maps:remove(<<"task_type">>, DataMap_1),

  io:format("~n DATA IN DATABASE FORMAT: ~p ~n",[DataMap_2]),
  DataMap_2.

convert_controlled_atmosphere_data_to_database_format(DataMap,ExecutorHandle, BH) ->
  %ADD CA ROOM ID AS INFORMATION ORIGINATOR
  Holon_ID = supplementary_functions:get_my_id(BH),
  DataMap1 = maps:put(<<"information_originator">>, Holon_ID, DataMap),

  %GET DATA1
  {ok,Data1} = base_task_ep:get_data1(ExecutorHandle, BH),
  io:format("~n DATA1 RETRIEVED IN CONVERT CONTROLLED ATMOSPHERE DATA TO DATABASE FORMAT: ~p ~n",[Data1]),

  %ADD TRIAL ID
  Trial_ID = maps:get(<<"trial_id">>,Data1),
  DataMap2 = maps:put(<<"trial_id">>,Trial_ID,DataMap1),

  %ADD TASK TYPE
  Task_Type = maps:get(<<"Task_Type">>,Data1),
  DataMap3 = maps:put(<<"task_type">>, Task_Type, DataMap2),

  io:format("~n CONTROLLED ATMOSPHERE DATA CONVERTED TO DATABASE FORMAT: ~p ~n",[DataMap3]),
  DataMap3.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% SIGNAL FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
extract_map_from_signal([Map | _Rest]) when is_map(Map) ->
  {ok, Map};
extract_map_from_signal([_ | Rest]) ->
  extract_map_from_signal(Rest);
extract_map_from_signal(_) ->
  {error, "No map found in the list"}.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% REFERENCE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reference_to_string(Reference)->
  Binary = term_to_binary(Reference),
  String = binary_to_list(Binary),
%%  io:format("~n REFERENCE:~p CONVERTED TO STRING:~p ~n",[Reference, String]),
  String.

string_to_reference(String)->
  Binary = list_to_binary(String),
  Reference = binary_to_term(Binary),
  io:format("~n STRING:~p CONVERTED TO REFERENCE:~p ~n",[String, Reference]),
  Reference.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TASK ID FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generate_task_id() ->
  Epoch_Time = os:system_time(),
  Random_Number = rand:uniform(100),
  Task_ID = Epoch_Time + Random_Number,
  io:format("~n TASK ID GENERATED: ~p ~n",[Task_ID]),
  Task_ID.

task_id_from_executor_handle(ExecutorHandle) ->
  Task_Shell = base_task_ep:get_shell(ExecutorHandle),
  io:format("~n TASK SHELL:~p ~n RETRIEVED FROM EXECUTOR HANDLE: ~p ~n",[Task_Shell, ExecutorHandle]),
  Task_ID = element(5, Task_Shell),
  io:format("~n TASK ID:~p ~n RETRIEVED FROM TASK SHELL: ~p ~n",[Task_ID, Task_Shell]),
  Task_ID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LINK FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_holon_id_from_promise(Promise)->
  Element_1 = element(4,Promise),
%%  io:format("~n ELEMENT 1 RETRIEVED FROM PROMISE: ~p ~n",[Element_1]),
  Element_2 = element(3,Element_1),
%%  io:format("~n ELEMENT 2 RETRIEVED FROM PROMISE: ~p ~n",[Element_2]),
  Holon_ID = element(3,Element_2),
  io:format("~n HOLON ID RETRIEVED FROM PROMISE: ~p ~n",[Holon_ID]),
  Holon_ID.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% MOVE FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
generate_move_request_for_fruit_pre_trial(BH)->
  %RETRIEVE TRIAL ID
  Trial_ID = base_variables:read(<<"Trial_Info">>,<<"Trial_ID">>,BH),
%%  io:format("~n TRIAL ID: ~p ~n",[Trial_ID]),

  %RETRIEVE ITEM TO BE MOVED
  Item = base_variables:read(<<"Fruit_Info">>,<<"Fruit_Type">>,BH),
%%  io:format("~n ITEM TO BE MOVED: ~p ~n",[Item]),

  %RETRIEVE CURRENT LOCATION
  Current_Location = base_variables:read(<<"Fruit_Info">>,<<"Current_Location">>,BH),
%%  io:format("~n CURRENT LOCATION: ~p ~n",[Current_Location]),

  %RETRIEVE REQUIRED LOCATION
  Required_Location = base_variables:read(<<"Fruit_Info">>,<<"Required_Location">>,BH),
%%  io:format("~n DESIRED LOCATION: ~p ~n",[Desired_Location]),

  %CREATE MOVE REQUEST
  Move_Request = #{<<"trial_id">> =>Trial_ID,<<"item">>=>Item, <<"current_location">> => Current_Location, <<"required_location">> => Required_Location},
  io:format("~n MOVE REQUEST GENERATED: ~p ~n",[Move_Request]),
  Move_Request.

generate_move_request_for_trial(BH)->
  %RETRIEVE TRIAL ID
  Trial_ID = supplementary_functions:get_my_id(BH),
%%  io:format("~n TRIAL ID: ~p ~n",[Trial_ID]),

  %RETRIEVE ITEM TO BE MOVED
  Item = base_variables:read(<<"Fruit_Info">>,<<"Fruit_Type">>,BH),
%%  io:format("~n ITEM TO BE MOVED: ~p ~n",[Item]),

  %RETRIEVE CURRENT LOCATION
  Current_Location = base_variables:read(<<"Fruit_Info">>,<<"Current_Location">>,BH),
%%  io:format("~n CURRENT LOCATION: ~p ~n",[Current_Location]),

  %RETRIEVE REQUIRED LOCATION
  Required_Location = base_variables:read(<<"Fruit_Info">>,<<"Required_Location">>,BH),
%%  io:format("~n DESIRED LOCATION: ~p ~n",[Desired_Location]),

  %CREATE MOVE REQUEST
  Move_Request = #{<<"trial_id">> =>Trial_ID,<<"item">>=>Item, <<"current_location">> => Current_Location, <<"required_location">> => Required_Location},
  io:format("~n MOVE REQUEST GENERATED: ~p ~n",[Move_Request]),
  Move_Request.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% TRIAL DATA FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
get_trial_data(Trial_Type, Trial_ID, BH) ->
  case Trial_Type of
    <<"fruit_only_trial">> ->
      io:format("~n RETRIEVING DATA FOR FRUIT ONLY TRIAL WITH ID: ~p ~n",[Trial_ID]),

      %SEND SIGNAL TO FACILITY MANAGER TYPE FOR FRUIT PROCUREMENT DATA
      RETRIEVE_PROCURE_FRUIT_DATA_WT = bhive:discover_bases(#base_discover_query{id = <<"FACILITY_MANAGER_TYPE">>}, BH), %send a call signal to the facility_manager_guardian_ep
      RETRIEVE_PROCURE_FRUIT_PAYLOAD = Trial_ID,
      [PROCURE_FRUIT_DATA] = base_signal:emit_call_signal(RETRIEVE_PROCURE_FRUIT_DATA_WT, ?RETRIEVE_PROCURE_FRUIT_DATA,RETRIEVE_PROCURE_FRUIT_PAYLOAD,BH),

      %SEND SIGNAL TO OPERATOR TYPE FOR RECEIVE FRUIT DATA
      RETRIEVE_RECEIVE_FRUIT_DATA_WT = bhive:discover_bases(#base_discover_query{id = <<"OPERATOR_TYPE">>}, BH), %send a call signal to the operator_guardian_ep
      RETRIEVE_RECEIVE_FRUIT_PAYLOAD = Trial_ID,
      [RECEIVE_FRUIT_DATA] = base_signal:emit_call_signal(RETRIEVE_RECEIVE_FRUIT_DATA_WT, ?RETRIEVE_RECEIVE_FRUIT_DATA,RETRIEVE_RECEIVE_FRUIT_PAYLOAD,BH),

      %SEND SIGNAL TO OPERATOR TYPE FOR MOVE DATA
      RETRIEVE_MOVE_DATA_WT = bhive:discover_bases(#base_discover_query{id = <<"OPERATOR_TYPE">>}, BH), %send a call signal to the operator_guardian_ep
      RETRIEVE_MOVE_DATA_PAYLOAD = Trial_ID,
      [MOVE_DATA] = base_signal:emit_call_signal(RETRIEVE_MOVE_DATA_WT, ?RETRIEVE_MOVE_DATA,RETRIEVE_MOVE_DATA_PAYLOAD,BH),

      %SEND SIGNAL TO OPERATOR TYPE FOR PERFORM FRUIT PREPARATION DATA
      RETRIEVE_PERFORM_FRUIT_PREPARATION_DATA_WT = bhive:discover_bases(#base_discover_query{id = <<"OPERATOR_TYPE">>}, BH), %send a call signal to the operator_guardian_ep
      RETRIEVE_PERFORM_FRUIT_PREPARATION_PAYLOAD = Trial_ID,
      [PERFORM_FRUIT_PREPARATION_DATA] = base_signal:emit_call_signal(RETRIEVE_PERFORM_FRUIT_PREPARATION_DATA_WT, ?RETRIEVE_PERFORM_FRUIT_PREPARATION_DATA,RETRIEVE_PERFORM_FRUIT_PREPARATION_PAYLOAD,BH),

      %SEND SIGNAL TO CONTROLLED ATMOSPHERE ROOM TYPE FOR COLD STORAGE DATA
      RETRIEVE_COLD_STORAGE_DATA_WT = bhive:discover_bases(#base_discover_query{id = <<"CONTROLLED_ATMOSPHERE_ROOM_TYPE">>}, BH), %send a call signal to the controlled_atmosphere_room_guardian_ep
      RETRIEVE_COLD_STORAGE_DATA_PAYLOAD = #{<<"trial_id">> => Trial_ID, <<"task_type">> => <<"COLD_STORAGE">>},
      [COLD_STORAGE_DATA] = base_signal:emit_call_signal(RETRIEVE_COLD_STORAGE_DATA_WT, ?RETRIEVE_COLD_STORAGE_DATA,RETRIEVE_COLD_STORAGE_DATA_PAYLOAD,BH),


      %CONSTRUCT MAP CONTAINING TRIAL DATA
      Trial_Data = #{<<"procure_fruit_data">> => PROCURE_FRUIT_DATA, <<"receive_fruit_data">> => RECEIVE_FRUIT_DATA,
        <<"move_data">> => MOVE_DATA, <<"perform_fruit_preparation_data">> => PERFORM_FRUIT_PREPARATION_DATA,
        <<"cold_storage_data">> => COLD_STORAGE_DATA},
      io:format("~n TRIAL DATA: ~p ~n RETRIEVED FOR TRIAL WITH ID: ~p ~n",[Trial_Data, Trial_ID]),
      Trial_Data;
    <<"insect_only_trial">> ->
      io:format("~n RETRIEVING DATA FOR INSECT ONLY TRIAL WITH ID: ~p ~n",[Trial_ID]);
    <<"fruit_and_internal_insect_trial">>->
      io:format("~n RETRIEVING DATA FOR FRUIT AND INTERNAL TRIAL WITH ID: ~p ~n",[Trial_ID]);
    <<"fruit_and_external_insect_trial">> ->
      io:format("~n RETRIEVING DATA FOR FRUIT AND EXTERNAL TRIAL WITH ID: ~p ~n",[Trial_ID])
  end.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% CA ROOM FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
convert_to_room_id_binary_to_integer(Room_Id_Binary)->
  << "CONTROLLED_ATMOSPHERE_ROOM_", Number/binary >> = Room_Id_Binary,
  Room_Id_Integer = binary_to_integer(Number),
  Room_Id_Integer.


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% LIST FUNCTIONS %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
reverse_list(List) ->
  reverse_list(List, []).

reverse_list([], Acc) ->
  Acc;
reverse_list([Head | Tail], Acc) ->
  reverse_list(Tail, [Head | Acc]).





