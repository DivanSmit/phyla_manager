%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jul 2024 17:40
%%%-------------------------------------------------------------------
-module(sensor_api_sp).
-author("LENOVO").
-behaviour(base_task_sp).
%% API
-export([init/2, stop/1]).


init(_Pars, BH) ->
  ListOfSensors = base_attributes:read(<<"attributes">>, <<"sensors">>, BH),

%%  {
%%    "type": "temperature",
%%    "frequency": 1000,
%%    "max": 30
%%  }

  lists:foldl(fun(X,Acc)->
    handle_spawn_request(X,BH)
  end, [], ListOfSensors),
  ok.

stop(_BH) ->
  ok.

handle_spawn_request(SensorData, BH)->

  Tsched = base:get_origo(),
  Type = <<"sensor_api">>,
  ID = make_ref(),
  Data1 = SensorData,
  base_task_sp:schedule_task(Tsched,Type, ID, Data1, BH),

  Time = maps:get(<<"frequency">>, SensorData),

  spawn(fun()->
    timer:sleep(Time),
    handle_spawn_request(SensorData, BH)
  end),
  ok.