%%%-------------------------------------------------------------------
%%% @author azhar
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 19. Jul 2023 11:16
%%%-------------------------------------------------------------------
-module(postgresql_functions).
-author("azhar").

%% API
-export([start_up/0,clear_tables/2,delete_table_contents/2 ,write_data_to_postgresql_database/2, connect_to_database/5, close_connection/1, cycle_data_tuple_list/4,
  acquire_data_postgresql/2, transform_data_rows/3, cycle_data_tuple/4, get_last_id_in_room_datas_table/1, acquire_controlled_atmosphere_data_postgresql/2]).

start_up()->
  io:format("~n***************************************~nSTARTUP SEQUENCE INITIATED~n***************************************~n"),
  %CONNECT TO hortgro_phylab_masters_implementation DATABASE
  C_1 = connect_to_database("localhost","postgres","Jeffryson","postgres",5432),

  %CLEAR TABLES IN hortgro_phylab_masters_implementation DATABASE
  clear_tables(C_1, hortgro_phylab_masters_implementation),

  %CLOSE CONNECTION WITH hortgro_phylab_masters_implementation DATABASE
  close_connection(C_1),

  %START SIMULATION PROGRAM
  simulation_program:start().

clear_tables(C,Database)->
  case Database of
    hortgro_phylab_masters_implementation->
      io:format("~n CLEARING TABLES IN THE hortgro_phylab_masters_implementation DATABASE ~n"),
      Tables = ["controlled_atmosphere_room_provide_controlled_atmosphere_data","facility_manager_procure_fruit","operator_move", "operator_perform_fruit_preparation","operator_receive_fruit"];
    atmosphere_control_subsystem->
      io:format("~n CLEARING TABLES IN THE atmosphere_control_subsystem DATABASE ~n"),
      Tables = ["room_datas"]
  end,
  delete_table_contents(C, Tables).

delete_table_contents(C, [Table|Rest]) ->
  %DELETE DATA FROM TABLE
  Query_1 = "DELETE FROM " ++ Table,
  Result_1 = epgsql:squery(C, Query_1),

%%  %RESET THE UID SEQUENCE
  Query_2 = "ALTER SEQUENCE " ++ Table ++ "_row_id_seq RESTART WITH 1",
  Result_2 = epgsql:squery(C,Query_2),

  io:format("~n DELETING THE FOLLOWING TABLES CONTENTS: ~p ~n", [Table]),

  %RECURSIVELY CALL FUNCTION UNTIL ALL TABLES ARE HANDLED
  case Rest == [] of
    %BREAK OUT OF RECURSIVE FUNCTION
    true ->
      ok;
    %CALL FUNCTION AGAIN
    false->
      delete_table_contents(C,Rest)
  end.


write_data_to_postgresql_database(DataMap, Table) ->
  io:format("Connecting to ~p ~n ",[Table]),
  %Connect to the PostgreSQL database
  C = connect_to_database("localhost","postgres","Jeffryson","postgres",5432),

  %%INSERT EMPTY ROW INTO TABLE
  {_,_,_,[{Row_ID}]} = epgsql:squery(C, "INSERT INTO " ++ Table ++ " DEFAULT VALUES RETURNING row_id;"),
  io:format("~n ROW ID OF EMPTY ROW THAT HAS BEEN ADDED: ~p ~n",[Row_ID]),

  %CALL FUNCTION THAT WRITES EACH ELEMENT IN THE DATA TUPLE LIST TO THE APPROPRIATE COLUMN IN THE TABLE
  DataTupleList = maps:to_list(DataMap),
  io:format("~n DATA TUPLE LIST: ~p ~n TO BE WRITTEN TO THE FOLLOWING TABLE: ~p ~n",[DataTupleList,Table]),
  cycle_data_tuple_list(DataTupleList, Table,Row_ID, C),

  %Close connection
  close_connection(C),
  ok.

connect_to_database(Host, Username, Password, Database, Port) ->

%%  %Connect to the PostgreSQL database
%%  {ok, C} = epgsql:connect(#{host => Host,
%%    username => Username,
%%    password => Password,
%%    database => Database,
%%    port => Port
%%  }),

  Something = epgsql:connect(#{host => Host,
    username => Username,
    password => Password,
    database => Database,
    port => Port
  }),

  io:format("~n Something: ~p~n", [Something]),


%%  %% Check if the connection has been established successfully %%
%%  case {ok, C} =:= {ok, C} of
%%    true->
%%      io:format("~n Connection has been established, C: ~p~n", [C]);
%%    false->
%%      io:format("~n Connection failed ~n")
%%  end,
%%DataMap = #{<<"id">>=>1,<<"sugar_content">>=>3,<<"time">>=>12}.
%%  C.
  ok.

close_connection(Pid)->
  io:format("~n Closing connection: ~p ~n",[Pid]),
  epgsql:close(Pid).

