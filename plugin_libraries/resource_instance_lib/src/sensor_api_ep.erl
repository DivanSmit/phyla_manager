%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 08. Jul 2024 17:41
%%%-------------------------------------------------------------------
-module(sensor_api_ep).
-author("LENOVO").
-behaviour(base_task_ep).
%% API
-export([init/2, stop/1, request_start/2, task_cancel/4, request_resume/2, start_task/3, resume_task/3, base_variable_update/4, end_task/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_start(ExecutorHandle, BH) ->
  {start_task,no_state}.

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  ok.

request_resume(ExecutorHandle, BH) ->
  ok.

start_task(TaskState, ExecutorHandle, BH) ->

  try
    {ok, SensorData} = base_task_ep:get_schedule_data(ExecutorHandle,BH),

    URL = "http://localhost:5000/api",
    Headers = [{"Content-Type", "application/json"}],
    {ok,Data} = bason:map_to_json(#{<<"message">> => maps:get(<<"type">>, SensorData)}),
    {ok, {{"HTTP/1.1", 200, "OK"}, _Headers, Body}} = httpc:request(post, {URL, Headers, "application/json", Data}, [], []),
%%  {Response, Values} = Body,
    Data_Map = bason:json_to_map(list_to_binary(Body)),

    base_task_ep:write_execution_data(
      maps:merge(Data_Map, SensorData),
      base_link_ep:get_shell(ExecutorHandle),
      BH),

    {end_task, reflect, complete}
  catch
      _:Error  -> io:format("Sensor API ERROR: http://localhost:5000/api~n"),
        {end_task, discard, error}
  end.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

end_task(TaskState, ExecutorHandle, BH) ->
  ok.