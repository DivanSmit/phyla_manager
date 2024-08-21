%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 05. Oct 2023 11:52
%%%-------------------------------------------------------------------
-module(fta_type_info_handler_ep).
-author("LENOVO").
-behaviour(base_receptor).
%% API
-export([init/2, stop/1, handle_signal/3, handle_request/4]).


init(Pars, BH) ->

  TableName1 = "tru_measurements",
  Columns1 = [
    {"unix", "bigint"},
    {"process", "text"},
    {"resource", "text"},
    {"name", "text"},
    {"fruittype", "text"},
    {"weight", "numeric"},
    {"amount", "numeric"},
    {"harvestdate", "text"}
  ],
  base_variables:write(list_to_binary(TableName1), <<"columns">>, Columns1, BH),
  try
    timer:sleep(100),
    postgresql_functions:create_new_table(TableName1, Columns1)
  catch
    _:_ ->
      try
        io:format("Trying to create ~p again~n", [TableName1])
      catch
        _:_ -> io:format("################POSTGRES ERROR###################~n~p cannot be opended~n~n", [TableName1])
      end
  end,

  ok.

stop(BH) ->
  ok.

handle_signal(<<"TRU_Data">>, Data, BH) ->
  Result = postgresql_functions:write_data_to_postgresql_database(Data, "tru_measurements"),
  case Result of
    ok -> ok;
    error -> io:format("Error when trying to write to DB:~nData: ~p~n", [Data])
  end,
  ok.

handle_request(<<"SPAWN_FTA_MACHINE_INSTANCE">>,Payload, FROM, BH)->

  IDInt = rand:uniform(1000),
  ID = integer_to_binary(IDInt),
  Name = list_to_binary("FTA_machine_" ++ integer_to_list(IDInt)),
  io:format("Spawn request recieved of ~p~n",[Name]),

  {ok, Recipe} = fta_machine_guardian_sp:generate_instance_recipe(Name, ID, BH),
  Tsched = base:get_origo(),
  Data1 = no_data,
  spawn(fun()->
    base_guardian_sp:schedule_instance_guardian(Tsched,Recipe,Data1,BH)
        end),
  Reply = #{<<"name">>=>Name},
  {reply, Reply};

handle_request(<<"INFO">>, <<"InstanceCapabilities">>, From, BH)->
  Capabilities = base_attributes:read(<<"INSTANCE">>,<<"CAPABILITIES">>,BH),
  {reply,Capabilities}.
