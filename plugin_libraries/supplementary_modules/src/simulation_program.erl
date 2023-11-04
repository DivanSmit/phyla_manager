%%%-------------------------------------------------------------------
%%% @author azhar
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Aug 2023 09:46
%%%-------------------------------------------------------------------
-module(simulation_program).
-author("azhar").

%% API
-export([test_bat_file/0, start/0, write_data_from_csv_file_to_postgresql_database/4]).

test_bat_file()->
  io:format("~n BAT FILE WORKING !!!!!! ~n"),
  ok.

start()->
  io:format("~n***************************************~nSIMULATION PROGRAM STARTED~n***************************************~n"),

  %CONNECT TO THE atmosphere_control_subsystem DATABASE
  C = postgresql_functions:connect_to_database("localhost","postgres","Petchmorakot786","atmosphere_control_subsystem",5432),

  %OPEN CSV FILE
  {ok, File} = file:open("C:/Users/azhar/Desktop/Hortgro_Phylab_Masters_Implementation/sample_data/ca_room_1/CA_1.csv",[read,raw,binary]),

  %START WRITING DATA FROM CSV TO POSTGRESQL DATABASE ONE LINE AT A TIME
  Table = "room_datas",
  N = 0,
  write_data_from_csv_file_to_postgresql_database(C, Table, File, N),

  %CLOSE FILE
  file:close(File),

  %CLOSE CONNECTION
  postgresql_functions:close_connection(C).