cycle_data_tuple_list([DataTuple|Rest], Table, Row_ID, C)->
  io:format("~n DATA TUPLE: ~p ~n TO BE WRITTEN TO THE FOLLOWING TABLE: ~p ~n",[DataTuple, Table]),

  %EXTRACT COLUMN NAME FROM TUPLE
  Column = binary_to_list(element(1, DataTuple)),
  io:format("~n COLUMN NAME: ~p ~n",[Column]),

  %EXTRACT VALUE FROM TUPLE
  Value = binary_to_list(element (2, DataTuple)),
  io:format("~n DATA VALUE: ~p ~n",[Value]),

  %WRITE VALUE TO APPROPRIATE COLUMN IN THE TABLE
  Query = "UPDATE \"" ++ Table ++ "\"\nSET \"" ++ Column ++ "\" = '" ++ Value ++ "'\nWHERE \"row_id\" = '" ++ binary_to_list(Row_ID) ++ "' ;",

  Result = epgsql:squery(C, Query),
  io:format("~n RESULT OF DATABASE QUERY: ~p ~n",[Result]),

  %RECURSIVELY CALL FUNCTION UNTIL ALL TUPLES ARE HANDLED
  case Rest == [] of
    %BREAK OUT OF RECURSIVE FUNCTION
    true ->
      ok;
    %CALL FUNCTION AGAIN
    false->
      cycle_data_tuple_list(Rest, Table, Row_ID, C)
  end.

%Change to acquire trial data
acquire_data_postgresql(Table, Trial_ID) ->
  %connect to the PostgreSQL database
  C = connect_to_database("localhost","postgres","Petchmorakot786","hortgro_phylab_masters_implementation",5432),

  %%Acquire all the trial data from a given table
  Query = "SELECT * FROM " ++ Table ++ " WHERE trial_id = '" ++ binary_to_list(Trial_ID) ++ "' ;",
%%  Query = "SELECT * FROM " ++ Table ++ ";",
  {ok, MetaData, Data} = epgsql:squery(C, Query),
  io:format("~n FETCHING DATA FROM TABLE:" ++ Table ++ " ~n"),

  %close connection
  close_connection(C),

  {MetaData, Data}.

transform_data_rows(MetaData, [DataTuple | Rest],Transformed_Data) ->
  %Print each row of data
  io:format("~n-------------------------------------------
  ~n ~p ~n ----------------------------------------- ~n",[DataTuple]),

  %Transform the data row into a map and print it again
  DataMap = cycle_data_tuple(MetaData, DataTuple, #{},1),
  io:format("~n-------------------------------------------
  ~n ~p ~n ----------------------------------------- ~n",[DataMap]),

  %Append new data map to the transformed data list
  Transformed_Data_New = lists:append(Transformed_Data,[DataMap]),

  %%Recursively handle the rest of the list
  case Rest == [] of
    true ->
      %Break out of recursive function
      Transformed_Data_New;
    false ->
      %Run function again
      transform_data_rows(MetaData, Rest,Transformed_Data_New)
  end.

cycle_data_tuple(MetaData, DataTuple, Map, N)->
  Tuple_Size = tuple_size(DataTuple),
  case N =< Tuple_Size of
    true ->
      Key = element(2, lists:nth(N,MetaData)),
      Value = element(N, DataTuple),
      DataMap = maps:put(Key,Value,Map),
      cycle_data_tuple(MetaData, DataTuple, DataMap, N+1);
    false->
      Map
  end.

get_last_id_in_room_datas_table(Room_Id_Integer) ->
  %connect to the PostgreSQL database
  C = connect_to_database("localhost","postgres","Petchmorakot786","atmosphere_control_subsystem",5432),

  %Acquire the last Id in the database table for a given room id
  Query = "SELECT \"Id\" FROM room_datas WHERE \"Room_Id\" = " ++ integer_to_list(Room_Id_Integer) ++ " ORDER BY \"Id\" DESC LIMIT 1",
  {ok, _ , [{Last_ID_Binary}]} = epgsql:squery(C, Query),
  Last_ID = binary_to_integer(Last_ID_Binary),
  io:format("~n Last ID: ~p ~n",[Last_ID]),

  %close connection
  close_connection(C),

  Last_ID.

acquire_controlled_atmosphere_data_postgresql(Last_ID, Room_Id_Integer)->
  %CONNECT TO atmosphere_control_subsystem DATABASE
  C = connect_to_database("localhost","postgres","Petchmorakot786","atmosphere_control_subsystem",5432),

  %Acquire the New Id in the database table for a given room id
  Query_1 = "SELECT \"Id\" FROM room_datas WHERE \"Room_Id\" = " ++ integer_to_list(Room_Id_Integer) ++ " ORDER BY \"Id\" DESC LIMIT 1",
  {ok, _ , [{New_ID_Binary}]} = epgsql:squery(C, Query_1),
  New_ID = binary_to_integer(New_ID_Binary),
  io:format("~n Last ID: ~p ~n",[Last_ID]),
  io:format("~n New ID: ~p ~n",[New_ID]),

  {ok, MetaData, Data} = case New_ID > Last_ID of
    true ->
      Query_2 = "SELECT \"Id\", \"O2\", \"Co2\", \"Humidity\", \"O2Setpoint\", \"TimeStamp\", \"T1\", \"T2\", \"T3\"
           FROM room_datas WHERE \"Id\" > " ++ integer_to_list(Last_ID) ++
        " AND \"Room_Id\" = " ++ integer_to_list(Room_Id_Integer) ++ " ORDER BY \"Id\" ASC",
      epgsql:squery(C, Query_2);
    false ->
      {ok, [],[]}
  end,

  %CLOSE CONNECTION
  close_connection(C),

  {New_ID, MetaData, Data}.

