%%% ====================================================================================== %%%
%%% ====================================================================================== %%%
%%% @copyright (C) 2023, Cybarete Pty Ltd
%%% @doc
%%% The execution plugin behaviour module defines the callbacks for the
%%% execution of a basic task and provides external functions to use.
%%% @end
%%% ====================================================================================== %%%
%%% ====================================================================================== %%%

-module(base_task_ep).
-compile(export_all).
-include("../base_terms.hrl").

%%% ====================================================================================== %%%
%%%                                 CALLBACK FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function is called when the plugin is first initialised
-callback init(Pars::term(),BH::term())->
    ok.

%% @doc this function is called when the plugin is removed from the system
-callback stop(BH::term())->
    ok.

%% @doc this function is called when the appropriate BASE task shell reaches the scheduled time and requests to start.
-callback request_start(ExecutorHandle::term(),BH::term())->
    {start_task, NewState::term()}
    |{await_start, NewState::term()}
    |{cancel_task, Reason::term(), NewState::term()}.

%% @doc this function is called when the appropriate BASE task is cancelled
%% the task will be removed from the schedule sector and discarded
-callback task_cancel(Reason::term(), TaskState::term(), ExecutorHandle::term(), BH::term())->
    ok.

%% @doc this function is called when a task is resumed after a BASE comes back online.
-callback request_resume(ExecutorHandle::term(),BH::term())->
    {await_resume, NewState::term()}
    |{resume_task, NewState::term()}
    |{end_task, LB::term(), NewState::term()}.

%% @doc this function is called when the appropriate BASE task shell is approved to start.
-callback start_task(TaskState::term(),ExecutorHandle::term(),BH::term())->
    {ok, NewState::term()}
    |{end_task, LB::term(), NewState::term()}.

%% @doc this function is called when the system is restarted and a BASE task which was executing is approved to resume.
-callback resume_task(TaskState::term(),ExecutorHandle::term(),BH::term())->
    {ok,NewState::term()}
    |{end_task, LB::term(), NewState::term()}.

%% @doc this function is called when the system is restarted and a BASE task which was executing is approved to resume.
-callback base_variable_update({VarPageName::term(), VarKey::term(), VarValue::term()},TaskState::term(),ExecutorHandle::term(),BH::term())->
    {ok, NewState::term()}
    |{end_task, LB::term(), NewState::term()}.

%% @doc this function is called when the appropriate BASE task shell has been triggered to end.
-callback end_task(TaskState::term(),ExecutorHandle::term(),BH::term())->
    ok.

%%% ====================================================================================== %%%
%%%                                 EXTERNAL FUNCTIONS
%%% ====================================================================================== %%%

%% @doc this function will trigger the start of a task awaiting start
start_task(ExecutorHandle,BH)->
    base_task_executor:start_task(ExecutorHandle,BH).

%% @doc this function will trigger the resume of a task awaiting resume
resume_task(ExecutorHandle,BH)->
    base_task_executor:resume_task(ExecutorHandle,BH).

%% @doc this function will trigger the ending of a task currently executing
end_task(ExH, LB, BH)->
    base_task_executor:end_task(ExH, LB, BH).

%% @doc this will get the shell of an execution agent
get_shell(ExH)->
    base_task_executor:get_shell(ExH).

%% @doc this will get the schedule data (or data1) of an execution agent
get_schedule_data(ExH,BH)->
    base_task_executor:get_data1(ExH,BH).

%% @doc this will get the execution data (or data2) of an execution agent
get_execution_data(ExH,BH)->
    base_task_executor:get_data2(ExH,BH).

%% @doc this will write the execution data (or data2) of an execution agent
write_execution_data(Data,Shell,BH)->
    base_task_executor:write_data2(Data,Shell,BH).