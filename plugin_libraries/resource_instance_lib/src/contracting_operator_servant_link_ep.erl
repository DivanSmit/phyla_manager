%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2024 14:39
%%%-------------------------------------------------------------------
-module(contracting_operator_servant_link_ep).
-author("LENOVO").
-behaviour(base_link_ep).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_start_link/3, request_resume_link/3, link_start/3, link_resume/3, partner_call/4, partner_signal/4, link_end/4, base_variable_update/4]).


init(Pars, BH) ->
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
  base_variables:write(<<"TaskStatus">>, <<"TRU">>, [], BH),
  base_variables:subscribe(<<"TaskStatus">>, <<"TRU">>, self(), BH),

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
    <<"Measure">> ->
      io:format("~p needs to measure the fruit~n", [Name]);
%%      io:format("~p received partner reply: ~p~n", [Name, Data]);
    <<"Move">> ->
      io:format("~p needs to collect the TRU~n", [Name]);

    <<"Transform">> ->
      io:format("~p needs to Transform the TRU~n", [Name]);
    %% tru:change_tru(In, Out, OriginalMap)
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
  reflect. %Change later to ensure that it also reflects the data for analysis

base_variable_update({<<"TaskStatus">>, <<"TRU">>, Value}, PluginState, ExH, BH) ->
  io:format("~n The TRU has been updated to ~p~n", [Value]),
  case PluginState of
    <<"Transform">> ->
      PartnerBC = base_link_ep:get_partner_bc(ExH),
      Data = #{
        <<"name">> => myFuncs:myName(BH),
        <<"type">> => <<"apple">>,
        <<"barcodes">> => Value,
        <<"process">> => base_business_card:get_name(PartnerBC)
      },
      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"TRU_INSTANCE">>}, BH),
      [TRUs] = base_signal:emit_request(TaskHolons, <<"NEW">>, Data, BH),
      io:format("TRUS: ~p~n", [TRUs]),

      base_link_ep:signal_partner(<<"New_TRUs">>, TRUs, ExH);
    <<"Measure">>->
      base_link_ep:signal_partner(<<"CurrentTRU">>, hd(Value), ExH);
    _ ->
      TaskHolons = bhive:discover_bases(#base_discover_query{capabilities = <<"TRU_INSTANCE">>}, BH),
      [TRUs] = base_signal:emit_request(TaskHolons, <<"GetTRUs">>, Value, BH),
      io:format("TRUs working on: ~p~n",[TRUs]),
      ok
  end,
  {ok, PluginState}.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%%% TODO Remove once testing is done
%%measure(TRUs) ->
%%  File = "C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/operator_RT_lib/src/testTRUdata.csv",
%%  Data = myFuncs:csv_to_maps(File),
%%
%%  lists:foldl(fun(Elem, Acc)->
%%    Map = #{
%%      <<"name">>=>Elem,
%%      <<"fruittype">>=><<"apple">>,
%%      <<"weight">>=>float_to_binary(random:uniform()*3+12.0,[{decimals, 2}]),
%%      <<"colorScore">> => integer_to_binary(rand:uniform(6)),
%%      <<"amount">>=><<"12">>,
%%      <<"harvestdate">>=><<"2024/07/14">>
%%    },
%%    Acc++[Map]
%%  end, [], TRUs).
%%
%%%%  lists:foldl(fun({Map, Index}, Acc) ->
%%%%    UpdatedMap = maps:update(<<"name">>, lists:nth(Index, TRUs), Map),
%%%%    Acc ++ [UpdatedMap]
%%%%              end, [], lists:zip(Data, lists:seq(1, length(Data)))).