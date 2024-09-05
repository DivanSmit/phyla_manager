%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2024 14:39
%%%-------------------------------------------------------------------
-module(contracting_resource_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
  base_variables:write(<<"measure">>,<<"values">>,[],BH),

  ok.

stop(BH) ->
  ok.

request_start_link(PluginState, ExH, BH) ->

  MyBC = base:get_my_bc(BH),
  MyName = base_business_card:get_name(MyBC),
  PartnerBC = base_link_ep:get_partner_bc(ExH),
  PartnerName = base_business_card:get_name(PartnerBC),
  CurrentTime = binary_to_list(myFuncs:convert_unix_time_to_normal(base:get_origo())),
  io:format("Servant contract: ~p with parent ~p ready to start at ~p~n",[MyName,PartnerName,CurrentTime]),

  {start, nostate}.

request_resume_link(PluginState, ExH, BH) ->
  {cancel, no_state}.

link_start(PluginState, ExH, BH) ->
  io:format("~nLINK TASK IS STARING SERVANT~n"),

  Name = myFuncs:myName(BH),
  {ok, Data1} = base_task_ep:get_schedule_data(ExH, BH),
  Action = maps:get(<<"truAction">>, Data1, none),
  case Action of
    % Based on the instructed action, something needs to happen and then send data to the partner if needed
    none ->
      io:format("No action in data1 for ~p: ~p~n", [Name, Data1]);
    <<"None">> ->
      io:format("No TRU action required for ~p~n", [Name]);
    <<"Store">>->
      io:format("~p needs to store the fruit. ~n", [Name]),
      %% TODO also needs to update the current capacity because values are entered

      FSM_data = #{
        <<"execution">>=>ExH,
        <<"BH">>=> BH,
        <<"Data1">>=>Data1
      },
      Shell = base_task_ep:get_shell(ExH),
      {ok, StateMachinePID} = gen_statem:start_link({global, Shell#task_shell.id}, no_operator_task_FSM, FSM_data, []);
   <<"Measure">>->
     spawn(fun()->
       listen_on_port(9910,ExH,BH)
     end);
    _ ->
      io:format("Invalid TRU action of~p for ~p~n", [Action, Name])
  end,

  {ok, Action}.

link_resume(PluginState, ExH, BH) ->
  erlang:error(not_implemented).

partner_call({<<"AVAILABILITY">>,nothing}, State, ExAgentHandle, BH) ->
  io:format("The servant link has recieved the partner call~n"),
  Reply = #{<<"AVAILABILITY">>=>false},
  {reply, Reply, nostate};

partner_call(Value, State, ExAgentHandle, BH) ->
  io:format("~n PARTNERCALL Value ~p ",[Value]),
  {reply, nothing, nothing}.

partner_signal({<<"CurrentTRU">>, Data}, PluginState, ExH, BH) ->
  io:format("~p received partner signal with Data ~p~n",[myFuncs:myName(BH),Data]),
  base_variables:write(<<"TRU">>,<<"CurrentTRU">>,Data, BH),
  {ok, PluginState}.

link_end(Reason, State, ExAgentHandle, BH) ->
  %% TODO remember to act differently when a task is canceled
  spawn(fun()->
    io:format("State: ~p~n", [State]),
    if
      State == <<"Measure">> ->
        io:format("Going to end the port~n"),
        send_message("localhost", 9910, "stop");
      true -> ok
    end
        end),
  reflect. %Change later to ensure that it also reflects the data for analysis

base_variable_update({<<"TaskStatus">>, Variable, Value}, PluginState, ExH, BH) ->
  io:format("~n The variable has been updated, ~p to ~p~n",[Variable,Value]),
  {ok, no_state}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

listen_on_port(Port,ExH,BH) ->
  {ok, ListenSocket} = gen_tcp:listen(Port, [binary, {packet, 0}, {active, false}, {reuseaddr, true}]),
  io:format("Listening on port ~p~n", [Port]),
  listen(ListenSocket, [], ExH,BH).

listen(ListenSocket, State,ExH,BH) ->
  {ok, Socket} = gen_tcp:accept(ListenSocket),
  {ok, Data} = gen_tcp:recv(Socket, 0),
  case Data of
    <<"stop">> -> gen_tcp:close(Socket),
      State;
    _ ->
      case jsx:decode(Data) of
        {error, _} ->
          io:format("Invalid JSON received: ~p~n", [Data]),
          gen_tcp:close(Socket),
          State;
        JsonValue -> io:format("Received JSON: ~p~n", [JsonValue]),
          case maps:get(<<"name">>, JsonValue) of
            <<"error">> -> % Test case for machine repair
              DataS = #{
                <<"name">>=>myFuncs:myName(BH),
                <<"StartTime">>=> now
              },
              TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"SPAWN_PROCESS_TASK_INSTANCE">>}, BH),
              base_signal:emit_signal(TaskHolons, <<"ScheduleMaintenance">>, DataS, BH),
              base_variables:write(<<"Maintenance">>, <<"Scheduled">>,true,BH),
              State;
            _ -> gen_tcp:close(Socket),
              CurrentTRU = base_variables:read(<<"TRU">>, <<"CurrentTRU">>, BH),
              NewJson = maps:update(<<"name">>, CurrentTRU, JsonValue),
              NewData = [NewJson | State],
              base_task_ep:write_execution_data(#{<<"TRU_Data">> => NewData}, base_link_ep:get_shell(ExH), BH),
              base_variables:write(<<"measure">>, <<"values">>, NewData, BH),
              io:format("New Data: ~p~n", [NewData]),
              listen(ListenSocket, NewData, ExH, BH)
          end

      end
  end.

send_message(Host, Port, JsonData) ->
  case gen_tcp:connect(Host, Port, [binary, {packet, 0}, {active, false}]) of
    {ok, Socket} ->
      gen_tcp:send(Socket, JsonData),
      io:format("Message sent to ~p:~p~n", [Host, Port]),
      gen_tcp:close(Socket),
      ok;
    {error, Reason} ->
      io:format("Failed to connect: ~p~n", [Reason]),
      {error, Reason}
  end.