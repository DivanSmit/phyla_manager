
-module(control_center_http_session_ep).
-behavior(base_task_ep).
-include("../../../base_include_libs/base_terms.hrl").

-record(task_state,{server_pid::pid(),server_state::term(),server_listener_pid::pid(),callback_module::term()}).
-define(INTERFACE_SERVER_TASK,<<"HTTP_INTERFACE_SERVER">>).
-define(HTTP_CONNECTOR_PAGE,<<"HTTP_CONNECTOR_PAGE">>).
-record(http_session,{user_details::term(),session_pid::pid(),last_active::number()}).
-record(user_request,{session_id::term(),content::term(), request_pid::pid()}).
-record(user_reply,{session_id::term(),content::term()}).


-export([request_start/2, start_task_error/3, request_resume/2,
  resume_task/3, start_task/3, end_task/3, init/2, stop/1, task_cancel/4, base_variable_update/4]).

%% ============================================================================================%%
%%                                    BASE TASK CALLBACKS
%% ============================================================================================%%

init([ConnectorServerFolder,Port], BH) ->
  io:format("Interface has started~n"),
  code:add_patha("C:/Users/LENOVO/Desktop/base-getting-started/phyla_manager_BASE/plugin_libraries/supplementary_modules/ebin"),


  spawn(fun()->
    base:wait_for_base_ready(BH),
    schedule_this_behaviour(ConnectorServerFolder,Port,BH)end),
  ok.

stop(BH) ->
  ok.

request_start(ExecutorHandle, BH) ->
  {start_task,#task_state{}}.

start_task_error(ExecutorHandle, Error, BH) ->
  ok.

request_resume(ExecutorHandle, BH) ->
  {end_task,discard,#task_state{}}.

resume_task(TaskState, ExecutorHandle, BH) ->
  {end_task,discard,#task_state{}}.

start_task(TaskState, ExecutorHandle, BH) ->
  ServerDir = base_attributes:read(?HTTP_CONNECTOR_PAGE,<<"SERVER_DIR">>,BH),
  Port = base_attributes:read(?HTTP_CONNECTOR_PAGE,<<"PORT">>,BH),
  filelib:ensure_dir(ServerDir),
  ExecutorPID = self(),
  GenServerPID = spawn_link(fun()-> http_session_gen_server:start_server(ServerDir, Port, ExecutorPID, BH) end),
  {ok,TaskState#task_state{server_pid = GenServerPID,server_state = started}}.

end_task(ExecutorHandle, TaskState,BH) when is_record(TaskState,task_state) ->
  inets:stop(stand_alone,TaskState#task_state.server_pid),
  discard;

end_task(ExecutorHandle, TaskState, BH)->
  discard.

schedule_this_behaviour(ServerFolder,Port,BH)->
  base:wait_for_base_ready(BH),
  TSCHED = base:get_origo(),
  Data1 = #{<<"port">>=>Port,<<"server_folder">>=>ServerFolder},
  base_attributes:write(?HTTP_CONNECTOR_PAGE,<<"SERVER_DIR">>,binary_to_list(ServerFolder),BH),
  base_attributes:write(?HTTP_CONNECTOR_PAGE,<<"PORT">>,Port,BH),
  io:format("The HTTP is requested to start~n"),
  base_task_sp:schedule_task(TSCHED,?INTERFACE_SERVER_TASK,?INTERFACE_SERVER_TASK,Data1,BH).

task_cancel(Reason, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).

base_variable_update(_, TaskState, ExecutorHandle, BH) ->
  erlang:error(not_implemented).