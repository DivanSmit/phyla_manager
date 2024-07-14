%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 14. Jul 2024 22:30
%%%-------------------------------------------------------------------
-module(contracting_servant_link_rp).
-author("LENOVO").
-behaviour(base_task_rp).
-include("../../../base_include_libs/base_terms.hrl").
%% API
-export([init/2, stop/1, request_reflection/2, start_reflection/3]).

init(Pars, BH) ->
  ok.

stop(BH) ->
  erlang:error(not_implemented).

request_reflection(ReflectorHandle, BH) ->
  {start_reflection, state}.

start_reflection(PluginState, ReflectorHandle, BH) ->
  io:format("Starting a reflection~n"),

  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = Shell#task_shell.tstart,
  EndTime = Shell#task_shell.tend,
  Duration = EndTime - StartTime,
  io:format("Duration: ~p~n",[Duration]),

%%  {ok,Requirements} = base_task_rp:get_schedule_data(ReflectorHandle,BH),

  Type = base_attributes:read(<<"meta">>,<<"processType">>,BH),
  io:format("Type: ~p~n",[Type]),


  Task = base_biography:get_task(Shell,BH),
  Meta = Task#base_task.meta,
  BC = Meta#base_contract.master_bc,
  ParentName = base_business_card:get_name(BC),
  io:format("ParentName: ~p~n",[ParentName]),

  AllTasks = base_biography:get_all_tasks(BH),
  ChildrenNamesBIN = myFuncs:extract_partner_names(AllTasks,servant),
  ChildrenNames = lists:foreach(fun(X)->binary_to_list(X) end, ChildrenNamesBIN),
  io:format("ChildrenNames: ~p~n",[ChildrenNamesBIN]),

  % Send data to Type
  MyBC = base:get_my_bc(BH),
  MyID = MyBC#business_card.identity,
  io:format("ID: ~p~n",[MyID]),

  Tax = MyID#identity.taxonomy,
  io:format("Tax: ~p~n",[Tax]),

  TypeType = Tax#base_taxonomy.base_type_code,
  io:format("Type: ~p~n",[TypeType]),

  TaskHolons = bhive:discover_bases(#base_discover_query{name = TypeType}, BH),
  io:format("Targets: ~p~n",[TaskHolons]),

  Reply = base_signal:emit_signal(TaskHolons, <<"STORE_DATA">>,
    #{
      <<"name">> => myFuncs:myName(BH),
      <<"type">>=> Type,
      <<"parent">>=> ParentName,
      <<"startUnix">>=> integer_to_binary(StartTime),
      <<"endUnix">> => integer_to_binary(EndTime),
      <<"duration">> => float_to_binary(Duration/1000,[{decimals, 2}]),
      <<"resource">> => ChildrenNamesBIN
    },
    BH),
    io:format("SIngal: ~p~n",[Reply]),
  ok.