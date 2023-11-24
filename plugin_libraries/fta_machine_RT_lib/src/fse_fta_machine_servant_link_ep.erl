%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 01. Nov 2023 18:10
%%%-------------------------------------------------------------------
-module(fse_fta_machine_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, handle_call/4, base_variable_update/4]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_start_link(PluginState, ExH, BH) ->
  io:format("The fta servant link has requested to start ~n "),
  {wait, no_state}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->

  %% Insert functionality here
  %%------------------------------------------
  io:format("FTA machine is measuring the data ~n "),
  Port = 9910,
  {ok, ListenSocket} = gen_tcp:listen(Port, [{active, false}, {reuseaddr, true}]),
  io:format("Server listening on port ~p~n", [Port]),
  accept_connections(ListenSocket, [], ExH,BH),
  io:format("The values have been measured ~n "),
  %%------------------------------------------

  {ok, no_state}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call({<<"AVAILABILITY">>,nothing}, State, ExAgentHandle, BH) ->
  io:format("The servant link has recieved the partner call~n"),

  Reply = #{<<"AVAILABILITY">>=>false},
  {reply, Reply, nostate};

partner_call(Value, State, ExAgentHandle, BH) ->
  io:format("~n PARTNERCALL Value ~p ",[Value]),
  {reply, nothing, nothing}.

partner_signal(Cast, State, ExAgentHandle, BH) ->
  erlang:error(not_implemented).

link_end(Reason, State, ExAgentHandle, BH) ->
  io:format("THe link is finished~n"),
  discard.

handle_call(Call, TaskState, ExAgentHandle, BH) ->
  erlang:error(not_implemented).

handle_message(Cast, TaskState, ExAgentHandle, BH) ->
  io:format("~n MESSAGE Value ~p ",[Cast]),
  {ok, nothing}.

base_variable_update(_, PluginState, ExH, BH) ->
  erlang:error(not_implemented).

%%Custom tasks here -------------------------------------------------------------------->

accept_connections(ListenSocket, Values,Ex, BH) when length(Values) < 6 ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  io:format("Accepted a new connection~n"),
  spawn(fun() -> handle_connection(Socket, Values, Ex, BH) end),
  accept_connections(ListenSocket, Values, Ex,BH);

accept_connections(_, Values,Ex, BH) when length(Values) == 6 ->
  io:format("All six values received: ~p~n", [lists:flatten(Values)]).

handle_connection(Socket, Values, Ex, BH) ->
  case gen_tcp:recv(Socket, 0) of
    {ok, ReceivedData} ->
      add_to_BASE_variable(ReceivedData,Ex, BH),
      io:format("Received: ~s~n", [ReceivedData]),
      spawn(fun()->
        DataMap = #{<<"id">>=>length(Values)+1,<<"sugar_content">>=>ReceivedData,<<"time">>=>base:get_origo()},
        io:format("Data ~p~n",[DataMap]),
        postgresql_functions:write_data_to_postgresql_database(DataMap,"Test1")
            end),
      NewValues = Values ++ [ReceivedData],

      handle_connection(Socket, NewValues,Ex, BH);
    {error, closed} ->
      io:format("Connection closed~n");
    {error, Reason} ->
      io:format("Error: ~p~n", [Reason])
  end.

add_to_BASE_variable(Value, Ex,BH)->
  OldValues = base_variables:read(<<"MEASUREMENTS">>, <<"values">>, BH),
  case OldValues of
    no_entry ->
      io:format("First entry~n"),
      base_variables:write(<<"MEASUREMENTS">>, <<"values">>, [Value], BH);
    _ ->
      NewList = [Value | OldValues],
      io:format("Values: ~p~n", [NewList]),
      base_variables:write(<<"MEASUREMENTS">>, <<"values">>, NewList, BH)
  end,

  if
    length(OldValues) >= 5 ->
      io:format("Ending the task~n"),
      base_task_ep:end_task(Ex, end_task, BH);
    true -> ok
  end.