write_data_from_csv_file_to_postgresql_database(C, Table, File, N)->
  io:format("~n N VALUE: ~p ~n",[N]),
  N_New = N+1,
  case file:read_line(File) of
    {ok, Line} ->
      case N of
        0 ->
          io:format("~n IGNORING THE FOLLOWING LINE FROM THE CSV FILE WHEN WRITING TO THE POSTGRESQL DATABASE: ~n ~p ~n",[Line]),
          write_data_from_csv_file_to_postgresql_database(C,Table,File,N_New);
        _ ->
          %WRITE LINE FROM CSV FILE TO THE POSTGRESQL DATABASE
          io:format("~n WRITING THE FOLLOWING LINE FROM THE CSV FILE TO THE POSTGRESQL DATABASE: ~n ~p ~n",[Line]),

          %EXTRACT VALUES FROM LINE
          LineStr = binary_to_list(Line),
          [Id, O2, Co2, Nh3, Humidity, RoomPressure, Ethylene, O2Setpoint, Patched, DataUploaded, Hv1, Hv2, Hv3, Hv4, O2SCR, N2,Ozone,
            EF, TempSetpoint, DanfossTemp, TimeStamp, T1, T2, T3_Last] = string:tokens(LineStr, ";"),

          %REMOVE \n from last columns value
          T3 = string:substr(T3_Last, 1, length(T3_Last) - 1),

          %ADD ROOM ID
          Room_Id_Integer = 1,

          %CONVERT DATA TO CORRECT FORMAT TO BE WRITTEN TO THE POSTGRESQL DATABASE
          O2_Numeric = list_to_float(string:join(string:tokens(O2, ","), ".")),
          Co2_Numeric = list_to_float(string:join(string:tokens(Co2, ","), ".")),
          Nh3_Numeric = list_to_float(string:join(string:tokens(Nh3, ","), ".")),
          Humidity_Numeric = list_to_float(string:join(string:tokens(Humidity, ","), ".")),
          RoomPressure_Numeric = list_to_float(string:join(string:tokens(RoomPressure, ","), ".")),
          Ethylene_Numeric = list_to_float(string:join(string:tokens(Ethylene, ","), ".")),
          O2Setpoint_Numeric = list_to_float(string:join(string:tokens(O2Setpoint, ","), ".")),
          Hv1_Numeric = list_to_float(string:join(string:tokens(Hv1, ","), ".")),
          Hv2_Numeric = list_to_float(string:join(string:tokens(Hv2, ","), ".")),
          Hv3_Numeric = list_to_float(string:join(string:tokens(Hv3, ","), ".")),
          Hv4_Numeric = list_to_float(string:join(string:tokens(Hv4, ","), ".")),
          O2SCR_Numeric = list_to_float(string:join(string:tokens(O2SCR, ","), ".")),
          N2_Numeric = list_to_float(string:join(string:tokens(N2, ","), ".")),
          Ozone_Numeric = list_to_float(string:join(string:tokens(Ozone, ","), ".")),
          EF_Numeric = list_to_float(string:join(string:tokens(EF, ","), ".")),
          TempSetpoint_Numeric = list_to_float(string:join(string:tokens(TempSetpoint, ","), ".")),
          DanfossTemp_Numeric = list_to_float(string:join(string:tokens(DanfossTemp, ","), ".")),
          T1_Numeric = list_to_float(string:join(string:tokens(T1, ","), ".")),
          T2_Numeric = list_to_float(string:join(string:tokens(T2, ","), ".")),
          T3_Numeric = list_to_float(string:join(string:tokens(T3, ","), ".")),

          %PRINT THE VALUES
          io:format("~n Id :~p ~n", [Id]),
          io:format("~n O2 :~p ~n", [O2_Numeric]),
          io:format("~n Co2 :~p ~n", [Co2_Numeric]),
          io:format("~n Nh3 :~p ~n", [Nh3_Numeric]),
          io:format("~n Humidity :~p ~n", [Humidity_Numeric]),
          io:format("~n RoomPressure :~p ~n", [RoomPressure_Numeric]),
          io:format("~n Ethylene :~p ~n", [Ethylene_Numeric]),
          io:format("~n O2Setpoint :~p ~n", [O2Setpoint_Numeric]),
          io:format("~n Patched :~p ~n", [Patched]),
          io:format("~n DataUploaded :~p ~n", [DataUploaded]),
          io:format("~n Hv1 :~p ~n", [Hv1_Numeric]),
          io:format("~n Hv2 :~p ~n", [Hv2_Numeric]),
          io:format("~n Hv3 :~p ~n", [Hv3_Numeric]),
          io:format("~n Hv4 :~p ~n", [Hv4_Numeric]),
          io:format("~n O2SCR :~p ~n", [O2SCR_Numeric]),
          io:format("~n N2 :~p ~n", [N2_Numeric]),
          io:format("~n Ozone :~p ~n", [Ozone_Numeric]),
          io:format("~n EF :~p ~n", [EF_Numeric]),
          io:format("~n TempSetpoint :~p ~n", [TempSetpoint_Numeric]),
          io:format("~n DanfossTemp :~p ~n", [DanfossTemp_Numeric]),
          io:format("~n TimeStamp :~p ~n", [TimeStamp]),
          io:format("~n T1 :~p ~n", [T1_Numeric]),
          io:format("~n T2 :~p ~n", [T2_Numeric]),
          io:format("~n T3 :~p ~n", [T3_Numeric]),
          io:format("~n Room_Id: ~p ~n", [Room_Id_Integer]),


          %WRITE DATA TO THE POSTGRESQL DATABASE
          Query = "INSERT INTO " ++ Table ++ " (\"Id\", \"O2\", \"Co2\", \"Nh3\", \"Humidity\", \"RoomPressure\", \"Ethylene\", \"O2Setpoint\", \"Hv1\", \"Hv2\", \"Hv3\", \"Hv4\", \"O2SCR\", \"N2\", \"Ozone\", \"EF\", \"TempSetpoint\", \"DanfossTemp\", \"T1\", \"T2\", \"T3\", \"Room_Id\", \"TimeStamp\", \"Patched\", \"DataUploaded\") VALUES (" ++
            Id ++ ", " ++ float_to_list(O2_Numeric) ++ ", " ++ float_to_list(Co2_Numeric) ++ ", " ++ float_to_list(Nh3_Numeric) ++ ", " ++
            float_to_list(Humidity_Numeric) ++ ", " ++ float_to_list(RoomPressure_Numeric) ++ ", " ++ float_to_list(Ethylene_Numeric) ++ ", " ++
            float_to_list(O2Setpoint_Numeric) ++ ", " ++ float_to_list(Hv1_Numeric) ++ ", " ++ float_to_list(Hv2_Numeric) ++ ", " ++
            float_to_list(Hv3_Numeric) ++ ", " ++ float_to_list(Hv4_Numeric) ++ ", " ++ float_to_list(O2SCR_Numeric) ++ ", " ++
            float_to_list(N2_Numeric) ++ ", " ++ float_to_list(Ozone_Numeric) ++ ", " ++ float_to_list(EF_Numeric) ++ ", " ++
            float_to_list(TempSetpoint_Numeric) ++ ", " ++ float_to_list(DanfossTemp_Numeric) ++ ", " ++ float_to_list(T1_Numeric) ++ ", " ++
            float_to_list(T2_Numeric) ++ ", " ++ float_to_list(T3_Numeric) ++ ", " ++ integer_to_list(Room_Id_Integer) ++ ", '" ++ TimeStamp ++ "', '" ++
            Patched ++ "', '" ++ DataUploaded ++ "');",
          Result = epgsql:squery(C, Query),
          io:format("~n LINE WRITTEN FROM CSV TO POSTGRESQL DATBASE WITH THE FOLLOWING RESULT: ~p ~n",[Result]),

          %WAIT 60 SECONDS BEFORE WRITING NEXT LINE
          timer:sleep(60000),
          write_data_from_csv_file_to_postgresql_database(C, Table, File, N_New)
      end;
    eof ->
      io:format("~n END OF CSV FILE REACHED ~n")
  end.




