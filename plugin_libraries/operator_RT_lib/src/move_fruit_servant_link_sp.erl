%%%-------------------------------------------------------------------
%%% @author LENOVO
%%% @copyright (C) 2023, <COMPANY>
%%% @doc
%%%
%%% @end
%%% Created : 10. Oct 2023 17:10
%%%-------------------------------------------------------------------
-module(move_fruit_servant_link_sp).
-author("LENOVO").
-behaviour(base_link_servant_sp).
%% API
-export([init/2, stop/1, request_start_negotiation/3, generate_proposal/4, proposal_accepted/3]).


init(Pars, BH) ->
  ok.

stop(BH) ->
  ok.

request_start_negotiation(MasterBC, NegH, BH) ->
  {start,no_state}.

generate_proposal(Requirements, PluginState, NegH, BH) ->

  AvailabilityTime = check_availability(BH),
  io:format("Generating proposal: ~p~n",[AvailabilityTime]),
  Result = lists:foldl(fun(Elem, Acc)->
    case Elem of
      #{<<"AVAILABILITY">>:=Time} ->
        case Time of                %% ADD all the cases here
          any-> true;
          true-> if
                   AvailabilityTime =< Time ->
                     Acc;
                   true ->
                     false
                 end
        end;
      _other->Acc
    end
                       end, true, Requirements),

  case Result of
    true->
      Proposal = #{<<"TIME">>=>AvailabilityTime},
      {proposal,Proposal,nostate};
    false-> {refuse,not_qualified}
  end.

proposal_accepted(PluginState, NegH, BH) ->
  io:format("Servant accepted promise~n"),
  Tsched = base:get_origo(),
  LinkID = list_to_binary(ref_to_list(make_ref())),
  Data1 = nodata,
  {promise, Tsched, LinkID,Data1, no_state}.

%% ________________________________________________________________
%% External Functions
%% ________________________________________________________________

check_availability(BH) ->
  TasksSched = base_schedule:get_all_tasks(BH),
  TasksExe = base_execution:get_all_tasks(BH),
  KeyS = maps:keys(TasksSched),
  KeyE = maps:keys(TasksExe),
  TimeSced = extract_sched_time(KeyS, TasksSched, 0),
  TimeExe = extract_exe_time(KeyE, TasksExe, 0),

  %% Choose the highest time
  if
    TimeExe > TimeSced ->
      TimeExe;
    true ->
      TimeSced
  end.

extract_sched_time([],_,_)->
  base:get_origo();

extract_sched_time([Key | Rest], Tasks, MaxTime) ->
  TaskShell = maps:get(Key, Tasks),

  {ThisTime} = case TaskShell of
                 {_, {task_shell, Time, _, _,
                   _, _, task, 1}, undefined, #{}, #{}, #{}} ->
                   {Time};
                 _ ->
                   {base:get_origo()} %% Needs to be fixed later
               end,

  {UpdatedMaxTime} = if
                     ThisTime > MaxTime -> {ThisTime};
                     true -> {MaxTime}
                   end,

  case Rest of
    [] -> UpdatedMaxTime;
    _ -> extract_sched_time(Rest, Tasks, UpdatedMaxTime)
  end.

extract_exe_time([],_,_)->
  base:get_origo();

extract_exe_time([Key | Rest], Tasks, MaxTime) ->
  TaskShell = maps:get(Key, Tasks),

  {ThisTime} = case TaskShell of
                 {_, {task_shell, _, Time, _,
                   _, _, task, 2}, undefined, #{}, #{}, #{}} ->
                   {Time};
                 _ -> io:format("ERROR in exe!!!!!!~n"),
                   {error}
               end,

  {UpdatedMaxTime} = if
                       ThisTime > MaxTime -> {ThisTime};
                       true -> {MaxTime}
                     end,

  case Rest of
    [] -> UpdatedMaxTime;
    _ -> extract_exe_time(Rest, Tasks, UpdatedMaxTime)
  end.







