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
  io:format("Starting a activity servant reflection for ~p~n",[myFuncs:myName(BH)]),

  Shell = base_task_rp:get_shell(ReflectorHandle),
  StartTime = Shell#task_shell.tstart,
  EndTime = Shell#task_shell.tend,
  Duration = EndTime - StartTime,

  Type = base_attributes:read(<<"meta">>,<<"processType">>,BH),

  Task = base_biography:get_task(Shell,BH),
  Meta = Task#base_task.meta,
  BC = Meta#base_contract.master_bc,
  ParentName = base_business_card:get_name(BC),

  AllTasks = base_biography:get_all_tasks(BH),
  ChildrenNamesBIN = myFuncs:extract_partner_names(AllTasks,servant),
  ChildrenNames = lists:delete(myFuncs:myName(BH), ChildrenNamesBIN),

  TRUs = tru:current(base_variables:read(<<"TRU">>,<<"List">>,BH)),

  % Send data to Type
  MyBC = base:get_my_bc(BH),
  MyID = MyBC#business_card.identity,
  Tax = MyID#identity.taxonomy,
  TypeType = Tax#base_taxonomy.base_type_code,

  TaskHolons = bhive:discover_bases(#base_discover_query{name = TypeType}, BH),

  StoreData = case TypeType of
                <<"PROCESS_STEP_TYPE">> ->
                  Action = base_attributes:read(<<"meta">>, <<"truAction">>,BH),
                  #{
                    <<"name">> => myFuncs:myName(BH),
                    <<"type">> => Type,
                    <<"parent">> => ParentName,
                    <<"startunix">> => integer_to_binary(StartTime),
                    <<"endunix">> => integer_to_binary(EndTime),
                    <<"duration">> => float_to_binary(Duration / 1000, [{decimals, 2}]),
                    <<"resource">> => jsx:encode(ChildrenNames),
                    <<"action">> => Action,
                    <<"trus">>=> jsx:encode(TRUs)
                  };
                <<"PROCESS_TASK_TYPE">> ->
                  #{
                    <<"name">> => myFuncs:myName(BH),
                    <<"type">> => Type,
                    <<"parent">> => ParentName,
                    <<"startunix">> => integer_to_binary(StartTime),
                    <<"endunix">> => integer_to_binary(EndTime),
                    <<"duration">> => float_to_binary(Duration / 1000, [{decimals, 2}]),
                    <<"resource">> => jsx:encode(ChildrenNames),
                    <<"trus">>=> jsx:encode(TRUs)
                  }
              end,

  base_signal:emit_signal(TaskHolons, <<"STORE_DATA">>, StoreData, BH),
  ok.