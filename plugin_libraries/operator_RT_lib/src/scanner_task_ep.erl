-module(scanner_task_ep).
-behavior(base_task_ep).
-include("../../../base_include_libs/base_terms.hrl").
-export([init/2, stop/1, request_start/2, start_task_error/3, request_resume/2, resume_task/3, start_task/3, end_task/3, handle_request/3, handle_signal/3]).

%% ============================================================================================%%
%%                                    BASE TASK CALLBACKS
%% ============================================================================================%%

init(Parameters, BH) ->
  ok.

stop(BH) ->
  ok.

request_start(ExecutorHandle, BH) ->
  {start_task, {}}.

start_task_error(Reason, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

request_resume(ExecutorHandle, BH) ->
  {end_task, discard, no_state}.

resume_task(TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

start_task(TaskState, ExecutorHandle, BH) ->
  % send out signal to each planet
  DR = #base_discover_query{capabilities = <<"PLANET_INSTANCE_INFO">>},
  TargetBCs = bhive:discover_bases(DR,BH),
  ListOfMaps = base_signal:emit_request(TargetBCs, <<"POSITION">>,<<"NO PAYLOAD">>,BH),
  % calculate distance to each planet
  if
    length(ListOfMaps) > 0 ->
      lists:foldl(fun(ReturnMap, Acc)->
        calculate_distance(ReturnMap, BH)
                  end, null, ListOfMaps);
    true-> no_planets
  end,

  spawn(fun()->
    TimerValue = 10000, % boost every second
    timer:sleep(TimerValue), % wait before scheduling the task again
    scanner_task_sp:handle_task_request(nothing, BH) end),

  {end_task, discard, boosted}.

end_task(TaskState, ExecutorHandle, BH) ->
  ok.

handle_request(Tag, Payload, BH) ->
  erlang:error(not_implemented).

handle_signal(Tag, Payload, BH) ->
  erlang:error(not_implemented).

%% ============================================================================================%%
%%                                    HELPER FUNCTIONS
%% ============================================================================================%%

calculate_distance(MapReply, BH)->
  case MapReply of
    #{<<"planetBC">>:=PlanetBC,<<"x">>:=Xcoord,<<"y">>:=Ycoord}->
      PlanetName = base_business_card:get_name(PlanetBC),
      MyBC = base:get_my_bc(BH),
      MyName = base_business_card:get_name(MyBC),
      MyXcord = base_variables:read(<<"POSITION">>,<<"x">>,BH),
      MyYcord = base_variables:read(<<"POSITION">>,<<"y">>,BH),

      Xdiff = abs(MyXcord - Xcoord),
      Ydiff = abs(MyYcord - Ycoord),
      Distance = math:sqrt(math:pow(Xdiff,2)+math:pow(Ydiff,2)),

      io:format("~n [Explorer ~p] is ~p light years away from planet ~p ~n",[MyName, round(Distance), PlanetName]);
      _other-> do_nothing
  end.

