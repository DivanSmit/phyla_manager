%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2024, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 12. Jun 2024 14:37
%%%-------------------------------------------------------------------
-module(contracting_room_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
-include("../../../base_include_libs/base_terms.hrl").

%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).

init(Pars, BH) ->
  base_attributes:write(<<"TaskDurations">>,<<"contractingOp">>,60000,BH),
  base_attributes:write(<<"TaskDurationList">>,<<"contractingOp">>,[60000],BH),
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal([Requirements], PluginState, NegH, BH) ->
%%  io:format("~p received requirements: ~p~n",[myFuncs:myName(BH), Requirements]),
  StartTime = maps:get(<<"AVAILABILITY">>,Requirements),
  Change = maps:get(<<"action">>, Requirements),
  TaskDuration = maps:get(<<"duration">>, Requirements),
  {Result, _} = check_my_capacity(StartTime, Change, BH),

  case Result of
    true->
      Proposal = #{<<"proposal">>=>accept,
        <<"startTime">>=>StartTime,
        <<"endTime">>=> StartTime+TaskDuration},
      {proposal,Proposal,maps:merge(#{<<"action">>=>Change, <<"startTime">>=>StartTime}, Requirements)};
    false-> {refuse,not_qualified}
  end.

proposal_accepted(PluginState, NegH, BH) ->

  % This should only happen once the task is completed
%%  CurrentCap = base_variables:read(<<"current_Capacity">>,<<"value">>, BH),
%%  Change = maps:get(<<"action">>,PluginState),
%%  base_variables:write(<<"current_Capacity">>,<<"value">>, CurrentCap+ Change,BH),

  Tsched = maps:get(<<"startTime">>, PluginState),
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = PluginState,
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________

check_my_capacity(StartTime, Change,BH)-> % returns {FinalStatus, FinalCapacity}
  CurrentCap = base_variables:read(<<"current_Capacity">>, <<"value">>, BH),
  MaxCap = base_attributes:read(<<"attributes">>, <<"capacity">>, BH),
  AllTasks = base_schedule:get_all_tasks(BH),
  BaseTasks = maps:values(AllTasks),

%%  io:format("~p has currentCap: ~p and Max: ~p and schedLen of ~p~n", [myFuncs:myName(BH), CurrentCap, MaxCap, length(BaseTasks)]),
  {Stat, Capis, _} = case BaseTasks of
                       [] ->
                         Cap1 = Change + CurrentCap,
%%                         io:format("Cap1 = ~p~n",[Cap1]),
                         if
                           Cap1 > MaxCap -> {false, Cap1, none};
                           Cap1 < 0 -> {false, Cap1, none};
                           true -> {true, Cap1, none}
                         end;
                       _ ->
                         lists:foldl(fun(Elem, {Status, Total, Added}) ->

                           ScheduleData = Elem#base_task.data1,
                           Shell = Elem#base_task.task_shell,
                           Tsched = Shell#task_shell.tsched,
                           Value = maps:get(<<"action">>, ScheduleData, 0),

                           Cap1 = Total + Value,
%%                           io:format("Cap1 second = ~p~n",[Cap1]),
%%                           io:format("Start: ~p and sched: ~p~n",[StartTime,Tsched]),
                           Cap = if
                                   StartTime >= Tsched andalso not Added ->
                                     Cap1 + Change;
                                   true -> Cap1
                                 end,
                           if
                             Cap > MaxCap -> {false, Cap, Added};
                             Cap < 0 -> {false, Cap, Added};
                             true -> {Status, Cap, Added}
                           end
                                     end, {true, CurrentCap, false}, BaseTasks)
                     end,


%%  io:format("Final values for ~p: ~p and ~p~n", [myFuncs:myName(BH), Stat, Capis]),
  {Stat, Capis}.
