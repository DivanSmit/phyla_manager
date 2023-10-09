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
